#!/usr/bin/env bash
# scripts/stow.sh
# 一键为 dotfiles 建立软链接，自动备份已有文件/目录

stow_dotfiles() {
    set -euo pipefail

    section "部署 Dotfiles (GNU Stow)"

    DOTFILES_DIR="${HOME}/dotfiles"
    CONFIG_DIR="${DOTFILES_DIR}/.config"
    BACKUP_DIR="${HOME}/dotfiles_backup"

    # 检查 stow 是否安装
    if ! command -v stow &>/dev/null; then
        error "stow 未安装，请先运行 base.sh 安装 stow"
        return 1
    fi

    # 检查配置目录
    if [[ ! -d "$CONFIG_DIR" ]]; then
        error "配置目录不存在: $CONFIG_DIR"
        return 1
    fi

    mkdir -p "$BACKUP_DIR"

    info "配置目录: $CONFIG_DIR"
    info "备份目录: $BACKUP_DIR"

    cd "$CONFIG_DIR"

    shopt -s nullglob

    for module in */; do
        module="${module%/}"

        step "处理模块 $module"

        # ====================== 备份已有文件 ======================
        while read -r f; do
            REL_PATH="${f#$module/}"
            TARGET_PATH="$HOME/$REL_PATH"

            if [[ -e "$TARGET_PATH" && ! -L "$TARGET_PATH" ]]; then
                BACKUP_PATH="$BACKUP_DIR/$REL_PATH"
                mkdir -p "$(dirname "$BACKUP_PATH")"

                warn "检测到已有文件: $TARGET_PATH"
                info "备份 -> $BACKUP_PATH"

                mv "$TARGET_PATH" "$BACKUP_PATH"
            fi
        done < <(find "$module" -mindepth 1 -type f)

        # ====================== 预检测 stow 冲突 ======================
        info "检测 $module 是否存在冲突"

        if ! stow -nvt "$HOME" "$module" > /dev/null 2>&1; then
            warn "$module 可能存在冲突，stow 仍将尝试部署"
        fi

        # ====================== 执行 stow ======================
        run_task "部署 $module 配置" \
            "stow --restow --target=\$HOME $module > /dev/null"
    done

    success "所有配置软链接建立完成"
    info "已有文件已备份到 $BACKUP_DIR"
}

# 允许脚本独立执行
if [[ "$0" == "$BASH_SOURCE" ]]; then
    stow_dotfiles
fi