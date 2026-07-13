# =============================================================================
# sections.sh — Docker 配置生成器的通用 section 输出函数
#
# Section 3-8 在 debian/redhat 分支间完全一致, 在此共享
# 函数通过 printf 写入全局变量 out (必须由调用者声明为 local out="")
# =============================================================================

# ---------------------------------------------------------------------------
# Node.js (via NodeSource, 包含 npm)
# 在 Section 1 (系统包) 之后、Section 2 (Locale) 之前调用
# NodeSource 的 nodejs 包自带 npm, 无需单独安装
# ---------------------------------------------------------------------------
section_nodejs() {
    local -n _out=$1
    [[ "$(cfg nodejs.include)" == "yes" ]] || return 0

    local ver; ver=$(cfg nodejs.version)
    local family; family=$(cfg image.family)

    _out+="# ---------------------------------------------------------------------------
# Node.js (via NodeSource, includes npm)
# ---------------------------------------------------------------------------
"

    if [[ "$family" == "debian" ]]; then
        _out+="RUN curl -fsSL https://deb.nodesource.com/setup_${ver}.x | bash - \\
    && apt-get install -y nodejs \\
    && rm -rf /var/lib/apt/lists/*

"
    elif [[ "$family" == "redhat" ]]; then
        _out+="RUN curl -fsSL https://rpm.nodesource.com/setup_${ver}.x | bash - \\
    && dnf install -y nodejs \\
    && dnf clean all

"
    fi
}

# ---------------------------------------------------------------------------
# Section 3: uv + Python
# ---------------------------------------------------------------------------
section_uv() {
    local base="$1"
    local -n _out=$2

    local needs_uv=0
    [[ "$(cfg python.include)" == "yes" ]] && needs_uv=1
    [[ "$(cfg nodejs.include)" == "yes" ]] && [[ "$(cfg opencode.include)" == "yes" ]] && needs_uv=1
    [[ "$(cfg hermes.include)" == "yes" ]] && needs_uv=1
    [[ "$needs_uv" -eq 0 ]] && return 0

    local arch; arch=$(detect_arch)
    local uv_target="uv-${arch}-unknown-linux-gnu"
    _out+="# ---------------------------------------------------------------------------
# 3. uv (Python & tool package manager)
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/local/uv/bin && \\
    curl -LsSf https://github.com/astral-sh/uv/releases/latest/download/${uv_target}.tar.gz | \\
    tar xz -C /usr/local/uv/bin --strip-components=1
ENV PATH=\"/usr/local/uv/bin:\${PATH}\"

ENV UV_PYTHON_INSTALL_DIR=\"/usr/local/uv/python\" \\
    UV_PYTHON_BIN_DIR=\"/usr/local/bin\" \\
    UV_TOOL_DIR=\"/usr/local/uv/tools\" \\
    UV_TOOL_BIN_DIR=\"/usr/local/bin\" \\
    UV_LINK_MODE=\"$(cfg python.uv_link_mode)\"

"
}

# ---------------------------------------------------------------------------
# Section 4: Directory structure
# ---------------------------------------------------------------------------
section_dirs() {
    local -n _out=$1

    local dirs=()
    [[ "$(cfg opencode.include)" == "yes" ]] && dirs+=("/root/.config/opencode")
    [[ "$(cfg python.include)" == "yes" ]] && dirs+=("/root/.config/uv")
    [[ "$(cfg hermes.include)" == "yes" ]] && dirs+=("/root/.hermes/skills")

    if [[ ${#dirs[@]} -eq 0 ]]; then
        dirs+=("/root")
    fi

    _out+="# ---------------------------------------------------------------------------
# 4. Directory structure
# ---------------------------------------------------------------------------
RUN mkdir -p \\
"
    for d in "${dirs[@]}"; do
        printf -v _line "    %s \\\\\n" "$d"
        _out+="${_line}"
    done
    _out="${_out% \\
}"
    _out+="
"
}

# ---------------------------------------------------------------------------
# Section 5: Copy config files
# ---------------------------------------------------------------------------
section_copy() {
    local -n _out=$1

    _out+="# ---------------------------------------------------------------------------
# 5. Copy config files (build context = repo root)
# ---------------------------------------------------------------------------

"

    if [[ "$(cfg vim.include)" == "yes" ]]; then
        _out+="# Vim
COPY vim/.vimrc /root/.vimrc

"
    fi

    if [[ "$(cfg git.include)" == "yes" ]]; then
        _out+="# Git
COPY git/.gitconfig /root/.gitconfig

"
    fi

    if [[ "$(cfg nodejs.include)" == "yes" ]]; then
        _out+="# npm (npmmirror registry)
COPY npm/.npmrc /root/.npmrc

"
    fi

    if [[ "$(cfg python.include)" == "yes" ]]; then
        _out+="# uv (PyPI mirror + Python install mirror)
COPY uv/uv.toml /root/.config/uv/uv.toml

# Install Python via uv (globally visible via /usr/local/bin symlinks)
# MUST be after COPY uv/uv.toml so python-install-mirror takes effect
RUN uv python install $(cfg python.version)

"
    fi

    if [[ "$(cfg opencode.include)" == "yes" ]]; then
        _out+="# OpenCode (AI coding assistant configs)
COPY opencode/opencode.jsonc      /root/.config/opencode/opencode.jsonc
COPY opencode/oh-my-openagent.json /root/.config/opencode/oh-my-openagent.json
COPY opencode/AGENTS.md           /root/.config/opencode/AGENTS.md
COPY opencode/commands.md         /root/.config/opencode/commands.md

"
    fi

    if [[ "$(cfg hermes.include)" == "yes" ]]; then
        _out+="# Hermes (AI agent config + skills)
COPY hermes/config.yaml           /root/.hermes/config.yaml
COPY hermes/.env                  /root/.hermes/.env
COPY hermes/skills/               /root/.hermes/skills/

"
    fi
}

# ---------------------------------------------------------------------------
# Section 6: OpenCode install (依赖 nodejs, 入口已校验依赖)
# ---------------------------------------------------------------------------
section_opencode_install() {
    local -n _out=$1
    [[ "$(cfg opencode.include)" == "yes" ]] || return 0
    _out+="# ---------------------------------------------------------------------------
# 6. OpenCode (AI coding assistant, Node.js)
# ---------------------------------------------------------------------------
RUN npm install -g opencode-ai@latest

"
}

# ---------------------------------------------------------------------------
# Section 7: Hermes install (依赖 python/uv, 入口已校验依赖)
# ---------------------------------------------------------------------------
section_hermes_install() {
    local -n _out=$1
    [[ "$(cfg hermes.include)" == "yes" ]] || return 0
    _out+="# ---------------------------------------------------------------------------
# 7. Hermes Agent (AI agent platform, Python)
# ---------------------------------------------------------------------------
RUN uv tool install hermes-agent

"
}

# ---------------------------------------------------------------------------
# Section 8: 环境变量 + WORKDIR + CMD
# ---------------------------------------------------------------------------
section_env() {
    local -n _out=$1
    _out+="# ---------------------------------------------------------------------------
# 8. Environment
# ---------------------------------------------------------------------------
ENV EDITOR=vim \\
    VISUAL=vim \\
    PYTHONUNBUFFERED=1

WORKDIR /workspace

CMD [\"/bin/bash\"]
"
}

# ---------------------------------------------------------------------------
# 文件头 (FROM + 注释)
# ---------------------------------------------------------------------------
file_header() {
    local -n _out=$1
    local base; base=$(cfg image.base)
    local tag; tag=$(cfg image.tag)
    _out+="# =============================================================================
# Dev environment — generated by docker/tools/generate-dockerfile.sh
# $(date -u '+%Y-%m-%d %H:%M:%S UTC')
# Build: docker build -t ${tag} -f docker/Dockerfile.generated .
# Run:   docker run -it --rm ${tag}
# =============================================================================
FROM ${base}

"
}
