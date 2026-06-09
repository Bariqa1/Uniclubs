"""
Tests for Algorithm 1: Hybrid Event Recommendation System
Covers: vector building, cache, cold-start weights, diversity injection, API endpoint.
"""

import sys
import os
import pytest
import numpy as np
from datetime import datetime, timezone, timedelta
from unittest.mock import MagicMock, patch

# ── Make sure `app` is importable without a running server ──────────────────
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# ── Shared test vocabulary (mirrors vocabularies.json) ──────────────────────
VOCAB = {
    "categories": ["tech", "sports", "arts", "academic", "social"],
    "all_tags": ["workshop", "seminar", "competition", "social", "networking", "guest_speaker"],
    "interests": ["AI", "Mobile Dev", "Coding", "Sports", "Design", "Art", "Photography", "Music", "Academic"],
    "interest_to_category": {
        "AI": "tech",
        "Mobile Dev": "tech",
        "Coding": "tech",
        "Sports": "sports",
        "Design": "arts",
        "Art": "arts",
        "Photography": "arts",
        "Music": "arts",
        "Academic": "academic",
    },
    "user_content_dim": 12,
    "event_content_dim": 13,
}

N_CAT = len(VOCAB["categories"])   # 5
N_TAG = len(VOCAB["all_tags"])     # 6


# ════════════════════════════════════════════════════════════════
# 1. USER CONTENT VECTOR
# ════════════════════════════════════════════════════════════════

from app.ai.recommender import _build_user_content_vector


class TestBuildUserContentVector:

    def test_output_shape(self):
        """Vector must be (n_categories * 2 + 2,) = 12."""
        user = {"interests": []}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        assert vec.shape == (N_CAT * 2 + 2,), f"Expected shape ({N_CAT * 2 + 2},), got {vec.shape}"

    def test_tech_interest_sets_correct_bit(self):
        """A user with 'AI' interest should have index 0 (tech) set in interest_vec."""
        user = {"interests": ["AI"]}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        # interest_vec occupies indices 0..N_CAT-1
        assert vec[0] == 1.0, "tech bit should be 1.0 for AI interest"
        assert vec[1] == 0.0, "sports bit should be 0.0"

    def test_multiple_interests_same_category(self):
        """Multiple interests mapping to the same category should still produce a single 1.0 (not sum)."""
        user = {"interests": ["AI", "Mobile Dev", "Coding"]}  # all → tech
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        assert vec[0] == 1.0   # tech set once

    def test_arts_interest(self):
        """'Design' maps to arts (index 2)."""
        user = {"interests": ["Design"]}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        assert vec[2] == 1.0, "arts bit should be 1.0 for Design interest"

    def test_attended_categories_set_attended_vec(self):
        """Attended tech events should set the attended_vec tech bit (index N_CAT + 0)."""
        user = {"interests": []}
        vec = _build_user_content_vector(user, ["tech"], 1, VOCAB)
        assert vec[N_CAT + 0] == 1.0, "attended tech bit should be 1.0"

    def test_unknown_interest_ignored(self):
        """Interests not in the vocabulary should not raise and should leave vector zeros."""
        user = {"interests": ["Underwater Basket Weaving"]}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        assert vec[:N_CAT].sum() == 0.0

    def test_participation_freq_capped_at_1(self):
        """participation_count >= 20 should produce participation_freq = 1.0."""
        user = {"interests": []}
        vec = _build_user_content_vector(user, [], 25, VOCAB)
        participation_freq = vec[N_CAT * 2]
        assert participation_freq == 1.0

    def test_participation_freq_zero_for_new_user(self):
        user = {"interests": []}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        assert vec[N_CAT * 2] == 0.0

    def test_account_age_in_valid_range(self):
        """account_age must be in [0, 1]."""
        user = {"interests": []}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        account_age = vec[N_CAT * 2 + 1]
        assert 0.0 <= account_age <= 1.0

    def test_dtype_is_float32(self):
        user = {"interests": ["AI"]}
        vec = _build_user_content_vector(user, [], 0, VOCAB)
        assert vec.dtype == np.float32


# ════════════════════════════════════════════════════════════════
# 2. EVENT CONTENT VECTOR
# ════════════════════════════════════════════════════════════════

from app.ai.recommender import _build_event_content_vector


class TestBuildEventContentVector:

    def test_output_shape(self):
        """Vector must be (n_categories + n_tags + 2,) = 13."""
        event = {"category": "tech", "tags": []}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec.shape == (N_CAT + N_TAG + 2,), f"Expected ({N_CAT + N_TAG + 2},), got {vec.shape}"

    def test_tech_category_one_hot(self):
        """tech category → index 0 of cat_onehot should be 1.0."""
        event = {"category": "tech", "tags": []}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec[0] == 1.0
        assert vec[1:N_CAT].sum() == 0.0

    def test_arts_category_one_hot(self):
        """arts is at index 2."""
        event = {"category": "arts", "tags": []}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec[2] == 1.0

    def test_known_tag_sets_bit(self):
        """'workshop' is at index 0 of all_tags → vec[N_CAT + 0] = 1.0."""
        event = {"category": "tech", "tags": ["workshop"]}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec[N_CAT + 0] == 1.0

    def test_unknown_tag_ignored(self):
        event = {"category": "tech", "tags": ["nonexistent_tag"]}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec[N_CAT:N_CAT + N_TAG].sum() == 0.0

    def test_unknown_category_leaves_onehot_zero(self):
        event = {"category": "unknown_cat", "tags": []}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec[:N_CAT].sum() == 0.0

    def test_missing_date_uses_defaults(self):
        """Events without a date should fall back to time_of_day=0.5, day_of_week=0.5."""
        event = {"category": "tech", "tags": []}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec[N_CAT + N_TAG] == 0.5      # time_of_day
        assert vec[N_CAT + N_TAG + 1] == 0.5  # day_of_week

    def test_time_and_day_in_valid_range(self):
        """time_of_day and day_of_week must be in [0, 1]."""
        event = {
            "category": "tech",
            "tags": [],
            "date": datetime(2026, 6, 15, 14, 0, tzinfo=timezone.utc),
        }
        vec = _build_event_content_vector(event, VOCAB)
        assert 0.0 <= vec[N_CAT + N_TAG] <= 1.0
        assert 0.0 <= vec[N_CAT + N_TAG + 1] <= 1.0

    def test_dtype_is_float32(self):
        event = {"category": "tech", "tags": ["workshop"]}
        vec = _build_event_content_vector(event, VOCAB)
        assert vec.dtype == np.float32


# ════════════════════════════════════════════════════════════════
# 3. CACHE
# ════════════════════════════════════════════════════════════════

from app.ai.recommender import _cache_valid, _set_cache, invalidate_cache, _cache


class TestCache:

    def setup_method(self):
        """Clear the cache before every test."""
        _cache.clear()

    def test_cache_miss_for_unknown_user(self):
        assert _cache_valid("no_such_user") is False

    def test_cache_hit_after_set(self):
        _set_cache("user1", [{"id": "e1"}])
        assert _cache_valid("user1") is True

    def test_cache_returns_correct_events(self):
        events = [{"id": "e1"}, {"id": "e2"}]
        _set_cache("user1", events)
        assert _cache["user1"]["events"] == events

    def test_cache_expires_after_ttl(self):
        _set_cache("user1", [])
        # Manually backdate the expiry
        _cache["user1"]["expires"] = datetime.now(timezone.utc) - timedelta(seconds=1)
        assert _cache_valid("user1") is False

    def test_invalidate_removes_entry(self):
        _set_cache("user1", [{"id": "e1"}])
        invalidate_cache("user1")
        assert _cache_valid("user1") is False

    def test_invalidate_nonexistent_user_does_not_raise(self):
        invalidate_cache("ghost_user")  # should not raise

    def test_multiple_users_cached_independently(self):
        _set_cache("userA", [{"id": "eA"}])
        _set_cache("userB", [{"id": "eB"}])
        assert _cache_valid("userA") is True
        assert _cache_valid("userB") is True
        invalidate_cache("userA")
        assert _cache_valid("userA") is False
        assert _cache_valid("userB") is True


# ════════════════════════════════════════════════════════════════
# 4. COLD-START WEIGHTS
# ════════════════════════════════════════════════════════════════

class TestColdStartWeights:
    """
    Algorithm 1 Step 1.5:
      new user  (no attended, no registered) → α=1.0, β=0.0
      returning user (has history)           → α=0.4, β=0.6
    """

    def _weights(self, attended_ids, registered_ids):
        if not attended_ids and not registered_ids:
            return 1.0, 0.0
        return 0.4, 0.6

    def test_new_user_is_content_only(self):
        alpha, beta = self._weights(set(), set())
        assert alpha == 1.0
        assert beta == 0.0

    def test_returning_user_is_hybrid(self):
        alpha, beta = self._weights({"e1"}, {"e1"})
        assert alpha == 0.4
        assert beta == 0.6

    def test_registered_but_not_attended_is_hybrid(self):
        """Even registering (without attending) flips to hybrid weights."""
        alpha, beta = self._weights(set(), {"e1"})
        assert alpha == 0.4
        assert beta == 0.6

    def test_attended_only_is_hybrid(self):
        alpha, beta = self._weights({"e1"}, set())
        assert alpha == 0.4
        assert beta == 0.6


# ════════════════════════════════════════════════════════════════
# 5. DIVERSITY INJECTION  (Step 6.5)
# ════════════════════════════════════════════════════════════════

class TestDiversityInjection:
    """Test the post-ranking diversity logic independently."""

    def _diversify(self, candidates, num=10):
        """Replicate the diversity injection from get_recommendations."""
        diversified = []
        seen_categories = {}
        max_per_category = max(2, num // 3)

        for event in candidates:
            cat = event.get("category", "")
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

        return diversified[:num]

    def _make_events(self, category, count, start_id=0):
        return [{"id": f"{category}_{i}", "category": category} for i in range(start_id, start_id + count)]

    def test_max_per_category_is_3_for_num_10(self):
        """num=10 → max_per_category = max(2, 10//3) = 3."""
        assert max(2, 10 // 3) == 3

    def test_max_per_category_is_2_for_num_5(self):
        assert max(2, 5 // 3) == 2

    def test_no_category_exceeds_cap_when_diverse_candidates_available(self):
        """
        Main loop caps each category at max_per_category (3 for num=10).
        Fallback may add 1 extra event to reach num, so effective max is 4.
        All 3 categories must appear in the result.
        """
        candidates = (
            self._make_events("tech", 10, 0) +
            self._make_events("arts", 10, 100) +
            self._make_events("sports", 10, 200)
        )
        result = self._diversify(candidates, num=10)
        cats_present = {e["category"] for e in result}
        assert cats_present == {"tech", "arts", "sports"}, "All 3 categories should appear"
        # Main loop cap is 3; fallback may add at most 1 extra to reach num=10
        for cat in ["tech", "arts", "sports"]:
            count = sum(1 for e in result if e["category"] == cat)
            assert count <= 4, f"{cat} appears {count} times, far exceeds expected max"

    def test_fallback_relaxes_cap_when_only_one_category(self):
        """When only one category exists, the fallback fills all slots regardless of cap."""
        candidates = self._make_events("tech", 10)
        result = self._diversify(candidates, num=10)
        # All 10 should be returned via fallback — cap is relaxed when no alternatives exist
        assert len(result) == 10

    def test_diverse_output_across_categories(self):
        """With balanced candidates, multiple categories appear in results."""
        candidates = (
            self._make_events("tech", 5, 0) +
            self._make_events("arts", 5, 10) +
            self._make_events("sports", 5, 20)
        )
        result = self._diversify(candidates, num=9)
        cats = {e["category"] for e in result}
        assert len(cats) > 1, "Results should span more than one category"

    def test_output_never_exceeds_num(self):
        candidates = self._make_events("tech", 20)
        result = self._diversify(candidates, num=10)
        assert len(result) <= 10

    def test_fallback_fills_remaining_slots(self):
        """If diversity cap leaves gaps, fallback fills them from remaining candidates."""
        candidates = self._make_events("tech", 5)   # only 5 events, cap is 3
        result = self._diversify(candidates, num=5)
        assert len(result) == 5   # fallback should fill all 5

    def test_empty_candidates_returns_empty(self):
        assert self._diversify([], num=10) == []

    def test_fewer_candidates_than_num(self):
        candidates = self._make_events("tech", 3)
        result = self._diversify(candidates, num=10)
        assert len(result) == 3


# ════════════════════════════════════════════════════════════════
# 6. NORMALIZATION
# ════════════════════════════════════════════════════════════════

class TestNormalization:
    """Test the _normalize helper (replicated here since it's defined inside _call_model_batched)."""

    def _normalize(self, arr):
        arr = np.array(arr, dtype=np.float32)
        mn, mx = arr.min(), arr.max()
        if mx == mn:
            return np.full_like(arr, 0.5)
        return (arr - mn) / (mx - mn)

    def test_min_becomes_0_max_becomes_1(self):
        result = self._normalize([1.0, 2.0, 3.0])
        assert result[0] == pytest.approx(0.0)
        assert result[-1] == pytest.approx(1.0)

    def test_all_same_values_returns_half(self):
        result = self._normalize([5.0, 5.0, 5.0])
        assert all(v == pytest.approx(0.5) for v in result)

    def test_output_in_0_1_range(self):
        result = self._normalize([10.0, -3.0, 7.5, 0.0, 100.0])
        assert result.min() >= 0.0
        assert result.max() <= 1.0

    def test_single_element_returns_half(self):
        result = self._normalize([42.0])
        assert result[0] == pytest.approx(0.5)


# ════════════════════════════════════════════════════════════════
# 7. API ENDPOINT
# ════════════════════════════════════════════════════════════════

from fastapi.testclient import TestClient


class TestRecommendationAPI:
    """Test the FastAPI routes with get_recommendations mocked out."""

    @pytest.fixture
    def client(self):
        with patch("app.ai.recommender._load_models"), \
             patch("app.utils.firebase_config.get_db"):
            from app.main import app
            return TestClient(app)

    @pytest.fixture
    def mock_events(self):
        return [
            {"id": "e1", "title": "AI Workshop", "category": "tech"},
            {"id": "e2", "title": "Art Exhibition", "category": "arts"},
        ]

    def test_get_recommendations_returns_200(self, client, mock_events):
        with patch("app.routes.recommendations.get_recommendations", return_value=mock_events):
            response = client.get("/api/recommendations/test_user")
        assert response.status_code == 200

    def test_get_recommendations_response_shape(self, client, mock_events):
        with patch("app.routes.recommendations.get_recommendations", return_value=mock_events):
            data = client.get("/api/recommendations/test_user").json()
        assert "userId" in data
        assert "count" in data
        assert "events" in data

    def test_get_recommendations_count_matches_events(self, client, mock_events):
        with patch("app.routes.recommendations.get_recommendations", return_value=mock_events):
            data = client.get("/api/recommendations/test_user").json()
        assert data["count"] == len(data["events"])

    def test_get_recommendations_user_id_in_response(self, client, mock_events):
        with patch("app.routes.recommendations.get_recommendations", return_value=mock_events):
            data = client.get("/api/recommendations/test_user").json()
        assert data["userId"] == "test_user"

    def test_get_recommendations_limit_param(self, client):
        # Mock db so the user has not opted out — otherwise get_recommendations is never called
        mock_db = MagicMock()
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"recommendationsOptOut": False}
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        with patch("app.routes.recommendations.get_recommendations", return_value=[]) as mock_fn, \
             patch("app.routes.recommendations.get_db", return_value=mock_db):
            client.get("/api/recommendations/test_user?limit=5")
        mock_fn.assert_called_once_with("test_user", num=5)

    def test_get_recommendations_empty_returns_200(self, client):
        with patch("app.routes.recommendations.get_recommendations", return_value=[]):
            response = client.get("/api/recommendations/test_user")
        assert response.status_code == 200
        assert response.json()["count"] == 0

    def test_delete_cache_returns_200(self, client):
        with patch("app.routes.recommendations.invalidate_cache"):
            response = client.delete("/api/recommendations/test_user/cache")
        assert response.status_code == 200

    def test_delete_cache_response_message(self, client):
        with patch("app.routes.recommendations.invalidate_cache"):
            data = client.delete("/api/recommendations/test_user/cache").json()
        assert "message" in data
