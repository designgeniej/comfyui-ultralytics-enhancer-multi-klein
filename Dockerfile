# Runpod ComfyUI Serverless worker for your Ultralytics Enhancer Multi KLEIN workflow
# Endpoint type: Queue
FROM runpod/worker-comfyui:5.8.4-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /comfyui

RUN set -eux; \
    mkdir -p /comfyui/custom_nodes; \
    git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy; \
    cd /comfyui/custom_nodes/rgthree-comfy; \
    git checkout 32142fe476878a354dda6e2d4b5ea98960de3ced || true; \
    git clone https://github.com/PGCRT/CRT-Nodes /comfyui/custom_nodes/CRT-Nodes; \
    cd /comfyui/custom_nodes/CRT-Nodes; \
    git checkout cb8d700a66cd7d5f62db1046272ad0cb41bddd2d || true; \
    git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes; \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes; \
    git checkout 068d4fee62d379723dd96dd3e768ed807f7d7135 || true

RUN set -eux; \
    python3 -m pip install --upgrade pip setuptools wheel; \
    for req in /comfyui/custom_nodes/*/requirements.txt; do \
      if [ -f "$req" ]; then \
        echo "Installing $req"; \
        python3 -m pip install --no-cache-dir -r "$req"; \
      fi; \
    done; \
    python3 -m pip install --no-cache-dir ultralytics opencv-python-headless huggingface_hub

ARG HF_TOKEN="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"

RUN set -eux; \
    download_model() { \
      local url="$1"; \
      local out="$2"; \
      mkdir -p "$(dirname "$out")"; \
      if [[ -n "${HF_TOKEN:-}" ]]; then \
        curl -L --fail --retry 5 --retry-delay 10 --retry-all-errors \
          -H "Authorization: Bearer ${HF_TOKEN}" \
          -o "$out" "$url"; \
      else \
        curl -L --fail --retry 5 --retry-delay 10 --retry-all-errors \
          -o "$out" "$url"; \
      fi; \
      test -s "$out"; \
    }; \
    \
    download_model \
      "https://huggingface.co/jags/yolov8_model_segmentation-set/resolve/main/face_yolov8n-seg2_60.pt?download=true" \
      "/comfyui/models/ultralytics/segm/face_yolov8n-seg2_60.pt"; \
    \
    if [[ -z "${HF_TOKEN:-}" ]]; then \
      echo "ERROR: HF_TOKEN build arg is required for black-forest-labs/FLUX.2-klein-9b-fp8." >&2; \
      echo "Accept the model agreement on Hugging Face, then rebuild with --build-arg HF_TOKEN=hf_xxx." >&2; \
      exit 1; \
    fi; \
    download_model \
      "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" \
      "/comfyui/models/diffusion_models/flux-2-klein-9b-fp8.safetensors"; \
    \
    download_model \
      "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
      "/comfyui/models/text_encoders/qwen_3_8b_fp8mixed.safetensors"; \
    \
    download_model \
      "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
      "/comfyui/models/vae/flux2-vae.safetensors"; \
    \
    ls -lh \
      /comfyui/models/ultralytics/segm/face_yolov8n-seg2_60.pt \
      /comfyui/models/diffusion_models/flux-2-klein-9b-fp8.safetensors \
      /comfyui/models/text_encoders/qwen_3_8b_fp8mixed.safetensors \
      /comfyui/models/vae/flux2-vae.safetensors

RUN mkdir -p /comfyui/input && \
    curl -L --fail --retry 5 --retry-delay 10 --retry-all-errors \
      -o "/comfyui/input/Serious (11).png" \
      "https://cool-anteater-319.convex.cloud/api/storage/76eba73b-19ac-4e07-8603-cd9f09f88ec5"
