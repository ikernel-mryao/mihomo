#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

CURRENT_USER=$(id -un)
USE_SUDO=0
if [[ "${1:-}" == "--sudo" ]]; then
    USE_SUDO=1
fi

mapfile -t PIDS < <(list_mihomo_pids)

if [[ "${#PIDS[@]}" -eq 0 ]]; then
    echo "当前没有运行中的 Mihomo 或 clash-linux 进程。"
    exit 0
fi

for pid in "${PIDS[@]}"; do
    [[ -n "$pid" ]] || continue

    proc_user=$(ps -o user= -p "$pid" | awk '{print $1}')
    proc_cmd=$(ps -o cmd= -p "$pid")

    if [[ -z "$proc_user" ]]; then
        continue
    fi

    if [[ "$proc_user" == "$CURRENT_USER" ]]; then
        kill "$pid"
        echo "已发送停止信号: PID=$pid CMD=$proc_cmd"
        continue
    fi

    if [[ "$USE_SUDO" -eq 1 ]]; then
        sudo kill "$pid"
        echo "已通过 sudo 发送停止信号: PID=$pid CMD=$proc_cmd"
        continue
    fi

    echo "发现非当前用户进程，无法直接停止: PID=$pid USER=$proc_user CMD=$proc_cmd" >&2
    echo "如需停止，请执行: sudo kill $pid" >&2
    exit 1
done

for _ in $(seq 1 10); do
    remaining=$(list_mihomo_pids)
    if [[ -z "${remaining:-}" ]]; then
        rm -f "$PID_FILE"
        echo "Mihomo 已停止。"
        exit 0
    fi
    sleep 1
done

echo "仍有未停止进程:" >&2
printf '%s\n' "$remaining" | while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    ps -o pid=,user=,etime=,cmd= -p "$pid"
done >&2

exit 1
