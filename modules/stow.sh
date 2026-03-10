#!/usr/bin/env bash
# scripts/stow.sh
# 一键为 dotfiles 建立软链接
# 自动备份已有文件/目录
# 适配 Git、Starship、Mise、Zsh 配置，保持路径与环境变量一致
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

    cd "$CONFIG_DIR"

    for module in */; do
        module="${module%/}"
        TARGET="$HOME"

        echo "正在为模块 $module 建立软链接"

        # =====================
        # 自动备份已有文件/目录
        # =====================
        find "$module" -mindepth 1 | while read -r f; do
            REL_PATH="${f#$module/}"   # 相对路径

            # zsh 模块特殊处理
            if [[ "$module" == "zsh" ]]; then
                if [[ "$REL_PATH" == ".zshrc" ]]; then
                    TARGET_PATH="$HOME/$REL_PATH"
                else
                    TARGET_PATH="$HOME/.config/zsh/$REL_PATH"
                    mkdir -p "$(dirname "$TARGET_PATH")"
                fi
            else
                # 其他模块保持原来的目标目录
                case "$module" in
                    git|starship|mise)
                        TARGET_PATH="$HOME/.config/$module/$REL_PATH"
                        mkdir -p "$(dirname "$TARGET_PATH")"
                        ;;
                    *)
                        TARGET_PATH="$HOME/.config/$module/$REL_PATH"
                        mkdir -p "$(dirname "$TARGET_PATH")"
                        ;;
                esac
            fi

            # 如果目标存在且不是链接，先备份
            if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                BACKUP_PATH="$BACKUP_DIR/$module/$REL_PATH"
                mkdir -p "$(dirname "$BACKUP_PATH")"
                echo "备份已有文件/目录 $TARGET_PATH -> $BACKUP_PATH"
                mv "$TARGET_PATH" "$BACKUP_PATH"
            fi
        done

        # =====================
        # 创建软链接
        # =====================
        # zsh 模块指定 --target=$HOME 保证 .zshrc 放 HOME
        if [[ "$module" == "zsh" ]]; then
            stow --verbose=1 --target="$HOME" --no-folding "$module"
        else
            stow --verbose=1 --target="$HOME/.config" --no-folding "$module"
        fi
    done

    echo "所有配置软链接建立完成 ✅"
    echo "已有文件已备份到 $BACKUP_DIR"
}