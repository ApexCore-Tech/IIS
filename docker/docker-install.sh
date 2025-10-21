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
function log_error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_RED}${TEXT_BOLD}[${timestamp}][ERROR]${TEXT_RESET} ${TEXT_RED}$*${TEXT_RESET}" >&2
}

function log_warn() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_YELLOW}[${timestamp}][WARN]${TEXT_RESET} ${TEXT_YELLOW}$*${TEXT_RESET}" >&2
}

function log_info() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_BLUE}[${timestamp}][INFO]${TEXT_RESET} $*"
}

function log_success() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${TEXT_GREEN}${TEXT_BOLD}[${timestamp}][SUCCESS]${TEXT_RESET} ${TEXT_GREEN}$*${TEXT_RESET}"
}

function log_debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${TEXT_CYAN}[${timestamp}][DEBUG]${TEXT_RESET} $*" >&2
  fi
}

function util_echo_icon() {
  echo
  echo -e "${TEXT_GREEN}╔═╗ ╔═╗ ╔════╗"
  echo -e " ║   ║  ║     "
  echo -e " ║   ║  ╠════╣"
  echo -e " ║   ║       ║"
  echo -e "╚═╝ ╚═╝ ╚════╝${TEXT_RESET}"
  echo
  echo -e "&copy; ApexCore.Tech"
  echo
}

function utils_get_scripts_metadata() {
  local script_name="${0##*/}"
  local script_dir=""
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local script_version="0.1.0-alpha+build.20251016"

  readonly script_name
  readonly script_dir
  readonly script_version
}

function utils_get_os_metadata() {
  :
}

function utils_detect_dns_tool() {
  if command -v getent &> /dev/null; then
    echo "getent"
  elif command -v host &> /dev/null; then
    echo "host"
  elif command -v nslookup &> /dev/null; then
    echo "nslookup"
  elif command -v dig &> /dev/null; then
    echo "dig"
  else
    echo "ping"
  fi
}

function utils_judge_networks_status() {
  # 测试网络联通使用的域名地址
  local domain="4r3al.team"
  local dns_tool

  log_info "检查 DNS 解析服务器情况中……"
  log_info "检查 DNS 工具中……"
  dns_tool=$(utils_detect_dns_tool 2>/dev/null)
  log_info "使用 DNS 工具为：${dns_tool}"

  case ${dns_tool} in
    "getent")
      if getent hosts "${domain}" &> /dev/null; then
        log_info "DNS 解析正常（getent）"
        return 0
      else
        log_error "DNS 解析失败（getent）"
        return 1
      fi
      ;;
    "host")
      if host "${domain}" &> /dev/null; then
        log_info "DNS 解析正常（host）"
        return 0
      else
        log_error "DNS 解析失败（host）"
        return 1
      fi
      ;;
    "nslookup")
      if nslookup "${domain}" &> /dev/null; then
        log_info "DNS 解析正常（nslookup）"
        return 0
      else
        log_error "DNS 解析失败（nslookup）"
        return 1
      fi
      ;;
    "dig")
      if dig "${domain}" +short &> /dev/null; then
        log_info "DNS 解析正常（dig）"
        return 0
      else
        log_error "DNS 解析失败（dig）"
        return 1
      fi
      ;;
    "ping")
      if ping -c 1 -W 2 "${domain}" &> /dev/null; then
        log_info "DNS 解析正常（ping）"
        return 0
      else
        if ping -c 1 -W 2 "114.114.114.114" &> /dev/null; then
          log_error "DNS 解析失败（ping）"
        else
          log_error "网络连接失败"
        fi
      fi
      ;;
    "*")
      log_error "无法找到可用的 DNS 检测工具"
      return 2
    ;;
  esac
}

function utils_found_pm() {
  local package_managers=()
  local pm
  export found_pm

  package_managers=("apt" "yum" "dnf" "pacman" "zypper" "dnf")

  for pm in "${package_managers[@]}"; do
    if command -v "${pm}" &> /dev/null; then
      found_pm="${pm}"
      log_success "找到包管理器：${pm}"
      break
    fi
  done

  if [[ -z "${found_pm}" ]]; then
    log_warn "未找到常用的包管理器"
  fi
}

function utils_judge_dependencies() {
  local missing_deps=()
  local required_tools=()
  local apt_packages=()
  local yum_packages=()
  local tool

  required_tools=(
    "wget"
    "unzip"
    "tar"
    "rsync"
  )

  log_info "检查所需依赖情况中……"

  for tool in "${required_tools[@]}"; do
    if ! command -v "${tool}" &> /dev/null; then
      log_error "缺少依赖工具：${tool}"
      missing_deps+=("${tool}")
    fi
  done

  if [[ ${#missing_deps[@]} -eq 0 ]]; then
    log_success "所需依赖均已安装"
  else
    log_warn "缺少如下依赖：${missing_deps[*]}"
    echo
    log_info "将自动安装所需依赖"
    utils_found_pm

    if [[ -n "${found_pm}" ]]; then
      case "${found_pm}" in
        "apt")
          declare -A apt_package_map=(
            ["wget"]="wget"
            ["unzip"]="unzip"
            ["tar"]="tar"
            ["rsync"]="rsync"
          )

          for tool in "${missing_deps[@]}"; do
            apt_packages+=("${apt_package_map[@]}")
          done

          log_info "如下命令将会被执行 apt update && apt install -y ${apt_packages[*]}"
          log_info "所需时间较长，请耐心等待……"
          log_info "执行 apt update 命令中……"
          if apt update > /dev/null 2>&1; then
            log_success "软件包列表更新完成"
          else
            log_error "软件包列表更新失败，请手动处理"
            return 1
          fi

          log_info "执行 apt install -y ${apt_packages[*]} 命令中……"
          if apt install -y "${apt_packages[*]}" > /dev/null 2>&1; then
            log_success "依赖安装完成"
          else
            log_error "依赖安装失败，请手动安装如下依赖 ${apt_packages[*]}"
            return 1
          fi
        ;;
        "yum" | "dnf")
          declare -A yum_package_map=(
            ["wget"]="wget"
            ["unzip"]="unzip"
            ["tar"]="tar"
            ["rsync"]="rsync"
          )

          for tool in "${missing_deps[@]}"; do
            yum_packages+=("${yum_package_map[@]}")
          done

          log_info "如下命令将会被执行 apt update && apt install -y ${yum_packages[*]}"
          log_info "所需时间较长，请耐心等待……"
          log_info "执行 apt update 命令中……"
          if apt update > /dev/null 2>&1; then
            log_success "软件包列表更新完成"
          else
            log_error "软件包列表更新失败，请手动处理"
            return 1
          fi

          log_info "执行 apt install -y ${yum_packages[*]} 命令中……"
          if apt install -y "${yum_packages[*]}" > /dev/null 2>&1; then
            log_success "依赖安装完成"
          else
            log_error "依赖安装失败，请手动安装如下依赖 ${yum_packages[*]}"
            return 1
          fi
        ;;
        "*")
          log_error "无法自动安装所需依赖，请手动处理"
        ;;
      esac
    fi
  fi
}

function utils_show_help() {
  :
}

function core_install_docker() {
  :
}

function core_install_docker_compose() {
  :
}

function main() {
  utils_judge_networks_status
}

main "$@"
