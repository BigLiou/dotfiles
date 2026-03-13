#!/usr/bin/env bash
# modules/mise.sh

############################################
# 安装运行时环境
############################################
mise_install_env() {

    section "安装开发环境 (mise)"

    if ! command -v mise &>/dev/null; then
        warn "mise 未安装，跳过开发环境安装"
        return 0
    fi

    # 确认配置文件存在
    local MISE_CONFIG="$HOME/mise.toml"

    if [[ ! -f "$MISE_CONFIG" ]]; then
        warn "未检测到 mise 配置文件: $MISE_CONFIG"
        warn "跳过环境安装"
        return 0
    fi

    info "使用配置文件: $MISE_CONFIG"

    # 1️⃣ 信任配置文件（避免 Trust prompt）
    run_task "信任 mise 配置" \
        "mise trust --yes"

    # 2️⃣ 安装运行时
    run_task "安装语言运行时 (mise install)" \
        "mise install"
}

############################################
# 验证环境是否安装成功
############################################
verify_mise_env() {

    step "验证运行时环境"

    command -v node &>/dev/null && success "Node 已安装" || warn "Node 未检测到"
    command -v python3 &>/dev/null && success "Python 已安装" || warn "Python 未检测到"
    command -v java &>/dev/null && success "Java 已安装" || warn "Java 未检测到"
    command -v mvn &>/dev/null && success "Maven 已安装" || warn "Maven 未检测到"
}

############################################
# 模块入口
############################################
mise_install() {

    section "Mise 环境部署"

    mise_install_env || return 1
    verify_mise_env

    echo ""
    echo "=================================================="
    success "开发环境安装完成"
    echo "=================================================="
}

############################################
# 独立执行入口
############################################
if [[ "$0" == "$BASH_SOURCE" ]]; then
    mise_install
fi