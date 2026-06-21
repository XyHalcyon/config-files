# Hermes Agent 常用命令速查

## 一、基础操作

### 启动与退出

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes` | 启动交互式会话 | `hermes` |
| `hermes chat -q "问题"` | 单次提问，非交互式 | `hermes chat -q "解释 Docker 和虚拟机的区别"` |
| `hermes -c` | 继续最近一次会话 | `hermes -c` |
| `hermes -c "名称"` | 继续指定名称的会话 | `hermes -c "debug-project"` |
| `hermes -r SESSION_ID` | 恢复指定会话 | `hermes -r 20260621_143052_a1b2` |
| `/quit` 或 `/exit` | 退出 CLI | 会话内输入 |
| `/new` 或 `/reset` | 新建会话（清空上下文） | 会话内输入 |

### 会话内斜杠命令

| 命令 | 说明 |
|---|---|
| `/new` | 新建会话 |
| `/retry` | 重新发送上条消息 |
| `/undo` | 撤销上一轮对话 |
| `/title [名称]` | 给会话命名 |
| `/compress` | 手动压缩上下文 |
| `/help` | 查看所有命令 |
| `/usage` | 查看 token 用量 |
| `/history` | 查看对话历史 |
| `/save` | 保存对话到文件 |

---

## 二、配置管理

### 查看与修改配置

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes config` | 查看当前配置 | `hermes config` |
| `hermes config edit` | 用编辑器打开 config.yaml | `hermes config edit` |
| `hermes config set KEY VAL` | 修改配置项 | `hermes config set agent.max_turns 200` |
| `hermes config path` | 打印 config.yaml 路径 | `hermes config path` |
| `hermes config env-path` | 打印 .env 路径 | `hermes config env-path` |
| `hermes config check` | 检查缺失/过时的配置 | `hermes config check` |
| `hermes config migrate` | 迁移配置到新版本 | `hermes config migrate` |

### 模型与提供商

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes model` | 交互式选择模型/提供商 | `hermes model` |
| `/model [名称]` | 会话内切换模型 | `/model anthropic/claude-sonnet-4` |
| `hermes auth` | 交互式凭据管理 | `hermes auth` |
| `hermes auth add PROVIDER` | 添加凭据 | `hermes auth add openai` |
| `hermes auth list` | 查看已存储的凭据 | `hermes auth list` |

### 常用配置示例

```
# 设置最大对话轮次
hermes config set agent.max_turns 200

# 设置推理力度 (none|minimal|low|medium|high)
hermes config set agent.reasoning_effort high

# 设置命令超时时间 (秒)
hermes config set terminal.timeout 300

# 开启/关闭上下文压缩
hermes config set compression.enabled true

# 开启/关闭持久化记忆
hermes config set memory.memory_enabled true
```

---

## 三、工具与技能

### 工具管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes tools` | 交互式工具启用/禁用 | `hermes tools` |
| `hermes tools list` | 列出所有工具及状态 | `hermes tools list` |
| `hermes tools enable NAME` | 启用工具集 | `hermes tools enable browser` |
| `hermes tools disable NAME` | 禁用工具集 | `hermes tools disable image_gen` |

### 技能管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes skills list` | 列出已安装技能 | `hermes skills list` |
| `hermes skills browse` | 浏览所有可用技能 | `hermes skills browse` |
| `hermes skills search KEYWORD` | 搜索技能 | `hermes skills search docker` |
| `hermes skills install ID` | 安装技能 | `hermes skills install obsidian` |
| `hermes skills uninstall NAME` | 卸载技能 | `hermes skills uninstall my-skill` |
| `hermes skills check` | 检查更新 | `hermes skills check` |
| `hermes skills update` | 更新过期技能 | `hermes skills update` |
| `/skill NAME` | 会话内加载技能 | `/skill systematic-debugging` |
| `/reload-skills` | 重新扫描技能目录 | `/reload-skills` |

---

## 四、Gateway (消息平台)

### 基础管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes gateway setup` | 交互式配置消息平台 | `hermes gateway setup` |
| `hermes gateway run` | 前台运行 Gateway | `hermes gateway run` |
| `hermes gateway install` | 安装为后台服务 | `hermes gateway install` |
| `hermes gateway start` | 启动后台服务 | `hermes gateway start` |
| `hermes gateway stop` | 停止后台服务 | `hermes gateway stop` |
| `hermes gateway restart` | 重启后台服务 | `hermes gateway restart` |
| `hermes gateway status` | 查看运行状态 | `hermes gateway status` |

### 钉钉接入示例

```
# 1. 配置钉钉
hermes gateway setup
# 选择 DingTalk -> Stream Mode -> 输入 AppKey/AppSecret

# 2. 在 .env 中设置白名单
# DINGTALK_ALLOWED_USERS=<你的 sender_id>

# 3. 启动 Gateway
hermes gateway install
hermes gateway start

# 4. 查看状态和日志
hermes gateway status
tail -50 ~/.hermes/logs/gateway.log
```

### Gateway 会话内命令

| 命令 | 说明 |
|---|---|
| `/approve` | 批准待执行命令 |
| `/deny` | 拒绝待执行命令 |
| `/restart` | 重启 Gateway |
| `/sethome` | 设置当前聊天为 home 频道 |
| `/platforms` | 查看平台连接状态 |

---

## 五、定时任务 (Cron)

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes cron list` | 列出所有定时任务 | `hermes cron list` |
| `hermes cron create SCHEDULE` | 创建任务 | 见下方示例 |
| `hermes cron edit ID` | 编辑任务 | `hermes cron edit job_abc123` |
| `hermes cron pause ID` | 暂停任务 | `hermes cron pause job_abc123` |
| `hermes cron resume ID` | 恢复任务 | `hermes cron resume job_abc123` |
| `hermes cron run ID` | 立即执行一次 | `hermes cron run job_abc123` |
| `hermes cron remove ID` | 删除任务 | `hermes cron remove job_abc123` |
| `hermes cron status` | 调度器状态 | `hermes cron status` |

### 定时任务示例

```
# 每 30 分钟执行一次
hermes cron create "30m" --prompt "检查服务器磁盘使用率并报告"

# 每天早上 9 点执行
hermes cron create "0 9 * * *" --prompt "生成今日工作简报"

# 每 2 小时执行一次
hermes cron create "every 2h" --prompt "汇总最近的 GitHub 通知"
```

---

## 六、会话管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes sessions list` | 列出最近会话 | `hermes sessions list` |
| `hermes sessions browse` | 交互式选择会话 | `hermes sessions browse` |
| `hermes sessions export OUT` | 导出会话到 JSONL | `hermes sessions export backup.jsonl` |
| `hermes sessions rename ID TITLE` | 重命名会话 | `hermes sessions rename abc123 "调试记录"` |
| `hermes sessions delete ID` | 删除会话 | `hermes sessions delete abc123` |
| `hermes sessions prune` | 清理过期会话 | `hermes sessions prune --older-than 30` |
| `hermes sessions stats` | 会话统计 | `hermes sessions stats` |

---

## 七、MCP 服务器

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes mcp list` | 列出 MCP 服务器 | `hermes mcp list` |
| `hermes mcp add NAME` | 添加 MCP 服务器 | `hermes mcp add my-server --url http://localhost:3000` |
| `hermes mcp remove NAME` | 移除 MCP 服务器 | `hermes mcp remove my-server` |
| `hermes mcp test NAME` | 测试连接 | `hermes mcp test my-server` |
| `hermes mcp configure NAME` | 选择启用的工具 | `hermes mcp configure my-server` |
| `/reload-mcp` | 会话内重新加载 MCP | `/reload-mcp` |

---

## 八、Profile (多配置)

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes profile list` | 列出所有 Profile | `hermes profile list` |
| `hermes profile create NAME` | 创建 Profile | `hermes profile create work` |
| `hermes profile create NAME --clone` | 从当前克隆创建 | `hermes profile create dev --clone` |
| `hermes profile use NAME` | 切换默认 Profile | `hermes profile use work` |
| `hermes profile delete NAME` | 删除 Profile | `hermes profile delete old-profile` |
| `hermes profile show NAME` | 查看详情 | `hermes profile show work` |
| `hermes -p NAME` | 以指定 Profile 启动 | `hermes -p work` |

---

## 九、诊断与排查

| 命令 | 说明 | 示例 |
|---|---|---|
| `hermes doctor` | 检查依赖和配置 | `hermes doctor` |
| `hermes doctor --fix` | 检查并自动修复 | `hermes doctor --fix` |
| `hermes status` | 组件状态总览 | `hermes status` |
| `hermes status --all` | 完整状态 | `hermes status --all` |
| `hermes insights` | 使用分析 | `hermes insights` |
| `hermes insights --days 7` | 最近 7 天分析 | `hermes insights --days 7` |
| `/debug` | 上传调试报告 | 会话内输入 `/debug` |
| `hermes update` | 更新到最新版本 | `hermes update` |

---

## 十、会话内高级操作

| 命令 | 说明 |
|---|---|
| `/personality NAME` | 设置人格 (concise/technical/creative/teacher 等) |
| `/reasoning LEVEL` | 设置推理力度 (none/minimal/low/medium/high) |
| `/verbose` | 切换详细程度 (off -> new -> all -> verbose) |
| `/voice on` | 开启语音模式 |
| `/voice tts` | 始终语音输出 |
| `/voice off` | 关闭语音 |
| `/yolo` | 跳过危险命令确认 |
| `/background PROMPT` | 后台运行任务 |
| `/queue PROMPT` | 排队下一轮执行 |
| `/steer PROMPT` | 注入消息 (不打断当前执行) |
| `/branch` | 分支当前会话 |
| `/kanban` | 查看 Kanban 看板 |
| `/curator` | 技能维护管理 |
| `/skin NAME` | 切换主题 |

---

## 关键路径速查

```
~/.hermes/config.yaml      主配置
~/.hermes/.env             API 密钥
~/.hermes/skills/          技能库
~/.hermes/sessions/        会话文件
~/.hermes/state.db         会话数据库 (SQLite)
~/.hermes/auth.json        OAuth 令牌和凭据池
~/.hermes/logs/            日志文件
```

## 文档链接

- 官方文档: https://hermes-agent.nousresearch.com/docs/
- GitHub: https://github.com/NousResearch/hermes-agent
- CLI 命令参考: https://hermes-agent.nousresearch.com/docs/reference/cli-commands
- 斜杠命令参考: https://hermes-agent.nousresearch.com/docs/reference/slash-commands
- 提供商配置: https://hermes-agent.nousresearch.com/docs/integrations/providers
- 消息平台: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/
