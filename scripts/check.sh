#!/usr/bin/env bash
# 提交前自检：所有 shell 脚本语法检查（有 shellcheck 则一并跑）
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
while IFS= read -r f; do
    bash -n "$f" 2>/dev/null || { echo "❌ 语法错误: $f"; fail=1; }
done < <(find . -path ./.git -prune -o \( -name "*.sh" -o -name "*.tmpl" \) -print)

if command -v shellcheck >/dev/null 2>&1; then
    echo "🔍 shellcheck..."
    # 只看 error 级别，避免历史遗留的 warning 噪声
    shellcheck -S error $(find . -path ./.git -prune -o -name "*.sh" -print) || fail=1
fi

[ "$fail" -eq 0 ] && echo "✅ 检查通过" || echo "❌ 检查失败"
exit "$fail"
