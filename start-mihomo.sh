#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

HOST_ARCH=$(host_arch) || {
    echo "当前脚本仅支持 x86_64/amd64 和 aarch64/arm64 Linux。" >&2
    exit 1
}

BIN_FILE=$(pick_working_bin "$HOST_ARCH") || {
    cat >&2 <<EOF
未找到可在当前架构 ($HOST_ARCH) 上运行的内核。

请检查以下文件是否存在且架构匹配：
  $RUN_DIR/mihomo
  $RUN_DIR/mihomo-amd64
  $RUN_DIR/mihomo-arm64
  $RUN_DIR/clash-linux
EOF
    exit 1
}

CONFIG_FILE=$(resolve_config_file) || {
    print_missing_config_help
    exit 1
}

prepare_runtime_config "$CONFIG_FILE" "$RUNTIME_CONFIG_FILE"
PORT=$(extract_mixed_port "$RUNTIME_CONFIG_FILE")
PORT=${PORT:-7890}

running_pids=$(list_mihomo_pids)
if [[ -n "${running_pids:-}" ]]; then
    echo "检测到 Mihomo 已在运行，请先执行 ./stop-mihomo.sh 后再重试。" >&2
    printf '%s\n' "$running_pids" | while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        ps -o pid=,user=,etime=,cmd= -p "$pid"
    done >&2
    exit 1
fi

if [[ "$BIN_FILE" == "$RUN_DIR/clash-linux" ]]; then
    BIN_MODE="clash-linux"
else
    BIN_MODE="mihomo"
fi

if [[ "$BIN_MODE" == "mihomo" ]]; then
    "$BIN_FILE" -d "$CONFIG_DIR" -f "$RUNTIME_CONFIG_FILE" -t
fi

mkdir -p "$RUN_DIR"
rm -f "$PID_FILE"

if [[ "$BIN_MODE" == "clash-linux" ]]; then
    cp "$RUNTIME_CONFIG_FILE" "$RUNTIME_CLASH_CONFIG_FILE"
    nohup "$BIN_FILE" -d "$RUN_DIR" >"$LOG_FILE" 2>&1 &
else
    nohup "$BIN_FILE" -d "$CONFIG_DIR" -f "$RUNTIME_CONFIG_FILE" >"$LOG_FILE" 2>&1 &
fi

PID=$!
echo "$PID" > "$PID_FILE"

for _ in $(seq 1 30); do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "Mihomo 启动失败，最近日志如下：" >&2
        tail -n 40 "$LOG_FILE" >&2 || true
        exit 1
    fi

    if ss -ltn "( sport = :$PORT )" | grep -q LISTEN; then
        cat <<EOF
Mihomo 已启动
PID: $PID
PORT: $PORT
CONFIG: $CONFIG_FILE
RUNTIME_CONFIG: $RUNTIME_CONFIG_FILE
LOG: $LOG_FILE
EOF
        exit 0
    fi

    sleep 1
done

echo "Mihomo 仍在初始化，请查看日志: $LOG_FILE" >&2
exit 1
