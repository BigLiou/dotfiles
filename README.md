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

```bash
# 1. 安装 chezmoi
sh -c "$(curl -fsLS https://get.chezmoi.io)"

# 2. 应用配置（会自动执行安装脚本）
chezmoi init --apply BigLiou/dotfiles
```

## 日常使用

```bash
chezmoi add ~/.zshrc              # 添加新配置到仓库
chezmoi add ~/.config/starship.toml

chezmoi edit ~/.zshrc             # 编辑配置（自动修改源文件）

chezmoi diff                      # 查看源文件与目标文件的差异

chezmoi apply                     # 应用所有配置（也触发首次安装脚本）

chezmoi update                    # 拉取远程最新配置并 apply

chezmoi status                    # 查看待应用的变更

chezmoi cd                        # 进入 chezmoi 仓库目录

chezmoi git add .                 # 手动 git 操作
chezmoi git commit -m "xxx"
chezmoi git push

chezmoi state delete --script <script名>  # 清除 run_once 记录，重跑安装脚本
```
