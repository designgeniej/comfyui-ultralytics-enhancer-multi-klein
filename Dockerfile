# syntax=docker/dockerfile:1.6
ARG WORKER_COMFYUI_VERSION=5.8.6
FROM runpod/worker-comfyui:${WORKER_COMFYUI_VERSION}-base

WORKDIR /comfyui

# Install verified custom nodes.
RUN comfy-node-install comfyui-kjnodes
RUN git clone https://github.com/PGCRT/CRT-Nodes.git /comfyui/custom_nodes/CRT-Nodes && \
    uv pip install -r /comfyui/custom_nodes/CRT-Nodes/requirements.txt && \
    cd /comfyui && \
    python -c "import importlib.util, sys; sys.path.insert(0, '/comfyui'); spec = importlib.util.spec_from_file_location('crt_nodes', '/comfyui/custom_nodes/CRT-Nodes/__init__.py', submodule_search_locations=['/comfyui/custom_nodes/CRT-Nodes']); mod = importlib.util.module_from_spec(spec); sys.modules['crt_nodes'] = mod; spec.loader.exec_module(mod); assert 'FaceEnhancementWithInjection' in mod.NODE_CLASS_MAPPINGS, 'CRT node FaceEnhancementWithInjection was not registered'"

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
