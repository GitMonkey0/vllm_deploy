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
HDFS_MODEL_MODE="${HDFS_MODEL_MODE:-auto}"
HDFS_MODEL_CACHE_DIR="${HDFS_MODEL_CACHE_DIR:-/opt/tiger/agihub_model_images/hdfs_model_cache}"
HDFS_MODEL_COPY_JOBS="${HDFS_MODEL_COPY_JOBS:-8}"

export ASCEND_VISIBLE_DEVICES
export VLLM_USE_V1="${VLLM_USE_V1:-1}"

resolve_hdfs_path() {
  local uri="$1"
  local without_scheme authority path candidate cache_path

  without_scheme="${uri#hdfs://}"
  authority="${without_scheme%%/*}"
  path="/${without_scheme#*/}"

  case "${authority}${path}" in
    haruna/home/byte_douyin_ai4se/user/*)
      candidate="/mnt/hdfs/byte_douyin_ai4se/user/${path#/home/byte_douyin_ai4se/user/}"
      ;;
    harunahj/home/byte_douyin_ai4se/common/ssd/user/*)
      candidate="/mnt/hdfs/byte_douyin_ai4se/ssd/${path#/home/byte_douyin_ai4se/common/ssd/user/}"
      ;;
    *)
      candidate=""
      ;;
  esac

  if [[ "${HDFS_MODEL_MODE}" != "copy" && -n "${candidate}" && -d "${candidate}" ]]; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  mkdir -p "${HDFS_MODEL_CACHE_DIR}"
  cache_path="${HDFS_MODEL_CACHE_DIR}/${authority}${path}"
  if [[ "${cache_path}" != "${HDFS_MODEL_CACHE_DIR}/"* || "${cache_path}" == "${HDFS_MODEL_CACHE_DIR}/" ]]; then
    echo "Refusing unsafe HDFS cache path: ${cache_path}" >&2
    return 1
  fi
  if [[ ! -d "${cache_path}" || "${HDFS_MODEL_REFRESH:-0}" == "1" ]]; then
    mkdir -p "$(dirname "${cache_path}")"
    if [[ -n "${candidate}" && -d "${candidate}" ]]; then
      rm -rf "${cache_path}.tmp"
      mkdir -p "${cache_path}.tmp"
      find "${candidate}" -mindepth 1 -maxdepth 1 -print0 |
        xargs -0 -P "${HDFS_MODEL_COPY_JOBS}" -I {} cp -a {} "${cache_path}.tmp/"
      rm -rf "${cache_path}"
      mv "${cache_path}.tmp" "${cache_path}"
    elif command -v hdfs >/dev/null 2>&1; then
      rm -rf "${cache_path}.tmp"
      hdfs dfs -get "${uri}" "${cache_path}.tmp"
      rm -rf "${cache_path}"
      mv "${cache_path}.tmp" "${cache_path}"
    elif command -v hadoop >/dev/null 2>&1; then
      rm -rf "${cache_path}.tmp"
      hadoop fs -get "${uri}" "${cache_path}.tmp"
      rm -rf "${cache_path}"
      mv "${cache_path}.tmp" "${cache_path}"
    else
      echo "Cannot resolve HDFS model path: ${uri}" >&2
      return 1
    fi
  fi
  printf '%s\n' "${cache_path}"
}

if [[ "${MODEL_PATH}" == hdfs://* ]]; then
  MODEL_PATH="$(resolve_hdfs_path "${MODEL_PATH}")"
fi

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
