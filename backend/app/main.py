from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

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
