# Opencode 常用命令速查

## 一、基础操作

### 启动与运行

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode` | 启动交互式 TUI 会话 | `opencode` |
| `opencode [project]` | 在指定目录启动 | `opencode ~/my-project` |
| `opencode run "消息"` | 单次非交互式执行 | `opencode run "解释这段代码"` |
| `opencode run -c "消息"` | 继续最近会话并执行 | `opencode run -c "继续上次的任务"` |
| `opencode -c` | 在 TUI 中继续最近会话 | `opencode -c` |
| `opencode -s SESSION_ID` | 恢复指定会话 | `opencode -s abc123def` |
| `opencode --fork -c` | Fork 最近会话（分支新会话） | `opencode --fork -c` |
| `opencode -m provider/model` | 指定模型启动 | `opencode -m codiz/claude-opus-4-7` |
| `opencode --agent NAME` | 指定 Agent 启动 | `opencode --agent sisyphus` |
| `opencode --prompt "提示"` | 带初始提示启动 | `opencode --prompt "你是安全专家"` |

### Server 模式

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode serve` | 启动 Headless 服务 | `opencode serve --port 4096` |
| `opencode web` | 启动服务并打开 Web 界面 | `opencode web` |
| `opencode attach <url>` | 连接到运行中的服务 | `opencode attach http://localhost:4096` |
| `opencode acp` | 启动 ACP (Agent Client Protocol) 服务 | `opencode acp` |

### 全局选项

| 选项 | 说明 | 示例 |
|---|---|---|
| `-m, --model` | 指定模型 (provider/model) | `opencode -m deepseek/deepseek-v4-pro` |
| `-c, --continue` | 继续最近会话 | `opencode -c` |
| `-s, --session` | 指定会话 ID | `opencode -s abc123` |
| `-h, --help` | 显示帮助 | `opencode --help` |
| `-v, --version` | 显示版本号 | `opencode -v` |
| `--log-level` | 日志级别 (DEBUG/INFO/WARN/ERROR) | `opencode --log-level DEBUG` |
| `--pure` | 无插件模式运行 | `opencode --pure` |
| `--print-logs` | 日志输出到 stderr | `opencode --print-logs` |

---

## 二、会话管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode session list` | 列出所有会话 | `opencode session list` |
| `opencode session delete <ID>` | 删除指定会话 | `opencode session delete abc123def` |
| `opencode export [sessionID]` | 导出会话为 JSON | `opencode export abc123def > backup.json` |
| `opencode export --sanitize <ID>` | 导出并脱敏敏感信息 | `opencode export --sanitize abc123def` |
| `opencode import <file>` | 从 JSON 文件导入会话 | `opencode import backup.json` |
| `opencode import <url>` | 从 URL 导入会话 | `opencode import https://example.com/session.json` |
| `opencode stats` | 查看 Token 用量和费用统计 | `opencode stats` |
| `opencode -c` | 在 TUI 中继续最近会话 | `opencode -c` |
| `opencode --fork -c` | Fork 最近会话 | `opencode --fork -c` |

### run 子命令选项

| 选项 | 说明 | 示例 |
|---|---|---|
| `-f, --file` | 附带文件到消息 | `opencode run "review" -f src/main.ts` |
| `--title` | 设置会话标题 | `opencode run "debug" --title "Auth Fix"` |
| `--format json` | JSON 格式输出 | `opencode run "hello" --format json` |
| `--share` | 分享会话 | `opencode run -c --share` |
| `-i, --interactive` | 交互式分屏模式 | `opencode run "help" -i` |
| `--thinking` | 显示思考过程 | `opencode run "复杂问题" --thinking` |
| `--variant` | 模型推理力度 (high/max/minimal) | `opencode run "..." --variant high` |
| `--command` | 指定 slash 命令 | `opencode run --command /git-master "commit"` |

---

## 三、Provider 与模型

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode providers list` | 列出已配置的 Provider | `opencode providers list` |
| `opencode providers login [url]` | 登录 Provider | `opencode providers login` |
| `opencode providers logout [provider]` | 登出 Provider | `opencode providers logout codiz` |
| `opencode models [provider]` | 列出所有可用模型 | `opencode models` |
| `opencode models codiz` | 列出指定 Provider 的模型 | `opencode models codiz` |

### Provider 配置示例

在 `~/.config/opencode/opencode.jsonc` 中：

```jsonc
{
  "provider": {
    "codiz": {
      "npm": "@ai-sdk/anthropic",
      "name": "Codiz",
      "options": {
        "baseURL": "https://codiz.dev/v1",
        "apiKey": "your-api-key"
      },
      "models": {
        "claude-opus-4-7": { "name": "claude-opus-4-7" },
        "claude-opus-4-7-thinking": { "name": "claude-opus-4-7-thinking" }
      }
    }
  }
}
```

---

## 四、MCP 服务器

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode mcp list` | 列出 MCP 服务器及状态 | `opencode mcp list` |
| `opencode mcp add [name]` | 添加 MCP 服务器 | 见下方示例 |
| `opencode mcp auth [name]` | OAuth 认证 | `opencode mcp auth github` |
| `opencode mcp logout [name]` | 移除 OAuth 凭据 | `opencode mcp logout github` |
| `opencode mcp debug <name>` | 调试 OAuth 连接 | `opencode mcp debug github` |

### 添加 MCP 服务器示例

```
# 添加远程 MCP 服务器
opencode mcp add my-server --url http://localhost:3000

# 添加带环境变量的本地 MCP 服务器
opencode mcp add playwright --env PLAYWRIGHT_BROWSER=chromium

# 添加带 HTTP Header 的远程服务器
opencode mcp add api --url https://api.example.com --header "Authorization: Bearer token"
```

---

## 五、Agent 管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode agent list` | 列出所有 Agent | `opencode agent list` |
| `opencode agent create` | 创建新 Agent | `opencode agent create` |
| `opencode debug agent <name>` | 查看 Agent 配置详情 | `opencode debug agent sisyphus` |

### Agent 与 Category 对照

| Agent | 用途 | Category | 用途 |
|---|---|---|---|
| `sisyphus` | 主编排器 | `ultrabrain` | 高难度逻辑/架构 |
| `hephaestus` | 构建器 | `deep` | 自主研究+实现 |
| `prometheus` | 规划器 | `visual-engineering` | 前端/UI/样式 |
| `oracle` | 高 IQ 推理顾问 | `quick` | 简单单文件修改 |
| `explore` / `librarian` | 代码搜索 | `artistry` | 创意方案 |
| `metis` / `momus` | 规划/审查 | `writing` | 文档/写作 |

---

## 六、Plugin 插件

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode plugin <module>` | 安装插件并更新配置 | `opencode plugin oh-my-openagent` |

---

## 七、GitHub 集成

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode github install` | 安装 GitHub Agent | `opencode github install` |
| `opencode github run` | 运行 GitHub Agent | `opencode github run` |
| `opencode pr <number>` | 拉取 PR 分支并运行 | `opencode pr 42` |

---

## 八、诊断与调试

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode debug config` | 显示解析后的完整配置 | `opencode debug config` |
| `opencode debug paths` | 显示全局路径 | `opencode debug paths` |
| `opencode debug lsp` | LSP 调试工具 | `opencode debug lsp` |
| `opencode debug skill` | 列出所有可用 Skill | `opencode debug skill` |
| `opencode debug agent <name>` | 查看 Agent 配置详情 | `opencode debug agent oracle` |
| `opencode debug info` | 显示调试信息 | `opencode debug info` |
| `opencode debug startup` | 打印启动耗时 | `opencode debug startup` |
| `opencode stats` | Token 用量和费用统计 | `opencode stats` |

### 升级与卸载

| 命令 | 说明 | 示例 |
|---|---|---|
| `opencode upgrade` | 升级到最新版本 | `opencode upgrade` |
| `opencode upgrade [target]` | 升级到指定版本 | `opencode upgrade 1.0.0` |
| `opencode uninstall` | 卸载并清除所有文件 | `opencode uninstall` |

---

## 九、会话内 Slash 命令

> 在 TUI 交互式会话中，输入 `/` 开头触发。

### 代码开发

| 命令 | 说明 | 示例 |
|---|---|---|
| `/frontend` | 前端/UI/UX/设计开发 | `/frontend 创建 Dashboard 页面` |
| `/programming` | 严格类型编程 (.py/.rs/.ts/.go) | `/programming 实现 LRU 缓存` |
| `/refactor` | 智能重构 | `/refactor 提取验证逻辑` |
| `/ast-grep` | AST 结构化搜索与批量修改 | `/ast-grep 替换 console.log` |
| `/lsp-setup` | 配置 Language Server | `/lsp-setup 配置 Python LSP` |

### Git 操作

| 命令 | 说明 | 示例 |
|---|---|---|
| `/git-master` | Git 原子提交/变基/历史搜索 | `/git-master 提交当前更改` |

### 质量保证

| 命令 | 说明 | 示例 |
|---|---|---|
| `/review-work` | 启动 5 路并行审查 | `/review-work` |
| `/remove-ai-slops` | 清理 AI 代码异味 | `/remove-ai-slops` |
| `/security-review` | 安全审查（3 漏洞猎手 + 2 PoC） | `/security-review 审查 src/api/` |
| `/visual-qa` | 视觉回归测试 | `/visual-qa 检查页面布局` |

### 调试

| 命令 | 说明 | 示例 |
|---|---|---|
| `/debugging` | 运行时交叉调试 | `/debugging 定位内存泄漏` |
| `/playwright` | 浏览器自动化 | `/playwright 截图 example.com` |

### 规划与执行

| 命令 | 说明 | 示例 |
|---|---|---|
| `/ulw-plan` | 探索先行规划 | `/ulw-plan 实现 JWT 认证` |
| `/hyperplan` | 多智能体对抗性规划 | `/hyperplan 设计微服务架构` |
| `/start-work` | 执行工作计划 | `/start-work .omo/plans/auth.md` |
| `/init-deep` | 初始化 AGENTS.md 知识库 | `/init-deep` |

### 会话控制

| 命令 | 说明 |
|---|---|
| `/handoff` | 创建上下文摘要用于新会话 |
| `/stop-continuation` | 停止所有续作机制 |
| `/ralph-loop` | 启动自引用开发循环 |
| `/ulw-loop` | 启动 Ultrawork 循环 |
| `/cancel-ralph` | 取消活跃循环 |

---

## 十、触发词速查

> 无需手动输入 `/`，对话中提及以下关键词即可自动触发。

| 触发词 | 对应命令 | 说明 |
|---|---|---|
| `commit`、`rebase`、`squash`、`who wrote` | `/git-master` | Git 操作 |
| `frontend`、`UI`、`UX`、`design`、`styling` | `/frontend` | 前端开发 |
| `debug this`、`why is X not working` | `/debugging` | 调试 |
| `security review`、`vulnerability audit` | `/security-review` | 安全审查 |
| `review work`、`verify implementation` | `/review-work` | 实现审查 |
| `remove AI slops`、`clean AI code` | `/remove-ai-slops` | 清理 AI 代码 |
| `visual QA`、`screenshot diff` | `/visual-qa` | 视觉 QA |
| `refactor`、`cleanup`、`restructure` | `/refactor` | 重构 |
| `LSP`、`language server`、`语言服务器` | `/lsp-setup` | LSP 配置 |
| `plan this`、`make a plan`、`break this down` | `/ulw-plan` | 规划 |

---

## 十一、常用工作流

### 新功能开发

```
# 1. 规划
/ulw-plan 为博客系统添加评论功能

# 2. 执行计划
/start-work

# 3. 审查
/review-work

# 4. 清理
/remove-ai-slops
```

### 调试修复

```
# 1. 定位问题
/debugging Token 过期后不自动刷新

# 2. 提交修复
/git-master 提交修复并推送

# 3. 审查
/review-work
```

### 前端页面开发

```
# 1. 创建页面
/frontend 创建设置页面（个人信息 + 通知偏好）

# 2. 视觉验证
/visual-qa 检查设置页面多分辨率布局

# 3. 性能审计
/frontend 审计设置页面 Lighthouse 性能
```

### CLI 单次执行

```
# 快速问答
opencode run "什么是 Rust 的所有权系统？"

# 带文件审查
opencode run "review this code" -f src/main.ts

# 指定模型
opencode run "解释量子计算" -m codiz/claude-opus-4-7-thinking

# 继续上次会话
opencode run -c "继续实现剩余的接口"
```

---

## 关键路径速查

```
~/.config/opencode/opencode.jsonc          主配置文件
~/.config/opencode/oh-my-openagent.json    Agent/Category 模型分配
~/.config/opencode/AGENTS.md               行为指南
~/.local/share/opencode/                   会话数据 (SQLite)
~/.cache/opencode/                         缓存文件
~/.local/state/opencode/                   状态文件
```

## 文档链接

- 官方仓库: https://github.com/anthropics/opencode
- CLI 命令参考: `opencode --help`
- 子命令帮助: `opencode <command> --help`
- Agent 配置: https://github.com/code-yeongyu/oh-my-openagent
