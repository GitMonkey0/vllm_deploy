#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${MODEL_PATH:-/opt/tiger/agihub_model_images/Qwen3.6-35B-A3B}"
MODEL_NAME="${MODEL_NAME:-qwen3.6-35b-a3b}"
HOST="${VLLM_HOST:-0.0.0.0}"
PORT="${VLLM_PORT:-8000}"
ASCEND_VISIBLE_DEVICES="${ASCEND_VISIBLE_DEVICES:-0,1}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-2}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-4}"
MAX_NUM_BATCHED_TOKENS="${MAX_NUM_BATCHED_TOKENS:-8192}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.88}"
DTYPE="${DTYPE:-bfloat16}"

export ASCEND_VISIBLE_DEVICES
export VLLM_USE_V1="${VLLM_USE_V1:-1}"

exec python -m vllm.entrypoints.openai.api_server \
  --host "${HOST}" \
  --port "${PORT}" \
  --model "${MODEL_PATH}" \
  --served-model-name "${MODEL_NAME}" \
  --trust-remote-code \
  --dtype "${DTYPE}" \
  --tensor-parallel-size "${TENSOR_PARALLEL_SIZE}" \
  --max-model-len "${MAX_MODEL_LEN}" \
  --max-num-seqs "${MAX_NUM_SEQS}" \
  --max-num-batched-tokens "${MAX_NUM_BATCHED_TOKENS}" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}"
