from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv
from pydantic import BaseModel
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
from app.services.chat_service import *
import os
import json
from app.ai.attendance_predictor import AttendancePredictor
from app.routes.sentiment_routes import router as sentiment_router

load_dotenv()
attendance_predictor = AttendancePredictor()
limiter = Limiter(key_func=get_remote_address)


if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-flash-latest")

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        from app.ai.recommender import _load_models
        _load_models()
    except Exception:
        pass
    yield

app = FastAPI(title="UniClubs API", version="1.0.0", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

ALLOWED_ORIGINS = [
    "https://uniclubs-f926d.web.app",
    "https://uniclubs-f926d.firebaseapp.com",
    "http://localhost",
    "http://localhost:8080",
    "http://10.0.2.2",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

from app.routes import recommendations
app.include_router(recommendations.router, prefix="/api")

class Message(BaseModel):
    message: str
    user_id: str

class FeedbackAnalysis(BaseModel):
    feedback_id: str
    text: str

@app.get("/")
def root():
    return {"status": "UniClubs API is running"}

@app.post("/analyze-sentiment")
@limiter.limit("10/minute")
async def analyze_sentiment(request: Request, data: FeedbackAnalysis):
    try:
        prompt = f"""
        Analyze the sentiment of this student feedback about a university event.
        Classify it as 'Positive', 'Negative', or 'Neutral'.
        Return the result as JSON with keys: 'label' and 'score' (score between 0 and 1).
        Feedback: "{data.text}"
        """

        response = model.generate_content(prompt)

        result_text = response.text.replace("```json", "").replace("```", "").strip()
        result_data = json.loads(result_text)

        doc_ref = db.collection('feedback').document(data.feedback_id)
        doc_ref.update({
            'sentimentLabel': result_data.get('label', 'Neutral'),
            'sentimentScore': result_data.get('score', 0.5)
        })

        return {"status": "success", "analysis": result_data}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/chat")
@limiter.limit("20/minute")
async def chat(request: Request, data: Message):
    try:
        history = get_history(data.user_id)
        prompt = f"""
        You are UniClubs Assistant.
        Help student with: finding clubs, event registration, app navigation, university activities.
        Previous conversation: {history}
        User question: {data.message}
        Important: Reply in plain text only. Do not use markdown or any special formatting."""

        response = model.generate_content(prompt)
        ai_reply = response.text or "No response"

        save_message(data.user_id, "user", data.message)
        save_message(data.user_id, "ai", ai_reply)

        return {"response": ai_reply}
    except Exception as e:
        return {"response": str(e)}

@app.get("/messages/{user_id}")
def get_messages(user_id: str):
    history = get_history(user_id)
    return {"history": history}

class AttendanceRequest(BaseModel):
    capacity: int
    tags_count: int
    interested_users_count: int
    past_avg_attendance: float
    interest_ratio: float

    category_Arts: int = 0
    category_Business: int = 0
    category_Community: int = 0
    category_Education: int = 0
    category_Health: int = 0
    category_Medical: int = 0
    category_Science: int = 0
    category_Sports: int = 0
    category_Technology: int = 0

app.include_router(recommendations.router, prefix="/api")
app.include_router(sentiment_router)

@app.post("/predict-attendance")
def predict_attendance(data: AttendanceRequest):
    try:
        prediction = attendance_predictor.predict(data.dict())

        return {
            "predicted_attendance": prediction
        }

    except Exception as e:
        return {"error": str(e)}
