# =============================================================================
# Dev environment with personal dotfiles & configs
# Build: docker build -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile .
# Run:   docker run -it --rm ubuntu26.04-custom:v0.1
# =============================================================================
FROM ubuntu:26.04

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    vim \
    git \
    curl \
    wget \
    ca-certificates \
    # Locale support (for vim CJK settings)
    locales \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Node.js (via NodeSource, includes npm)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Locale (required by vim config: encoding=utf-8, langmenu=zh_CN.UTF-8)
# ---------------------------------------------------------------------------
RUN locale-gen en_US.UTF-8 zh_CN.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# 3. uv (per uv/commands.md §1 安装 + §2 环境变量)
# ---------------------------------------------------------------------------
# Install uv binary to /usr/local/uv/bin (system-wide, all users)
COPY pkgs/uv-x86_64-unknown-linux-gnu.tar.gz /tmp/uv.tar.gz
RUN mkdir -p /usr/local/uv/bin && \
    tar xz -f /tmp/uv.tar.gz -C /usr/local/uv/bin --strip-components=1 && \
    rm -f /tmp/uv.tar.gz
ENV PATH="/usr/local/uv/bin:${PATH}"

# uv environment variables (controls install directories & link mode)
ENV UV_PYTHON_INSTALL_DIR="/usr/local/uv/python" \
    UV_PYTHON_BIN_DIR="/usr/local/bin" \
    UV_TOOL_DIR="/usr/local/uv/tools" \
    UV_TOOL_BIN_DIR="/usr/local/bin" \
    UV_LINK_MODE="copy"

# ---------------------------------------------------------------------------
# 4. Directory structure
# ---------------------------------------------------------------------------
RUN mkdir -p \
    /root/.config/opencode \
    /root/.config/pip \
    /root/.config/uv \
    /root/.hermes/skills \
    /root/.omo

# ---------------------------------------------------------------------------
# 5. Copy config files (build context = repo root)
# ---------------------------------------------------------------------------

# Vim
COPY vim/.vimrc /root/.vimrc

# Git
COPY git/.gitconfig /root/.gitconfig

# Pip (Aliyun mirror for Chinese mainland)
# NOTE: pip is NOT installed (Python managed by uv); config kept for reference only
COPY pip/pip.conf /root/.config/pip/pip.conf

# npm (npmmirror registry for Chinese mainland)
COPY npm/.npmrc /root/.npmrc

# uv (USTC default index + Tsinghua fallback + NJU Python mirror)
COPY uv/uv.toml /root/.config/uv/uv.toml

# Install Python via uv (globally visible via /usr/local/bin symlinks)
# MUST be after COPY uv/uv.toml so python-install-mirror takes effect
RUN uv python install 3.10

# Shared Python venv 'common' — uv venv doesn't seed pip by default, install explicitly.
# NOT auto-activated on new terminals; activate manually:
#   source /usr/local/uv/envs/common/bin/activate
RUN uv venv /usr/local/uv/envs/common --python 3.10 \
    && uv pip install pip --python /usr/local/uv/envs/common/bin/python

# OpenCode (AI coding assistant configs)
COPY opencode/opencode.jsonc      /root/.config/opencode/opencode.jsonc
COPY opencode/AGENTS.md           /root/.config/opencode/AGENTS.md
COPY opencode/commands.md         /root/.config/opencode/commands.md

# OMO (oh-my-openagent agent orchestration config)
COPY omo/omo.jsonc                /root/.omo/omo.jsonc

# Hermes (AI agent config + skills)
COPY hermes/config.yaml           /root/.hermes/config.yaml
COPY hermes/.env                  /root/.hermes/.env
COPY hermes/skills/               /root/.hermes/skills/

# Optional repo templates (not copied to home; use per-repo)
#   git/.gitignore     → copy to <repo>/.gitignore
#   git/.gitattributes → copy to <repo>/.gitattributes

# ---------------------------------------------------------------------------
# 6. OpenCode (AI coding assistant, Node.js)
#    Requires API keys in opencode/opencode.jsonc (currently placeholders "xxx")
# ---------------------------------------------------------------------------
RUN npm install -g opencode-ai@latest

# ---------------------------------------------------------------------------
# 7. Hermes Agent (AI agent platform, Python)
#    Requires API keys in hermes/.env (currently placeholders)
# ---------------------------------------------------------------------------
RUN uv tool install hermes-agent

# ---------------------------------------------------------------------------
# 8. Environment
# ---------------------------------------------------------------------------
ENV EDITOR=vim \
    VISUAL=vim \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

# Default shell
CMD ["/bin/bash"]
