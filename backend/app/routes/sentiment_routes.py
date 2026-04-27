import os
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
from app.utils.firebase_config import get_db

router = APIRouter(prefix="/ai", tags=["Sentiment Analysis"])

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel(
    model_name='gemini-1.5-flash',
    generation_config={"response_mime_type": "application/json"}
)

class FeedbackRequest(BaseModel):
    feedback_id: str
    text: str

@router.post("/analyze-sentiment")
async def analyze_sentiment(request: FeedbackRequest):
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="Feedback text cannot be empty")

    db = get_db()
    fallback_result = {
        "sentimentLabel": "Neutral",
        "sentimentScore": 0.5,
        "status": "fallback"
    }

    try:
        prompt = f"""
        Analyze the sentiment of this student feedback for 'UniClubs'.
        Return a JSON object:
        {{
            "sentimentLabel": "Positive" | "Neutral" | "Negative",
            "sentimentScore": float (0.0 to 1.0)
        }}
        Feedback: "{request.text}"
        """

        response = model.generate_content(prompt)

        if response and response.text:
            result = json.loads(response.text)
            result["status"] = "success"
        else:
            result = fallback_result

    except Exception:
        result = fallback_result

    try:
        doc_ref = db.collection("feedback").document(request.feedback_id)
        doc_ref.update({
            "sentimentLabel": result['sentimentLabel'],
            "sentimentScore": result['sentimentScore'],
            "aiStatus": result['status'],
            "analyzedAt": genai.protos.Timestamp()
        })
        return {"status": result['status'], "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))