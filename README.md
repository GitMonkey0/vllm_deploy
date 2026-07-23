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
ASCEND_VISIBLE_DEVICES=0,1 ./start_vllm_npu.sh
MAX_MODEL_LEN=16384 ./start_vllm_npu.sh
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
