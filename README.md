# config-files

个人 dotfiles 与配置文件集合。

## Vim

### `vim/.vimrc`

Vim 编辑器配置。部署至 `~/.vimrc`。

**功能分区：**

| Section | Key Settings |
|---|---|
| 全局配置 (Global) | `nocompatible`, `history=1000`, `mouse=a`, `autoread` |
| 字体和颜色 (Font/Color) | `syntax enable`, `cursorline`, `guifont=Courier_New` |
| 代码折叠 (Folding) | `foldenable`, `foldmethod=manual`, `foldclose=all` |
| 文字处理 (Text) | `expandtab`, `tabstop=4`, `shiftwidth=4`, `autoindent` |
| Vim 界面 (UI) | `number`, `ruler`, `wildmenu`, `hlsearch`, `incsearch` |
| 编码设置 (Encoding) | `encoding=utf-8`, `langmenu=zh_CN.UTF-8` |
| 其他 (Other) | `laststatus=2`, `clipboard+=unnamed`, `nobackup` |

**自动文件头：** 创建 `.py` 或 `.sh` 文件时自动插入作者、时间戳、描述信息。

---

## OpenCode

### `opencode/opencode.jsonc`

OpenCode 主配置文件。部署至 `~/.config/opencode/opencode.jsonc`。

- **Provider**：Codiz（Anthropic 兼容 API，基于 `@ai-sdk/anthropic`），地址 `https://codiz.dev/v1`
- **Models**（Codiz）：`claude-opus-4-7`、`claude-opus-4-7-thinking`、`claude-opus-4-8`、`claude-opus-4-8-thinking`
- **Provider**：bailian-payg（阿里云百炼 Model Studio，Anthropic 兼容 API，基于 `@ai-sdk/anthropic`），地址 `https://dashscope.aliyuncs.com/apps/anthropic/v1`
- **Models**（bailian-payg）：`glm-5.2`（GLM-5.2）和 `qwen3.7-max`（Qwen3.7 Max），均启用 thinking 模式（budgetTokens=8192）
- **Plugin**：`oh-my-openagent`，用于代理编排
- **Permissions**：`*` → `allow`（允许所有工具调用）

> **注意**：`apiKey` 字段为占位符（`xxx`），请替换为实际的 Codiz API 密钥。

---

### `opencode/oh-my-openagent.json`

Sisyphus 编排系统的代理与分类模型分配。部署至 `~/.config/opencode/oh-my-openagent.json`。

**Agents** — 各代理的主模型与回退模型分配：

| Agent | Primary Model | Fallback Model | 角色 |
|---|---|---|---|
| `sisyphus` | `deepseek/deepseek-v4-pro` | `alibaba-cn/qwen-3.7-max` | 主编排器 |
| `hephaestus` | `deepseek/deepseek-v4-pro` | `codiz/claude-opus-4-8` | 构建器 |
| `prometheus` | `codiz/claude-opus-4-8` | `deepseek/deepseek-v4-pro` | 规划器 |
| `oracle` | `codiz/claude-opus-4-8-thinking` | `codiz/claude-opus-4-8` | 高智商推理顾问 |
| `atlas` | `alibaba-cn/qwen-3.7-max` | `bailian-payg/glm-5.2` | 研究索引 |
| `metis` | `bailian-payg/glm-5.2` | `alibaba-cn/qwen-3.7-max` | 预规划顾问 |
| `momus` | `alibaba-cn/qwen-3.7-max` | `bailian-payg/glm-5.2` | 计划审查 |
| `multimodal-looker` | `codiz/claude-opus-4-8` | `deepseek/deepseek-v4-pro` | 视觉分析 |
| `explore` / `librarian` | `deepseek/deepseek-v4-flash` | — | 上下文 / 参考搜索 |
| `sisyphus-junior` | `alibaba-cn/qwen-3.7-max` | `deepseek/deepseek-v4-pro` | 任务执行器 |

**Categories** — 任务类型到模型的映射：

| Category | Primary Model | Fallback Model | 用途 |
|---|---|---|---|
| `ultrabrain` | `codiz/claude-opus-4-8-thinking` | `codiz/claude-opus-4-8` | 复杂逻辑 / 架构 |
| `artistry` | `alibaba-cn/qwen-3.7-max` | `deepseek/deepseek-v4-pro` | 创意方案 |
| `deep` | `codiz/claude-opus-4-8` | `deepseek/deepseek-v4-pro` | 自主研究 + 实现 |
| `visual-engineering` | `deepseek/deepseek-v4-pro` | `codiz/claude-opus-4-8` | 前端 / UI / 样式 |
| `unspecified-high` | `deepseek/deepseek-v4-pro` | `alibaba-cn/qwen-3.7-max` | 未分类高复杂度 |
| `writing` | `alibaba-cn/qwen-3.7-max` | `deepseek/deepseek-v4-pro` | 文档 / 写作 |
| `unspecified-low` | `deepseek/deepseek-v4-flash` | `deepseek/deepseek-v4-pro` | 未分类低复杂度 |
| `quick` | `deepseek/deepseek-v4-flash` | `deepseek/deepseek-v4-pro` | 简单单文件修改 |

---

### `opencode/AGENTS.md`

LLM 编码助手行为指南。部署至 `~/.config/opencode/AGENTS.md`。

通过四项原则减少常见 LLM 编码错误：

| 原则 | 说明 |
|---|---|
| 编码前先思考 | 明确假设，呈现权衡，不确定时提问 |
| 简洁优先 | 用最少代码解决问题，不做推测性设计 |
| 精准修改 | 只动该动的部分，遵循既有风格 |
| 目标驱动 | 定义成功标准，循环直至验证通过 |

> **注意**：这些指南偏向谨慎而非速度。对于简单任务，自行判断。
>
> **来源**：改编自 [multica-ai/andrej-karpathy-skills/CLAUDE.md](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md)。

---

### `opencode/commands.md`

OpenCode 常用命令速查手册。部署至 `~/.config/opencode/commands.md`。

涵盖 11 大类命令：

| 分类 | 内容 |
|---|---|
| 基础操作 | `opencode` 启动、`run` 单次执行、Server 模式、全局选项 |
| 会话管理 | `session list/delete`、`export/import`、`stats` 统计 |
| Provider 与模型 | `providers list/login/logout`、`models` 列出可用模型 |
| MCP 服务器 | `mcp list/add/auth/logout/debug` |
| Agent 管理 | `agent list/create`、`debug agent` 查看详情 |
| Plugin 插件 | `plugin <module>` 安装并更新配置 |
| GitHub 集成 | `github install/run`、`pr <number>` 拉取 PR |
| 诊断与调试 | `debug config/paths/lsp/skill/startup`、升级卸载 |
| Slash 命令 | 会话内 `/frontend`、`/git-master`、`/debugging` 等 20+ 命令 |
| 触发词速查 | `commit`→`/git-master`、`security review`→`/security-review` 等自动触发 |
| 常用工作流 | 新功能开发（规划→执行→审查→清理）、调试修复、前端页面的完整流程 |

---

## Pip

### `pip/pip.conf`

Pip 包管理器的国内镜像源配置。部署至 `~/.config/pip/pip.conf`。

| 字段 | 值 | 说明 |
|---|---|---|
| `index-url` | `http://mirrors.aliyun.com/pypi/simple/` | 使用阿里云 PyPI 镜像加速下载 |
| `trusted-host` | `mirrors.aliyun.com` | 信任 HTTP 镜像源（非 HTTPS） |

---

## npm

### `npm/.npmrc`

npm 包管理器的镜像源与代理配置。部署至 `~/.npmrc`。

| 字段 | 值 | 说明 |
|---|---|---|
| `registry` | `https://registry.npmmirror.com` | 使用淘宝 npm 镜像源加速下载 |
| `prefix` | `/usr/local` | 全局安装包的路径 |
| `proxy` | `http://proxy.xxx.com:8080` | HTTP 代理（需替换为实际代理地址） |
| `https-proxy` | `http://proxy.xxx.com:8080` | HTTPS 代理（需替换为实际代理地址） |
| `cache` | `/tmp/npm/cache` | npm 缓存目录 |

**等效命令：** `.npmrc` 中的配置项均可通过 `npm config set` 命令直接设置：

| 命令 | 对应字段 |
|---|---|
| `npm config set registry https://registry.npmmirror.com` | `registry` |
| `npm config set prefix /usr/local` | `prefix` |
| `npm config set proxy http://proxy.xxx.com:8080` | `proxy` |
| `npm config set https-proxy http://proxy.xxx.com:8080` | `https-proxy` |
| `npm config set cache /tmp/npm/cache` | `cache` |

执行 `npm config set` 后会自动写入 `~/.npmrc`，也可直接编辑该文件。通过 `npm config list` 查看当前生效的全部配置。

---

## uv

### `uv/uv.toml`

uv 包管理器的镜像源配置。部署至 `~/.config/uv/uv.toml`。

| 字段 | 值 | 说明 |
|---|---|---|
| `python-install-mirror` | `https://mirrors.nju.edu.cn/github-release/astral-sh/python-build-standalone` | CPython 解释器下载镜像（`uv python install` 使用） |
| `[[index]]` (tsinghua) | `https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple` | 清华 PyPI 镜像源 |
| `[[index]]` (ustc) | `https://mirrors.ustc.edu.cn/pypi/simple` | 中科大 PyPI 镜像源，`default = true`（默认索引） |

---

### `uv/commands.md`

uv 命令行工具常用命令速查手册。

涵盖 9 大类命令：

| 分类 | 内容 |
|---|---|
| 安装 | 安装命令、更新、PATH 配置 |
| 环境变量 | `UV_CACHE_DIR`、`UV_TOOL_DIR`、`UV_PYTHON_INSTALL_DIR` 等配置说明 |
| Python 管理 | `uv python install/list/pin/uninstall` |
| 项目管理 | `uv init/add/remove/sync/lock/run/build` |
| 工具管理 | `uv tool install/list/upgrade/uninstall/run` |
| 虚拟环境 | `uv venv` 创建与激活 |
| pip 兼容接口 | `uv pip install/uninstall/list/freeze/compile/sync` |
| 缓存与清理 | `uv cache dir/clean/prune` |
| 常用工作流 | 新项目初始化、requirements.txt 迁移、全局工具管理 |

---

## Hermes

### `hermes/config.yaml`

Hermes Agent 主配置文件。部署至 `~/.hermes/config.yaml`。

**模型配置：**

| 用途 | 模型 | 提供商 | 说明 |
|---|---|---|---|
| 主模型 | `qwen3.7-max` | dashscope | 阿里云通义千问，主力对话模型 |
| 委派模型 | `glm-5.1` | dashscope | 智谱 GLM，用于子代理委派任务 |
| 视觉辅助 | `deepseek-v4-flash` | deepseek | 图片分析辅助 |
| 网页提取 | `deepseek-v4-flash` | deepseek | 网页内容提取辅助 |
| X 搜索 | `grok-4.20-reasoning` | xAI | X/Twitter 搜索（需 XAI API Key） |
| 其他辅助 | auto | 继承主模型 | 压缩、标题生成、策展等 11 项自动选择 |

**核心设置：**

| 配置项 | 值 | 说明 |
|---|---|---|
| `agent.max_turns` | 150 | 单次对话最大轮次 |
| `agent.gateway_timeout` | 1800 | Gateway 超时（秒） |
| `agent.reasoning_effort` | medium | 推理力度 |
| `terminal.backend` | local | 终端后端（本地执行） |
| `terminal.timeout` | 180 | 命令超时（秒） |
| `compression.enabled` | true | 上下文压缩 |
| `memory.memory_enabled` | true | 持久化记忆 |
| `memory.memory_char_limit` | 2200 | 记忆字符上限 |
| `delegation.max_concurrent_children` | 3 | 最大并行子代理数 |
| `delegation.max_spawn_depth` | 1 | 子代理嵌套深度 |
| `tts.provider` | edge | 文字转语音（微软 Edge） |
| `stt.provider` | local | 语音转文字（Whisper 本地） |
| `display.streaming` | true | 流式输出 |
| `security.redact_secrets` | true | 自动脱敏敏感信息 |

**消息平台：** 已配置钉钉（DingTalk）Stream 模式集成。

**工具集：** CLI 平台启用 browser、clarify、code_execution、computer_use、cronjob、delegation、file、image_gen、memory、session_search、skills、terminal、todo、tts、vision、web。

---

### `hermes/.env`

Hermes Agent API 密钥文件。部署至 `~/.hermes/.env`。

> **警告**：包含敏感凭据，请勿上传至公开仓库。

| 变量 | 用途 |
|---|---|
| `DASHSCOPE_API_KEY` | 阿里云 DashScope（通义千问、智谱 GLM） |
| `DEEPSEEK_API_KEY` | DeepSeek API |
| `DINGTALK_CLIENT_SECRET` | 钉钉 Stream 模式客户端密钥 |

**凭据解析机制：** `config.yaml` 仅声明 provider 名称（如 `dashscope`、`deepseek`），Hermes 启动时加载 `.env` 到环境变量，再按命名约定自动查找对应的 `<PROVIDER>_API_KEY`。解析结果记录在自动生成的 `auth.json` 中（`source: env:XXX_API_KEY`），无需手动维护。

---

### `hermes/skills/`

Hermes Agent 技能库。部署至 `~/.hermes/skills/`。

包含 436 个文件，覆盖 11 个分类：

| 分类 | 技能数 | 代表技能 |
|---|---|---|
| `autonomous-ai-agents` | 2 | hermes-agent, opencode |
| `creative` | 14 | architecture-diagram, ascii-art, comfyui, excalidraw, p5js |
| `data-science` | 1 | jupyter-live-kernel |
| `devops` | 6 | dingtalk-integration, gateway-debugging, kanban-orchestrator |
| `dogfood` | 1 | dogfood |
| `email` | 1 | himalaya |
| `github` | 6 | github-pr-workflow, github-code-review, github-repo-management |
| `mlops` | 8 | llama-cpp, segment-anything, weights-and-biases, huggingface-hub |
| `note-taking` | 1 | obsidian |
| `productivity` | 7 | airtable, maps, notion, ocr-and-documents, powerpoint |
| `research` | 5 | arxiv, blogwatcher, llm-wiki, polymarket, research-paper-writing |
| `software-development` | 9 | plan, systematic-debugging, test-driven-development, spike |

---

### `hermes/commands.md`

Hermes Agent 常用命令速查手册。

涵盖 10 大类命令：

| 分类 | 内容 |
|---|---|
| 基础操作 | 启动、退出、会话控制 |
| 配置管理 | config、model、auth |
| 工具与技能 | tools、skills 管理 |
| Gateway | 消息平台配置与管理（含钉钉接入示例） |
| 定时任务 | Cron 创建、管理、调度 |
| 会话管理 | 会话列表、导出、清理 |
| MCP 服务器 | 添加、测试、配置 MCP |
| Profile | 多配置切换与克隆 |
| 诊断与排查 | doctor、status、insights |
| 高级操作 | 语音、人格、推理力度、后台任务 |

---

## Git

### `git/.gitconfig`

Git 全局配置文件。部署至 `~/.gitconfig`。

**配置项：**

| Section | 字段 | 值 | 说明 |
|---|---|---|---|
| `safe` | `directory` | `/xxx/xxx` | 信任目录 |
| `user` | `name` / `email` | — | 提交者身份 |
| `core` | `editor` | `vim` | 默认编辑器 |
| `core` | `autocrlf` | `input` | 提交时 CRLF→LF，检出时不转换（Linux/Mac） |
| `init` | `defaultBranch` | `main` | 新仓库默认分支名 |
| `push` | `default` | `simple` | 只推送当前分支 |
| `pull` | `ff` | `only` | 仅快进合并，有分叉时报错 |
| `fetch` | `prune` | `true` | fetch 时自动清理已删除的远程分支引用 |
| `rebase` | `autoStash` | `true` | rebase 前自动 stash |
| `merge` | `conflictstyle` | `zdiff3` | 冲突显示 base 版本，三方对比 |
| `alias` | `lg` | `log --oneline --graph --all --decorate` | 可视化提交历史 |

**等效命令：**

| 命令 | 对应字段 |
|---|---|
| `git config --global core.editor "vim"` | `core.editor` |
| `git config --global core.autocrlf input` | `core.autocrlf` |
| `git config --global init.defaultBranch main` | `init.defaultBranch` |
| `git config --global push.default simple` | `push.default` |
| `git config --global pull.ff only` | `pull.ff` |
| `git config --global fetch.prune true` | `fetch.prune` |
| `git config --global rebase.autoStash true` | `rebase.autoStash` |
| `git config --global merge.conflictstyle zdiff3` | `merge.conflictstyle` |
| `git config --global alias.lg "log --oneline --graph --all --decorate"` | `alias.lg` |

---

### `git/.gitattributes`

Git 行尾规范化配置文件。部署至各仓库根目录 `.gitattributes`，配合 `git/.gitconfig` 中的 `core.autocrlf = input` 使用。

**核心规则：**

| 规则 | 覆盖文件类型 |
|---|---|
| `* text=auto` | 默认所有文本文件入库自动转 LF |
| `text` | Python（`.py/.ipynb/.pyx/.pyi/.pyw`）、Markdown、JSON、JS/TS、CSS/SCSS/LESS、HTML |
| `text eol=lf` | Shell（`.sh/.bash/.zsh`）、Lock 文件（`*.lock`） |
| `binary` | 图片（`.png/.jpg/.gif/.ico/.svg`）、压缩包（`.zip/.tar/.gz`）、二进制（`.exe/.dll/.so`） |

**工作原理：**

- `git add` 入库时：CRLF 自动转为 LF 存入仓库（`text` 规则）
- `git checkout` 出库时：由于 `core.autocrlf = input`，不再转回 CRLF，工作区保持 LF
- `git diff` 不再因行尾差异产生假变更

> **注意**：`.sh` 和 `*.lock` 文件使用 `eol=lf` 强制 LF，即使 `core.autocrlf` 设为 `true` 也不会在 checkout 时转为 CRLF。

---

### `git/.gitignore`

Git 忽略规则模板。部署至各仓库根目录 `.gitignore`，按需裁剪。

**覆盖类别：**

| 类别 | 忽略内容 |
|---|---|
| Python | 缓存（`__pycache__/`）、编译产物（`*.pyc/.pyo`）、构建输出（`dist/`、`build/`）、虚拟环境（`venv/`、`.env`） |
| 包管理器 | `.tox/`、`.nox/`、PDM（`.pdm-python/` 等）、`__pypackages__/` |
| 测试 | `.pytest_cache/`、`.coverage`、`htmlcov/`、`.mypy_cache/`、`.ruff_cache/` |
| Jupyter | `.ipynb_checkpoints/` |
| ML 模型 | PyTorch（`.pt/.pth/.ckpt`）、TensorFlow（`.tfrecord`）、ONNX（`.onnx`）、HuggingFace（`.safetensors/.bin`）、序列化（`.pkl/.pickle`） |
| Node.js | `node_modules/`、`npm-debug.log`、`yarn-error.log`、`pnpm-store/` |
| IDE / 编辑器 | `.idea/`、`.vscode/`、`*.swp`、`*.swo`、`.history`、`.devcontainer/` |
| OS | `.DS_Store`、`Thumbs.db`、`Desktop.ini`、`$RECYCLE.BIN/` |
| 临时文件 | `*.log`、`*.tmp`、`*.bak`、`*.cache`、`*.pid` |
| Docker | `.dockerignore` |
| Terraform | `.terraform/`、`*.tfstate`、`*.tfvars`、`*.tfplan` |

---

### `git/commands.md`

Git 常用命令速查手册。

涵盖 13 大类命令：

| 分类 | 内容 |
|---|---|
| 配置管理 | `git config` 全局/仓库配置 |
| 仓库操作 | `init`、`clone`、`remote` |
| 工作区与暂存区 | `add`、`restore`、`rm`、`reset` |
| 提交 | `commit`、`log`、`diff`、`blame` |
| 分支管理 | `branch`、`switch`、`checkout`、`merge`、`cherry-pick`、`stash` |
| 变基 | `rebase`、交互式 rebase 操作说明 |
| 远程协作 | `fetch`、`pull`、`push` |
| 回退与撤销 | `reset`、`revert`、`reflog`（含安全性标注） |
| 标签 | `tag` 轻量/附注标签管理 |
| 子模块 | `submodule` 添加/初始化/更新 |
| 大文件 | `lfs` 追踪与管理 |
| 二分查找 | `bisect` 定位引入 bug 的提交 |
| 工作流场景 | hotfix、squash、同步 fork、清理分支、找回误删 |

---

## Docker

提供 `docker/Dockerfile`、`docker/commands.md` 和 `docker/.dockerignore`，用于快速构建包含全部工具与配置的开发环境容器。

### `docker/Dockerfile`

Docker 镜像构建文件，基于 Ubuntu 26.04，部署至项目根目录。

**构建阶段（8 步）：**

| 阶段 | 内容 |
|---|---|
| 1. 系统包 | vim、git、curl、wget、nodejs、npm、locales |
| 2. Locale | `en_US.UTF-8` + `zh_CN.UTF-8` |
| 3. uv + Python | 安装 uv 到 `/usr/local/uv`，通过 `uv python install 3.12` 安装 Python |
| 4. 目录结构 | 创建 `~/.config/*` 和 `~/.hermes/skills` |
| 5. 配置复制 | 7 套工具配置 → 对应路径（见下方部署章节） |
| 6. OpenCode | `npm install -g @opencode/opencode` |
| 7. Hermes Agent | `uv pip install --system hermes-agent` |
| 8. 环境变量 | `EDITOR=vim`、`PYTHONUNBUFFERED=1` 等 |

**环境变量：**

| 变量 | 值 | 说明 |
|---|---|---|
| `PATH` | `/usr/local/uv/bin` 前置 | uv 命令全局可见 |
| `UV_PYTHON_INSTALL_DIR` | `/usr/local/uv/python` | Python 解释器安装目录 |
| `UV_PYTHON_BIN_DIR` | `/usr/local/bin` | Python 可执行文件软链目录 |
| `UV_TOOL_DIR` | `/usr/local/uv/tools` | uv 工具安装目录 |
| `UV_TOOL_BIN_DIR` | `/usr/local/bin` | uv 工具可执行文件软链目录 |
| `UV_LINK_MODE` | `copy` | 包安装使用 copy 模式（容器兼容性最优） |
| `EDITOR` / `VISUAL` | `vim` | 默认编辑器 |
| `PYTHONUNBUFFERED` | `1` | Python stdout 不缓冲 |

**构建与运行：**

```bash
# 在仓库根目录构建
docker build -t config-files-dev -f docker/Dockerfile .

# 交互式进入容器
docker run -it --rm config-files-dev

# 挂载本地工作目录 + 保留包缓存
docker run -it --rm -v $(pwd):/workspace -v dev-cache:/root/.cache config-files-dev
```

> **注意**：`opencode/opencode.jsonc` 和 `hermes/.env` 中的 API Key 为占位符（`xxx`），构建前需替换为真实密钥。`npm/.npmrc` 中的 `proxy`/`https-proxy` 为占位符（`proxy.xxx.com:8080`），不需要代理时请删除这两行，否则 `npm install` 会卡住。系统未安装 pip（Python 由 uv 管理）。

---

### `docker/.dockerignore`

Docker 构建上下文排除规则，加速构建并减小上下文体积。

| 排除项 | 原因 |
|---|---|
| `.git/` | Git 仓库数据 |
| `.omo/` `.codegraph/` | OpenCode 内部数据 |
| `docker/` | Dockerfile 自身 |
| `.DS_Store` `Thumbs.db` | OS 元数据文件 |
| `*.swp` `*.swo` `*~` | vim 临时文件 |

---

### `docker/commands.md`

Docker 常用命令速查手册。

涵盖 9 大类命令：

| 分类 | 内容 |
|---|---|
| 安装 | 本仓库 `docker/Dockerfile` 构建命令 |
| 构建 | `docker build` 常用参数（平台、缓存、构建参数） |
| 运行 | `docker run` 参数（端口、挂载、环境变量、资源限制） |
| 镜像管理 | `pull/push/tag/rmi/save/load` |
| 容器管理 | `ps/exec/logs/cp/inspect/stats` |
| Docker Compose | `up/down/logs/exec/restart` |
| 数据卷与网络 | `volume` 和 `network` 子命令 |
| 清理 | `prune/df` 系列，磁盘空间管理 |
| 常用工作流 | 本仓库使用、多服务开发、镜像发布、故障排查、磁盘清理 |

---

## 部署

```bash
# Vim
cp vim/.vimrc ~/.vimrc

# OpenCode
mkdir -p ~/.config/opencode
cp opencode/opencode.jsonc ~/.config/opencode/
cp opencode/oh-my-openagent.json ~/.config/opencode/
cp opencode/AGENTS.md ~/.config/opencode/
cp opencode/commands.md ~/.config/opencode/

# Pip
mkdir -p ~/.config/pip
cp pip/pip.conf ~/.config/pip/

# Git
cp git/.gitconfig ~/.gitconfig
# .gitignore 和 .gitattributes 部署至各仓库根目录，非 home 目录
# cp git/.gitignore <repo>/.gitignore
# cp git/.gitattributes <repo>/.gitattributes

# npm
cp npm/.npmrc ~/.npmrc

# uv
mkdir -p ~/.config/uv
cp uv/uv.toml ~/.config/uv/

# Hermes
mkdir -p ~/.hermes
cp hermes/config.yaml ~/.hermes/
cp hermes/.env ~/.hermes/
cp -r hermes/skills ~/.hermes/
```
