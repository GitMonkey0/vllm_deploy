# vLLM NPU Deployment

Deploy `/opt/tiger/agihub_model_images/Qwen3.6-35B-A3B` with vLLM on Ascend NPU.

## Environment Verified

- `vllm`: `0.23.0`
- `torch_npu`: `2.10.0.post2`
- Device: 2 x Ascend `910B2C`
- API: OpenAI-compatible server on IPv6 port `8000`

## Start

```bash
./start_vllm_npu.sh
```

Default model name:

```text
qwen3.6-35b-a3b
```

Default endpoint:

```text
http://[::1]:8000
```

The server binds to `::` by default, so it is exposed on IPv6.

Automatic OpenAI-compatible tool calling is enabled by default with:

```bash
--enable-auto-tool-choice --tool-call-parser qwen3_xml
```

The startup script does not set `--max-model-len`, `--max-num-seqs`, or
`--max-num-batched-tokens` unless the corresponding environment variable is
provided.

## HDFS Model Paths

`MODEL_PATH` may be either a local Hugging Face model directory or an HDFS URI
with the same directory layout.

```bash
MODEL_PATH=hdfs://haruna/home/byte_douyin_ai4se/user/zhuwenqiang/model/swe_all_merge_320/hf_ckpt \
  ./start_vllm_npu.sh
```

By default `HDFS_MODEL_MODE=auto` resolves known HDFS mount paths under
`/mnt/hdfs` and serves from the mounted directory when available. To copy the
model to local disk before starting vLLM:

```bash
HDFS_MODEL_MODE=copy \
HDFS_MODEL_CACHE_DIR=/opt/tiger/agihub_model_images/hdfs_model_cache \
HDFS_MODEL_COPY_JOBS=8 \
MODEL_PATH=hdfs://haruna/home/byte_douyin_ai4se/user/zhuwenqiang/model/swe_all_merge_320/hf_ckpt \
  ./start_vllm_npu.sh
```

Set `HDFS_MODEL_REFRESH=1` with `HDFS_MODEL_MODE=copy` to refresh an existing
local cache.

For model serving, local disk cache is usually the safer choice for startup
stability and repeated restarts. HDFS FUSE avoids a full copy and may be faster
to first byte, but model loading can be slower or less predictable because many
weight files are read through the networked filesystem.

When `HDFS_MODEL_MODE=copy` and the HDFS URI can be mapped to `/mnt/hdfs`, the
script copies top-level model files in parallel. Increase `HDFS_MODEL_COPY_JOBS`
if HDFS and local disk have headroom; lower it if the copy competes with active
serving traffic.

## Verify

```bash
./check_vllm.sh
```

The verification request disables thinking with:

```json
{
  "chat_template_kwargs": {
    "enable_thinking": false
  }
}
```

## Useful Overrides

```bash
VLLM_PORT=8001 ./start_vllm_npu.sh
VLLM_HOST='::' ./start_vllm_npu.sh
MODEL_PATH=/path/to/model ./start_vllm_npu.sh
MODEL_PATH=hdfs://haruna/path/to/model ./start_vllm_npu.sh
ASCEND_VISIBLE_DEVICES=0,1 ./start_vllm_npu.sh
TOOL_CALL_PARSER=qwen3_xml ./start_vllm_npu.sh
```

## Manual Request

```bash
curl 'http://[::1]:8000/v1/chat/completions' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3.6-35b-a3b",
    "messages": [
      {"role": "user", "content": "用一句话说明你已经启动成功。"}
    ],
    "temperature": 0.2,
    "chat_template_kwargs": {"enable_thinking": false}
  }'
```
