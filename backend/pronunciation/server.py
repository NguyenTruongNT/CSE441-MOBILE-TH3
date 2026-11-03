"""Single-worker local API. Model errors never produce synthetic scores."""
from contextlib import asynccontextmanager
import asyncio
import json
import logging
import os
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, ValidationError

from engine import AssessmentError, ModelEngine

ROOT = Path(__file__).resolve().parent
MAX_REQUEST = 12 * 1024 * 1024


class AnalysisRequest(BaseModel):
    sessionId: str = Field(min_length=1, max_length=120, pattern=r"^[A-Za-z0-9_.-]+$")
    exerciseId: str = Field(min_length=1, max_length=100)
    audioBase64: str = Field(min_length=128, max_length=MAX_REQUEST)
    mimeType: str = Field(min_length=1, max_length=100)


def create_app(engine=None, load_models=True):
    assessment = engine if engine is not None else ModelEngine()
    catalog = json.loads((ROOT.parent.parent / "assets/pronunciation/exercises.json").read_text(encoding="utf-8-sig"))
    exercises = {exercise["id"]: exercise for exercise in catalog}
    busy = asyncio.Lock()

    @asynccontextmanager
    async def lifespan(app):
        if load_models:
            await asyncio.to_thread(assessment.load)
        yield

    app = FastAPI(title="English AI pronunciation", version="2.0.0", lifespan=lifespan)
    app.add_middleware(CORSMiddleware,
        allow_origins=[origin.strip() for origin in os.environ.get("CORS_ORIGINS", "").split(",") if origin.strip()],
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_methods=["GET", "POST"], allow_headers=["Content-Type", "Accept"])

    @app.get("/health")
    def health():
        return {"status": "ok" if assessment.ready else "loading", "assessmentReady": assessment.ready,
                "provider": "wav2vec2-phoneme-edit-similarity", "models": assessment.manifest}

    @app.post("/api/pronounce/analyze")
    async def analyze(request: Request):
        length = request.headers.get("content-length", "0")
        if length.isdigit() and int(length) > MAX_REQUEST:
            return JSONResponse({"code": "invalidAudio", "message": "Yêu cầu vượt quá 12 MB."}, 413)
        data = bytearray()
        async for chunk in request.stream():
            data.extend(chunk)
            if len(data) > MAX_REQUEST:
                return JSONResponse({"code": "invalidAudio", "message": "Yêu cầu vượt quá 12 MB."}, 413)
        try:
            payload = AnalysisRequest.model_validate_json(data).model_dump()
        except ValidationError:
            return JSONResponse({"code": "invalidAudio", "message": "Thiếu hoặc sai dữ liệu phiên/bài/audio."}, 400)
        exercise = exercises.get(payload["exerciseId"])
        if exercise is None:
            return JSONResponse({"code": "unsupported", "message": "Không tìm thấy bài luyện."}, 400)
        if not assessment.ready:
            return JSONResponse({"code": "insufficientEvidence", "message": "Mô hình chưa sẵn sàng. Kiểm tra backend."}, 503)
        if busy.locked():
            return JSONResponse({"code": "unknown", "message": "Máy chủ đang phân tích một bản ghi. Hãy thử lại sau."}, 429)
        async with busy:
            try:
                return await asyncio.to_thread(assessment.analyze, payload, exercise)
            except AssessmentError as error:
                return JSONResponse({"code": error.code, "message": error.message}, error.status)
            except Exception:
                logging.exception("Pronunciation inference failed")
                # Avoid echoing audio, payload or internal paths in error responses.
                return JSONResponse({"code": "unknown", "message": "Không hoàn tất được phân tích. Kiểm tra backend và thử lại."}, 500)

    return app


app = create_app()
