# 方案：点文件管理支持 macOS + Ubuntu 双系统自动识别

> 目标：同一套 dotfiles，在 macOS 和 Ubuntu 24.04+ 上 `chezmoi apply` 自动识别系统并执行对应安装与配置。
> 状态：方案评审稿，未实施。

---

## 1. 核心机制：自动识别

### 1.1 检测方式

优先用 **bash 运行时判定**（保证脚本单独可执行、可 review），chezmoi 模板变量只做辅助：

| 检测项 | bash 方式 | chezmoi 模板方式 |
|---|---|---|
| macOS | `uname -s` == `Darwin` | `{{ .chezmoi.os }}` == `darwin` |
| Ubuntu | `grep '^ID=ubuntu$' /etc/os-release` | `{{ .chezmoi.osRelease.id }}` == `ubuntu` |
| 架构 | `uname -m`（aarch64/arm64/x86_64） | `{{ .chezmoi.arch }}` |

**约定**：每个 `.sh.tmpl` 脚本顶部统一加一段 OS 判定，二选一：

```bash
# 运行时判定（推荐，脚本可脱离 chezmoi 单独执行）
# 注意：脚本带 set -e，grep 失败会触发 errexit，必须用 if 包住（不能写 `grep && IS_UBUNTU=1`）
IS_DARWIN=0; IS_UBUNTU=0
case "$(uname -s)" in
  Darwin) IS_DARWIN=1 ;;
  Linux)  if grep -q '^ID=ubuntu$' /etc/os-release 2>/dev/null; then IS_UBUNTU=1; fi ;;
esac
```

### 1.2 文件级差异化

> 2026-08-12 修正：**chezmoi 不支持 `.darwin`/`.linux` 文件名后缀**（会当成字面目标安装）。
> 做法改为单个模板文件内用 `{{ if eq .chezmoi.os "darwin" }}` / `{{- else -}}` 分支渲染，配合 `{{- -}}` 做空行/换行控制。

```
dot_tmux.conf.tmpl        # 单个模板，darwin → pbcopy/pbpaste，linux → xclip
```

---

## 2. Homebrew 安装（mac 专用分支，带国内镜像源选择）

> 现状：`00-install-packages` 只有 apt 逻辑。mac 分支第一步就是装 Homebrew。
> 关键：**国内直连 GitHub 装 Homebrew 极慢/会失败**，所以必须像 apt 镜像源那样提供选择。

### 2.1 交互设计（00 脚本运行时选择镜像源）

> 2026-08-12 曾尝试改为 chezmoi 配置驱动（`.chezmoidata.toml` + 模板托管 mirror.env），最终**回退**：
> 交互式选择 + 运行时写 mirror.env 更直接；切换交给 `mirror()` 函数（见 dot_zsh_functions）。
> mirror.env 为运行时状态文件，不入 chezmoi 仓库。

```
🍺 请选择 Homebrew 安装源：
  1) 清华大学 TUNA   (推荐，国内直连快)
  2) 中科大 USTC     (备用)
  3) 官方 GitHub     (国外网络或代理环境)
请输入编号 [1-3，默认 1]
```

- 无论 brew 是否已装，选择后立即 `export` 镜像变量，**本次运行就走镜像**（避免“选了 TUNA 却用官方源”）。
- 选 1/2 时写 `~/.config/homebrew/mirror.env`（`.zshrc` 自动加载）；选 3 时删除该文件。
- 平时切换镜像：直接跑 `mirror()` 函数（mac 重写 mirror.env 并当前终端生效 / Ubuntu 重写 ubuntu.sources 并 apt-get update）。

### 2.2 各镜像的技术要点

| 源 | 安装脚本 | 需注入的环境变量 |
|---|---|---|
| **清华 TUNA** | `git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install`，再 `/bin/bash brew-install/install.sh`（绕开 raw.githubusercontent.com） | `HOMEBREW_BREW_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git`<br>`HOMEBREW_CORE_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git`<br>`HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles`<br>`HOMEBREW_API_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api` |
| **中科大 USTC** | `curl -fsSL https://mirrors.ustc.edu.cn/misc/brew-install.sh` | `HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git`<br>`HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles`<br>`HOMEBREW_API_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/api` |
| **官方 GitHub** | `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`（需代理） | 无（用官方默认） |

> **URL 已逐一核对**（2026-08-12，HTTP + git ls-remote 探测）：
> - **USTC 无 homebrew-core git 镜像**（`homebrew-core.git` 探测为 404），且安装脚本正确地址是 `misc/brew-install.sh`（我最初写的 `brew-install/install.sh` 是 404，已修正）。
> - Homebrew 4.x 默认 API 模式，`HOMEBREW_CORE_GIT_REMOTE` 仅在非 API 模式下生效；TUNA 保留它（该镜像存在、探测 200）为兼容，无副作用；USTC 已删掉该变量。

> 通用提速：安装与后续均设 `HOMEBREW_NO_AUTO_UPDATE=1`；Homebrew 4.x 默认 API 模式，`HOMEBREW_API_DOMAIN` 比 `CORE_GIT_REMOTE` 更重要。
> ⚠️ 具体 URL 以各镜像站官方 help 页为准（TUNA `/help/homebrew/`、USTC `/help/brew.git/`），落地实现时需再核对一遍。

### 2.3 环境变量持久化（脚本运行时写 mirror.env，保证装完 brew install 走镜像）

- 00 脚本选 1/2 时写 `~/.config/homebrew/mirror.env`（`.zshrc` 的 `[ -f ] && source` 自动加载），并直接 `export` 让**本次运行**就走镜像；选 3 官方时删除该文件并 `unset`。
- `mirror()` 函数（dot_zsh_functions）切换时同样重写/删除该文件并当前终端生效，与脚本逻辑一致。mirror.env 是**运行时状态文件，不入 chezmoi 仓库**。
- 注意副作用：这是"当前机器"相关配置，同一套 dotfiles 若部署到国外 mac 会变慢。先按"mac = 国内"处理，后续可改用 chezmoi 按机器条件（如 `.chezmoi.hostname`）细化。

### 2.4 Apple Silicon 的 PATH

- 安装脚本自动装到 `/opt/homebrew`（Apple Silicon）或 `/usr/local`（Intel）。
- **Apple Silicon 的 `/opt/homebrew/bin` 默认不在系统 PATH**，需在 `~/.zshrc` **前置**（与 `brew shellenv` 一致，`export PATH="/opt/homebrew/bin:$PATH"`）。现有 zshrc 的 PATH 只有 `$HOME/.local/bin:$HOME/bin`，必须补。

### 2.5 Xcode Command Line Tools

- mac 上编译类工具依赖 Xcode CLT，装 Homebrew 前需确保已装：`xcode-select -p` 检查，无则 `xcode-select --install`（图形弹窗）。
- 有 CLT 后，Ubuntu 上的 `build-essential`/`lib*-dev` 包在 mac **不需要**（mise 的运行时编译依赖自带）。

---

## 3. 逐文件改造清单

### 3.1 无需改动 ✅

| 文件 | 原因 |
|---|---|
| 03-zinit / 04-claude | 无 brew 替代（zinit 无 formula；`claude-code` formula 探测 404），git clone / 官方脚本本身跨平台，mac/Ubuntu 通用 |
| after_00-mise-install | mise 运行时跨平台，mise.toml 的 node/python/java 在 mac 可装 |
| mise.toml / starship.toml / gitconfig / gitignore / claude settings | 纯配置，跨平台 |

### 3.2 需要改造 🔧（mac 策略：**能 brew 全 brew，并入 00 一个大清单；其余安装脚本 mac 上 `exit 0`**）

| 文件 | 现状 | 改造 | 复杂度 |
|---|---|---|---|
| **00-install-packages** | 纯 apt 镜像 + apt 安装 | 顶部 OS 分支：**Darwin → Homebrew 安装（镜像选择，见第 2 节）+ 一个大 `brew install`（基础包 + starship/mise/yazi/lazygit/lazydocker）+ `brew install --cask docker-desktop`**；Linux → 现有 apt 逻辑 | 中（最大头） |
| 01-install-starship | curl 安装器，通用 | mac 已并入 00 的 brew 清单；脚本顶部加 Darwin 守卫 `exit 0` | — |
| 02-install-mise | curl 安装器，通用 | mac 已并入 00 的 brew 清单；顶部加 Darwin 守卫 `exit 0`（brew 装的 mise 在 `/opt/homebrew/bin`，与原有 `~/.local/bin/mise` 检查无关） | — |
| 05-install-yazi | apt 官方源 | mac 已并入 00 的 brew 清单；顶部加 Darwin 守卫 `exit 0`；Linux → 现状 | 小 |
| 06-install-lazygit | 下载 URL 硬编码 `linux_$arch` | mac 已并入 00 的 brew 清单；顶部加 Darwin 守卫 `exit 0`；Linux → 现状 + x86_64→amd64 bug（**已修**） | 小 |
| 07-install-lazydocker | 官方脚本 `install_update_linux.sh` 纯 Linux | mac 已并入 00 的 brew 清单；顶部加 Darwin 守卫 `exit 0`；Linux → 现状 | 小 |
| **08-install-docker** | 纯 Ubuntu apt + systemd | mac 已并入 00 的 `--cask docker-desktop`；顶部加 Darwin 守卫 `exit 0`；Linux → 现有逻辑保留 | 中（分歧最大） |
| after_01-set-default-shell | `chsh -s` | **macOS 无需改动**：Catalina 起系统默认即 `/bin/zsh`，脚本命中 `$SHELL==/bin/zsh` 提前退出。仅当主动想用 Homebrew 新版 zsh 时，才需 `/etc/shells` + chsh（可选，默认不做） | — |
| dot_zsh_aliases | `alias bat='batcat'`、`fd='fdfind'`（Ubuntu 二进制名） | 改为**按命令存在自动选**：`command -v batcat` 有则 batcat，否则 bat/fd——mac 上 `cat`/`fd` 别名才不指向不存在命令 | 小 |
| dot_zsh_functions | `_check_deps`/`tips` 提示写死 apt；`dproxy` 依赖 systemd | apt 提示按 OS 换 brew；`dproxy` 加守卫，mac 上提示"用 Docker Desktop 面板设置代理" | 小 |
| dot_zshrc | PATH 缺 brew；fzf examples 路径是 Ubuntu 的 | PATH **前置** `/opt/homebrew/bin`（与 brew shellenv 一致）；fzf 路径按 brew 位置（`/opt/homebrew/opt/fzf/shell/`）补一条，保留 `[ -f ]` 守卫优雅降级 | 小 |
| dot_tmux.conf | 剪贴板用 `xclip`（X11） | 改单个 `dot_tmux.conf.tmpl`，模板内 `{{ if eq .chezmoi.os "darwin" }}` 分支（darwin → `pbcopy`/`pbpaste`，linux → `xclip`）。**不做文件名后缀拆分**（chezmoi 不支持 `.darwin`/`.linux`） | 小 |

### 3.3 Ubuntu → macOS brew 包清单映射（00 脚本用）

| Ubuntu 包 | macOS brew | 说明 |
|---|---|---|
| curl wget git zip unzip p7zip-full | curl wget git zip unzip p7zip | 同名 |
| zsh tmux fzf ripgrep | tmux fzf ripgrep（zsh 可选） | zsh：mac 系统自带且默认就是 zsh，默认不装；要新版才 `brew install zsh`（需配 after_01 的可选分支） |
| eza zoxide btop duf ncdu | eza zoxide btop duf ncdu | 同名 |
| bat fd | bat fd | 二进制名在 mac 就是 bat/fd（无 batcat/fdfind） |
| build-essential libssl-dev 等 lib*-dev 全家 | — | 不需要，Xcode CLT + mise 自带依赖 |
| tcpdump net-tools lsof xclip | tcpdump lsof | net-tools 无 mac 版；xclip 换 pbcopy |
| 无 | **xcode-select CLT** | 前置，见 2.5 |

> 另有脚本工具（并入 00 的 brew 大清单）：`starship`、`mise`、`yazi`、`lazygit`、`lazydocker`（formula 均验证存在）；Docker Desktop 为 cask：`brew install --cask docker-desktop`。

---

## 4. 需要拍板的决策点

1. **macOS 上 Docker 的装法**（推荐 a）：
   - a) `brew install --cask docker-desktop` = Docker Desktop（**注意：homebrew-cask 的 token 是 `docker-desktop`，不是 `docker`；`brew install docker` 只装 CLI 无引擎**），GUI 里配镜像加速/日志/BuildKit，最省事，与 WSL 引导思路一致；
   - b) colima + `brew install docker`（无 GUI、轻量，但需另配 colima 的 daemon.json）。
2. **mac 上是否对齐装 yazi / lazygit / lazydocker**：装——已并入 00 的 brew 大清单，保持两系统工具一致。
3. **Homebrew 镜像默认值**：默认选清华（推荐），用户可改。

---

## 5. 实施顺序（里程碑）

1. **骨架**：给所有 `.sh.tmpl` 加统一 OS 判定；跑 `chezmoi apply --dry-run` 确认 **Ubuntu 上行为零变化**。
2. **00-install-packages**：加 Darwin 分支（Homebrew 镜像选择 + 安装 + brew 大清单 + `--cask docker-desktop`）。
3. **01/02/05/06/07/08**：各加 Darwin 守卫 `exit 0`（mac 由 00 的 brew 统一安装）。after_01 在 mac 无需处理（默认已 zsh，跳过）。
4. **dotfiles**：aliases / functions / zshrc / tmux 的跨平台处理。
5. **真机验证**：在一台 mac 上 `chezmoi apply` 全流程跑通，再回 Ubuntu 回归。

---

## 6. 风险与注意点

- **无 mac 真机**：大部分 mac 分支无法实测，建议合并前在真机验证一遍。
- **镜像 URL 易变**：落地时以清华/USTC 官方 help 页为准。
- **brew env 持久化的副作用**：写入共享 zshrc 后，国外 mac 也会走国内镜像（变慢）。先接受，后续按机器条件细化。
- **mise.toml 已内置国内镜像**：npm 源（npmmirror）与 pip 源（tuna）写在共享配置里，与 brew env 同类问题、跨国机器会受影响——既有设计，非本次引入。
- **计划/README 文档会被 chezmoi apply 到 home**：仓库根目录的非 `dot_` 文件（如 `README.md`、本方案文件）会被 `chezmoi apply` 复制到 `~/`。建议给 `.chezmoiignore` 加对应条目，或放到不被管理的目录。
- ~~lazygit 架构 bug~~：`x86_64` 未映射 `amd64` 导致 x86 下载 404——**已修复**（sed 增加 `x86_64→amd64`）。
