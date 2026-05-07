from app.utils.firebase_config import get_db
from datetime import datetime
from google.cloud.firestore_v1 import Query

def save_message(user_id, role, text):
    db = get_db()
    db.collection("users") \
      .document(user_id) \
      .collection("messages") \
      .add({
           "text": text,
           "role": role,
           "timestamp": datetime.utcnow()
      })

def get_history(user_id):
    db = get_db()
    messages_ref = db.collection("users") \
                     .document(user_id) \
                     .collection("messages") \
                     .order_by("timestamp", direction=Query.DESCENDING) \
                     .limit(20)

    docs = messages_ref.get()

    history = []
    for doc in docs:
        data = doc.to_dict()
        ts = data.get("timestamp")
        history.append({
            "content": data["text"],
            "role": data["role"],
            "userId": user_id if data["role"] == "user" else "0",
            "userName": "AI Assistant" if data["role"] =="ai" else "User",
            "createdAt": ts.isoformat() if ts else ""
        })

    return history