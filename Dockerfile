# syntax=docker/dockerfile:1.6
ARG WORKER_COMFYUI_VERSION=5.8.6
FROM runpod/worker-comfyui:${WORKER_COMFYUI_VERSION}-base

WORKDIR /comfyui

# Temporary test path: the FLUX model is hosted as a .rar, so install unar.
RUN apt-get update && \
    apt-get install -y --no-install-recommends unar && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install verified custom nodes.
RUN comfy-node-install comfyui-kjnodes crt-nodes

# Download verified model files.
RUN comfy model download \
    --url https://huggingface.co/jags/yolov8_model_segmentation-set/resolve/main/face_yolov8n-seg2_60.pt \
    --relative-path models/checkpoints \
    --filename face_yolov8n-seg2_60.pt
RUN mkdir -p /comfyui/models/diffusion_models /tmp/flux-rar && \
    wget --progress=dot:giga -O /tmp/flux-rar/flux.rar "https://st7.ranoz.gg/sTg20n0u-flux.rar" && \
    mkdir -p /tmp/flux-rar/extracted && \
    unar -f -o /tmp/flux-rar/extracted /tmp/flux-rar/flux.rar && \
    MODEL_FILE="$(find /tmp/flux-rar/extracted -type f -iname 'flux-2-klein-9b-fp8.safetensors' -print -quit)" && \
    if [ -z "$MODEL_FILE" ]; then MODEL_FILE="$(find /tmp/flux-rar/extracted -type f -iname '*.safetensors' -print -quit)"; fi && \
    test -n "$MODEL_FILE" && \
    cp "$MODEL_FILE" /comfyui/models/diffusion_models/flux-2-klein-9b-fp8.safetensors && \
    rm -rf /tmp/flux-rar
RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors \
    --relative-path models/vae \
    --filename flux2-vae.safetensors
RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors \
    --relative-path models/text_encoders \
    --filename qwen_3_8b_fp8mixed.safetensors

# Keep the inherited CMD ["/start.sh"].
