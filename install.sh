#!/bin/bash
# 定义一些路径
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
ZSH_CONFIG="$CONFIG_DIR/zsh/.zshrc"
FISH_CONFIG="$CONFIG_DIR/fish/config.fish"

# 彩色输出的函数
color_echo() {
    echo -e "\033[1;32m$1\033[0m"  # 绿色
}

# 提示用户选择安装的 shell
clear
color_echo "=================================================="
color_echo "          欢迎使用 dotfiles 安装脚本！          "
color_echo "=================================================="
echo ""
echo "请选择要安装的 shell:"
echo "1) Zsh"
echo "2) Fish"
read -p "请输入你的选择 (1 或 2): " shell_choice

# 如果 .config 目录不存在，则创建它
mkdir -p $CONFIG_DIR/zsh
mkdir -p $CONFIG_DIR/fish

# 备份现有的 dotfiles
color_echo "正在备份现有的 dotfiles..."
[ -f $ZSH_CONFIG ] && mv $ZSH_CONFIG "$ZSH_CONFIG.bak"
[ -f $FISH_CONFIG ] && mv $FISH_CONFIG "$FISH_CONFIG.bak"

# 根据用户的选择安装 Zsh 或 Fish
if [ "$shell_choice" -eq 1 ]; then
    color_echo "正在安装 Zsh..."
    if ! command -v zsh &> /dev/null; then
        sudo apt-get install zsh -y
    fi

    # 安装 Zinit（Zsh 插件管理器）
    if [ ! -d "$HOME/.zinit" ]; then
        color_echo "正在安装 Zinit 插件管理器..."
        bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
    fi

    # 创建 Zsh 配置文件 .zshrc 的符号链接
    color_echo "创建 Zsh 配置文件 .zshrc 的符号链接..."
    ln -s "$DOTFILES_DIR/zsh/.zshrc" $ZSH_CONFIG

    # 安装 Starship 提示符
    if ! command -v starship &> /dev/null; then
        color_echo "正在安装 Starship 提示符..."
        curl -sS https://starship.rs/install.sh | sh
    fi

    # 初始化 Starship 提示符用于 Zsh
    color_echo 'eval "$(starship init zsh)"' >> $ZSH_CONFIG

    # 设置 Zsh 为默认 shell
    color_echo "正在将 Zsh 设置为默认 shell..."
    chsh -s $(which zsh)

elif [ "$shell_choice" -eq 2 ]; then
    color_echo "正在安装 Fish..."
    if ! command -v fish &> /dev/null; then
        sudo apt-get install fish -y
    fi

    # 创建 Fish 配置文件的符号链接
    color_echo "创建 Fish 配置文件的符号链接..."
    ln -s "$DOTFILES_DIR/fish/config.fish" $FISH_CONFIG

    # 安装 Starship 提示符
    if ! command -v starship &> /dev/null; then
        color_echo "正在安装 Starship 提示符..."
        curl -sS https://starship.rs/install.sh | sh
    fi

    # 初始化 Starship 提示符用于 Fish
    color_echo 'starship init fish | source' >> $FISH_CONFIG

    # 设置 Fish 为默认 shell
    color_echo "正在将 Fish 设置为默认 shell..."
    chsh -s $(which fish)

else
    color_echo "无效选择。请重新运行脚本并选择 1 (Zsh) 或 2 (Fish)。"
    exit 1
fi

# 其他清理或结束操作
color_echo "=================================================="
color_echo "               dotfiles 安装完成！              "
color_echo "=================================================="
echo ""
color_echo "请重启你的 shell 或运行以下命令以应用更改："
color_echo "source ~/.zshrc   # 如果你选择了 Zsh"
color_echo "source ~/.config/fish/config.fish   # 如果你选择了 Fish"
color_echo "=================================================="
