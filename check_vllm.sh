#!/usr/bin/env bash
set -euo pipefail

HOST="${VLLM_CHECK_HOST:-::1}"
PORT="${VLLM_PORT:-8000}"
MODEL_NAME="${MODEL_NAME:-qwen3.6-35b-a3b}"

if [[ "${HOST}" == *:* && "${HOST}" != \[*\] ]]; then
  URL_HOST="[${HOST}]"
else
  URL_HOST="${HOST}"
fi

BASE_URL="http://${URL_HOST}:${PORT}"

echo "Checking health: ${BASE_URL}/health"
curl -fsS "${BASE_URL}/health" >/dev/null
echo "Health: OK"

echo "Listing models:"
curl -fsS "${BASE_URL}/v1/models"
echo

echo "Running chat completion with thinking disabled:"
curl -fsS "${BASE_URL}/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d "{
    \"model\": \"${MODEL_NAME}\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"用一句话说明你已经启动成功。\"}
    ],
    \"temperature\": 0.2,
    \"chat_template_kwargs\": {\"enable_thinking\": false}
  }"
echo
