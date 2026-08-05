#!/usr/bin/env bash
# =============================================================================
# install.sh — 容器内手动安装开发环境 (对应 docker/Dockerfile)
#
# 用途: 在已启动的 ubuntu:26.04 (或其他 Debian 系) 容器中, 手动安装
#       docker/Dockerfile 内的全部软件与配置, 适用于:
#         - 不想重新 build 镜像, 直接在基础镜像上临时搭建环境
#         - 镜像已构建但配置变更, 想增量更新而不重建
#         - 在远程容器/集群节点上初始化工作环境
#
# 与 docker/Dockerfile 的对应关系:
#   RUN  → 普通命令 (apt-get / curl / npm / uv ...)
#   ENV  → 写入 /etc/profile.d/dev-env.sh (login shell) + /etc/environment (PAM/非 shell)
#   COPY → cp 自本仓库目录 (脚本自动按自身位置定位仓库根, 无需挂载)
#
# 前置条件:
#   1. 以 root 运行 (apt-get 需要)
#   2. 本仓库已存在于容器内 (git clone / 镜像内置 / 已 checkout 均可),
#      在仓库根目录 (config-files/) 内执行本脚本即可, 容器无需 -v 挂载
#
# 用法 (在容器内、仓库根目录下执行):
#   bash docker/install.sh                       # 默认全装
#   bash docker/install.sh --python 3.12         # 指定 Python 版本
#   bash docker/install.sh --node 20             # 指定 Node.js 版本
#   PYTHON_VERSION=3.12 bash docker/install.sh   # 环境变量方式
#
# 幂等: 可重复执行, 已完成的步骤会跳过, 配置文件会被覆盖为仓库最新版
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# 可配置参数 (环境变量或命令行参数覆盖)
# ---------------------------------------------------------------------------
# 仓库根 = 脚本所在目录的上一级 (脚本位于 <repo>/docker/install.sh)
# 通过 BASH_SOURCE 定位, 无需挂载、无需 CWD 假设, 在仓库内任意位置执行均可
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_VERSION="${PYTHON_VERSION:-3.10}"        # uv 安装的 Python 版本
NODEJS_VERSION="${NODEJS_VERSION:-22}"           # NodeSource 的 Node.js 大版本
UV_LINK_MODE="${UV_LINK_MODE:-copy}"             # uv 包链接模式 (容器兼容性最优)

# ---------------------------------------------------------------------------
# 日志
# ---------------------------------------------------------------------------
log()  { printf '\033[1;32m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# 命令行参数
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --python)      PYTHON_VERSION="$2"; shift 2 ;;
        --node)        NODEJS_VERSION="$2"; shift 2 ;;
        --link-mode)   UV_LINK_MODE="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0 ;;
        *) die "未知参数: $1 (使用 -h 查看帮助)" ;;
    esac
done

# ---------------------------------------------------------------------------
# 前置校验
# ---------------------------------------------------------------------------
[[ $EUID -eq 0 ]] || die "必须以 root 运行 (apt-get 需要), 请加 sudo 或用 root 进入容器"

# 确认脚本位于本仓库内 (docker/install.sh), 上一级应为仓库根 (含 docker/Dockerfile)
if [[ ! -f "$REPO_ROOT/docker/Dockerfile" ]]; then
    err "未在仓库根定位到 docker/Dockerfile (REPO_ROOT=$REPO_ROOT)"
    die "请在仓库根目录 (config-files/) 内执行: bash docker/install.sh"
fi

# ---------------------------------------------------------------------------
# 工具函数: 持久化环境变量 (对应 Dockerfile 的 ENV 指令)
#
# Dockerfile 的 ENV 在镜像构建期固化, 对所有进程生效; 脚本里的 export 仅对当前
# shell 生效。为模拟 ENV 的持久性, 这里写入两处:
#   1. /etc/profile.d/dev-env.sh  → login shell (bash -l) 启动时 source
#   2. /etc/environment           → PAM 会话 (SSH/su/cron 等非 shell 进程) 读取
# ---------------------------------------------------------------------------
PROFILE_ENV="/etc/profile.d/dev-env.sh"
ETC_ENV="/etc/environment"
mkdir -p /etc/profile.d
[[ -f "$PROFILE_ENV" ]] || : > "$PROFILE_ENV"
[[ -f "$ETC_ENV" ]] || : > "$ETC_ENV"

persist_env() {
    local key="$1" val="$2"
    export "$key=$val"
    # profile.d: export KEY="VALUE" (支持 $VAR 展开, 用于 PATH)
    if grep -q "^export ${key}=" "$PROFILE_ENV"; then
        sed -i "s|^export ${key}=.*|export ${key}=\"${val}\"|" "$PROFILE_ENV"
    else
        printf 'export %s="%s"\n' "$key" "$val" >> "$PROFILE_ENV"
    fi
    # /etc/environment: KEY=VALUE (无 export, 不展开变量) — 仅对非 PATH 类静态值
    if [[ "$key" != "PATH" ]]; then
        if grep -q "^${key}=" "$ETC_ENV"; then
            sed -i "s|^${key}=.*|${key}=${val}|" "$ETC_ENV"
        else
            printf '%s=%s\n' "$key" "$val" >> "$ETC_ENV"
        fi
    fi
}

# ---------------------------------------------------------------------------
# apt 包安装 (幂等): 按 dpkg 状态逐包判断, 仅装缺失的包
#   - 避免 "vim 已存在则跳过整块" 导致 locales 等被漏装 (locale-gen 找不到)
#   - 仅在有缺失包时才 apt-get update, 重跑时省时
# ---------------------------------------------------------------------------
apt_install_if_missing() {
    local missing=()
    for pkg in "$@"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            :                           # 已装
        else
            missing+=("$pkg")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "      安装缺失包: ${missing[*]}"
        apt-get update
        apt-get install -y --no-install-recommends "${missing[@]}"
        rm -rf /var/lib/apt/lists/*
    else
        log "      全部已装, 跳过: $*"
    fi
}

# ---------------------------------------------------------------------------
# CPU 架构检测 (决定 uv 下载的二进制包, 参考 docker/tools 的 detect_arch)
# ---------------------------------------------------------------------------
arch="$(uname -m)"
case "$arch" in
    x86_64|amd64) UV_TARBALL="uv-x86_64-unknown-linux-gnu.tar.gz" ;;
    aarch64|arm64) UV_TARBALL="uv-aarch64-unknown-linux-gnu.tar.gz" ;;
    *) die "不支持的 CPU 架构: $arch (仅支持 x86_64 / aarch64)" ;;
esac

log "开始安装开发环境 (Python $PYTHON_VERSION, Node.js $NODEJS_VERSION, uv $arch)"
log "仓库路径: $REPO_ROOT"

# =============================================================================
# 1. System packages (对应 Dockerfile Section 1)
#    按 dpkg 状态逐包判断, 避免 "vim 已存在 → 跳过整块 → locales 漏装" 的问题
# =============================================================================
log "[1/8] 安装系统包 (apt: vim git curl wget ca-certificates locales)"
apt_install_if_missing vim git curl wget ca-certificates locales

# =============================================================================
# 2. Locale (对应 Dockerfile Section 2)
#    提前到 Node.js 之前: locale 生成后, 后续 apt 操作不再触发 perl locale 警告
#    vim 配置要求 encoding=utf-8, langmenu=zh_CN.UTF-8, 故需生成对应 locale
# =============================================================================
log "[2/8] 生成 Locale (en_US.UTF-8, zh_CN.UTF-8)"
locale-gen en_US.UTF-8 zh_CN.UTF-8
persist_env LANG en_US.UTF-8
persist_env LC_ALL en_US.UTF-8
# 立即生效, 避免 nodejs 安装时 perl 报 locale 警告
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# Node.js (对应 Dockerfile "Node.js via NodeSource", Section 2 与 3 之间)
#    通过 NodeSource 安装 LTS, 不依赖系统包版本, 含 npm
# ---------------------------------------------------------------------------
log "[*]   安装 Node.js v${NODEJS_VERSION} (NodeSource)"
if ! command -v node >/dev/null 2>&1; then
    curl -fsSL "https://deb.nodesource.com/setup_${NODEJS_VERSION}.x" | bash -
    apt-get install -y nodejs
    rm -rf /var/lib/apt/lists/*
else
    log "      node 已存在 ($(node --version)), 跳过"
fi

# =============================================================================
# 3. uv (对应 Dockerfile Section 3)
#    安装到 /usr/local/uv/bin (系统级, 所有用户可见)
#    环境变量控制 uv 的安装目录与链接模式
# =============================================================================
log "[3/8] 安装 uv 到 /usr/local/uv/bin"
if ! command -v uv >/dev/null 2>&1; then
    mkdir -p /usr/local/uv/bin
    curl -LsSf "https://github.com/astral-sh/uv/releases/latest/download/${UV_TARBALL}" \
        | tar xz -C /usr/local/uv/bin --strip-components=1
else
    log "      uv 已存在 ($(uv version 2>/dev/null || echo installed)), 跳过"
fi
# PATH 写 profile.d (用 $PATH 展开, 不写 /etc.environment 以免覆盖系统 PATH)
persist_env PATH "/usr/local/uv/bin:\${PATH}"
# 立即生效供后续命令使用
export PATH="/usr/local/uv/bin:${PATH}"

persist_env UV_PYTHON_INSTALL_DIR /usr/local/uv/python
persist_env UV_PYTHON_BIN_DIR     /usr/local/bin
persist_env UV_TOOL_DIR           /usr/local/uv/tools
persist_env UV_TOOL_BIN_DIR       /usr/local/bin
persist_env UV_LINK_MODE           "$UV_LINK_MODE"

# =============================================================================
# 4. Directory structure (对应 Dockerfile Section 4)
# =============================================================================
log "[4/8] 创建目录结构 (~/.config/*, ~/.hermes/skills)"
mkdir -p \
    /root/.config/opencode \
    /root/.config/pip \
    /root/.config/uv \
    /root/.hermes/skills

# =============================================================================
# 5. Copy config files (对应 Dockerfile Section 5)
#    从挂载的仓库目录复制各工具配置到对应路径
# =============================================================================
log "[5/8] 复制配置文件 (vim/git/pip/npm/uv/opencode/hermes)"
copy() {
    local src="$1" dst="$2"
    if [[ -f "$src" ]]; then
        cp -f "$src" "$dst"
    else
        warn "缺失源文件: $src (跳过)"
    fi
}
copy_dir() {
    local src="$1" dst="$2"
    if [[ -d "$src" ]]; then
        cp -rf "$src" "$dst"
    else
        warn "缺失源目录: $src (跳过)"
    fi
}

# Vim / Git / Pip / npm / uv
copy    "$REPO_ROOT/vim/.vimrc"                   /root/.vimrc
copy    "$REPO_ROOT/git/.gitconfig"              /root/.gitconfig
copy    "$REPO_ROOT/pip/pip.conf"                /root/.config/pip/pip.conf
copy    "$REPO_ROOT/npm/.npmrc"                  /root/.npmrc
copy    "$REPO_ROOT/uv/uv.toml"                  /root/.config/uv/uv.toml

# OpenCode (AI 编程助手配置)
copy    "$REPO_ROOT/opencode/opencode.jsonc"      /root/.config/opencode/opencode.jsonc
copy    "$REPO_ROOT/opencode/oh-my-openagent.json" /root/.config/opencode/oh-my-openagent.json
copy    "$REPO_ROOT/opencode/AGENTS.md"          /root/.config/opencode/AGENTS.md
copy    "$REPO_ROOT/opencode/commands.md"        /root/.config/opencode/commands.md

# Hermes (Agent 配置 + 技能库)
copy    "$REPO_ROOT/hermes/config.yaml"          /root/.hermes/config.yaml
copy    "$REPO_ROOT/hermes/.env"                 /root/.hermes/.env
copy_dir "$REPO_ROOT/hermes/skills/"            /root/.hermes/skills/

# ---------------------------------------------------------------------------
# Python via uv (对应 Dockerfile RUN uv python install 3.10)
#    必须在 COPY uv/uv.toml 之后执行, 使 python-install-mirror 镜像生效
# ---------------------------------------------------------------------------
log "[*]   安装 Python ${PYTHON_VERSION} (uv python install)"
if ! uv python find "$PYTHON_VERSION" >/dev/null 2>&1; then
    uv python install "$PYTHON_VERSION"
else
    log "      Python ${PYTHON_VERSION} 已安装, 跳过"
fi

# =============================================================================
# 6. OpenCode (对应 Dockerfile Section 6, 依赖 Node.js)
#    API Key 在 opencode/opencode.jsonc 中为占位符, 使用前请替换
# =============================================================================
log "[6/8] 安装 OpenCode (npm install -g opencode-ai@latest)"
if command -v opencode >/dev/null 2>&1; then
    log "      opencode 已存在, 跳过 (如需升级: npm i -g opencode-ai@latest)"
else
    npm install -g opencode-ai@latest
fi

# =============================================================================
# 7. Hermes Agent (对应 Dockerfile Section 7, 依赖 Python/uv)
#    API Key 在 hermes/.env 中为占位符, 使用前请替换
# =============================================================================
log "[7/8] 安装 Hermes Agent (uv tool install hermes-agent)"
if uv tool list 2>/dev/null | grep -q "hermes-agent"; then
    log "      hermes-agent 已安装, 跳过 (如需升级: uv tool upgrade hermes-agent)"
else
    uv tool install hermes-agent
fi

# =============================================================================
# 8. Environment & WORKDIR (对应 Dockerfile Section 8)
# =============================================================================
log "[8/8] 配置环境变量与工作目录"
persist_env EDITOR vim
persist_env VISUAL vim
persist_env PYTHONUNBUFFERED 1

# WORKDIR /workspace (脚本无法持久 cd, 写入 .bashrc 让交互 shell 自动进入)
mkdir -p /workspace
if ! grep -q "cd /workspace" /root/.bashrc 2>/dev/null; then
    printf '\n# 进入默认工作目录\ncd /workspace 2>/dev/null\n' >> /root/.bashrc
fi

# =============================================================================
# 完成
# =============================================================================
echo
log "安装完成 ✅"
echo "  Python:      $(uv python find "$PYTHON_VERSION" 2>/dev/null || echo "$PYTHON_VERSION (uv 管理)")"
echo "  Node.js:     $(node --version 2>/dev/null || echo 未安装)"
echo "  uv:          $(uv version 2>/dev/null || echo 未安装)"
echo "  opencode:    $(opencode --version 2>/dev/null || echo 未安装)"
echo "  hermes:      $(uv tool list 2>/dev/null | grep -o 'hermes-agent.*' || echo 未安装)"
echo
warn "环境变量已写入 $PROFILE_ENV 和 $ETC_ENV"
warn "请重新登录 shell 或执行 'source $PROFILE_ENV' 使环境变量生效"
warn "API Key 占位符 (opencode.jsonc / hermes/.env) 使用前请替换为真实密钥"
