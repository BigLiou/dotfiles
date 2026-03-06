#!/usr/bin/env bash

# ==============================================
# Dotfiles 安装日志与任务工具集
# ==============================================

# ====================== 颜色定义 ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ====================== 内部输出函数 ======================
# 带颜色、图标、时间戳的核心打印函数
__print() {
    local color="$1"
    local icon="$2"
    local message="$3"
    local timestamp
    timestamp=$(date +"%H:%M:%S")

    if [[ ! -t 1 ]]; then
        # 非交互终端，去掉颜色和图标
        echo "[$timestamp] $message"
    else
        echo -e "${color}${icon} [${timestamp}] ${message}${NC}"
    fi
}

# ====================== 状态输出接口 ======================
# 用于步骤、成功、错误、警告、信息
section() {
    local title="$1"
    echo
    echo "============================================"
    echo "  $title"
    echo "============================================"
    echo
}

step()    { __print "$BLUE"  "▶" "$1"; }
success() { __print "$GREEN" "✅" "$1"; }
error()   { __print "$RED"   "❌" "$1"; }
warn()    { __print "$YELLOW" "⚠️" "$1"; }
info()    { __print "$BLUE"  "🔧" "$1"; }

# ====================== 普通信息输出接口 ======================
# plain "颜色" "内容" [是否显示时间，默认 true]
plain() {
    local color="${1:-$NC}"
    local message="$2"
    local show_time="${3:-true}"

    if [[ "$show_time" == "true" ]]; then
        local timestamp
        timestamp=$(date +"%H:%M:%S")
        echo -e "${color}[${timestamp}] ${message}${NC}"
    else
        echo -e "${color}${message}${NC}"
    fi
}

# ====================== 正在执行任务（带 Spinner + 耗时） ======================
# 用法: run_task "任务名称" "命令"
run_task() {
    local task="$1"
    local cmd="$2"
    local max_retries="${3:-3}"

    local attempt=1
    local exit_code=0

    local start_time
    start_time=$(date +%s)

    while [[ $attempt -le $max_retries ]]; do

        info "正在执行 $task... (第 $attempt/$max_retries 次)"

        bash -c "$cmd"
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            local end_time
            end_time=$(date +%s)
            local elapsed=$((end_time - start_time))
            success "$task 执行完成 (耗时 ${elapsed} 秒)"
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            warn "$task 执行失败，准备重试..."
            sleep 1
        fi

        attempt=$((attempt+1))
    done

    local end_time
    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    error "$task 执行失败 (已重试 $max_retries 次，耗时 ${elapsed} 秒)"
    return $exit_code
}

# ====================== 安装完成 Banner ======================
banner_done() {
    cat <<'EOF'

__________.__       .____    .__              
\______   \__| ____ |    |   |__| ____  __ __ 
 |    |  _/  |/ ___\|    |   |  |/  _ \|  |  \
 |    |   \  / /_/  >    |___|  (  <_> )  |  /
 |______  /__\___  /|_______ \__|\____/|____/ 
        \/  /_____/         \/                

EOF
    echo -e "${GREEN}     🎉 BigLiou‘s Dotfiles 配置完成 🎉${NC}"
    echo
    echo "请重新打开终端以使环境生效"
    echo
}