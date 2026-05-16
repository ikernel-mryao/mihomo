#!/usr/bin/env bash
set -euo pipefail

unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset all_proxy
unset ALL_PROXY

echo "已取消代理环境变量"
