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
    # Node.js ecosystem (Ubuntu 26.04 default, typically v22+)
    nodejs \
    npm \
    # Locale support (for vim CJK settings)
    locales \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Locale (required by vim config: encoding=utf-8, langmenu=zh_CN.UTF-8)
# ---------------------------------------------------------------------------
RUN locale-gen en_US.UTF-8 zh_CN.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# 3. uv + Python (per uv/commands.md §1 安装 + §2 环境变量)
# ---------------------------------------------------------------------------
# Install uv to /usr/local/uv (system-wide, all users)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/uv" sh
ENV PATH="/usr/local/uv/bin:${PATH}"

# uv environment variables (controls install directories & link mode)
ENV UV_PYTHON_INSTALL_DIR="/usr/local/uv/python" \
    UV_PYTHON_BIN_DIR="/usr/local/bin" \
    UV_TOOL_DIR="/usr/local/uv/tools" \
    UV_TOOL_BIN_DIR="/usr/local/bin" \
    UV_LINK_MODE="copy"

# Install Python via uv (globally visible via /usr/local/bin symlinks)
RUN uv python install 3.12

# ---------------------------------------------------------------------------
# 4. Directory structure
# ---------------------------------------------------------------------------
RUN mkdir -p \
    /root/.config/opencode \
    /root/.config/pip \
    /root/.config/uv \
    /root/.hermes/skills

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
# Comment out placeholder proxy entries to avoid npm install hanging
RUN sed -i '/^proxy=/s/^/# /; /^https-proxy=/s/^/# /' /root/.npmrc

# uv (USTC default index + Tsinghua fallback + NJU Python mirror)
COPY uv/uv.toml /root/.config/uv/uv.toml

# OpenCode (AI coding assistant configs)
COPY opencode/opencode.jsonc      /root/.config/opencode/opencode.jsonc
COPY opencode/oh-my-openagent.json /root/.config/opencode/oh-my-openagent.json
COPY opencode/AGENTS.md           /root/.config/opencode/AGENTS.md
COPY opencode/commands.md         /root/.config/opencode/commands.md

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
RUN npm install -g @opencode/opencode

# ---------------------------------------------------------------------------
# 7. Hermes Agent (AI agent platform, Python)
#    Requires API keys in hermes/.env (currently placeholders)
# ---------------------------------------------------------------------------
RUN uv pip install --system hermes-agent

# ---------------------------------------------------------------------------
# 8. Environment
# ---------------------------------------------------------------------------
ENV EDITOR=vim \
    VISUAL=vim \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

# Default shell
CMD ["/bin/bash"]
