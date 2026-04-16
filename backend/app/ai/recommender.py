"""
Algorithm 1: Hybrid Event Recommendation System
Score(u,e) = α × ContentScore(u,e) + β × CollaborativeScore(u,e)
"""

import json
import os
import numpy as np
import tensorflow as tf
from datetime import datetime, timezone, timedelta
from app.utils.firebase_config import get_db

_MODEL_DIR = os.path.join(os.path.dirname(__file__), "../../ml_models/recommendation_model")

_user_collab  = None
_user_content = None
_event_collab = None
_event_content = None
_vocab = None

_cache: dict = {}
CACHE_TTL_MINUTES = 30


def _load_models():
    global _user_collab, _user_content, _event_collab, _event_content, _vocab
    if _user_collab is None:
        _user_collab   = tf.saved_model.load(os.path.join(_MODEL_DIR, "user_collab"))
        _user_content  = tf.saved_model.load(os.path.join(_MODEL_DIR, "user_content"))
        _event_collab  = tf.saved_model.load(os.path.join(_MODEL_DIR, "event_collab"))
        _event_content = tf.saved_model.load(os.path.join(_MODEL_DIR, "event_content"))
        with open(os.path.join(_MODEL_DIR, "vocabularies.json")) as f:
            _vocab = json.load(f)
        _warmup_models()
    return _user_collab, _user_content, _event_collab, _event_content, _vocab


def _warmup_models():
    """Run dummy inference to trigger TF JIT compilation at startup, not on first request."""
    print("⏳ Warming up TF models (JIT compile)...")
    with open(os.path.join(_MODEL_DIR, "vocabularies.json")) as f:
        vocab = json.load(f)

    n_cat = len(vocab["categories"])
    n_tag = len(vocab["all_tags"])
    user_cv = np.zeros(n_cat * 2 + 2, dtype=np.float32)
    event_cv = np.zeros(n_cat + n_tag + 2, dtype=np.float32)

    _user_collab.signatures["serving_default"](user_id=tf.constant(["__warmup__"]))
    _user_content.signatures["serving_default"](user_content=tf.constant([user_cv]))
    _event_collab.signatures["serving_default"](event_id=tf.constant(["__warmup__"]))
    _event_content.signatures["serving_default"](event_content=tf.constant([event_cv]))
    print("✅ TF models warmed up.")


def _cache_valid(user_id: str) -> bool:
    entry = _cache.get(user_id)
    return bool(entry and datetime.now(timezone.utc) < entry["expires"])


def _set_cache(user_id: str, events: list):
    _cache[user_id] = {
        "events": events,
        "expires": datetime.now(timezone.utc) + timedelta(minutes=CACHE_TTL_MINUTES),
    }


def invalidate_cache(user_id: str):
    _cache.pop(user_id, None)


def _build_user_content_vector(user: dict, attended_categories: list, participation_count: int, vocab: dict) -> np.ndarray:
    categories = vocab["categories"]
    i2c = vocab["interest_to_category"]

    interest_vec = np.zeros(len(categories), dtype=np.float32)
    for interest in user.get("interests", []):
        cat = i2c.get(interest)
        if cat in categories:
            interest_vec[categories.index(cat)] = 1.0

    attended_vec = np.zeros(len(categories), dtype=np.float32)
    for cat in attended_categories:
        if cat in categories:
            attended_vec[categories.index(cat)] = 1.0

    participation_freq = min(participation_count / 20.0, 1.0)
    created_at = user.get("createdAt")
    if created_at and hasattr(created_at, "timestamp"):
        age_days = (datetime.now(timezone.utc).timestamp() - created_at.timestamp()) / 86400
    else:
        age_days = 365
    account_age = min(age_days / 730.0, 1.0)

    return np.concatenate([
        interest_vec,
        attended_vec,
        np.array([participation_freq], dtype=np.float32),
        np.array([account_age], dtype=np.float32),
    ])


def _build_event_content_vector(event: dict, vocab: dict) -> np.ndarray:
    categories = vocab["categories"]
    all_tags = vocab["all_tags"]

    cat_onehot = np.zeros(len(categories), dtype=np.float32)
    cat = event.get("category", "")
    if cat in categories:
        cat_onehot[categories.index(cat)] = 1.0

    tag_vec = np.zeros(len(all_tags), dtype=np.float32)
    for tag in event.get("tags", []):
        if tag in all_tags:
            tag_vec[all_tags.index(tag)] = 1.0

    event_date = event.get("date")
    if event_date and hasattr(event_date, "timestamp"):
        dt = datetime.fromtimestamp(event_date.timestamp(), tz=timezone.utc)
        time_of_day = dt.hour / 24.0
        day_of_week = dt.weekday() / 7.0
    else:
        time_of_day = 0.5
        day_of_week = 0.5

    return np.concatenate([
        cat_onehot,
        tag_vec,
        np.array([time_of_day], dtype=np.float32),
        np.array([day_of_week], dtype=np.float32),
    ])


def _call_model_batched(user_id: str, user_cv: np.ndarray, candidates: list[dict], vocab: dict,
                        alpha: float, beta: float) -> list[float]:
    """Score all candidates in a single batched TF call instead of one-by-one."""
    u_collab, u_content, e_collab, e_content, _ = _load_models()

    # User embeddings (single call)
    uc_emb  = list(u_collab.signatures["serving_default"](user_id=tf.constant([user_id])).values())[0]
    uco_emb = list(u_content.signatures["serving_default"](user_content=tf.constant([user_cv])).values())[0]

    # Build batched event tensors
    event_ids = [e.get("id", "unknown") for e in candidates]
    event_cvs = np.array([_build_event_content_vector(e, vocab) for e in candidates], dtype=np.float32)

    # Batch calls
    ec_embs  = list(e_collab.signatures["serving_default"](event_id=tf.constant(event_ids)).values())[0]
    eco_embs = list(e_content.signatures["serving_default"](event_content=tf.constant(event_cvs)).values())[0]

    # Scores: dot product of user embedding with each event embedding
    collab_scores  = tf.reduce_sum(uc_emb * ec_embs,  axis=1).numpy()
    content_scores = tf.reduce_sum(uco_emb * eco_embs, axis=1).numpy()

    def _normalize(arr: np.ndarray) -> np.ndarray:
        mn, mx = arr.min(), arr.max()
        if mx == mn:
            return np.full_like(arr, 0.5)
        return (arr - mn) / (mx - mn)

    return (alpha * _normalize(content_scores) + beta * _normalize(collab_scores)).tolist()


def get_recommendations(user_id: str, num: int = 10) -> list[dict]:
    """Algorithm 1 — Hybrid Event Recommendation (CLAUDE.md), Steps 0-7."""

    # Step 0: Check cache
    if _cache_valid(user_id):
        return _cache[user_id]["events"][:num]

    db = get_db()
    _, _, _, _, vocab = _load_models()

    # Step 1: Fetch user profile and interaction history (parallel-friendly: 2 reads only)
    user_doc = db.collection("users").document(user_id).get()
    if not user_doc.exists:
        return []
    user = user_doc.to_dict()
    user["_id"] = user_id

    reg_docs = list(db.collection("registrations").where("userId", "==", user_id).stream())
    registered_event_ids = set()
    attended_event_ids   = set()

    for r in reg_docs:
        d = r.to_dict()
        eid = d.get("eventId")
        if not eid:
            continue
        registered_event_ids.add(eid)
        if d.get("status") == "attended":
            attended_event_ids.add(eid)

    # Step 2: Fetch all upcoming events in ONE query (no per-event reads)
    now = datetime.now(timezone.utc)
    event_docs = list(db.collection("events").where("status", "==", "upcoming").stream())

    candidates = []
    attended_categories = []

    for doc in event_docs:
        d = doc.to_dict()
        d["id"] = doc.id

        # Collect attended categories from the same batch (no extra reads)
        if doc.id in attended_event_ids:
            cat = d.get("category", "")
            if cat:
                attended_categories.append(cat)

        # Skip already-registered or past events
        if doc.id in registered_event_ids:
            continue
        event_date = d.get("date")
        if event_date and hasattr(event_date, "timestamp"):
            if event_date.timestamp() < now.timestamp():
                continue
        candidates.append(d)

    if not candidates:
        return []

    # Step 1.5: Cold-start handling
    if not attended_event_ids and not registered_event_ids:
        alpha, beta = 1.0, 0.0
    else:
        alpha, beta = 0.4, 0.6

    # Step 3: Build user features
    user_cv = _build_user_content_vector(user, attended_categories, len(attended_event_ids), vocab)

    # Step 4: Call TFRS model (batched — all candidates in one call)
    hybrid_scores = _call_model_batched(user_id, user_cv, candidates, vocab, alpha, beta)

    # Step 5: Map scores to events
    for event, score in zip(candidates, hybrid_scores):
        event["_score"] = score

    # Step 6: Rank
    candidates.sort(key=lambda e: e["_score"], reverse=True)

    # Step 6.5: Diversity injection
    diversified: list[dict] = []
    seen_categories: dict[str, int] = {}
    max_per_category = max(2, num // 3)

    for event in candidates:
        cat   = event.get("category", "")
        count = seen_categories.get(cat, 0)
        if count < max_per_category:
            diversified.append(event)
            seen_categories[cat] = count + 1
        if len(diversified) >= num:
            break

    if len(diversified) < num:
        ids_in = {e["id"] for e in diversified}
        for event in candidates:
            if event["id"] not in ids_in:
                diversified.append(event)
            if len(diversified) >= num:
                break

    for e in diversified:
        e.pop("_score", None)

    recommendations = diversified[:num]

    # Step 7: Cache
    _set_cache(user_id, recommendations)
    return recommendations
