# =====================
# 基础环境
# =====================

export EDITOR=vim
export PATH="$HOME/.local/bin:$PATH"

# =====================
# 自定义配置路径
# =====================

# Git 全局配置
export GIT_CONFIG_GLOBAL="$HOME/.config/git/.gitconfig"

# Starship 配置
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Zsh 历史记录
export HISTFILE="$HOME/.config/zsh/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

# =====================
# 自动补全
# =====================

autoload -Uz compinit
compinit

# =====================
# Zinit 插件管理器
# =====================

ZINIT_HOME="$HOME/.local/share/zinit"

if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
    git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# =====================
# 插件
# =====================

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting

# =====================
# 工具
# =====================

# fzf
if command -v fzf >/dev/null 2>&1; then
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
        source /usr/share/doc/fzf/examples/key-bindings.zsh

    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
        source /usr/share/doc/fzf/examples/completion.zsh
fi

# starship
eval "$(starship init zsh)"

# mise
eval "$(mise activate zsh)"