# Multi-stage image build for OpenVINO support with Intel iGPU
# Based on gpu.Dockerfile pattern

# First, build the application in the `/app` directory.
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder-base
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Disable Python downloads, because we want to use the system interpreter
# across both images.
ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /app
FROM builder-base AS packages-builder
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --no-install-project --no-dev --extra openvino -v

FROM builder-base AS app-builder
COPY wyoming_onnx_asr/ ./wyoming_onnx_asr/
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv venv && \
    uv pip install --no-deps .

FROM python:3.12-slim-bookworm
# It is important to use the image that matches the builder, as the path to the
# Python executable must be the same.

# Install minimal OpenCL support
# Note: Full Intel GPU drivers should be installed on host system
RUN apt-get update && apt-get install -y \
    ocl-icd-libopencl1 \
    clinfo \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=packages-builder /app/.venv /app/.venv
# Copy just the site-packages from our app installation (tiny layer)
COPY --from=app-builder /app/.venv/lib/python3.12/site-packages /app/.venv/lib/python3.12/site-packages/

# Copy the application
COPY wyoming_onnx_asr/ /app/wyoming_onnx_asr/
# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# OpenVINO configuration
ENV OV_CACHE_DIR="/cache/openvino"
ENV OV_ENABLE_DEVICE_CACHE=1

VOLUME /data
VOLUME /cache
ENV HF_HUB_CACHE="/data"
ENTRYPOINT ["python", "-m", "wyoming_onnx_asr", "--device", "openvino-gpu"]
CMD [ "--uri", "tcp://*:10300", "--model-en", "nemo-parakeet-tdt-0.6b-v2" ]