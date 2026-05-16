#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

mapfile -t PIDS < <(list_mihomo_pids)

if [[ "${#PIDS[@]}" -eq 0 ]]; then
    echo "Mihomo 当前未运行。"
    exit 1
fi

echo "Mihomo 运行中："
for pid in "${PIDS[@]}"; do
    [[ -n "$pid" ]] || continue
    ps -o pid=,user=,etime=,cmd= -p "$pid"
done

if [[ -s "$RUNTIME_CONFIG_FILE" ]]; then
    port=$(extract_mixed_port "$RUNTIME_CONFIG_FILE")
    if [[ -n "${port:-}" ]]; then
        echo "监听端口: $port"
    fi
fi

if [[ -f "$LOG_FILE" ]]; then
    echo "日志文件: $LOG_FILE"
fi
