# syntax=docker/dockerfile:1

# ---------- builder ----------
FROM python:3.13-slim AS builder

# Grab the uv binary from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Layer 1: dependencies only. This layer is cached until pyproject.toml
# or uv.lock changes, so code edits don't trigger a reinstall.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

# Layer 2: your actual code
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-editable

# ---------- runtime ----------
FROM python:3.13-slim

# Run as a non-root user
RUN useradd --create-home --shell /bin/bash app

# Only the virtualenv comes across: no uv, no build tooling
COPY --from=builder --chown=app:app /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

WORKDIR /app
USER app

EXPOSE 8000

# Default command runs the API. The worker overrides this in compose.
CMD ["uvicorn", "chat_pulse.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
