# =============================================================================
# common.sh — Docker 配置生成器的公共工具函数库
#
# 被 generate-dockerfile.sh (入口) 和 generate-{debian,redhat}.sh (分支) source
# 提供: 配置解析、配置读取、架构/发行版检测、日志工具
# =============================================================================

# ---------------------------------------------------------------------------
# 默认值表 (配置文件未设置时的回退值)
# ---------------------------------------------------------------------------
declare -A _DEFAULTS=(
    [image.base]="ubuntu:26.04"
    [image.arch]="x86_64"
    [image.family]="debian"
    [image.tag]="ubuntu26.04-custom:v0.1"
    [locale.codes]="en_US.UTF-8,zh_CN.UTF-8"
    [locale.lang]="en_US.UTF-8"
    [python.include]="yes"
    [python.version]="3.10"
    [python.uv_link_mode]="copy"
    [vim.include]="yes"
    [git.include]="yes"
    [nodejs.include]="yes"
    [npm.prefix]="/usr/local"
    [opencode.include]="yes"
    [hermes.include]="yes"
    [extra.apt_packages]=""
)

# 全局配置存储 (由 parse_conf 写入)
declare -gA CFG=()

# ---------------------------------------------------------------------------
# 日志工具
# ---------------------------------------------------------------------------
log_error() { printf '[错误] %s\n' "$*" >&2; }
log_warn()  { printf '[警告] %s\n' "$*"; }
log_info()  { printf '[信息] %s\n' "$*"; }

# ---------------------------------------------------------------------------
# cfg <key>
# 返回配置值: CFG[key] 优先, 否则 _DEFAULTS[key], 否则空
# ---------------------------------------------------------------------------
cfg() {
    local key="$1"
    if [[ -v CFG["$key"] ]]; then
        printf '%s' "${CFG[$key]}"
    elif [[ -v _DEFAULTS["$key"] ]]; then
        printf '%s' "${_DEFAULTS[$key]}"
    fi
}

# ---------------------------------------------------------------------------
# parse_conf <file> [array_name]
# KV 配置文件解析器 (不使用 source, 避免 shell 注入风险)
#
# 格式: key=value, # 注释, 空行忽略
# key 规则: 以字母开头, 仅含字母/数字/点/下划线
# 注意: 不支持引号包裹值, 不支持嵌套结构
#
# array_name 可选, 默认写入全局 CFG
# ---------------------------------------------------------------------------
parse_conf() {
    local file="$1"
    local target="${2:-CFG}"
    local -n _tgt=$target

    [[ -f "$file" ]] || { log_error "配置文件不存在: $file"; return 1; }

    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))
        line="${line%%$'\r'}"
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        if [[ "$line" != *"="* ]]; then
            log_error "第 ${line_num} 行格式错误 (缺少 =): '$line'"
            return 1
        fi

        local key="${line%%=*}"
        local val="${line#*=}"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val%"${val##*[![:space:]]}"}"

        if [[ ! "$key" =~ ^[a-z][a-z0-9._]*$ ]]; then
            log_error "第 ${line_num} 行键名无效: '$key' (必须以字母开头, 仅含字母/数字/点/下划线)"
            return 1
        fi

        _tgt["$key"]="$val"
    done < "$file"
}

# ---------------------------------------------------------------------------
# detect_arch
# 从配置项 image.arch 读取架构, 不再自动探测
# ---------------------------------------------------------------------------
detect_arch() {
    cfg image.arch
}

# ---------------------------------------------------------------------------
# detect_family
# 从配置项 image.family 读取发行版族, 不再自动探测
# ---------------------------------------------------------------------------
detect_family() {
    cfg image.family
}

# ---------------------------------------------------------------------------
# 配置值校验 (供入口脚本调用)
# ---------------------------------------------------------------------------
validate_conf() {
    local errors=0

    # --- image.tag: 必须含冒号 ---
    local tag; tag=$(cfg image.tag)
    if [[ "$tag" != *":"* ]]; then
        log_error "image.tag 必须包含 ':' 分隔名称和标签, 当前: '$tag'"
        errors=$((errors + 1))
    fi

    # --- image.family: 必须为 debian/redhat ---
    local family; family=$(cfg image.family)
    if [[ "$family" != "debian" && "$family" != "redhat" ]]; then
        log_error "image.family 必须是 debian 或 redhat, 当前: '$family'"
        errors=$((errors + 1))
    fi

    # --- image.arch: 必须为 x86_64/aarch64 ---
    local arch; arch=$(cfg image.arch)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
        log_error "image.arch 必须是 x86_64 或 aarch64, 当前: '$arch'"
        errors=$((errors + 1))
    fi

    # --- locale.lang: 必须在 locale.codes 列表中 ---
    local lang; lang=$(cfg locale.lang)
    local codes; codes=$(cfg locale.codes)
    local found=0
    IFS=',' read -ra code_arr <<< "$codes"
    for c in "${code_arr[@]}"; do
        c="${c#"${c%%[![:space:]]*}"}"; c="${c%"${c##*[![:space:]]}"}"
        [[ "$c" == "$lang" ]] && { found=1; break; }
    done
    if [[ "$found" -eq 0 ]]; then
        log_error "locale.lang ($lang) 必须在 locale.codes ($codes) 中"
        errors=$((errors + 1))
    fi

    # --- python.version: 格式校验 ---
    local pyver; pyver=$(cfg python.version)
    if [[ ! "$pyver" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        log_error "python.version 格式无效: '$pyver' (应为 3.10 或 3.10.8)"
        errors=$((errors + 1))
    fi

    # --- yes/no 布尔值校验 ---
    local bool_keys=(
        python.include vim.include git.include
        nodejs.include
        opencode.include hermes.include
    )
    for k in "${bool_keys[@]}"; do
        local v; v=$(cfg "$k")
        if [[ "$v" != "yes" && "$v" != "no" ]]; then
            log_error "$k 必须是 yes 或 no, 当前: '$v'"
            errors=$((errors + 1))
        fi
    done

    # --- uv.link_mode: 枚举值校验 ---
    local lm; lm=$(cfg python.uv_link_mode)
    case "$lm" in
        copy|hardlink|symlink|clone|local) ;;
        *)
            log_error "python.uv_link_mode 无效: '$lm' (可选: copy/hardlink/symlink/clone/local)"
            errors=$((errors + 1))
            ;;
    esac

    # --- opencode 依赖 nodejs ---
    if [[ "$(cfg opencode.include)" == "yes" && "$(cfg nodejs.include)" == "no" ]]; then
        log_error "opencode 需要 nodejs (通过 npm 安装), 但 nodejs.include=no"
        errors=$((errors + 1))
    fi

    # --- hermes 依赖 python (uv) ---
    if [[ "$(cfg hermes.include)" == "yes" && "$(cfg python.include)" == "no" ]]; then
        log_error "hermes 需要 python (通过 uv 安装), 但 python.include=no"
        errors=$((errors + 1))
    fi

    [[ "$errors" -gt 0 ]] && { log_error "校验失败, 共 ${errors} 个错误"; return 1; }
    return 0
}

# ---------------------------------------------------------------------------
# 汇总报告 (供分支脚本生成后调用)
# ---------------------------------------------------------------------------
print_summary() {
    local family; family=$(detect_family)
    printf '\n'
    log_info "Dockerfile 已生成: ${OUTPUT_DOCKERFILE:-<未设置>}"
    printf '  基础镜像:   %s\n' "$(cfg image.base)"
    printf '  发行版族:   %s\n' "$family"
    printf '  架构:       %s\n' "$(detect_arch)"
    printf '  输出标签:   %s\n' "$(cfg image.tag)"
    printf '  Python:     %s\n' "$(if [[ "$(cfg python.include)" == "yes" ]]; then printf '%s' "$(cfg python.version)"; else printf '不安装'; fi)"
    printf '  Node.js:    %s\n' "$(if [[ "$(cfg nodejs.include)" == "yes" ]]; then printf '是'; else printf '否'; fi)"
    printf '  OpenCode:   %s\n' "$(if [[ "$(cfg opencode.include)" == "yes" ]]; then printf '是'; else printf '否'; fi)"
    printf '  Hermes:     %s\n' "$(if [[ "$(cfg hermes.include)" == "yes" ]]; then printf '是'; else printf '否'; fi)"
    printf '\n'
    printf '构建命令 (在仓库根目录执行):\n'
    printf '  docker build -t %s -f docker/Dockerfile.generated .\n' "$(cfg image.tag)"
    printf '运行:\n'
    printf '  docker run -it --rm %s\n' "$(cfg image.tag)"
}
