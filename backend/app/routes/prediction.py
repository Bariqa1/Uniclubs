from fastapi import APIRouter
from app.ai.attendance_predictor import AttendancePredictor

router = APIRouter()

predictor = AttendancePredictor()

@router.post("/predict-attendance")
def predict_attendance(data: dict):

    result = predictor.predict(data)

    return {
        "predicted_attendance": result
    }
