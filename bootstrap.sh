#!/bin/bash

set -e
clear

# 引入 color_echo.sh
source ./color_echo.sh

# 获取当前脚本所在目录
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 平台判断
OS=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        OS="Ubuntu"
    fi
fi

# 欢迎信息
generic_echo "=================================================="
generic_echo "         🚀 正在引导 dotfiles 环境初始化"
generic_echo "=================================================="
echo ""
generic_echo "本脚本将帮助你配置开发环境，包括："
generic_echo "• 创建软链接"
generic_echo "• 备份现有配置文件"
generic_echo "• 安装必要的工具与插件"
echo ""

if [[ -n "$OS" ]]; then
    generic_echo "💡 检测到当前系统为：$OS"
else
    error_echo "❌ 无法识别的操作系统，仅支持 macOS 和 Ubuntu。"
    exit 1
fi

# 进入对应平台子目录执行安装脚本
if [[ "$OS" == "macOS" ]]; then
    if [[ -f "$DOTFILES_DIR/Mac/install.sh" ]]; then
        generic_echo "🔧 正在进入 macOS 安装流程..."
        bash "$DOTFILES_DIR/Mac/install.sh"
    else
        error_echo "❌ 找不到 macOS 安装脚本：Mac/install.sh"
        exit 1
    fi
elif [[ "$OS" == "Ubuntu" ]]; then
    if [[ -f "$DOTFILES_DIR/Ubuntu/install.sh" ]]; then
        generic_echo "🔧 正在进入 Ubuntu 安装流程..."
        bash "$DOTFILES_DIR/Ubuntu/install.sh"
    else
        error_echo "❌ 找不到 Ubuntu 安装脚本：Ubuntu/install.sh"
        exit 1
    fi
fi
