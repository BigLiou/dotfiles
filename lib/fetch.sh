#!/usr/bin/env bash
# lib/fetch.sh —— 统一的 GitHub 下载层
#
# 设计目标：
#   1. 直连优先，失败自动回退到镜像（镜像可配置、可增删）
#   2. 对"连上了但零字节"的链路能及时放弃（--speed-limit / git lowSpeed）
#   3. 失败过的网络 10 分钟内不再重复试直连，避免每个文件都白等
#
# 用法：
#   source "{{ .chezmoi.sourceDir }}/lib/fetch.sh"
#   gh_get "owner/repo/releases/download/v1.0/x.tar.gz" "$TMP/x.tar.gz"
#   gh_clone "owner/repo" "$HOME/.local/share/xxx"
#   V=$(gh_latest_tag "owner/repo")     # 返回不带前导 v 的版本号
#
# 可配置环境变量：
#   GH_MIRRORS   空格分隔的镜像前缀（默认 gh-proxy + ghfast）
#   GH_DIRECT    设为 0 时完全跳过直连
#   GH_STATE     状态缓存文件

GH_MIRRORS="${GH_MIRRORS:-https://gh-proxy.com/ https://ghfast.top/}"
GH_STATE="${GH_STATE:-${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/gh-state}"
GH_DIRECT="${GH_DIRECT:-1}"
GH_CONNECT_TIMEOUT="${GH_CONNECT_TIMEOUT:-8}"
GH_MAX_TIME="${GH_MAX_TIME:-300}"
GH_RETRIES="${GH_RETRIES:-3}"

_gh_mark() {
    mkdir -p "$(dirname "$GH_STATE")" 2>/dev/null || true
    printf '%s' "${1:-}" > "$GH_STATE" 2>/dev/null || true
}

# 10 分钟内直连失败过的网络，不再重复尝试
_gh_direct_blocked() {
    [ "$GH_DIRECT" = "0" ] && return 0
    [ "$(cat "$GH_STATE" 2>/dev/null)" = "blocked" ] || return 1
    local mtime age
    mtime=$(stat -c %Y "$GH_STATE" 2>/dev/null || stat -f %m "$GH_STATE" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - mtime ))
    [ "$age" -lt 600 ]
}

_gh_curl() {
    curl -fL \
        --connect-timeout "$GH_CONNECT_TIMEOUT" \
        --max-time "$GH_MAX_TIME" \
        --speed-limit 1024 --speed-time 30 \
        --retry "$GH_RETRIES" --retry-delay 2 --retry-all-errors \
        "$@"
}

# gh_get <github 路径> <输出文件>
#   路径不含 https://github.com/ 前缀，例如
#   "starship/starship/releases/download/v1.0/starship-x86_64-unknown-linux-musl.tar.gz"
gh_get() {
    local path="$1" out="$2" url m
    url="https://github.com/$path"
    mkdir -p "$(dirname "$out")" 2>/dev/null || true

    if ! _gh_direct_blocked; then
        if _gh_curl -o "$out" "$url" 2>/dev/null; then
            _gh_mark direct
            return 0
        fi
        _gh_mark blocked
    fi

    for m in $GH_MIRRORS; do
        if _gh_curl -o "$out" "${m}${url}" 2>/dev/null; then
            return 0
        fi
    done

    echo "❌ 下载失败（直连与镜像均不可用）: $url" >&2
    return 1
}

# gh_clone <owner/repo> <目标目录>
gh_clone() {
    local repo="$1" dir="$2" m
    local opts=(-c http.lowSpeedLimit=1024 -c http.lowSpeedTime=20 --depth 1)

    if ! _gh_direct_blocked; then
        if git clone "${opts[@]}" "https://github.com/$repo" "$dir" 2>/dev/null; then
            _gh_mark direct
            return 0
        fi
        rm -rf "$dir"
        _gh_mark blocked
    fi

    for m in $GH_MIRRORS; do
        if git clone "${opts[@]}" "${m}https://github.com/$repo" "$dir" 2>/dev/null; then
            return 0
        fi
        rm -rf "$dir"
    done

    echo "❌ git clone 失败: $repo" >&2
    return 1
}

# gh_latest_tag <owner/repo> —— 返回去掉前导 v 的 tag（失败时输出空）
gh_latest_tag() {
    local repo="$1" tag
    tag=$(curl -fsSL --connect-timeout 8 --max-time 25 \
            "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    printf '%s' "${tag#v}"
}
