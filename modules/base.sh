#!/usr/bin/env bash  
# modules/base.sh
export PATH="$HOME/.local/bin:$PATH"
# ====================== 更新软件源 ======================
update_apt() {
    local max_retries=3
    local retry=1

    while [[ $retry -le $max_retries ]]; do
        if run_task "更新软件包索引" \
            "sudo apt-get update -y > /dev/null"; then
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
    if [[ -n "$cmd" ]] && command -v "$cmd" &>/dev/null; then
        success "工具 $pkg 已安装"
        return 0
    fi

    while [[ $retry -le $max_retries ]]; do
        if run_task "$pkg 安装" \
            "sudo apt-get install -y $pkg > /dev/null"; then
            if [[ -n "$cmd" ]] && command -v "$cmd" &>/dev/null; then
                return 0
            fi
            # 如果 cmd 为空，直接返回成功
            if [[ -z "$cmd" ]]; then
                return 0
            fi
        fi
        retry=$((retry+1))
    done

    error "$pkg 安装失败（已重试 $max_retries 次）"
    return 1
}

# ====================== 安装 Starship ======================
install_starship() {
    if command -v starship &>/dev/null; then
        success "工具 starship 已安装"
        return 0
    fi

    local max_retries=3
    local retry=1

    while [[ $retry -le $max_retries ]]; do
        if run_task "starship 安装" \
            "curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null"; then
            if command -v starship &>/dev/null; then
                return 0
            fi
        fi

        warn "starship 安装失败，正在重试 ($retry/$max_retries)..."
        retry=$((retry+1))
        sleep 1
    done

    error "starship 安装失败（已重试 $max_retries 次）"
    return 1
}

# ====================== 安装 Zinit ======================
install_zinit() {
    section "安装 Zinit 插件管理器"

    local ZINIT_HOME="$HOME/.local/share/zinit"
    if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
        success "Zinit 已安装"
        return 0
    fi

    # 确保 git 已安装
    if ! command -v git &>/dev/null; then
        install_if_missing git
    fi

    # 安装 Zinit
    run_task "安装 Zinit" "git clone https://github.com/zdharma-continuum/zinit $ZINIT_HOME > /dev/null"
    if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
        success "Zinit 安装完成"
    else
        error "Zinit 安装失败"
        return 1
    fi
}

# ====================== 安装 Mise ======================
install_mise() {
    section "安装 Mise"

    # 直接检测实际路径
    if [[ -x "$HOME/.local/bin/mise" ]]; then
        success "Mise 已安装"
        return 0
    fi

    run_task "Mise 安装" \
        "curl -fsSL https://mise.run -o /tmp/mise_install.sh && bash /tmp/mise_install.sh"

    # 再次检测
    if [[ -x "$HOME/.local/bin/mise" ]]; then
        success "Mise 安装完成"
        return 0
    fi

    error "Mise 安装失败"
    return 1
}

# ====================== 安装编译环境和开发库 ======================
install_build_deps() {
    section "安装编译环境和开发库"

    local pkgs=(
        build-essential
        libssl-dev
        zlib1g-dev
        libbz2-dev
        libreadline-dev
        libsqlite3-dev
        clang
        llvm
        libncursesw5-dev
        xz-utils
        tk-dev
        libxml2-dev
        libxmlsec1-dev
        libffi-dev
        liblzma-dev
    )

    local max_retries=3
    local retry=1

    while [[ $retry -le $max_retries ]]; do
        if run_task "安装编译环境依赖" \
            "sudo apt-get install -y ${pkgs[*]} > /dev/null"; then
            success "编译环境依赖安装完成"
            return 0
        fi
        warn "编译环境依赖安装失败，重试 ($retry/$max_retries)..."
        retry=$((retry+1))
        sleep 1
    done

    error "编译环境依赖安装失败（已重试 $max_retries 次）"
    return 1
}

# ====================== 模块对外入口 ======================
base_install() {
    section "基础工具安装"

    # 更新软件源
    update_apt || return 1

    # ====================== 安装基础组件 ======================
    install_if_missing curl
    install_if_missing wget
    install_if_missing git
    install_if_missing zip
    install_if_missing unzip
    install_if_missing zsh
    install_if_missing tmux
    install_if_missing stow
    install_if_missing fzf
    install_if_missing rg ripgrep

    # ====================== 网络与排查工具 ======================
    install_if_missing tcpdump
    install_if_missing ifconfig net-tools
    install_if_missing htop
    install_if_missing tree

    # ====================== 安装编译环境依赖 ======================
    install_build_deps

    # ====================== 安装 Zinit & Mise ======================
    install_zinit
    install_mise

    # ====================== 安装 Starship ======================
    install_starship

    success "基础工具安装完成"
}

# ====================== 脚本独立执行入口 ======================
if [[ "$0" == "$BASH_SOURCE" ]]; then
    base_install
fi