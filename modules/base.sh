#!/usr/bin/env bash
# modules/base.sh

# ====================== 更新软件源 ======================
update_apt() {
    local max_retries=3
    local retry=1

    while [[ $retry -le $max_retries ]]; do
        if run_task "更新软件包索引" \
            "sudo apt-get update -y"; then
            return 0
        fi
        retry=$((retry+1))
    done

    error "软件源更新失败（已重试 $max_retries 次）"
    return 1
}

# ====================== 安装单个工具（幂等 + 显示包名） ======================
install_if_missing() {
    local cmd="$1"
    local pkg="${2:-$1}"
    local max_retries=3
    local retry=1

    # 检查命令是否存在
    if command -v "$cmd" &>/dev/null; then
        success "工具 $pkg 已安装"  # ⚡ 显示包名而不是命令名
        return 0
    fi

    while [[ $retry -le $max_retries ]]; do
        if run_task "$pkg 安装" \
            "sudo apt-get install -y $pkg"; then

            if command -v "$cmd" &>/dev/null; then
                return 0
            fi
        fi
        retry=$((retry+1))
    done

    error "$pkg 安装失败（已重试 $max_retries 次）"
    return 1
}

# ====================== 安装 starship ======================
install_starship() {
    if command -v starship &>/dev/null; then
        success "工具 starship 已安装"
        return 0
    fi

    local max_retries=3
    local retry=1

    while [[ $retry -le $max_retries ]]; do
        # 执行安装，并捕获返回值
        if run_task "starship 安装" \
            "curl -sS https://starship.rs/install.sh | sh -s -- -y"; then

            # 安装后二次验证
            if command -v starship &>/dev/null; then
                return 0
            fi
        fi

        warning "starship 安装失败，正在重试 ($retry/$max_retries)..."
        retry=$((retry+1))
        sleep 1
    done

    error "starship 安装失败（已重试 $max_retries 次）"
    return 1
}

# ====================== 模块对外入口 ======================
base_install() {

    section "基础工具安装"

    # 更新软件源
    update_apt || return 1

    # ====================== 安装基础组件 ======================
    install_if_missing curl
    install_if_missing git
    install_if_missing zip
    install_if_missing unzip
    install_if_missing zsh
    install_if_missing tmux
    install_if_missing stow

    # ====================== 网络与排查工具 ======================
    install_if_missing tcpdump
    install_if_missing ifconfig net-tools   # net-tools 安装时检测 ifconfig
    install_if_missing htop
    install_if_missing tree

    # ====================== 安装 Starship ======================
    install_starship

    success "基础工具安装完成"
}

# ====================== 脚本独立执行入口 ======================
if [[ "$0" == "$BASH_SOURCE" ]]; then
    base_install
fi