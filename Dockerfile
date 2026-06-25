# syntax=docker/dockerfile:1.6
ARG WORKER_COMFYUI_VERSION=5.8.6
FROM runpod/worker-comfyui:${WORKER_COMFYUI_VERSION}-base

WORKDIR /comfyui

# Install verified custom nodes.
RUN comfy-node-install comfyui-kjnodes crt-nodes rgthree-comfy

# Download verified model files.
RUN comfy model download \
    --url https://huggingface.co/jags/yolov8_model_segmentation-set/resolve/main/face_yolov8n-seg2_60.pt \
    --relative-path models/checkpoints \
    --filename face_yolov8n-seg2_60.pt

RUN mkdir -p /comfyui/models/diffusion_models && \
    BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
      wget --progress=dot:giga -O /comfyui/models/diffusion_models/flux-2-klein-9b-fp8.safetensors "https://civitai.com/api/download/models/2658598?fileId=2545829" && break; \
      if [ "$i" -eq 5 ]; then echo "flux model download failed after 5 attempts" >&2; exit 1; fi; \
      SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i); \
      echo "flux download attempt $i failed; retrying in $SLEEP seconds" >&2; \
      sleep "$SLEEP"; \
    done

RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors \
    --relative-path models/vae \
    --filename flux2-vae.safetensors

RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors \
    --relative-path models/text_encoders \
    --filename qwen_3_8b_fp8mixed.safetensors

# Keep the inherited CMD ["/start.sh"].
