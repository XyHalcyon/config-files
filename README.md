# config-files

Personal dotfiles and configuration files.

## Files

### `vim/.vimrc`

Vim editor configuration. Deploy to `~/.vimrc`.

**Sections:**

| Section | Key Settings |
|---|---|
| 全局配置 (Global) | `nocompatible`, `history=1000`, `mouse=a`, `autoread` |
| 字体和颜色 (Font/Color) | `syntax enable`, `cursorline`, `guifont=Courier_New` |
| 代码折叠 (Folding) | `foldenable`, `foldmethod=manual`, `foldclose=all` |
| 文字处理 (Text) | `expandtab`, `tabstop=4`, `shiftwidth=4`, `autoindent` |
| Vim 界面 (UI) | `number`, `ruler`, `wildmenu`, `hlsearch`, `incsearch` |
| 编码设置 (Encoding) | `encoding=utf-8`, `langmenu=zh_CN.UTF-8` |
| 其他 (Other) | `laststatus=2`, `clipboard+=unnamed`, `nobackup` |

**Auto-header**: Automatically inserts author/timestamp/description header when creating new `.py` or `.sh` files.

---

### `opencode/opencode.jsonc`

OpenCode main configuration. Deploy to `~/.config/opencode/opencode.jsonc`.

- **Provider**: Codiz (Anthropic-compatible API via `@ai-sdk/anthropic`) at `https://codiz.dev/v1`
- **Plugin**: `oh-my-openagent` for agent orchestration
- **Permissions**: `*` → `allow` (all tool calls permitted)
- **Models**: `claude-opus-4-7` and `claude-opus-4-7-thinking`

> **Note**: The `apiKey` field contains a placeholder (`xxx`). Replace it with your actual Codiz API key.

---

### `opencode/oh-my-openagent.json`

Agent and category model assignments for the Sisyphus orchestration system. Deploy to `~/.config/opencode/oh-my-openagent.json`.

**Agents** — each agent is assigned a primary model and fallback:

| Agent | Primary Model | Role |
|---|---|---|
| `sisyphus` | `deepseek/deepseek-v4-pro` | Main orchestrator |
| `hephaestus` | `codiz/claude-opus-4-7-thinking` | Builder |
| `prometheus` | `codiz/claude-opus-4-7-thinking` | Planner |
| `oracle` | `codiz/claude-opus-4-7-thinking` | High-IQ reasoning consultant |
| `explore` / `librarian` | `deepseek/deepseek-v4-flash` | Contextual / reference grep |
| `metis` / `momus` / `atlas` | `alibaba-cn/qwen-3.7-max` | Planning / review |

**Categories** — task-type to model mapping:

| Category | Primary Model | Use Case |
|---|---|---|
| `ultrabrain` | `codiz/claude-opus-4-7-thinking` | Hard logic / architecture |
| `deep` | `codiz/claude-opus-4-7` | Autonomous research + implementation |
| `visual-engineering` | `codiz/claude-opus-4-7` | Frontend / UI / styling |
| `quick` | `deepseek/deepseek-v4-flash` | Trivial single-file changes |
| `writing` | `codiz/claude-opus-4-7` | Documentation / prose |

---

### `opencode/AGENTS.md`

Behavioral guidelines for LLM coding assistants. Deploy to `~/.config/opencode/AGENTS.md`.

Designed to reduce common LLM coding mistakes through four principles:

| Principle | Description |
|---|---|
| Think Before Coding | State assumptions, surface tradeoffs, ask when uncertain |
| Simplicity First | Minimum code that solves the problem, nothing speculative |
| Surgical Changes | Touch only what you must, match existing style |
| Goal-Driven Execution | Define success criteria, loop until verified |

> **Note**: These guidelines bias toward caution over speed. For trivial tasks, use judgment.
>
> **Source**: Adapted from [multica-ai/andrej-karpathy-skills/CLAUDE.md](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md).

---

### `pip/pip.conf`

Pip 包管理器的国内镜像源配置。部署至 `~/.config/pip/pip.conf`。

| 字段 | 值 | 说明 |
|---|---|---|
| `index-url` | `http://mirrors.aliyun.com/pypi/simple/` | 使用阿里云 PyPI 镜像加速下载 |
| `trusted-host` | `mirrors.aliyun.com` | 信任 HTTP 镜像源（非 HTTPS） |

---

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

> **Warning**: 包含敏感凭据，请勿上传至公开仓库。

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

## Deploy

```bash
# Vim
cp vim/.vimrc ~/.vimrc

# OpenCode
mkdir -p ~/.config/opencode
cp opencode/opencode.jsonc ~/.config/opencode/
cp opencode/oh-my-openagent.json ~/.config/opencode/
cp opencode/AGENTS.md ~/.config/opencode/

# Pip
mkdir -p ~/.config/pip
cp pip/pip.conf ~/.config/pip/

# Hermes
mkdir -p ~/.hermes
cp hermes/config.yaml ~/.hermes/
cp hermes/.env ~/.hermes/
cp -r hermes/skills ~/.hermes/
```
