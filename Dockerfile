# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base
#
# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN git clone https://github.com/scraed/LanPaint /comfyui/custom_nodes/LanPaint
RUN git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp4mixed.safetensors?download=true' --relative-path models/text_encoders --filename 'qwen_3_8b_fp4mixed.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors' --relative-path models/vae --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/wikeeyang/Flux2-Klein-9B-True-V1/resolve/f367d2790f7fa6dbb6104b231feed43a95c371f9/Flux2-Klein-9B-True-fp8.safetensors' --relative-path models/diffusion_models --filename 'Flux2-Klein-9B-True-fp8.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-mimfathi-10919291.jpg' "https://cool-anteater-319.convex.cloud/api/storage/cfbb630e-1d76-4fd7-bcf6-6e1d22cbd74e"
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-peterfazekas-1137340.jpg' "https://cool-anteater-319.convex.cloud/api/storage/a42cbdde-67af-4977-a36e-674ea6ed786e"
RUN wget --progress=dot:giga -O '/comfyui/input/western-wear-photoshoot-saree-bodycon-dress-a-line-dress-wrap-dress-maxi-dress-slip-dress-halter-neck-dress-cocktail-dress-tube-dress-summer-dress-and-asymmetrical-dress-photography-bringitonline-74_1.jpeg' "https://cool-anteater-319.convex.cloud/api/storage/e99455a0-a2f4-468a-b930-880116bf6e0c"
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-alina-zahorulko-48514961-31445409.jpg' "https://cool-anteater-319.convex.cloud/api/storage/fc032981-e20c-45ef-a665-2a089967fb20"
RUN wget --progress=dot:giga -O '/comfyui/input/western-wear-photoshoot-saree-bodycon-dress-a-line-dress-wrap-dress-maxi-dress-slip-dress-halter-neck-dress-cocktail-dress-tube-dress-summer-dress-and-asymmetrical-dress-photography-bringitonline-50_1.jpeg' "https://cool-anteater-319.convex.cloud/api/storage/98c14ca3-b4a7-4e3b-b5c0-2d7c5e48e53c"


# Force Python to dump console output instantly instead of caching/buffering it
ENV PYTHONUNBUFFERED=1

# Start ComfyUI and dynamically locate and execute your handler file
CMD ["bash", "-c", "python3 /comfyui/main.py --listen 127.0.0.1 --port 8188 & python3 $(find / -maxdepth 2 -name '*handler.py' |
