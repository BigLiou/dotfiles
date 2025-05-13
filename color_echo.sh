# 彩色输出脚本

# 成功类消息
success_echo() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

# 提示类消息
info_echo() {
    echo -e "\033[1;34m💡 $1\033[0m"
}

# 错误类消息
error_echo() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

# 警告类消息
warn_echo() {
    echo -e "\033[1;33m⚠️ $1\033[0m"
}

# 完成类消息
complete_echo() {
    echo -e "\033[1;35m🎉 $1\033[0m"
}

# 常规信息类消息
generic_echo() {
    echo -e "\033[1;37m$1\033[0m"
}
