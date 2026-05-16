#!/usr/bin/env bash

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RUN_DIR="$ROOT_DIR/run"
CONFIG_DIR="$ROOT_DIR/config"
DOWNLOAD_DIR="$ROOT_DIR/downloads"
DEFAULT_CONFIG_FILE="$CONFIG_DIR/config.yaml"
RUNTIME_CONFIG_FILE="$RUN_DIR/config.runtime.yaml"
RUNTIME_CLASH_CONFIG_FILE="$RUN_DIR/config.yaml"
LOG_FILE="$RUN_DIR/mihomo.log"
PID_FILE="$RUN_DIR/mihomo.pid"

normalize_arch() {
    case "$1" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            return 1
            ;;
    esac
}

host_arch() {
    normalize_arch "$(uname -m)"
}

pick_working_bin() {
    local arch="$1"
    local candidate
    local candidates=(
        "$RUN_DIR/mihomo"
        "$RUN_DIR/mihomo-$arch"
        "$RUN_DIR/clash-linux"
    )

    if [[ "$arch" == "amd64" ]]; then
        candidates+=("$RUN_DIR/mihomo-arm64")
    else
        candidates+=("$RUN_DIR/mihomo-amd64")
    fi

    for candidate in "${candidates[@]}"; do
        [[ -x "$candidate" ]] || continue
        if "$candidate" -v >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

resolve_config_file() {
    local fallback_config
    fallback_config=$(find "$ROOT_DIR" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) | head -n 1 || true)

    if [[ -s "$DEFAULT_CONFIG_FILE" ]]; then
        echo "$DEFAULT_CONFIG_FILE"
        return 0
    fi

    if [[ -n "${fallback_config:-}" ]]; then
        echo "$fallback_config"
        return 0
    fi

    return 1
}

extract_mixed_port() {
    local config_file="$1"
    awk -F ':' '
        $1 ~ /^[[:space:]]*mixed-port$/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
            print $2
            exit
        }
    ' "$config_file"
}

prepare_runtime_config() {
    local source_file="$1"
    local target_file="$2"

    mkdir -p "$RUN_DIR"
    awk 'index($0, "GEOIP,private") == 0' "$source_file" > "$target_file"
}

list_mihomo_pids() {
    pgrep -f "$RUN_DIR/(mihomo|mihomo-amd64|mihomo-arm64|clash-linux)" || true
}

print_missing_config_help() {
    cat >&2 <<EOF
未找到明文配置文件:
  $DEFAULT_CONFIG_FILE

请登录你的机场/订阅服务，下载可直接给 Mihomo 使用的明文 Clash/Mihomo YAML 配置，
然后保存为上面的 config.yaml。

注意:
- 加密订阅链接不能直接给 Mihomo 使用
- 该仓库不会把你的 config/config.yaml 上传到 GitHub
EOF
}
