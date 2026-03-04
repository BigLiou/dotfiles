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

# ====================== 菜单 ======================
show_menu() {
    info "========================================"
    info "              安装选项"
    info "========================================"
    info "1. 安装基础工具"
    info "2. 安装 Mise、Neovim 和 LazyVim"
    info "9. 全部安装"
    info "0. 退出"
    info "========================================"
}

get_user_choice() {
    read -rp "请选择要执行的操作: " choice
    echo "$choice"
}

# ====================== 主流程 ======================
main() {
    show_menu
    local choice
    choice=$(get_user_choice)

    case "$choice" in
        0)
            info "退出安装脚本"
            exit 0
            ;;
        1)
            base_install
            ;;
        2)
            mise_install
            ;;
        9)
            base_install
            mise_install
            ;;
        *)
            error "无效的选择：$choice"
            exit 1
            ;;
    esac

    banner_done
}

main "$@"