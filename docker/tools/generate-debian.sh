#!/usr/bin/env bash
# =============================================================================
# generate-debian.sh — Debian 系 (Ubuntu) Dockerfile 生成器
#
# 由 generate-dockerfile.sh (入口) 调用, 不独立执行
# 依赖: lib/common.sh + lib/sections.sh 已被 source
# 输入: 全局 CFG 数组已填充, $REPO_ROOT 和 $OUTPUT_DOCKERFILE 已设置
# 输出: $OUTPUT_DOCKERFILE
# =============================================================================
set -euo pipefail

generate_debian() {
    local out=""

    file_header out

    # ================================================================
    # Section 1: System packages (apt-get)
    # ================================================================
    out+="# ---------------------------------------------------------------------------
# 1. System packages (apt)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \\
    # Core tools
    vim \\
    git \\
    curl \\
    wget \\
    ca-certificates \\
"

    out+="    # Locale support (apt)
    locales \\
"

    local extra_pkgs; extra_pkgs=$(cfg extra.apt_packages)
    if [[ -n "$extra_pkgs" ]]; then
        out+="    # Extra packages
"
        IFS=',' read -ra pkgs <<< "$extra_pkgs"
        for pkg in "${pkgs[@]}"; do
            pkg="${pkg#"${pkg%%[![:space:]]*}"}"; pkg="${pkg%"${pkg##*[![:space:]]}"}"
            if [[ -n "$pkg" ]]; then
                printf -v _line "    %s \\\\\n" "$pkg"
                out+="${_line}"
            fi
        done
    fi

    out+="    # Cleanup
    && rm -rf /var/lib/apt/lists/*

"

    # ================================================================
    # Section 2: Locale (locale-gen)
    # ================================================================
    local codes; codes=$(cfg locale.codes)
    local lang; lang=$(cfg locale.lang)
    local locale_gen="locale-gen"
    IFS=',' read -ra larr <<< "$codes"
    for loc in "${larr[@]}"; do
        loc="${loc#"${loc%%[![:space:]]*}"}"; loc="${loc%"${loc##*[![:space:]]}"}"
        [[ -n "$loc" ]] && locale_gen+=" ${loc}"
    done

    out+="# ---------------------------------------------------------------------------
# 2. Locale
# ---------------------------------------------------------------------------
RUN ${locale_gen}
ENV LANG=${lang} \\
    LC_ALL=${lang}

"

    # ================================================================
    # Section 3-8: 通用
    # ================================================================
    section_nodejs out
    section_uv "$(cfg image.base)" out
    section_dirs out
    section_copy out
    section_opencode_install out
    section_hermes_install out
    section_env out

    printf '%s' "$out" > "$OUTPUT_DOCKERFILE"
}

# 直接执行生成 (被入口 source 后调用本函数)
generate_debian
print_summary
