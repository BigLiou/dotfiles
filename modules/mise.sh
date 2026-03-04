#!/usr/bin/env bash
# modules/mise.sh

# ====================== 安装 Mise ======================
install_mise() {
    if command -v mise &>/dev/null; then
        success "Mise 已安装"
        return 0
    fi

    run_task "安装 Mise" \
        "curl -sSL https://mise.run | sh"

    # 激活 Mise
    eval "$(~/.local/bin/mise activate bash)"
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
    source ~/.bashrc
}

# ====================== 安装 Neovim + LazyVim ======================
install_neovim() {
    if command -v nvim &>/dev/null; then
        success "Neovim 已安装"
        return 0
    fi

    run_task "安装 Neovim" \
      "mise install neovim"

    run_task "全局激活 Neovim" \
      "mise use -g neovim"

    eval "$(~/.local/bin/mise activate bash)"
}

install_lazyvim() {
    local nvim_config="$HOME/.config/nvim"
    if [[ -d "$nvim_config" ]]; then
        success "LazyVim 已安装"
        return 0
    fi

    run_task "安装 LazyVim" \
        "git clone https://github.com/LazyVim/starter ~/.config/nvim"
    
    run_task "删除 LazyVim 自带 .git 目录" \
        "rm -rf ~/.config/nvim/.git"

    # 自动安装插件
    run_task "自动安装 LazyVim 插件" \
        "nvim --headless '+Lazy! sync' +qa"
}

# ====================== 安装 Node.js 16 + 20 ======================
install_node() {
    run_task "安装 Node.js 16" \
        "mise install node@16"
    
    run_task "安装 Node.js 20" \
        "mise install node@20"

    # 默认使用 20 版本
    run_task "设置全局默认 Node.js 20" \
        "mise use -g node@20"

    eval "$(~/.local/bin/mise activate bash)"
    success "Node.js 16 & 20 安装完成"
}

# ====================== 安装 Java 8 (Temurin) + Maven ======================
install_java_maven() {
    run_task "安装 Java Temurin 8" \
        "mise install java@temurin-8"

    run_task "安装 Maven" \
        "mise install maven@latest"

    run_task "设置全局默认 Java 8 & Maven" \
        "mise use -g java@temurin+8 maven@latest"

    eval "$(~/.local/bin/mise activate bash)"
    success "Java 8 + Maven 安装完成"
}

# ====================== 安装 Python 3.10 + 3.11 ======================
install_python() {
    run_task "安装 Python 3.10" \
        "mise install python@3.10"

    run_task "安装 Python 3.11" \
        "mise install python@3.11"

    # 默认使用 3.11
    run_task "设置全局默认 Python 3.11" \
        "mise use -g python@3.11"

    eval "$(~/.local/bin/mise activate bash)"
    success "Python 3.10 & 3.11 安装完成"
}

# ====================== 模块对外入口 ======================
mise_install() {
    section "Mise 环境一键部署"

    install_mise || return 1
    install_node || return 1
    install_java_maven || return 1
    install_python || return 1
    install_neovim || return 1
    install_lazyvim || return 1

    echo ""
    echo "=================================================="
    success " ✅ 全部环境安装完成！"
    echo ""
    success "已安装："
    success "  • Neovim + LazyVim"
    success "  • Node.js 16 / 20"
    success "  • Java 8 (Temurin) + Maven"
    success "  • Python 3.10 / 3.11"
    echo ""
    success "默认版本："
    success "  • node -v  → Node 20"
    success "  • java -v → Java 8"
    success "  • python3 -V → Python 3.11"
    echo "=================================================="
}

# ====================== 脚本独立执行入口 ======================
if [[ "$0" == "$BASH_SOURCE" ]]; then
    mise_install
fi