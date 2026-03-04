#!/usr/bin/env bash
# lib/utils.sh
# 系统信息与权限检查工具

# ====================== 内部输出函数依赖 logging.sh ======================
# 确保 logging.sh 已加载
if ! command -v info &>/dev/null; then
    echo -e "\033[0;31m❌ 未加载 logging.sh，请先加载\033[0m"
    exit 1
fi

# ====================== 系统检测 ======================
check_system() {
    local uname_s
    local uname_r
    local os_name

    uname_s=$(uname -s)
    uname_r=$(uname -r)
    
    # 尝试读取发行版信息
    if [[ -f "/etc/os-release" ]]; then
        os_name=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        os_name="未知发行版"
    fi

    info "系统信息: $uname_s $uname_r ($os_name)"

    # 检查是否 Linux
    if [[ "$uname_s" != "Linux" ]]; then
        error "此安装脚本仅适用于 Linux 系统"
        return 1
    fi

    # 检查是否 Ubuntu
    if [[ ! -f "/etc/os-release" ]] || ! grep -qi ubuntu /etc/os-release; then
        error "此安装脚本仅适用于 Ubuntu 系统（当前: $os_name）"
        return 1
    fi

    success "系统检测通过"
    return 0
}

# ====================== 权限检测 & 预获取 sudo ======================
check_permissions() {
    local user_name euid
    user_name="$USER"
    euid="$EUID"

    info "当前用户: $user_name (UID: $euid)"

    local home_status tmp_status
    if [ -w "$HOME" ]; then
        home_status="✅ 可写"
    else
        home_status="❌ 不可写"
    fi
    info "HOME 目录: $home_status"

    if [ -w "/tmp" ]; then
        tmp_status="✅ 可写"
    else
        tmp_status="❌ 不可写"
    fi
    info "/tmp 目录: $tmp_status"

    if [ "$EUID" -eq 0 ]; then
        warn "⚠️ 不建议以 root 用户运行脚本"
    fi

    # 判断是否有关键权限问题
    if ! ([ -w "$HOME" ] && [ -w "/tmp" ]); then
        error "权限检查未通过，请确认 HOME 或 /tmp 可写"
        return 1
    fi

    # ====================== 预获取 sudo 权限 ======================
    if command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
        info "尝试获取 sudo 权限..."
        if sudo -v; then
            # 后台保持 sudo 会话
            while true; do
                sudo -n true
                sleep 60
            done 2>/dev/null &
            SUDO_KEEPALIVE_PID=$!
        else
            warn "未能获取 sudo 权限，后续安装可能会要求输入密码"
        fi
    fi

    success "权限检查通过"
    return 0
}

# ====================== 退出时清理 sudo keepalive ======================
cleanup_sudo() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

# trap 注册，确保脚本退出时清理
trap cleanup_sudo EXIT