"""FastAPI application with CORS, healthcheck, and Lambda Powertools integration.

Entry point for both local uvicorn development and Lambda (via Mangum adapter
in handler.py). Respects the 3-mode contract for environment-aware behavior.
"""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import TYPE_CHECKING

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from {{ project_slug }}.config.mode import get_current_mode

if TYPE_CHECKING:
    from collections.abc import AsyncIterator

try:
    from aws_lambda_powertools import Logger, Metrics, Tracer

    logger = Logger(service="{{ project_slug }}")
    tracer = Tracer(service="{{ project_slug }}")
    metrics = Metrics(namespace="{{ project_slug }}")
    _powertools_available = True
except ImportError:
    _powertools_available = False


@asynccontextmanager
async def _lifespan(app: FastAPI) -> AsyncIterator[None]:
    yield


app = FastAPI(
    title="{{ project_name }} API",
    version="0.1.0",
    lifespan=_lifespan,
)

cors_origins = os.environ.get("API_CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in cors_origins],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def healthcheck() -> dict[str, str]:
    mode = get_current_mode()
    namespace = os.environ.get("DEPLOYMENT_NAMESPACE", "{{ deployment_namespace }}")
    return {"status": "ok", "namespace": namespace, "mode": mode.value}


@app.exception_handler(Exception)
async def _unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    if _powertools_available:
        logger.exception("Unhandled exception", path=str(request.url))
    return JSONResponse(
        status_code=500,
        content={"error": "internal_server_error", "code": "INTERNAL", "detail": None},
    )


# TODO: Add API routes post-generation
