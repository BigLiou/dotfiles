#!/usr/bin/env bash
# modules/mise.sh

############################################
# 内部：激活 mise
############################################
activate_mise() {
    if [[ ! -x "$HOME/.local/bin/mise" ]]; then
        error "mise 可执行文件不存在"
        return 1
    fi

    export PATH="$HOME/.local/bin:$PATH"
    eval "$("$HOME/.local/bin/mise" activate bash)"
}

############################################
# 安装 Mise（必须成功）
############################################
install_mise() {

    if command -v mise &>/dev/null; then
        success "Mise 已安装"
        activate_mise || return 1
        return 0
    fi

    run_task "下载 Mise 安装脚本" \
        "curl -fSL https://mise.run -o /tmp/mise-install.sh" || return 1

    run_task "执行 Mise 安装脚本" \
        "bash /tmp/mise-install.sh" || return 1

    if [[ ! -x "$HOME/.local/bin/mise" ]]; then
        error "Mise 安装失败，未生成可执行文件"
        return 1
    fi

    activate_mise || return 1

    if ! command -v mise &>/dev/null; then
        error "mise 激活失败"
        return 1
    fi

    success "Mise 安装并激活成功"
}

############################################
# 安装 Node
############################################
install_node() {

    run_task "安装 Node.js 16" \
        "mise install node@16" || return 1

    run_task "安装 Node.js 20" \
        "mise install node@20" || return 1

    run_task "设置全局默认 Node.js 20" \
        "mise use -g node@20" || return 1

    activate_mise || return 1

    node -v &>/dev/null || {
        error "Node 安装后不可用"
        return 1
    }

    success "Node.js 16 & 20 安装完成"
}

############################################
# 安装 Java + Maven
############################################
install_java_maven() {

    run_task "安装 Java Temurin 8" \
        "mise install java@temurin-8" || return 1

    run_task "安装 Maven" \
        "mise install maven" || return 1

    run_task "设置默认 Java 8" \
        "mise use -g java@temurin-8" || return 1

    run_task "设置默认 Maven" \
        "mise use -g maven" || return 1

    activate_mise || return 1

    java -version &>/dev/null || {
        error "Java 安装后不可用"
        return 1
    }

    mvn -v &>/dev/null || {
        error "Maven 安装后不可用"
        return 1
    }

    success "Java 8 + Maven 安装完成"
}

############################################
# 安装 Python
############################################
install_python() {

    run_task "安装 Python 3.10" \
        "mise install python@3.10" || warn "Python 3.10 安装失败，继续执行"

    run_task "安装 Python 3.11" \
        "mise install python@3.11" || return 1

    run_task "设置默认 Python 3.11" \
        "mise use -g python@3.11" || return 1

    activate_mise || return 1

    python3 -V &>/dev/null || {
        error "Python 安装后不可用"
        return 1
    }

    success "Python 3.10 & 3.11 安装完成"
}

############################################
# 模块入口
############################################
mise_install() {

    section "Mise 环境一键部署"

    install_mise || return 1
    install_node || return 1
    install_java_maven || return 1
    install_python || return 1

    echo ""
    echo "=================================================="
    success "全部环境安装完成并已激活"
    echo "=================================================="
}

############################################
# 独立执行入口
############################################
if [[ "$0" == "$BASH_SOURCE" ]]; then
    mise_install
fi