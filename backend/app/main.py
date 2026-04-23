from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from pydantic import BaseModel
import google.generativeai as genai
from app.chat_service import *
import os
from app.ai.attendance_predictor import AttendancePredictor


load_dotenv()
attendance_predictor = AttendancePredictor()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Pre-load models on startup so the first request is fast
    try:
        from app.ai.recommender import _load_models
        _load_models()
        print("✅ Recommendation models loaded.")
    except Exception as e:
        print(f"⚠️  Could not pre-load models: {e}")
    yield

app = FastAPI(title="UniClubs API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.routes import recommendations
app.include_router(recommendations.router, prefix="/api")

@app.get("/")
def root():
    return {"status": "UniClubs API is running"}

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-flash-latest")

class Message(BaseModel):
    message: str
    user_id: str


@app.post("/chat")
def chat(data: Message):
    try:
        history = get_history(data.user_id)
        prompt = f"""
        You are UniClubs Assistant.

        Help student with:
        - finding clubs
        - event registration
        - app navigation
        - university activities

        Previous conversation: {history}
        User question: {data.message}"""


        response = model.generate_content(prompt)
        ai_reply =response.text or "No response"

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


@app.post("/predict-attendance")
def predict_attendance(data: AttendanceRequest):
    try:
        prediction = attendance_predictor.predict(data.dict())

        return {
            "predicted_attendance": prediction
        }

    except Exception as e:
        return {"error": str(e)}
