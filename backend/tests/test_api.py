"""
Tests for UniClubs API endpoints:
  - Health check
  - Attendance prediction
  - Sentiment analysis
  - Chatbot
  - Rate limiting
"""

import sys
import os
import pytest
from unittest.mock import patch, MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi.testclient import TestClient


@pytest.fixture(scope="module")
def client():
    with patch("app.ai.recommender._load_models"), \
         patch("app.utils.firebase_config.get_db"), \
         patch("app.ai.attendance_predictor.AttendancePredictor.__init__", return_value=None):
        from app.main import app
        return TestClient(app)


# ════════════════════════════════════════════════════════════════
# TC-API-01  Health Check
# ════════════════════════════════════════════════════════════════

class TestHealthCheck:

    def test_root_returns_200(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_root_returns_running_status(self, client):
        data = client.get("/").json()
        assert "status" in data
        assert "running" in data["status"].lower()


# ════════════════════════════════════════════════════════════════
# TC-ATT  Attendance Prediction
# ════════════════════════════════════════════════════════════════

VALID_ATTENDANCE_PAYLOAD = {
    "capacity": 100,
    "tags_count": 3,
    "interested_users_count": 50,
    "past_avg_attendance": 40.0,
    "interest_ratio": 0.5,
    "category_Technology": 1,
}


class TestAttendancePrediction:

    def test_valid_input_returns_200(self, client):
        with patch("app.main.attendance_predictor.predict", return_value=42.0):
            response = client.post("/predict-attendance", json=VALID_ATTENDANCE_PAYLOAD)
        assert response.status_code == 200

    def test_valid_input_returns_prediction(self, client):
        with patch("app.main.attendance_predictor.predict", return_value=42.0):
            data = client.post("/predict-attendance", json=VALID_ATTENDANCE_PAYLOAD).json()
        assert "predicted_attendance" in data
        assert data["predicted_attendance"] == 42.0

    def test_category_defaults_to_zero(self, client):
        payload = {k: v for k, v in VALID_ATTENDANCE_PAYLOAD.items()
                   if not k.startswith("category_")}
        with patch("app.main.attendance_predictor.predict", return_value=30.0):
            response = client.post("/predict-attendance", json=payload)
        assert response.status_code == 200

    def test_all_category_flags_accepted(self, client):
        payload = {**VALID_ATTENDANCE_PAYLOAD,
                   "category_Arts": 0, "category_Sports": 0,
                   "category_Science": 0, "category_Business": 0}
        with patch("app.main.attendance_predictor.predict", return_value=55.0):
            response = client.post("/predict-attendance", json=payload)
        assert response.status_code == 200

    def test_prediction_is_numeric(self, client):
        with patch("app.main.attendance_predictor.predict", return_value=37.5):
            data = client.post("/predict-attendance", json=VALID_ATTENDANCE_PAYLOAD).json()
        assert isinstance(data["predicted_attendance"], (int, float))

    def test_predictor_receives_correct_fields(self, client):
        with patch("app.main.attendance_predictor.predict", return_value=0.0) as mock_predict:
            client.post("/predict-attendance", json=VALID_ATTENDANCE_PAYLOAD)
        called_dict = mock_predict.call_args[0][0]
        assert "capacity" in called_dict
        assert "past_avg_attendance" in called_dict


# ════════════════════════════════════════════════════════════════
# TC-SENT  Sentiment Analysis
# ════════════════════════════════════════════════════════════════

class TestSentimentAnalysis:

    def _mock_gemini(self, label="Positive", score=0.92):
        import json
        mock_resp = MagicMock()
        mock_resp.text = json.dumps({"label": label, "score": score})
        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_resp
        return mock_model

    def _mock_db(self):
        """Returns a mock Firestore db where the user has not opted out."""
        mock_db = MagicMock()
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"sentimentOptOut": False}
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        return mock_db

    def test_positive_feedback_returns_positive_label(self, client):
        with patch("app.routes.sentiment_routes.model", self._mock_gemini("Positive", 0.92)), \
             patch("app.routes.sentiment_routes.get_db", return_value=self._mock_db()):
            data = client.post("/ai/analyze-sentiment",
                               json={"feedback_id": "f1", "user_id": "u1",
                                     "text": "Amazing workshop, very well organized!"}).json()
        assert data["status"] == "success"
        assert data["analysis"]["label"] == "Positive"

    def test_negative_feedback_returns_negative_label(self, client):
        with patch("app.routes.sentiment_routes.model", self._mock_gemini("Negative", 0.85)), \
             patch("app.routes.sentiment_routes.get_db", return_value=self._mock_db()):
            data = client.post("/ai/analyze-sentiment",
                               json={"feedback_id": "f2", "user_id": "u1",
                                     "text": "Poorly organized, waste of time."}).json()
        assert data["analysis"]["label"] == "Negative"

    def test_score_in_valid_range(self, client):
        with patch("app.routes.sentiment_routes.model", self._mock_gemini("Neutral", 0.5)), \
             patch("app.routes.sentiment_routes.get_db", return_value=self._mock_db()):
            data = client.post("/ai/analyze-sentiment",
                               json={"feedback_id": "f3", "user_id": "u1",
                                     "text": "It was okay."}).json()
        score = data["analysis"]["score"]
        assert 0.0 <= score <= 1.0

    def test_response_contains_label_and_score(self, client):
        with patch("app.routes.sentiment_routes.model", self._mock_gemini("Positive", 0.88)), \
             patch("app.routes.sentiment_routes.get_db", return_value=self._mock_db()):
            data = client.post("/ai/analyze-sentiment",
                               json={"feedback_id": "f4", "user_id": "u1",
                                     "text": "Great event!"}).json()
        assert "label" in data["analysis"]
        assert "score" in data["analysis"]

    def test_empty_text_via_ai_route_returns_error(self, client):
        # Empty text is rejected before Firestore is called — no db mock needed
        response = client.post("/ai/analyze-sentiment",
                               json={"feedback_id": "f5", "user_id": "u1", "text": ""})
        data = response.json()
        assert data["status"] == "error"

    def test_firestore_updated_on_success(self, client):
        # Set up db so the feedback doc_ref's update() can be verified
        mock_db = MagicMock()
        mock_user_doc = MagicMock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"sentimentOptOut": False}
        doc_ref = MagicMock()
        # users collection returns the user doc; feedback collection returns doc_ref
        def collection_side_effect(name):
            m = MagicMock()
            if name == "users":
                m.document.return_value.get.return_value = mock_user_doc
            else:
                m.document.return_value = doc_ref
            return m
        mock_db.collection.side_effect = collection_side_effect
        with patch("app.routes.sentiment_routes.model", self._mock_gemini("Positive", 0.9)), \
             patch("app.routes.sentiment_routes.get_db", return_value=mock_db):
            client.post("/ai/analyze-sentiment",
                        json={"feedback_id": "f6", "user_id": "u1", "text": "Excellent!"})
        doc_ref.update.assert_called_once()


# ════════════════════════════════════════════════════════════════
# TC-CHAT  Chatbot
# ════════════════════════════════════════════════════════════════

class TestChatbot:

    def _mock_gemini_chat(self, reply="Here are the upcoming events."):
        mock_resp = MagicMock()
        mock_resp.text = reply
        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_resp
        return mock_model

    def test_chat_returns_200(self, client):
        with patch("app.main.model", self._mock_gemini_chat()), \
             patch("app.services.chat_service.get_history", return_value=[]), \
             patch("app.services.chat_service.save_message"):
            response = client.post("/chat",
                                   json={"message": "What events are on today?",
                                         "user_id": "user123"})
        assert response.status_code == 200

    def test_chat_response_contains_text(self, client):
        with patch("app.main.model", self._mock_gemini_chat("Here are upcoming events.")), \
             patch("app.services.chat_service.get_history", return_value=[]), \
             patch("app.services.chat_service.save_message"):
            data = client.post("/chat",
                               json={"message": "Show me tech events",
                                     "user_id": "user123"}).json()
        assert "response" in data
        assert len(data["response"]) > 0

    def test_chat_with_guest_user_id(self, client):
        with patch("app.main.model", self._mock_gemini_chat("I can help you.")), \
             patch("app.services.chat_service.get_history", return_value=[]), \
             patch("app.services.chat_service.save_message"):
            response = client.post("/chat",
                                   json={"message": "Hello",
                                         "user_id": "guest-session-abc123"})
        assert response.status_code == 200

    def test_get_messages_returns_history(self, client):
        history = [{"content": "Hello", "role": "user"}]
        with patch("app.main.get_history", return_value=history):
            data = client.get("/messages/user123").json()
        assert "history" in data
        assert data["history"] == history

    def test_get_messages_empty_history(self, client):
        with patch("app.main.get_history", return_value=[]):
            data = client.get("/messages/new_user").json()
        assert data["history"] == []
