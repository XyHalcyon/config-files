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
```
