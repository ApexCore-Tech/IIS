#!/bin/bash
#
# Docker 与 Docker Compose 的一键安装脚本
#
# Copyright © 2025 ApexCore.Tech

# -e: 遇到错误退出
# -u: 使用未定义变量时报错
# -o pipefail: 管道中任何命令失败都算失败
set -euo pipefail

readonly TEXT_BOLD='\033[1m'
readonly TEXT_RED='\033[0;31m'
readonly TEXT_GREEN='\033[0;32m'
readonly TEXT_YELLOW='\033[1;33m'
readonly TEXT_BLUE='\033[0;34m'
readonly TEXT_CYAN='\033[0;36m'
readonly TEXT_RESET='\033[0m'

# 带时间戳的日志函数
log::error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_RED}${TEXT_BOLD}[${timestamp}][ERROR]${TEXT_RESET} ${TEXT_RED}$*${TEXT_RESET}" >&2
}

log::warn() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_YELLOW}[${timestamp}][WARN]${TEXT_RESET} ${TEXT_YELLOW}$*${TEXT_RESET}" >&2
}

log::info() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_BLUE}[${timestamp}][INFO]${TEXT_RESET} $*"
}

log::success() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_GREEN}${TEXT_BOLD}[${timestamp}][SUCCESS]${TEXT_RESET} ${TEXT_GREEN}$*${TEXT_RESET}"
}

log::debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${TEXT_CYAN}[${timestamp}][DEBUG]${TEXT_RESET} $*" >&2
  fi
}
init_script_metadata() {
  local script_name="${0##*/}"
  local script_dir=""
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local script_version="0.1.0-alpha+build.20251016"

  readonly script_name
  readonly script_dir
  readonly script_version
}

function main() {
  init_script_metadata
}

main "$@"
