# Opencode 常用命令参考

> 在 Opencode 对话中直接输入命令（以 `/` 开头），或者提及命令描述中的触发词即可激活。

---

## 项目管理

### `/hyperplan` — 多智能体对抗性规划

通过团队模式（5 个敌对角色交叉评审，主代理综合）进行规划。

```
/hyperplan 为电商后台管理系统设计架构
```

### `/start-work` — 执行工作计划

从 Prometheus 生成的工作计划开始执行。

```
/start-work

# 或者加载特定计划文件
/start-work .omo/plans/user-auth-plan.md
```

### `/ulw-plan` — 探索先行规划

编码前必用：5+ 步骤、模糊范围、多模块、架构决策等场景。

```
/ulw-plan 为 REST API 添加 JWT 认证功能
/ulw-plan 重构用户管理模块，支持多租户
```

---

## 开发辅助

### `/programming` — 严格类型编程

处理 `.py` `.rs` `.ts` `.go` 文件。强制严格类型、现代技术栈、TDD。

```
/programming 用 Rust 实现一个线程安全的 LRU 缓存
/programming 在 TypeScript 中实现 Zod schema 验证
```

### `/refactor` — 智能重构

通过 LSP、AST-grep、架构分析等工具进行智能重构。

```
/refactor 将 UserService 中的验证逻辑提取到独立模块
/refactor 简化 src/utils 目录下的工具函数
```

### `/ast-grep` — AST 结构化搜索

用 AST 语法树进行代码搜索和批量修改，比正则更精确。

```
# 搜索所有 React 函数组件
/ast-grep 查找所有 export function 的 React 组件

# 批量替换模式
/ast-grep 将所有 console.log 替换为 logger.info
```

### `/lsp-setup` — LSP 配置

配置语言服务器，让编辑器提供诊断、跳转定义、查找引用等功能。

```
/lsp-setup 为 Python 项目配置 basedpyright
/lsp-setup 为 TypeScript 项目配置 LSP
```

---

## Git 操作

### `/git-master` — Git 专家操作

原子提交、变基、历史搜索（blame、bisect、log -S）。

```
/git-master 提交当前所有更改，commit message 为 "feat: add user auth"
/git-master 查找是谁添加了 src/auth.ts 第 42 行
/git-master 将最近 3 个 commit 合并为一个
```

---

## 前端开发

### `/frontend` — 前端/UI/UX

构建页面/组件、性能审计、设计 QA。自动调用设计规则、Lighthouse 审计、UI/UX 数据库。

```
/frontend 创建一个现代化的登录页面
/frontend 审计当前页面的 Lighthouse 性能
/frontend 为 Sidebar 组件添加深色模式支持
```

### `/visual-qa` — 视觉回归测试

对 Web 页面和终端 UI 进行严格的视觉 QA，截图对比。

```
/visual-qa 检查 Dashboard 页面是否有布局偏移
/visual-qa 对比首页改版前后的视觉效果
```

---

## 质量保证

### `/review-work` — 实现后审查

启动 5 个并行后台代理进行全面审查：目标验证、代码质量、安全性、手工 QA、上下文挖掘。

```
/review-work 审查刚才的用户认证模块实现
```

### `/remove-ai-slops` — 清理 AI 代码异味

移除 AI 生成代码中的 10 类常见问题：过度复杂、超长模块、冗余注释等。

```
/remove-ai-slops 清理 src/api/routes/ 下的代码
/remove-ai-slops 检查最近 3 个 commit 的更改
```

### `/security-review` — 安全审查

启动 3 个漏洞猎手 + 2 个 PoC 工程师并行审查代码库。

```
/security-review 审查 src/api/ 目录
/security-review 审计最近添加的支付模块
```

---

## 调试

### `/debugging` — 运行时调试

跨语言运行时调试：崩溃、静默失败、错误响应、死锁、内存泄漏、反向工程。

```
/debugging 为什么 Express 服务器间歇性返回 500
/debugging 定位 React 组件的无限重渲染问题
```

---

## 浏览器自动化

### `/playwright` — 浏览器自动化

通过 Playwright 进行浏览器操作：验证、信息收集、网页抓取、测试、截图。

```
/playwright 打开 https://example.com 并截图
/playwright 测试登录流程是否正常
/playwright 抓取 GitHub Trending 页面数据
```

---

## 会话管理

### `/handoff` — 上下文交接

创建详细的上下文摘要，用于在新会话中继续工作。

```
/handoff

# 输出示例：
# Session: ses_abc123 | Messages: 45 | Todo: 8/12 completed
# Current task: Implementing JWT auth middleware
# Blocked on: Waiting for Oracle review result
```

### `/stop-continuation` — 停止续作

停止当前会话的所有续作机制（ralph loop、todo continuation、boulder）。

```
/stop-continuation
```

---

## 循环模式

### `/ralph-loop` — 自引用开发循环

启动自引用开发循环直到完成。

```
/ralph-loop 完善用户认证系统的所有边缘情况
```

### `/ulw-loop` — Ultrawork 循环

启动 ultrawork 模式，持续执行直到完成。

```
/ulw-loop 完成整个购物车功能的开发
```

### `/cancel-ralph` — 取消循环

取消活跃的 Ralph Loop。

```
/cancel-ralph
```

---

## 初始化

### `/init-deep` — 初始化知识库

初始化分层 AGENTS.md 知识库。

```
/init-deep

# 在项目中生成/更新：
# - AGENTS.md（根级行为指南）
# - 各子目录的 AGENTS.md（按需）
```

---

## 触发词速查

很多命令不需要手动输入 `/`，提到以下关键词即可自动触发：

| 触发词 | 对应命令 | 说明 |
|---|---|---|
| `commit`、`rebase`、`squash`、`who wrote` | `/git-master` | Git 操作 |
| `frontend`、`UI`、`UX`、`design`、`styling` | `/frontend` | 前端开发 |
| `debug this`、`why is X not working` | `/debugging` | 调试 |
| `security review`、`vulnerability audit` | `/security-review` | 安全审查 |
| `review work`、`verify implementation` | `/review-work` | 实现审查 |
| `remove AI slops`、`clean AI code` | `/remove-ai-slops` | 清理 AI 代码 |
| `visual QA`、`screenshot diff` | `/visual-qa` | 视觉 QA |
| `refactor`、`cleanup`、`extract` | `/refactor` | 重构 |
| `LSP`、`language server`、`语言服务器` | `/lsp-setup` | LSP 配置 |
| `plan this`、`make a plan`、`规划` | `/ulw-plan` | 规划 |

---

## 工作流示例

### 典型新功能开发流程

```
# 1. 规划
/ulw-plan 为博客系统添加评论功能

# 2. 开始执行计划
/start-work

# 3. 实现完成后审查
/review-work

# 4. 清理 AI 代码异味
/remove-ai-slops
```

### 调试修复流程

```
# 1. 描述问题
/debugging 用户登录后 Token 过期不自动刷新

# 2. 修复后验证
/git-master 提交修复

# 3. 审查
/review-work
```

### 前端页面开发流程

```
# 1. 创建页面
/frontend 创建设置页面，包含个人信息和通知偏好

# 2. 视觉验证
/visual-qa 检查设置页面在不同分辨率下的布局

# 3. 性能审计
/frontend 审计设置页面的 Lighthouse 性能
```
