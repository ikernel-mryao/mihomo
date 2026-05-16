#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

VERSION="v1.19.23"
MODE="native"

download_asset() {
	local arch="$1"
	local asset_name
	local output_name
	local asset_url

	case "$arch" in
		amd64)
			asset_name="mihomo-linux-amd64-v1-go120-${VERSION}.gz"
			;;
		arm64)
			asset_name="mihomo-linux-arm64-${VERSION}.gz"
			;;
		*)
			echo "不支持的下载架构: $arch" >&2
			return 1
			;;
	esac

	asset_url="https://github.com/MetaCubeX/mihomo/releases/download/${VERSION}/${asset_name}"
	output_name="mihomo-${arch}"

	curl -fsSL "$asset_url" -o "$DOWNLOAD_DIR/$asset_name"
	gzip -dc "$DOWNLOAD_DIR/$asset_name" > "$RUN_DIR/$output_name"
	chmod +x "$RUN_DIR/$output_name"

	if [[ "$arch" == "$NATIVE_ARCH" ]]; then
		install -m 755 "$RUN_DIR/$output_name" "$RUN_DIR/mihomo"
	fi
}

if [[ $# -gt 0 ]]; then
	case "$1" in
		--all)
			MODE="all"
			;;
		--arch)
			if [[ $# -lt 2 ]]; then
				echo "用法: ./install-mihomo.sh [--all | --arch amd64|arm64]" >&2
				exit 1
			fi
			MODE=$(normalize_arch "$2") || {
				echo "当前脚本仅支持 amd64 和 arm64 目标架构，输入为: $2" >&2
				exit 1
			}
			;;
		*)
			echo "用法: ./install-mihomo.sh [--all | --arch amd64|arm64]" >&2
			exit 1
			;;
	esac
fi

HOST_ARCH=$(uname -m)
NATIVE_ARCH=$(normalize_arch "$HOST_ARCH") || {
	echo "当前脚本仅支持 x86_64/amd64 和 aarch64/arm64 Linux，当前架构: $HOST_ARCH" >&2
	exit 1
}

mkdir -p "$DOWNLOAD_DIR" "$RUN_DIR"

case "$MODE" in
	native)
		download_asset "$NATIVE_ARCH"
		;;
	all)
		download_asset amd64
		download_asset arm64
		;;
	amd64|arm64)
		download_asset "$MODE"
		;;
esac

BIN_FILE=$(pick_working_bin "$NATIVE_ARCH") || {
	echo "安装完成后仍未找到可运行内核，请检查 run/ 目录。" >&2
	exit 1
}

cat <<EOF
Mihomo 已安装到:
	$BIN_FILE

本机架构:
	$HOST_ARCH

已准备的二进制:
$(find "$RUN_DIR" -maxdepth 1 -type f -name 'mihomo*' -printf '	%f\n' | sort)

下一步:
1. 准备明文 Clash/Mihomo YAML 配置文件
2. 保存为 $ROOT_DIR/config/config.yaml
3. 运行 ./start-mihomo.sh
EOF
