# Git 常用命令速查

## 一、配置管理

| 命令 | 说明 |
|---|---|
| `git config --global user.name "Your Name"` | 设置全局用户名 |
| `git config --global user.email "your@email.com"` | 设置全局邮箱 |
| `git config --global --list` | 查看当前全局配置 |
| `git config --list` | 查看当前仓库配置（含全局） |
| `git config --global --edit` | 编辑全局配置文件 |
| `git config --edit` | 编辑当前仓库配置文件 |

配置文件位置：

| 级别 | 路径 | 作用域 |
|---|---|---|
| 系统 | `/etc/gitconfig` | 所有用户 |
| 全局 | `~/.gitconfig` | 当前用户 |
| 仓库 | `.git/config` | 当前仓库 |

优先级：仓库 > 全局 > 系统

---

## 二、仓库操作

| 命令 | 说明 | 示例 |
|---|---|---|
| `git init` | 初始化新仓库 | `git init my-project` |
| `git clone <url>` | 克隆远程仓库 | `git clone git@github.com:user/repo.git` |
| `git clone -b <branch> <url>` | 克隆指定分支 | `git clone -b develop <url>` |
| `git clone --depth 1 <url>` | 浅克隆（只拉最新一次提交） | `git clone --depth 1 <url>` |
| `git remote -v` | 查看远程仓库地址 | `git remote -v` |
| `git remote add <name> <url>` | 添加远程仓库 | `git remote add upstream <url>` |

---

## 三、工作区与暂存区

| 命令 | 说明 |
|---|---|
| `git status` | 查看当前状态（已修改/已暂存/未跟踪） |
| `git status -s` | 简短格式输出 |
| `git add <file>` | 将文件加入暂存区 |
| `git add .` | 暂存当前目录所有变更 |
| `git add -A` | 暂存所有变更（含删除） |
| `git add -p` | 交互式选择暂存（逐块确认） |
| `git rm <file>` | 删除文件并暂存 |
| `git rm --cached <file>` | 从暂存区移除，保留工作区文件 |
| `git mv <old> <new>` | 移动/重命名文件并暂存 |
| `git restore <file>` | 撤销工作区修改（回到暂存区状态） |
| `git restore --staged <file>` | 从暂存区撤销（保留工作区修改） |
| `git checkout -- <file>` | 旧版：撤销工作区修改 |
| `git reset HEAD <file>` | 旧版：从暂存区撤销 |

---

## 四、提交

| 命令 | 说明 |
|---|---|
| `git commit -m "message"` | 提交暂存的变更 |
| `git commit -am "message"` | 跳过 `git add`，直接提交已跟踪文件的修改 |
| `git commit --amend` | 修改最近一次提交（提交信息或补充文件） |
| `git commit --amend --no-edit` | 追加文件到最近提交，不修改提交信息 |
| `git commit --allow-empty -m "msg"` | 创建空提交（触发 CI 等场景） |
| `git log` | 查看提交历史 |
| `git log --oneline` | 单行显示提交历史 |
| `git log --oneline --graph --all` | 可视化分支图 |
| `git log --author="name"` | 按作者筛选 |
| `git log --since="2025-01-01"` | 按时间筛选 |
| `git log -p` | 显示每次提交的 diff |
| `git log -S "keyword"` | 搜索提交内容变更中包含关键词的提交 |
| `git show <commit>` | 查看某次提交的详细信息 |
| `git show HEAD` | 查看最近一次提交 |
| `git diff` | 工作区与暂存区的差异 |
| `git diff --staged` | 暂存区与最近提交的差异 |
| `git diff HEAD` | 工作区与最近提交的差异 |
| `git diff <branch1>..<branch2>` | 两个分支的差异 |
| `git blame <file>` | 查看文件每行的修改者和提交信息 |
| `git blame -L 10,20 <file>` | 只看指定行范围 |

---

## 五、分支管理

| 命令 | 说明 |
|---|---|
| `git branch` | 列出本地分支 |
| `git branch -r` | 列出远程分支 |
| `git branch -a` | 列出所有分支（本地 + 远程） |
| `git branch <name>` | 创建分支（不切换） |
| `git branch -d <name>` | 删除已合并的分支 |
| `git branch -D <name>` | 强制删除分支（即使未合并） |
| `git branch -m <new-name>` | 重命名当前分支 |
| `git switch <branch>` | 切换到已有分支（Git 2.23+） |
| `git switch -c <branch>` | 创建并切换到新分支（Git 2.23+） |
| `git checkout <branch>` | 切换到已有分支 |
| `git checkout -b <branch>` | 创建并切换到新分支 |
| `git checkout -b <branch> origin/<branch>` | 基于远程分支创建本地分支 |
| `git merge <branch>` | 将指定分支合并到当前分支 |
| `git merge --no-ff <branch>` | 禁用快进合并（保留分支历史） |
| `git merge --abort` | 取消合并 |
| `git merge --squash <branch>` | 压合合并（合并为一个提交，不自动 commit） |
| `git cherry-pick <commit>` | 将某次提交应用到当前分支 |
| `git cherry-pick <A>..<B>` | 批量 cherry-pick（不含 A） |
| `git cherry-pick --abort` | 取消 cherry-pick |
| `git stash` | 暂存当前修改 |
| `git stash save "message"` | 带说明暂存 |
| `git stash list` | 查看暂存列表 |
| `git stash pop` | 恢复最近暂存并删除记录 |
| `git stash apply` | 恢复最近暂存（保留记录） |
| `git stash drop stash@{n}` | 删除指定暂存 |
| `git stash clear` | 清空所有暂存 |

---

## 六、变基（Rebase）

| 命令 | 说明 |
|---|---|
| `git rebase <branch>` | 将当前分支变基到指定分支上 |
| `git rebase -i HEAD~n` | 交互式变基最近 n 次提交（squash/fixup/reword 等） |
| `git rebase --continue` | 解决冲突后继续 |
| `git rebase --skip` | 跳过当前冲突提交 |
| `git rebase --abort` | 取消变基，恢复原状 |
| `git rebase --onto <newbase> <from> <to>` | 将 `<from>..<to>` 的提交变基到 `<newbase>` |

**交互式 rebase 常用操作（`git rebase -i` 进入编辑）：**

| 操作 | 说明 |
|---|---|
| `pick` | 保留该提交 |
| `squash` / `s` | 合并到上一个提交，保留提交信息 |
| `fixup` / `f` | 合并到上一个提交，丢弃提交信息 |
| `reword` / `r` | 仅修改提交信息 |
| `edit` / `e` | 暂停以修改提交内容 |
| `drop` / `d` | 删除该提交 |

---

## 七、远程协作

| 命令 | 说明 |
|---|---|
| `git fetch` | 拉取远程所有更新（不合并） |
| `git fetch origin <branch>` | 拉取远程指定分支 |
| `git pull` | 拉取并合并（`fetch + merge`） |
| `git pull --rebase` | 拉取并变基（`fetch + rebase`） |
| `git push` | 推送当前分支 |
| `git push -u origin <branch>` | 推送并设置上游跟踪分支 |
| `git push --force-with-lease` | 安全强制推送（远端有他人提交会拒绝） |
| `git push origin --delete <branch>` | 删除远程分支 |
| `git fetch --prune` | 拉取并清理远程已删除的本地引用 |
| `git remote prune origin` | 清理远程已不存在的本地引用 |
| `git push origin <tag>` | 推送单个标签 |
| `git push origin --tags` | 推送所有标签 |

---

## 八、回退与撤销

| 命令 | 说明 | 安全性 |
|---|---|---|
| `git restore <file>` | 撤销工作区修改 | ✅ 安全 |
| `git restore --staged <file>` | 取消暂存 | ✅ 安全 |
| `git reset --soft HEAD~1` | 撤销最近提交，改动回到暂存区 | ✅ 安全 |
| `git reset --mixed HEAD~1` | 撤销最近提交，改动回到工作区（默认） | ✅ 安全 |
| `git reset --hard HEAD~1` | 撤销最近提交，**丢弃所有改动** | ⚠️ 危险 |
| `git revert <commit>` | 创建新提交来撤销指定提交 | ✅ 安全（推荐） |
| `git revert -m 1 <merge-commit>` | 撤销合并提交（保留主线） | ✅ 安全 |
| `git reset --hard origin/main` | 强制同步到远端状态 | ⚠️ 危险 |
| `git reflog` | 查看所有引用变更记录（救命工具） | 📋 参考 |
| `git reset --hard HEAD@{n}` | 通过 reflog 恢复到之前状态 | 🔧 恢复 |

---

## 九、标签（Tag）

| 命令 | 说明 |
|---|---|
| `git tag` | 列出所有标签 |
| `git tag -l "v2.*"` | 通配符过滤 |
| `git tag v1.0.0` | 创建轻量标签 |
| `git tag -a v1.0.0 -m "message"` | 创建附注标签（含信息） |
| `git tag -d v1.0.0` | 删除本地标签 |
| `git push origin --delete v1.0.0` | 删除远程标签 |
| `git checkout v1.0.0` | 切换到标签（detached HEAD） |
| `git show v1.0.0` | 查看标签详情 |

---

## 十、子模块（Submodule）

| 命令 | 说明 |
|---|---|
| `git submodule add <url> <path>` | 添加子模块 |
| `git clone --recurse-submodules <url>` | 克隆时同时初始化子模块 |
| `git submodule init` | 初始化子模块 |
| `git submodule update` | 更新子模块到记录的版本 |
| `git submodule update --init --recursive` | 初始化并递归更新所有子模块 |
| `git submodule update --remote` | 更新子模块到远程最新版本 |
| `git submodule foreach git pull` | 对所有子模块执行命令 |
| `git submodule deinit <path>` | 取消子模块初始化 |
| `git rm <path>` | 删除子模块 |

---

## 十一、大文件 / LFS

| 命令 | 说明 |
|---|---|
| `git lfs track "*.zip"` | 追踪指定类型的大文件 |
| `git lfs track "*.{mp4,psd,pdf}"` | 追踪多种类型 |
| `git lfs ls-files` | 查看已追踪的 LFS 文件 |
| `git lfs migrate` | 将历史中已有的大文件迁移到 LFS |

---

## 十二、二分查找（Bisect）

| 命令 | 说明 |
|---|---|
| `git bisect start` | 开始二分查找 |
| `git bisect bad` | 标记当前提交为"有问题" |
| `git bisect good <commit>` | 标记某次提交为"没问题" |
| `git bisect good` | 标记当前提交为"没问题" |
| `git bisect bad` | 标记当前提交为"有问题" |
| `git bisect run <script>` | 自动二分查找（脚本返回 0=good） |
| `git bisect reset` | 结束二分查找，回到原始 HEAD |

---

## 十三、工作流场景

### 修复紧急 Bug（基于 main 创建 hotfix）

```bash
git switch main
git pull
git switch -c hotfix/critical-bug
# ... 修复并提交 ...
git push -u origin hotfix/critical-bug
# 合并后删除本地分支
git switch main
git pull
git branch -d hotfix/critical-bug
```

### 将提交压缩为一条（squash）

```bash
git rebase -i HEAD~3     # 对最近 3 次提交操作
# 将第 2、3 行的 pick 改为 squash 或 fixup
# :wq 退出后编辑合并后的提交信息
git push --force-with-lease
```

### 同步 Fork 仓库（添加上游）

```bash
git remote add upstream <原仓库地址>
git fetch upstream
git switch main
git merge upstream/main
git push origin main
```

### 修改最近一次提交的作者

```bash
git commit --amend --author="Name <email>"
```

### 清理已合并的本地分支

```bash
git branch --merged | grep -v "\*\|main\|master" | xargs -r git branch -d
```

### 找回误删的分支或提交

```bash
git reflog                          # 找到之前的 HEAD 位置
git checkout -b recovered-branch HEAD@{2}
```

---

## 关键路径速查

```
~/.gitconfig         全局配置文件
.git/config          当前仓库配置文件
.git/hooks/          Git 钩子脚本目录
.git/refs/           分支和标签引用
.git/objects/        提交对象、树对象、blob 对象存储
.git/logs/           引用日志（reflog 数据源）
.gitattributes       路径属性配置（换行符、LFS 等）
.gitignore           忽略文件规则
```

## 文档链接

- 官方文档: https://git-scm.com/doc
- Pro Git 中文版: https://git-scm.com/book/zh/v2
- GitHub Git 指南: https://github.com/git-guides
- 交互式学习: https://learngitbranching.js.org/
