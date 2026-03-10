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

# ====================== 主流程 ======================
main() {
    info "=============================="
    info "开始安装基础工具"
    info "=============================="
    base_install  # 安装 stow、基础工具等

    info "=============================="
    info "开始建立配置软链接"
    info "=============================="
    stow_dotfiles

    info "=============================="
    info "安装完成 ✅"
    info "=============================="
}

main "$@"