#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${MODEL_PATH:-/opt/tiger/agihub_model_images/Qwen3.6-35B-A3B}"
MODEL_NAME="${MODEL_NAME:-qwen3.6-35b-a3b}"
HOST="${VLLM_HOST:-::}"
PORT="${VLLM_PORT:-8000}"
ASCEND_VISIBLE_DEVICES="${ASCEND_VISIBLE_DEVICES:-0,1}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-2}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.88}"
DTYPE="${DTYPE:-bfloat16}"
TOOL_CALL_PARSER="${TOOL_CALL_PARSER:-qwen3_xml}"

export ASCEND_VISIBLE_DEVICES
export VLLM_USE_V1="${VLLM_USE_V1:-1}"

args=(
  python -m vllm.entrypoints.openai.api_server
  --host "${HOST}" \
  --port "${PORT}" \
  --model "${MODEL_PATH}" \
  --served-model-name "${MODEL_NAME}" \
  --trust-remote-code \
  --dtype "${DTYPE}" \
  --tensor-parallel-size "${TENSOR_PARALLEL_SIZE}" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
  --enable-auto-tool-choice \
  --tool-call-parser "${TOOL_CALL_PARSER}"
)

if [[ -n "${MAX_MODEL_LEN:-}" ]]; then
  args+=(--max-model-len "${MAX_MODEL_LEN}")
fi

if [[ -n "${MAX_NUM_SEQS:-}" ]]; then
  args+=(--max-num-seqs "${MAX_NUM_SEQS}")
fi

if [[ -n "${MAX_NUM_BATCHED_TOKENS:-}" ]]; then
  args+=(--max-num-batched-tokens "${MAX_NUM_BATCHED_TOKENS}")
fi

exec "${args[@]}"
