import os
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
from app.utils.firebase_config import get_db

router = APIRouter(prefix="/ai", tags=["Sentiment Analysis"])

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-flash-latest")

class FeedbackRequest(BaseModel):
    feedback_id: str
    text: str

@router.post("/analyze-sentiment")
async def analyze_sentiment(request: FeedbackRequest):
    if not request.text.strip():
        return {"status": "error", "message": "Text is empty"}

    db = get_db()
    try:
        prompt = f"""
        Analyze the sentiment of this student feedback about a university event.
        Classify it as 'Positive', 'Negative', or 'Neutral'.
        Return the result as JSON with keys: 'label' and 'score' (score between 0 and 1).
        Feedback: "{request.text}"
        """

        response = model.generate_content(prompt)

        result_text = response.text.replace("```json", "").replace("```", "").strip()
        result_data = json.loads(result_text)

        doc_ref = db.collection('feedback').document(request.feedback_id)
        doc_ref.update({
            'sentimentLabel': result_data.get('label', 'Neutral'),
            'sentimentScore': result_data.get('score', 0.5),
            'aiStatus': 'success'
        })

        return {"status": "success", "analysis": result_data}

    except Exception as e:
        print(f"🔥 Error: {str(e)}")
        return {"status": "error", "message": str(e)}