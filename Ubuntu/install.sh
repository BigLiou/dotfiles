#!/bin/bash
set -e

# 引入 color_echo.sh
source ./color_echo.sh

# 彩色输出
generic_echo() {
    echo -e "\033[1;32m$1\033[0m"
}

# 检查系统
if [[ "$(uname -s)" != "Linux" ]] || ! grep -qi ubuntu /etc/os-release; then
    error_echo "❌ 此安装脚本仅适用于 Ubuntu 系统"
    exit 1
fi

# 安装常用工具前的检测函数
install_if_missing() {
    local cmd=$1
    local pkg=${2:-$1}

    if ! command -v "$cmd" &>/dev/null; then
        generic_echo "🔧 正在安装 $pkg..."
        sudo apt install -y "$pkg"
    else
        generic_echo "✅ 已安装 $cmd"
    fi
}

# 更新源
generic_echo "🚀 更新软件包索引..."
sudo apt update

# 安装基本工具
install_if_missing git
install_if_missing curl
install_if_missing zsh
install_if_missing stow

# 安装 Starship
if ! command -v starship &>/dev/null; then
    generic_echo "🚀 安装 Starship..."
    curl -sS https://starship.rs/install.sh | sh
else
    generic_echo "✅ 已安装 starship"
fi

# 安装 zinit（zsh 插件管理器）
if [ ! -d "$HOME/.zinit" ]; then
    generic_echo "🧩 安装 zinit 插件管理器..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
else
    generic_echo "✅ 已安装 zinit"
fi

# dotfiles 目录（假设 install.sh 位于 dotfiles/Ubuntu）
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

# 使用 stow 链接配置
generic_echo "🔗 使用 stow 创建软链接..."
stow zsh
stow starship

# 设置默认 shell
if [[ "$SHELL" != *zsh ]]; then
    generic_echo "💡 设置 zsh 为默认 shell..."
    chsh -s "$(which zsh)"  # 设置当前用户为 zsh
    exec zsh    # 切换到 Zsh
else
    generic_echo "✅ 当前默认 shell 已是 zsh"
fi

# 完成信息
generic_echo ""
generic_echo "=================================================="
generic_echo "🎉 dotfiles 配置完成！"
generic_echo "🔁 请重启终端或运行 zsh 启动新环境"
generic_echo "=================================================="