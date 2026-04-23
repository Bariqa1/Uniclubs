import joblib
import pandas as pd

class AttendancePredictor:

    def __init__(self):
        self.model = joblib.load("ml_models/attendance_model.pkl")
        self.features = joblib.load("ml_models/features.pkl")

    def predict(self, input_data: dict):

        df = pd.DataFrame([input_data])

        # enforce correct schema
        df = df.reindex(columns=self.features, fill_value=0)

        prediction = self.model.predict(df)[0]

        return float(prediction)
