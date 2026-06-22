# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# install custom nodes into comfyui
RUN git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy && cd /comfyui/custom_nodes/rgthree-comfy && (git checkout 32142fe476878a354dda6e2d4b5ea98960de3ced 2>/dev/null || (git fetch origin 32142fe476878a354dda6e2d4b5ea98960de3ced --depth=1 && git checkout 32142fe476878a354dda6e2d4b5ea98960de3ced) || echo "WARN: commit 32142fe476878a354dda6e2d4b5ea98960de3ced unreachable in https://github.com/rgthree/rgthree-comfy, falling back to default branch HEAD")
RUN git clone https://github.com/PGCRT/CRT-Nodes /comfyui/custom_nodes/CRT-Nodes && cd /comfyui/custom_nodes/CRT-Nodes && (git checkout cb8d700a66cd7d5f62db1046272ad0cb41bddd2d 2>/dev/null || (git fetch origin cb8d700a66cd7d5f62db1046272ad0cb41bddd2d --depth=1 && git checkout cb8d700a66cd7d5f62db1046272ad0cb41bddd2d) || echo "WARN: commit cb8d700a66cd7d5f62db1046272ad0cb41bddd2d unreachable in https://github.com/PGCRT/CRT-Nodes, falling back to default branch HEAD")

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do comfy model download --url 'https://cool-anteater-319.convex.cloud/api/storage/cb886d30-559e-4487-bca0-d90c910eea3e' --relative-path models/Unknown --filename 'segm/face_yolov8n-seg2_60.pt' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/Serious (11).png' "https://cool-anteater-319.convex.cloud/api/storage/76eba73b-19ac-4e07-8603-cd9f09f88ec5"
