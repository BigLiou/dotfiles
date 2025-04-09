# 安装 Zsh 和相关配置

# 定义一些路径
DOTFILES_DIR="$HOME/dotfiles"
ZSH_CONFIG="$HOME/.zshrc"
STARSHIP_CONFIG="$HOME/.config/starship.toml"

# 彩色输出的函数
color_echo() {
    echo -e "\033[1;32m$1\033[0m"
}

# 备份现有的 .zshrc 文件
color_echo "正在备份现有的 .zshrc..."
[ -f $ZSH_CONFIG ] && mv $ZSH_CONFIG "$ZSH_CONFIG.bak"

# 安装 Zsh
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
ln -sf "$DOTFILES_DIR/.zshrc" $ZSH_CONFIG

# 安装 Starship 提示符
if ! command -v starship &> /dev/null; then
    color_echo "正在安装 Starship 提示符..."
    curl -sS https://starship.rs/install.sh | sh
fi

# 创建 starship 配置文件 starship.toml 的符号链接
color_echo "创建 starship 配置文件 starship.toml 的符号链接..."
ln -sf "$DOTFILES_DIR/.config/starship.toml" STARSHIP_CONFIG

# 设置 Zsh 为默认 shell
color_echo "正在将 Zsh 设置为默认 shell..."
chsh -s $(which zsh)

# 切换到 Zsh
color_echo "正在切换到 Zsh..."
exec zsh

# 结束操作
color_echo "=================================================="
color_echo "               Zsh 安装完成！                    "
color_echo "=================================================="
echo ""
color_echo "请重启你的 shell 或运行以下命令以应用更改："
color_echo "source ~/.zshrc"
color_echo "=================================================="
