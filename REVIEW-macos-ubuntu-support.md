# 审查报告：macOS + Ubuntu 双系统支持

> 审查日期：2026-08-12
> 范围：整个 dotfiles 仓库（`.chezmoiscripts/*`、`dot_*` 配置、`mise.toml`、模板文件）
> 方法：逐个文件静态审查 + 本机（Ubuntu）运行验证 + 针对性模拟测试（mac 分支）
> 状态：待修复。A1/A2/A3 为上线 macOS 前必须处理项。

---

## 结论概览

| 级别 | 数量 | 说明 |
|---|---|---|
| 🔴 严重（会跑挂） | 3 | A1 在 mac 上装不上语言运行时；A2 home 目录被污染；A3 新机 Claude 认证失败 |
| 🟡 稳健性 | 5 | B1-B5，工具缺失时报错、备份缺失、写法隐患 |
| 🟢 冗余 | 5 | C1-C5，死别名、重复逻辑、噪音 |
| ⚪ 其他/安全 | 4 | D1-D4 |

---

## 🔴 A. 会在 mac / Ubuntu 真机跑挂的问题

### A1. [macOS] `after_00-mise-install` 找不到 brew 装的 mise → 语言运行时全装不上

`.chezmoiscripts/run_once_after_00-mise-install.sh.tmpl:14`

```bash
export PATH="$HOME/.local/bin:$PATH"
```

只加了 `~/.local/bin`。macOS 上 mise 由 00 脚本 `brew install` 装到 **`/opt/homebrew/bin`**，不在脚本 PATH 里 → `command -v mise` 失败 → 直接「mise 未安装，跳过运行时安装」，**Node/Python/Java 在 mac 上一个都不装**。

触发场景：README 的一行引导 `sh -c "curl ..." && ~/bin/chezmoi init --apply`——非登录 shell，`.zshrc` 未加载，PATH 里没有 `/opt/homebrew/bin`（00 脚本内的 `export PATH` 只对自身进程生效，不传给兄弟脚本）。

> 本机 Ubuntu 实测 node/python/java 都已装上（mise 在 `~/.local/bin`，恰好被覆盖），所以只影响 mac。

**修复**：该脚本 PATH 前追加 `/opt/homebrew/bin`（Intel mac 可顺带 `/usr/local/bin`）。

### A2. [跨平台] `README.md` / `PLAN-*.md` 会被 `chezmoi apply` 到 `~/`（home 目录污染）

仓库根目录**没有 `.chezmoiignore`**，而 `README.md`、`PLAN-macos-ubuntu-support.md` 是普通文件（非 `dot_` 前缀）→ `chezmoi managed` 确认被管理 → 目标即 `~/README.md`、`~/PLAN-macos-ubuntu-support.md`。

**已实锤**：`~/README.md` 存在（2.3k，之前 apply 写入）；PLAN 与本文档下次 apply 也会冒出来。此风险在 PLAN §6 自己就有标注，一直未处理。

**修复**：新增 `.chezmoiignore`，忽略 `README.md`、`PLAN-*.md`、`REVIEW-*.md`（或把文档挪到 `docs/` 目录再 ignore）。

### A3. [macOS / 新机] `.claude/settings.json` 空 token `sk-` 部署后 Claude 认证失败

`dot_claude/settings.json`

```json
"ANTHROPIC_AUTH_TOKEN": "sk-"
```

空占位 token 被 apply 到 `~/.claude/settings.json`。新机器上 Claude Code 认证失败，直到手动填真 token。若为有意设计（新机手动填），建议在 README 说明；否则新机易踩坑。

---

## 🟡 B. 稳健性 / 写法问题

### B1. `.zshrc` 里 starship / mise 的 `eval` 无守卫（zoxide 却有）

`dot_zshrc:85-88`

```zsh
eval "$(starship init zsh)"   # 无 command -v 守卫
eval "$(mise activate zsh)"   # 无 command -v 守卫
```

而 zoxide 有 `command -v` 守卫。工具缺失时（装失败 / 新机首次 shell）每次开终端刷 `starship: command not found`。三个应统一加守卫。

### B2. `after_01-set-default-shell` 的 `zsh -c '...zinit...'` 在 `set -e` 下无守卫

`.chezmoiscripts/run_once_after_01-set-default-shell.sh.tmpl:31-34`

```bash
zsh -c 'source "$HOME/.local/share/zinit/zinit.zsh" && ...'
```

若 03 的 zinit clone 因网络失败，`zinit.zsh` 不存在 → `zsh -c` 返回非零 → `set -e` 让脚本在 chsh 成功后中断，「exec zsh」提示不打印。应改为 `if zsh -c '...'; then ... fi`。

### B3. [macOS 隐患] `findport` 用了 `grep -oP`

`dot_zsh_functions:279`

```bash
pids=$(echo "$pid_info" | grep -oP 'pid=\K\d+' | sort -u)
```

macOS 的 BSD grep **不支持 `-P`**。当前 mac 无 `ss`、走 lsof 分支，故为潜伏问题，但 `findport` 会部署到 mac，一旦将来命中即挂。改可移植写法：

```bash
grep -oE 'pid=[0-9]+' | cut -d= -f2
```

### B4. [Ubuntu] 00 脚本写 apt 源无备份，与 `mirror()` 不一致

00 脚本覆盖 `/etc/apt/sources.list.d/ubuntu.sources` 没有 `.bak` 备份，而 `mirror()` 函数已带备份。换源失败无法回滚。建议 00 也加 `cp ... .bak`。

### B5. after_00 的 `mise install` 依赖 cwd 恰好是 `$HOME`

`mise install` 不带参数能发现 `~/mise.toml`（本机验证有效），但依赖 chezmoi 运行时 cwd 的隐性假设。稳妥做法是脚本内显式：

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/mise.toml"
```

---

## 🟢 C. 冗余代码

| # | 位置 | 问题 |
|---|---|---|
| C1 | `dot_zsh_aliases:32` | `alias fd='fd'` 死别名——mac 上 `fd` 本身即命令，别名原地指自己，完全多余（实测 zsh 不会无限递归，纯噪音）。elif 整段可删 |
| C2 | `dot_zsh_aliases:42-56` | `alias ls="eza $eza_base"`（双引号/定义时展开）与 `alias tree='eza $eza_tree_common -L 2'`（单引号/使用时展开）风格不一致，`ls` 的数组烘死在定义时，建议统一单引号 |
| C3 | `dot_zshrc:44-46` | zinit clone 与 `03-install-zinit` 脚本重复（zshrc 属失败兜底，可接受，但为重复逻辑） |
| C4 | 00 脚本 Ubuntu 循环 | `cmd="${pkg%% *}"` 后又 `check_cmd="${cmd%% *}"` 等值重复；注释「如 rg ripgrep」与实际数组不符 |
| C5 | 11 个脚本 | 开头 10 行日志样板（LOG_DIR/tee）全重复。run_once 脚本需独立可执行，较难共享，可接受，仅提示 |

---

## ⚪ D. 其他 / 安全

- **`credential.helper = store`**（`dot_gitconfig`）明文存 Git 密码，个人选择，仅提示。
- **`.claude/settings.json` 含 API 配置**已提交，token 目前为空占位，建议保持不入库真 token。
- **08 脚本 `features.buildkit`** 新版 Docker 已默认开启，配置冗余但无害。
- **`dot_gitconfig` 缩进混用 tab/spaces**，git 可解析，仅风格问题。

---

## 修复建议优先级

1. **必改（macOS 上线前）**：A1、A2、A3
2. **建议同批修**：B1、B2、B3、B4
3. **顺手清理**：C1、C2、C4（冗余）
4. **可选**：B5、C3、C5、D 项

> 注意：本文档置于仓库根目录，与 README/PLAN 一样会被 `chezmoi apply` 到 `~/`。**在修复 A2（新增 `.chezmoiignore`）之前，下次 apply 会把它也写到 home 目录。**

---

## 第二轮复审（2026-08-12 晚）

> 方法升级：除了静态审查，本轮加入**运行时实证**（真机加载 `.zshrc`、逐个 eval 定位、边界输入注入、模板渲染校验）。
> 结论：第一轮 A1-A3 / B1-B4 全部确认成立，另新增 8 项。

### 新增问题

#### N1. [macOS · 必改] xcode-select 等待循环可能无限挂起

`.chezmoiscripts/run_once_before_00-install-packages.sh.tmpl:31-32`

```bash
until xcode-select -p &>/dev/null 2>&1; do
    sleep 5
done
```

**没有超时、没有退出途径**。若 GUI 安装弹窗未出现（比如被忽略、无网络、无桌面），`chezmoi apply` 会在此**永久卡住**。建议改成最多等待 N 次后提示用户手动 `xcode-select --install` 并跳过（或明确报错退出）。

#### N2. [跨平台 · 必改] `.gitignore_global` 被覆盖后 `.claude/settings.local.json` 的保护会消失

现状（已实证）：

- `~/.gitignore_global` 里有用户**手工添加**的 `**/.claude/settings.local.json` 行——这正是 `.claude/settings.local.json` 不被 git 跟踪、进而不被 chezmoi 管理的**唯一原因**。
- 仓库的 `dot_gitignore_global` **没有**这行 → 下次 `chezmoi apply` 会覆盖全局 gitignore、**删掉保护线** → `.claude/settings.local.json` 立刻变为未忽略 → 出现在 `git status`，一旦误提交就变成受管文件、被部署到所有机器。

修 A2 时必须一并处理：把该行并入 `dot_gitignore_global`，**且/或**在 `.chezmoiignore` 里排除 `.claude/settings.local.json`（推荐两者都做，双保险）。

#### N3. [macOS · 低] 00 脚本非数字输入会打日志噪音

`.chezmoiscripts/run_once_before_00-install-packages.sh.tmpl:93`

输入 `abc` 时 `[ "$BREW_MIRROR" -eq 1 ]` 打印两行 `[: abc: integer expression expected`（已实测**不崩**，落到官方源分支，但日志很脏）。与 `mirror()` 的 `^[1-3]$` 校验不一致，建议先校验再比较。

#### N4. [跨平台 · 低] 非交互 context 下 source `.zshrc` 会打 `zle` 警告

`zsh -i -c` 实测：`.zshrc` 加载打印 2 次 `(eval):1: can't change option: zle`，来源是 **starship**（`zle -N` ×11）和 **zoxide**（`zle -N` ×1）的 init 输出。真实交互终端 ZLE 已激活、无此问题；但任何脚本 `source ~/.zshrc` 都会看到噪音。如介意可对这两个 eval 加 `[[ -o interactive ]]` 守卫。

#### N5. [macOS · 低] `after_01` 在非登录 shell 下 `$SHELL` 可能未设

`.chezmoiscripts/run_once_after_01-set-default-shell.sh.tmpl:19`

`sh -c` 引导的 bootstrap 是非登录 shell，`$SHELL` 可能为空 → 不满足 `$SHELL == zsh` → 走 `chsh` 分支，macOS 上可能弹出密码交互导致卡住。可先判空：`if [[ -n "$SHELL" && "$SHELL" == "$ZSH_PATH" ]]`。

#### N6. [跨平台 · 极低] `.zshrc` 里 `brew --prefix fzf` 在无 brew 时退化

`dot_zshrc:71`：Ubuntu 无 brew → `FZF_SHELL="/shell"` → `[ -f ]` 为假、无害，属噪音。可加 `command -v brew` 守卫。

#### N7. [Ubuntu · 中低] 08-docker 拉取 gpg 失败无回退

`.chezmoiscripts/run_once_before_08-install-docker.sh.tmpl:112`

`curl --connect-timeout 5 --max-time 30` 拉 keyring 失败时 `set -e` 直接中止整个安装，没有自动回退官方源或重试提示。建议失败时给出明确提示 + 可选官方源回退。

#### N8. [Ubuntu · 低] 06-lazygit 的 GitHub API 无鉴权可能限流

`.chezmoiscripts/run_once_before_06-install-lazygit.sh.tmpl:24`

未带 token 调 `api.github.com`（60 次/小时配额），命中限流时 `tag_name` 解析为空 → 下载 URL 404 → 中止。建议解析失败时明确报错并提示（或在 curl 加 `--max-time`）。

### 本轮实证记录

| 检查项 | 结果 |
|---|---|
| 11 个脚本 `bash -n` | ✅ 全部通过 |
| `dot_zshrc` / `dot_zsh_aliases` / `dot_zsh_functions` `zsh -n` | ✅ 全部通过 |
| 脚本中残留 `{{ }}` 模板变量 | ✅ 无 |
| `dot_tmux.conf.tmpl` Linux 渲染 | ✅ 正常，无 `{{ }}` 残留 |
| `.zshrc` 本机真机加载 | ⚠️ 仅非交互 context 有 `zle` 警告（N4） |
| 00 脚本非数字 `BREW_MIRROR` | ✅ 不崩，仅日志噪音（N3） |
| eza 别名行为 | ✅ 确认 C2（ls 定义时烘死数组，tree 使用时展开） |

### 修复优先级（合并两轮）

1. **必改**：A1、A2（含 N2 连锁）、A3、N1
2. **建议**：B1、B2、B3、B4、N7
3. **顺手**：C1、C2、C4、N3、N5、N8
4. **可选**：B5、C3、C5、D 项、N4、N6
