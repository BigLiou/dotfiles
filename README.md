# BigLiou Dotfiles

基于 [chezmoi](https://www.chezmoi.io/) 管理的跨设备 dotfiles，开箱即用。

## 能做什么

`chezmoi apply` 一次，自动完成：

- 配置 `.gitconfig`、`.zshrc`、`mise.toml`、`starship.toml`
- 切换阿里云镜像源（自动识别 Ubuntu 22.04/24.04）
- 安装系统包（curl, git, zsh, tmux, fzf, ripgrep 等）
- 安装 starship、mise、zinit（仅首次自动装好）
- 部署语言运行时（Node.js, Python, Java, Maven）
- 设置 zsh 为默认 shell 并立即切换

## 配置内容

| 文件 | 说明 |
|---|---|
| `.gitconfig` | Git 用户、编辑器、换行符、安全目录 |
| `.zshrc` | zinit 插件管理器 + zsh-autosuggestions / zsh-completions / zsh-syntax-highlighting + fzf + starship prompt + mise 集成 + proxy/dproxy 代理函数 |
| `mise.toml` | 语言运行时版本管理（node, python, java, maven） |
| `starship.toml` | Starship prompt 配置 |

## 新机器初始化

### 方式一：分步执行

```bash
# 1. 安装 chezmoi
sh -c "$(curl -fsLS https://get.chezmoi.io)"

# 2. 应用配置（会自动执行安装脚本）
~/bin/chezmoi init --apply BigLiou/dotfiles
```

### 方式二：一行命令

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" && ~/bin/chezmoi init --apply BigLiou/dotfiles
```

## 日常使用

所有 chezmoi 命令都可通过 `cz` 前缀缩写使用：

| 缩写 | 完整命令 |
|---|---|
| `cza` | `chezmoi add` |
| `czap` | `chezmoi apply` |
| `czd` | `chezmoi diff` |
| `cze` | `chezmoi edit` |
| `czs` | `chezmoi status` |
| `czu` | `chezmoi update` |
| `czcd` | `chezmoi cd` |
| `czg` | `chezmoi git` |

```bash
cza ~/.zshrc                     # chezmoi add
cza ~/.config/starship.toml

cze ~/.zshrc                     # chezmoi edit（自动修改源文件）

czd                              # chezmoi diff

czap                             # chezmoi apply（也触发首次安装脚本）

czu                              # chezmoi update（拉取远程并 apply）

czs                              # chezmoi status

czcd                             # chezmoi cd（进入仓库目录）

czg add .                        # chezmoi git 操作
czg commit -m "xxx"
czg push

chezmoi state delete --script <脚本名>  # 清除 run_once 记录，重跑安装脚本
```
