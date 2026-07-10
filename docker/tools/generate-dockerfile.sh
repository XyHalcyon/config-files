#!/usr/bin/env bash
# =============================================================================
# generate-dockerfile.sh — Dockerfile 生成器入口 (唯一入口)
#
# 职责:
#   1. 加载公共库 (解析器/校验器/检测器)
#   2. 解析配置文件
#   3. 校验配置项
#   4. 根据 image.base 检测发行版族 (debian/redhat)
#   5. 路由到对应的分支脚本 (generate-{debian,redhat}.sh)
#
# 用法:
#   bash docker/tools/generate-dockerfile.sh [配置文件]
#   bash docker/tools/generate-dockerfile.sh                         # 使用默认配置
#
# 分支脚本约定:
#   - 文件名: generate-<family>.sh (例如 generate-debian.sh, generate-redhat.sh)
#   - 依赖: lib/common.sh + lib/sections.sh 已由入口 source
#   - 接收: 全局 CFG 数组、$REPO_ROOT、$OUTPUT_DOCKERFILE 已就绪
#   - 职责: 实现 generate_<family> 函数, 在 source 后执行生成并 print_summary
#
# 新增发行版族:
#   1. 创建 generate-<family>.sh (参考 generate-redhat.sh)
#   2. 在 lib/common.sh 的 detect_family() 添加匹配词
#   3. 入口脚本的 case 分支自动路由, 无需修改
#
# 依赖: bash >= 4.0 (关联数组, nameref)
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# 路径定位 (脚本所在目录 → 仓库根目录)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
DEFAULT_CONFIG="${SCRIPT_DIR}/build.conf.default"
OUTPUT_DOCKERFILE="${REPO_ROOT}/docker/Dockerfile.generated"

# ---------------------------------------------------------------------------
# 加载公共库
# ---------------------------------------------------------------------------
# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"
# shellcheck source=lib/sections.sh
source "${LIB_DIR}/sections.sh"

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
    local config_file="${1:-$DEFAULT_CONFIG}"

    log_info "配置文件: $config_file"
    log_info "输出文件: $OUTPUT_DOCKERFILE"

    # 解析配置
    parse_conf "$config_file" CFG

    # 校验
    validate_conf

    # 检测发行版族并路由
    local family; family=$(detect_family "$(cfg image.base)")
    log_info "检测发行版族: $family"

    local branch_script="${SCRIPT_DIR}/generate-${family}.sh"
    if [[ ! -f "$branch_script" ]]; then
        log_error "未找到发行版分支脚本: $branch_script"
        log_error "当前支持: $(ls "${SCRIPT_DIR}"/generate-*.sh 2>/dev/null | xargs -n1 basename 2>/dev/null || echo '<无>')"
        exit 1
    fi

    # 调用分支脚本 (source 后, 分支脚本立即执行生成 + print_summary)
    # shellcheck source=generate-debian.sh
    source "$branch_script"
}

main "$@"
