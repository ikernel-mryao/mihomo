#!/usr/bin/env bash

# shellcheck source=./common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

CONFIG_CANDIDATE="$RUNTIME_CONFIG_FILE"
if [[ ! -s "$CONFIG_CANDIDATE" ]]; then
    CONFIG_CANDIDATE=$(resolve_config_file || true)
fi

PORT=7890
if [[ -n "${CONFIG_CANDIDATE:-}" && -s "$CONFIG_CANDIDATE" ]]; then
    PORT=$(extract_mixed_port "$CONFIG_CANDIDATE")
    PORT=${PORT:-7890}
fi

export http_proxy="http://127.0.0.1:$PORT"
export https_proxy="http://127.0.0.1:$PORT"
export HTTP_PROXY="http://127.0.0.1:$PORT"
export HTTPS_PROXY="http://127.0.0.1:$PORT"
export all_proxy="http://127.0.0.1:$PORT"
export ALL_PROXY="http://127.0.0.1:$PORT"

echo "已设置代理环境变量到 127.0.0.1:$PORT"
