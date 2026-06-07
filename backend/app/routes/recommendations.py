from fastapi import APIRouter, HTTPException
from app.ai.recommender import get_recommendations, invalidate_cache
from app.utils.firebase_config import get_db

router = APIRouter()

@router.get("/recommendations/{user_id}")
def recommendations(user_id: str, limit: int = 10):
    try:
        db = get_db()
        user_doc = db.collection('users').document(user_id).get()

        # الافتراضي هو السماح بالتحليلات
        allow_recommendations = True

        if user_doc.exists:
            user_data = user_doc.to_dict()
            # نجلب قيمة recommendationsOptOut (إذا لم يجدها يعتبرها False)
            opt_out = user_data.get('recommendationsOptOut', False)
            # العلاقة عكسية: إذا عمل OptOut (True) إذن السماح يكون (False)
            allow_recommendations = not opt_out

        if allow_recommendations:
            print(f"✅ DEBUG: Privacy OFF (OptOut=False) for {user_id}. Using AI (TFRS).")
            events = get_recommendations(user_id, num=limit)
            is_personalized = True
        else:
            print(f"🚫 DEBUG: Privacy ON (OptOut=True) for {user_id}. Returning GENERAL events.")
            events_ref = db.collection('events').limit(limit).stream()
            events = []
            for doc in events_ref:
                event_data = doc.to_dict()
                event_data['eventId'] = doc.id
                events.append(event_data)
            is_personalized = False

        return {
            "userId": user_id,
            "count": len(events),
            "is_personalized": is_personalized,
            "events": events
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/recommendations/{user_id}/cache")
def clear_cache(user_id: str):
    invalidate_cache(user_id)
    return {"message": f"Cache cleared for user {user_id}"}