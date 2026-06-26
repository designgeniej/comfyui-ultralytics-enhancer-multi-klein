# syntax=docker/dockerfile:1.6
ARG WORKER_COMFYUI_VERSION=5.8.6
FROM runpod/worker-comfyui:${WORKER_COMFYUI_VERSION}-base

WORKDIR /comfyui

# Install verified custom nodes.
RUN comfy-node-install comfyui-kjnodes
RUN git clone https://github.com/PGCRT/CRT-Nodes.git /comfyui/custom_nodes/CRT-Nodes && \
    cd /comfyui/custom_nodes/CRT-Nodes && \
    (git checkout cb8d700a66cd7d5f62db1046272ad0cb41bddd2d 2>/dev/null || (git fetch origin cb8d700a66cd7d5f62db1046272ad0cb41bddd2d --depth=1 && git checkout cb8d700a66cd7d5f62db1046272ad0cb41bddd2d))
RUN uv pip install --python /opt/venv/bin/python -r /comfyui/custom_nodes/CRT-Nodes/requirements.txt
RUN /opt/venv/bin/python -c "import cv2; print('cv2 ok', cv2.__version__)"
RUN grep -q '"FaceEnhancementWithInjection"' /comfyui/custom_nodes/CRT-Nodes/__init__.py && \
    grep -q 'UltralyticsEnhancer as FaceEnhancementWithInjection' /comfyui/custom_nodes/CRT-Nodes/__init__.py && \
    echo "CRT FaceEnhancementWithInjection source check ok"
RUN cd /comfyui && timeout 300 /opt/venv/bin/python main.py --quick-test-for-ci --cpu

# Download verified model files.
RUN comfy model download \
    --url https://huggingface.co/jags/yolov8_model_segmentation-set/resolve/main/face_yolov8n-seg2_60.pt \
    --relative-path models/ultralytics/segm \
    --filename face_yolov8n-seg2_60.pt
RUN mkdir -p /comfyui/models/diffusion_models && \
    wget --progress=dot:giga -O /comfyui/models/diffusion_models/flux-2-klein-9b-fp8.safetensors "https://st7.ranoz.gg/YOXG9XTk-flux-2-klein-9b-fp8.f"
RUN comfy model download \
    --url https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors \
    --relative-path models/vae \
    --filename flux2-vae.safetensors
RUN mkdir -p /comfyui/models/text_encoders && \
    wget --progress=dot:giga -O /comfyui/models/text_encoders/qwen_3_8b_fp8mixed.safetensors "https://st7.ranoz.gg/I9O5DyiC-qwen_3_8b_fp8mixed.f"

# Keep the inherited CMD ["/start.sh"].
