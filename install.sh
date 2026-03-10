#!/usr/bin/env bash
set -euo pipefail

# ====================== 基础路径 ======================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ====================== 加载核心库 ======================
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"

# ====================== 系统与权限检查 ======================
check_system
check_permissions

# ====================== 自动加载所有模块 ======================
for module in "$SCRIPT_DIR"/modules/*.sh; do
    source "$module"
done

# ====================== 设置默认 shell ======================
set_default_shell() {

    if ! command -v zsh &>/dev/null; then
        warn "zsh 未安装，跳过默认 shell 设置"
        return
    fi

    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
        step "设置 zsh 为默认 shell"

        if chsh -s "$(command -v zsh)" "$USER"; then
            success "默认 shell 已设置为 zsh"
        else
            warn "默认 shell 设置失败（可能需要重新登录）"
        fi
    else
        success "默认 shell 已是 zsh"
    fi
}

# ====================== 主流程 ======================
main() {

    info "=============================="
    info "开始安装基础工具"
    info "=============================="
    base_install

    info "=============================="
    info "开始建立配置软链接"
    info "=============================="
    stow_dotfiles

    info "=============================="
    info "安装开发环境"
    info "=============================="
    mise_install

    info "=============================="
    info "设置默认 shell"
    info "=============================="
    set_default_shell

    info "=============================="
    info "安装完成 ✅"
    info "=============================="

    # ====================== 切换当前 shell ======================
    if [[ -z "${ZSH_VERSION:-}" ]]; then
        info "进入 zsh shell"
        exec zsh
    fi
}

main "$@"