#!/usr/bin/env bash
# scripts/stow.sh
# 一键为 dotfiles 建立软链接，自动备份已有文件/目录
# 适配 Git、Starship、Mise、Zsh 配置

stow_dotfiles() {
    set -euo pipefail

    DOTFILES_DIR="${HOME}/dotfiles"
    CONFIG_DIR="${DOTFILES_DIR}/.config"
    BACKUP_DIR="${HOME}/dotfiles_backup"

    # 检查 stow 是否安装
    if ! command -v stow &>/dev/null; then
        echo "错误：stow 未安装，请先运行 base.sh 安装 stow"
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"
    cd "$CONFIG_DIR"

    for module in */; do
        module="${module%/}"
        echo "正在为模块 $module 建立软链接"

        # 备份已有文件/目录
        find "$module" -mindepth 1 | while read -r f; do
            REL_PATH="${f#$module/}"   # 相对路径

            # 目标路径
            if [[ "$module" == "zsh" ]]; then
                if [[ "$REL_PATH" == ".zshrc" ]]; then
                    TARGET_PATH="$HOME/$REL_PATH"
                else
                    TARGET_PATH="$HOME/.config/zsh/$REL_PATH"
                fi
            else
                TARGET_PATH="$HOME/.config/$module/$REL_PATH"
            fi

            # 创建父目录
            mkdir -p "$(dirname "$TARGET_PATH")"

            # 备份已有文件/目录
            if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                BACKUP_PATH="$BACKUP_DIR/$module/$REL_PATH"
                mkdir -p "$(dirname "$BACKUP_PATH")"
                echo "备份已有文件/目录 $TARGET_PATH -> $BACKUP_PATH"
                mv "$TARGET_PATH" "$BACKUP_PATH"
            fi
        done

        # 建立软链接
        if [[ "$module" == "zsh" ]]; then
            # zsh: .zshrc 映射到 $HOME，其余映射到 ~/.config/zsh
            stow --verbose=1 --target="$HOME" --no-folding "$module"
        else
            # 其他模块保留模块名目录
            stow --verbose=1 --target="$HOME/.config" "$module"
        fi
    done

    echo "所有配置软链接建立完成 ✅"
    echo "已有文件已备份到 $BACKUP_DIR"
}