#!/usr/bin/env bash
# scripts/stow.sh
# 一键为 dotfiles 建立软链接
# 自动备份已有文件/目录
# 适配 Git、Starship、Mise、Zsh 配置，保持路径与环境变量一致

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

    # =====================
    # 设置目标目录，保持子目录结构
    # =====================
    case "$module" in
        git|starship|mise)
            TARGET="$HOME/.config/$module"
            mkdir -p "$TARGET"
            ;;
        zsh)
            TARGET="$HOME/.config/zsh"
            mkdir -p "$TARGET"
            ;;
        *)
            TARGET="$HOME/.config/$module"
            mkdir -p "$TARGET"
            ;;
    esac

    echo "正在为模块 $module 建立软链接到 $TARGET"

    # =====================
    # 自动备份已有文件/目录
    # =====================
    find "$module" -mindepth 1 | while read -r f; do
        REL_PATH="${f#$module/}"          # 相对路径
        TARGET_PATH="$TARGET/$REL_PATH"
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
    # 使用 --no-folding 保持子目录结构
    stow --verbose=1 --target="$TARGET" --no-folding "$module"
done

echo "所有配置软链接建立完成 ✅"
echo "已有文件已备份到 $BACKUP_DIR"