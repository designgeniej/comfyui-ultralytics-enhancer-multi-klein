# Runpod ComfyUI Serverless worker for Ultralytics Enhancer Multi KLEIN
# Endpoint type: Queue
#
# Required build arg:
#   HF_TOKEN=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
#
# Do NOT hardcode your Hugging Face token into this file for production.
# If you hardcode it temporarily for testing, rotate/delete the token afterwards.

FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1

WORKDIR /comfyui

# System deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      curl \
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Custom nodes required by the workflow
RUN set -eux; \
    mkdir -p /comfyui/custom_nodes; \
    \
    git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy; \
    cd /comfyui/custom_nodes/rgthree-comfy; \
    git checkout 32142fe476878a354dda6e2d4b5ea98960de3ced || true; \
    \
    git clone https://github.com/PGCRT/CRT-Nodes /comfyui/custom_nodes/CRT-Nodes; \
    cd /comfyui/custom_nodes/CRT-Nodes; \
    git checkout cb8d700a66cd7d5f62db1046272ad0cb41bddd2d || true; \
    \
    git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes; \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes; \
    git checkout 068d4fee62d379723dd96dd3e768ed807f7d7135 || true

# Python deps from custom nodes
RUN set -eux; \
    python3 -m pip install --upgrade pip setuptools wheel; \
    for req in /comfyui/custom_nodes/*/requirements.txt; do \
      if [ -f "$req" ]; then \
        echo "Installing requirements from $req"; \
        python3 -m pip install --no-cache-dir -r "$req"; \
      fi; \
    done; \
    python3 -m pip install --no-cache-dir \
      ultralytics \
      opencv-python-headless \
      huggingface_hub

# Hugging Face token for gated model download.
# Pass this as a build arg:
#   docker build --build-arg HF_TOKEN=hf_xxx -t your-image .
ARG HF_TOKEN="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"

# Download workflow models.
# Important: this block intentionally does NOT use `set -x`, because that can leak HF_TOKEN in logs.
RUN set -euo pipefail; \
    download_model() { \
      local name="$1"; \
      local url="$2"; \
      local out="$3"; \
      echo "Downloading ${name}"; \
      mkdir -p "$(dirname "$out")"; \
      curl -L --fail --retry 5 --retry-delay 10 --retry-all-errors \
        -H "Authorization: Bearer ${HF_TOKEN}" \
        -o "$out" "$url"; \
      test -s "$out"; \
      ls -lh "$out"; \
    }; \
    \
    if [[ -z "${HF_TOKEN:-}" ]]; then \
      echo "ERROR: HF_TOKEN is empty." >&2; \
      echo "Pass it as a Docker build arg, or hardcode only for a throwaway test token." >&2; \
      exit 1; \
    fi; \
    \
    download_model \
      "face_yolov8n-seg2_60.pt" \
      "https://huggingface.co/jags/yolov8_model_segmentation-set/resolve/main/face_yolov8n-seg2_60.pt?download=true" \
      "/comfyui/models/ultralytics/segm/face_yolov8n-seg2_60.pt"; \
    \
    download_model \
      "flux-2-klein-9b-fp8.safetensors" \
      "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors?download=true" \
      "/comfyui/models/diffusion_models/flux-2-klein-9b-fp8.safetensors"; \
    \
    download_model \
      "qwen_3_8b_fp8mixed.safetensors" \
      "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors?download=true" \
      "/comfyui/models/text_encoders/qwen_3_8b_fp8mixed.safetensors"; \
    \
    download_model \
      "flux2-vae.safetensors" \
      "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors?download=true" \
      "/comfyui/models/vae/flux2-vae.safetensors"

# Test input image used by your current API workflow.
RUN mkdir -p /comfyui/input && \
    curl -L --fail --retry 5 --retry-delay 10 --retry-all-errors \
      -o "/comfyui/input/Serious (11).png" \
      "https://cool-anteater-319.convex.cloud/api/storage/76eba73b-19ac-4e07-8603-cd9f09f88ec5"

# The base image already includes the Runpod worker handler and startup command.
