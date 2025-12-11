#!/bin/bash
# Test Whisper beam search - mount local vllm source over installed package

IMAGE="vllm/vllm-openai:v0.11.2"
WORKSPACE="/home/nathanprice/vllm"
PORT=${1:-8000}
VLLM_INSTALL_PATH="/usr/local/lib/python3.12/dist-packages/vllm"

echo "🚀 Testing Whisper Beam Search with Docker"
echo "=========================================="
echo "Image: $IMAGE"
echo "Source: $WORKSPACE/vllm"
echo "Mounting to: $VLLM_INSTALL_PATH"
echo "Port: $PORT"
echo ""

# Stop any existing containers using the same port
echo "🛑 Stopping any existing containers on port $PORT..."
docker ps -q --filter "publish=$PORT" | xargs -r docker stop
docker ps -aq --filter "publish=$PORT" | xargs -r docker rm

# Check if image exists
if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "📥 Pulling Docker image..."
    docker pull "$IMAGE"
fi

echo "🐳 Starting container..."
echo "   Mounting your vllm source to replace the installed package"
echo ""

docker run --gpus all --rm \
    --name vllm-beam-test \
    -p $PORT:8000 \
    -v "$WORKSPACE/vllm:$VLLM_INSTALL_PATH" \
    -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
    --entrypoint bash \
    "$IMAGE" \
    -c "
        echo '📦 Installing missing dependencies...'
        pip3 install ijson --quiet 2>&1 | tail -3
        pip3 install vllm[audio]
        
        echo ''
        echo '✅ Your vLLM source is mounted and ready!'
        echo ''
        echo 'Verifying mount...'
        python3 -c 'import vllm; import os; print(\"vLLM location:\", vllm.__file__); print(\"Using mounted source:\", \"vllm\" in vllm.__file__)'
        echo ''
        echo '🚀 Starting vLLM server...'
        echo ''
        echo 'Test beam search with:'
        echo '  curl -X POST http://localhost:$PORT/v1/audio/transcriptions \\'
        echo '    -H \"Authorization: Bearer token-abc123\" \\'
        echo '    -F file=@test_audio.wav \\'
        echo '    -F model=\"openai/whisper-large-v3-turbo\" \\'
        echo '    -F use_beam_search=true \\'
        echo '    -F beam_width=5'
        echo ''
        
        vllm serve \\
            --model openai/whisper-large-v3 \\
            --port 8000 \\
            --host 0.0.0.0
    "

echo "Server is ready. Run your tests now."