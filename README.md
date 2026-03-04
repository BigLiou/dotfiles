Ubuntu Development Environment (Dotfiles)
一份模块化、可扩展、一键部署的 Ubuntu 开发环境自动化配置脚本，基于 GNU Stow 统一管理配置文件，支持多环境工具与双 Shell 兼容。
核心目标
一键全自动安装开发环境基础组件
自动初始化 NVM/SDKMAN/Conda 环境工具
一键安装并配置 Zsh + Starship 美化终端
GNU Stow 统一管理所有配置文件，无冗余
Bash/Zsh 共用环境配置，兼容双 Shell
安装完成后当前终端立即生效，无需重启
目录结构
plaintext
.
├── README.md        # 项目说明文档
├── install.sh       # 主执行脚本
├── lib              # 公共函数库
│   ├── logging.sh   # 日志输出工具
│   └── utils.sh     # 通用工具函数
├── modules          # 功能模块化脚本
│   ├── base.sh      # 基础依赖安装
│   ├── starship.sh  # Starship 终端美化
│   └── stow_config.sh # 配置文件软链接管理
└── stow             # 所有配置文件源文件
    ├── bash         # Bash 配置
    ├── git          # Git 配置
    ├── shell        # 通用环境变量配置
    │   └── env.sh
    ├── starship     # Starship 主题配置
    └── zsh          # Zsh 配置
架构说明
1. install.sh（主入口）
项目核心调度脚本，承担全部核心流程：
按顺序调度所有功能模块执行
自动安装系统依赖与开发工具
调用 Stow 生成配置文件软链接
切换系统默认 Shell 为 Zsh
加载环境并立即生效
2. lib/（公共函数库）
封装通用能力，所有模块共用：
logging.sh：统一格式化日志输出
utils.sh：系统检测、文件操作等工具函数
3. modules/（功能模块层）
单一职责、可自由插拔扩展，默认模块：
base.sh：安装 curl/git/build-essential 等基础组件
starship.sh：安装并配置 Starship 终端提示符
stow_config.sh：执行 GNU Stow 配置映射
可扩展模块（按需添加）：
plaintext
modules/
├── nvm.sh       # Node 版本管理
├── sdkman.sh    # Java 生态版本管理
├── conda.sh     # Python 虚拟环境
├── zsh.sh       # Zsh 插件安装
└── docker.sh    # Docker 环境
4. stow/（配置文件仓库）
所有配置唯一存放地，通过 Stow 软链接映射到 $HOME 目录：
plaintext
stow/bash/.bashrc
stow/zsh/.zshrc
stow/git/.gitconfig
stow/starship/.config/starship.toml
stow/shell/.shell_env  # 通用环境配置
执行以下命令即可自动生成软链接：
bash
运行
stow bash
stow zsh
stow git
stow starship
stow shell
环境加载模型（双层分离设计）
① 环境层（与 Shell 无关）
文件：~/.shell_env（由 stow/shell/.shell_env 管理）
作用：
NVM/SDKMAN/Conda 初始化
系统 PATH 扩展
通用命令别名
所有 Shell 共享的环境配置
② Shell 层（与 Shell 相关）
文件：~/.bashrc / ~/.zshrc
作用：
终端提示符样式
Shell 专属插件 / 特性
Starship 初始化
统一引用通用环境：source ~/.shell_env
执行流程
一键启动
bash
运行
bash install.sh
自动执行步骤
安装系统基础依赖
安装开发工具与终端美化组件
执行 Stow 配置文件映射
设置 Zsh 为系统默认 Shell
加载全部环境变量
自动切换至 Zsh，当前终端立即生效
设计原则
安装逻辑与配置逻辑完全分离
所有配置文件仅维护一份，无冗余
GNU Stow 统一管理软链接，易于维护 / 卸载
通用环境与 Shell 专属配置分层解耦
模块化设计，支持自由增删功能
卸载方法
1. 移除配置软链接（推荐）
bash
运行
stow -D bash
stow -D zsh
stow -D git
stow -D starship
stow -D shell
2. 软件卸载
工具可手动删除，或自行编写 uninstall.sh 实现自动化卸载
适用场景
Ubuntu 服务器 / 开发机初始化
个人本地开发环境标准化配置
团队统一开发环境管理
多台机器快速重建一致的开发环境
未来扩展建议
新增 NVM/SDKMAN/Conda 专用安装模块
新增 Docker/Node/Java 开发环境模块
兼容 macOS 系统
增加 CI 自动化验证脚本，保证安装稳定性