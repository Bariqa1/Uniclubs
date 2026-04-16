from fastapi import APIRouter, HTTPException
from app.ai.recommender import get_recommendations, invalidate_cache

router = APIRouter()


@router.get("/recommendations/{user_id}")
def recommendations(user_id: str, limit: int = 10):
    try:
        events = get_recommendations(user_id, num=limit)
        return {"userId": user_id, "count": len(events), "events": events}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/recommendations/{user_id}/cache")
def clear_cache(user_id: str):
    invalidate_cache(user_id)
    return {"message": f"Cache cleared for user {user_id}"}
