# Docker 构建工具

根据配置文件动态生成 `Dockerfile`，按需选择安装的软件和工具，并自动适配基础镜像的发行版族和 CPU 架构。

## 架构概览

```
docker/tools/                         # 生成器代码目录
├── generate-dockerfile.sh            # 唯一入口: 解析 + 校验 + 路由
├── lib/                              # 公共库
│   ├── common.sh                     #   - 配置解析、cfg()/detect_*()、日志、校验
│   └── sections.sh                   #   - Dockerfile 中通用 section 3-8 输出函数
├── generate-{debian,redhat}.sh       # 发行版族分支脚本 (由入口 source, 不独立执行)
├── build.conf.default                # 默认配置文件 (含规则说明)
└── README.md                         # 本文件

docker/                               # 生成产物目录 (与手动维护的 Dockerfile 平行)
├── Dockerfile                        # 手动维护的完整版
└── Dockerfile.generated              # 脚本生成的定制版 (建议加入 .gitignore)
```

**调用流程**：

```
入口 (generate-dockerfile.sh)
  ├── source lib/common.sh        # 加载工具函数
  ├── source lib/sections.sh      # 加载通用 section 函数
  ├── 解析配置文件 → 填充 CFG 数组
  ├── validate_conf               # 校验
  ├── detect_family               # 检测发行版族
  └── source generate-<族>.sh     # 分支脚本立即执行生成 + print_summary
```

## 快速上手

```bash
# 1. 在仓库根目录 (config-files/) 执行

# 使用默认配置生成 (安装全部软件)
bash docker/tools/generate-dockerfile.sh

# 使用自定义配置
cp docker/tools/build.conf.default docker/tools/build.conf
vim docker/tools/build.conf
bash docker/tools/generate-dockerfile.sh docker/tools/build.conf

# 2. 构建镜像
docker build -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile.generated .

# 3. 运行
docker run -it --rm ubuntu26.04-custom:v0.1
```

## 配置参考

配置格式为 `key=value`。`#` 开头为注释，空行自动忽略。所有配置项均有默认值。

| 配置项 | 默认值 | 可选值 | 说明 |
|--------|--------|--------|------|
| `image.base` | `ubuntu:26.04` | `ubuntu:*` / `*ascend*` 等 | 基础镜像 (详见下文"发行版族与架构检测") |
| `image.tag` | `ubuntu26.04-custom:v0.1` | `名称:标签` 格式 | 生成镜像的标签 |
| `locale.codes` | `en_US.UTF-8,zh_CN.UTF-8` | 逗号分隔的 locale | 需要生成的 locale |
| `locale.lang` | `en_US.UTF-8` | 必须在 codes 中 | 默认语言 |
| `python.include` | `yes` | `yes`/`no` | 安装 Python (uv) |
| `python.version` | `3.10` | `3.8`~`3.13` | Python 版本 |
| `python.uv_link_mode` | `copy` | `copy`/`hardlink`/`symlink`/`clone`/`local` | uv 包安装模式 |
| `vim.include` | `yes` | `yes`/`no` | 安装 vim 配置 |
| `git.include` | `yes` | `yes`/`no` | 安装 git 配置 |
| `nodejs.include` | `yes` | `yes`/`no` | 安装 Node.js |
| `npm.prefix` | `/usr/local` | 任意路径 | npm 全局路径 |
| `opencode.include` | `yes` | `yes`/`no` | 安装 OpenCode |
| `hermes.include` | `yes` | `yes`/`no` | 安装 Hermes |
| `extra.apt_packages` | (空) | 逗号分隔的包名 | 额外 APT 包 |

## 发行版族与架构自动检测

### 发行版族 (`detect_family`)

决定使用 `apt-get` 还是 `dnf`、`locale-gen` 还是 `localedef`。

| 镜像名匹配词 | 检测到的族 | 生成的分支脚本 |
|--------------|-----------|----------------|
| `ascend` / `openeuler` / `centos` / `rhel` / `rocky` / `alma` / `fedora` | `redhat` | `generate-redhat.sh` |
| 其他 (默认) | `debian` | `generate-debian.sh` |

**RedHat 生成的差异**：
- 包管理: `dnf install -y` / `dnf clean all`
- locale 包: `glibc-all-langpacks` (而非 `locales`)
- locale 生成: `localedef -i <lang> -f <charset> <locale>` (而非 `locale-gen`)

### 架构 (`detect_arch`)

决定 `uv` 安装包的下载架构。

| 镜像名匹配词 | 检测到的架构 |
|--------------|-------------|
| `ascend` / `arm` / `aarch64` | `aarch64` |
| 其他 (默认) | `x86_64` |

## 配置示例

### Ubuntu (默认, x86-64)
```bash
bash docker/tools/generate-dockerfile.sh
# 路由到 generate-debian.sh
```

### vllm-ascend (ARM, RedHat 系)
```ini
# build.conf
image.base=quay.io/ascend/vllm-ascend:latest
image.tag=vllm-ascend-custom:v0.1
```
```bash
bash docker/tools/generate-dockerfile.sh docker/tools/build.conf
# 路由到 generate-redhat.sh, uv 使用 aarch64 下载
```

### 最精简 (仅基础工具)
```ini
python.include=no
nodejs.include=no
opencode.include=no
hermes.include=no
```

## 工具依赖关系

脚本入口会校验，违反依赖时报错并退出 (exit code 非 0)：

```
opencode ──→ nodejs    (通过 npm 安装)
hermes   ──→ python    (通过 uv tool install)
```

## 扩展：新增发行版族 (例如 Alpine)

三步完成：

**1. 创建分支脚本 `generate-alpine.sh`**（参考 `generate-redhat.sh`）：

```bash
#!/usr/bin/env bash
set -euo pipefail

generate_alpine() {
    local out=""
    file_header out

    # Section 1: apk
    out+="# ---------------------------------------------------------------------------
# 1. System packages (apk)
# ---------------------------------------------------------------------------
RUN apk add --no-cache vim git curl wget ca-certificates

"

    # Section 2: locale (Alpine 用 musl-libc 自带)
    # ...

    # Section 3-8: 通用
    section_uv "$(cfg image.base)" out
    section_dirs out
    section_copy out
    section_opencode_install out
    section_hermes_install out
    section_env out

    printf '%s' "$out" > "$OUTPUT_DOCKERFILE"
}

generate_alpine
print_summary
```

**2. 在 `lib/common.sh` 的 `detect_family()` 添加匹配词**：

```bash
if [[ "$base" == *"alpine"* || ... ]]; then
    printf 'alpine'
```

**3. 完成** — 入口脚本的 case 分支会自动路由到 `generate-alpine.sh`，无需修改入口脚本。

## 常见错误

| 错误信息 | 原因 | 修复 |
|----------|------|------|
| `image.tag 必须包含 ':'` | 标签缺少 `:` | `image.tag=myimage:v1` |
| `locale.lang 必须在 locale.codes 中` | 默认语言不在列表中 | 调整 locale.lang |
| `xxx 必须是 yes 或 no` | 布尔值输入错误 | 使用小写 `yes` / `no` |
| `opencode 需要 nodejs` | 依赖冲突 | 设 `nodejs.include=yes` 或禁 opencode |
| `hermes 需要 python` | 依赖冲突 | 设 `python.include=yes` 或禁 hermes |
| `未找到发行版分支脚本: generate-xxx.sh` | 新增族未创建分支脚本 | 按扩展章节创建 |

## 注意事项

1. **构建上下文**: `docker build` 必须在仓库根目录执行，因为 `COPY` 指令引用仓库内配置文件路径
2. **生成文件路径**: 固定输出到 `docker/Dockerfile.generated`，不覆盖手动维护的 `docker/Dockerfile`
3. **`build.conf.default`**: 是默认值参考文件或模板，自定义请复制为 `build.conf`
4. **`uv.toml` 顺序**: 生成脚本保证 `uv.toml` 在 `uv python install` 之前复制，让镜像下载走配置
5. **npm 代理**: `.npmrc` 中的 `proxy` 和 `https-proxy` 默认注释，如需代理请在容器内手动取消注释
6. **未知发行版**: 默认走 `debian` 分支，生成 apt-get 命令。若基础镜像不是 Debian 系，需新增分支脚本
