import os
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

_db = None

def get_db():
    global _db
    if _db is None:
        if not firebase_admin._apps:
            base_dir = Path(__file__).resolve().parent.parent.parent

            cred_file_name = os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json")

            cred_path = os.path.join(base_dir, cred_file_name)

            print(f"🔍 Looking for Firebase key at: {cred_path}")

            if not os.path.exists(cred_path):
                raise FileNotFoundError(f"❌ لم يتم العثور على ملف المفتاح في: {cred_path}")

            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
    return _db