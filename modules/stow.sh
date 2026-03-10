#!/usr/bin/env bash
# scripts/stow.sh
# 一键为 dotfiles 建立软链接，自动备份已有文件/目录

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

        # 备份已有文件
        find "$module" -mindepth 1 -type f | while read -r f; do
            REL_PATH="${f#$module/}"
            TARGET_PATH="$HOME/$REL_PATH"

            if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                BACKUP_PATH="$BACKUP_DIR/$REL_PATH"
                mkdir -p "$(dirname "$BACKUP_PATH")"

                echo "备份已有文件 $TARGET_PATH -> $BACKUP_PATH"
                mv "$TARGET_PATH" "$BACKUP_PATH"
            fi
        done

        # 统一映射到 HOME
        stow --verbose=1 --target="$HOME" "$module"
    done

    echo "所有配置软链接建立完成 ✅"
    echo "已有文件已备份到 $BACKUP_DIR"
}