# uv 常用命令速查

## 一、安装

| 命令 | 说明 |
|---|---|
| `curl -LsSf https://astral.sh/uv/install.sh \| env UV_INSTALL_DIR="/usr/local/uv" sh` | 安装 uv 到 `/usr/local/uv` |
| `uv self update` | 更新 uv 到最新版本 |
| `uv version` | 查看当前版本 |

安装后需将 `/usr/local/uv` 加入 `PATH`：

```bash
export PATH="/usr/local/uv:$PATH"
```

---

## 二、环境变量

> 在 `~/.bashrc` 或 `~/.zshrc` 中设置，控制 uv 的各类目录行为。

| 变量 | 说明 | 示例 |
|---|---|---|
| `UV_CACHE_DIR` | 包缓存目录 | `export UV_CACHE_DIR="/tmp/uv/cache"` |
| `UV_TOOL_DIR` | 工具安装目录（`uv tool install` 的输出路径） | `export UV_TOOL_DIR="/usr/local/uv/tools"` |
| `UV_PYTHON_INSTALL_DIR` | Python 解释器安装目录（`uv python install` 的输出路径） | `export UV_PYTHON_INSTALL_DIR="/usr/local/uv/python"` |
| `UV_PYTHON_BIN_DIR` | Python 可执行文件 symlink 目录（默认 `~/.local/bin`） | `export UV_PYTHON_BIN_DIR="/usr/local/bin"` |
| `UV_TOOL_BIN_DIR` | 工具可执行文件 symlink 目录（默认 `~/.local/bin`） | `export UV_TOOL_BIN_DIR="/usr/local/bin"` |
| `UV_INDEX_URL` | 默认 PyPI 索引 URL | `export UV_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/pypi/simple"` |
| `UV_LINK_MODE` | 包链接模式（`clone` / `copy` / `hardlink` / `symlink`） | `export UV_LINK_MODE=copy` |
| `UV_NO_SYNC` | 跳过自动同步（`1` = 禁用） | `export UV_NO_SYNC=1` |

---

## 三、Python 管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv python install 3.12` | 安装指定版本的 CPython | `uv python install 3.12` |
| `uv python install 3.10 3.11 3.12` | 同时安装多个版本 | `uv python install 3.10 3.11 3.12` |
| `uv python install pypy@3.10` | 安装 PyPy | `uv python install pypy@3.10` |
| `uv python list` | 列出已安装的 Python 版本 | `uv python list` |
| `uv python find 3.12` | 查找指定 Python 路径 | `uv python find 3.12` |
| `uv python pin 3.12` | 为当前项目固定 Python 版本 | `uv python pin 3.12` |
| `uv python uninstall 3.10` | 卸载指定版本 | `uv python uninstall 3.10` |
| `uv python dir` | 打印 Python 安装根目录 | `uv python dir` |

---

## 四、项目管理

### 创建与初始化

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv init` | 在当前目录初始化项目 | `uv init` |
| `uv init my-project` | 在新目录中初始化项目 | `uv init my-project` |
| `uv init --lib` | 初始化库项目（非应用） | `uv init --lib` |
| `uv init --app` | 初始化应用项目 | `uv init --app` |
| `uv init --python 3.12` | 指定 Python 版本初始化 | `uv init --python 3.12` |

### 依赖管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv add requests` | 添加依赖 | `uv add requests` |
| `uv add --dev pytest` | 添加开发依赖 | `uv add --dev pytest ruff` |
| `uv add --optional redis` | 添加可选依赖 | `uv add --optional server redis` |
| `uv add "django>=5.0"` | 添加带版本约束的依赖 | `uv add "django>=5.0"` |
| `uv remove requests` | 移除依赖 | `uv remove requests` |
| `uv sync` | 同步项目依赖（安装 lock 文件中所有包） | `uv sync` |
| `uv sync --no-dev` | 只同步生产依赖 | `uv sync --no-dev` |
| `uv lock` | 更新 lock 文件 | `uv lock` |
| `uv lock --upgrade` | 升级所有依赖后更新 lock | `uv lock --upgrade` |
| `uv lock --upgrade-package django` | 只升级指定包 | `uv lock --upgrade-package django` |
| `uv tree` | 查看依赖树 | `uv tree` |
| `uv tree --depth 2` | 限制依赖树深度 | `uv tree --depth 2` |
| `uv tree --invert` | 反向依赖树（谁依赖了这个包） | `uv tree --invert` |

### 运行

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv run python` | 在项目环境中运行 Python | `uv run python` |
| `uv run python script.py` | 运行脚本 | `uv run python script.py` |
| `uv run pytest` | 运行项目中的工具 | `uv run pytest` |
| `uv run --python 3.11 pytest` | 指定 Python 版本运行 | `uv run --python 3.11 pytest` |
| `uv run --no-project python` | 不关联项目运行 | `uv run --no-project python` |

### 构建与发布

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv build` | 构建发布包（wheel + sdist） | `uv build` |
| `uv publish` | 发布到 PyPI | `uv publish` |
| `uv publish --token $PYPI_TOKEN` | 使用 Token 发布 | `uv publish --token $PYPI_TOKEN` |

---

## 五、工具管理

> `uv tool` 用于安装和管理全局 Python 工具（类似 `pipx`）。

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv tool install ruff` | 安装全局工具 | `uv tool install ruff` |
| `uv tool install "ruff>=0.6"` | 安装指定版本 | `uv tool install "ruff>=0.6"` |
| `uv tool install --from git+https://github.com/...` | 从 Git 仓库安装 | `uv tool install --from git+https://github.com/user/repo` |
| `uv tool list` | 列出已安装的工具 | `uv tool list` |
| `uv tool upgrade ruff` | 升级指定工具 | `uv tool upgrade ruff` |
| `uv tool upgrade --all` | 升级所有工具 | `uv tool upgrade --all` |
| `uv tool uninstall ruff` | 卸载工具 | `uv tool uninstall ruff` |
| `uv tool run ruff check .` | 运行工具（不安装到全局） | `uv tool run ruff check .` |
| `uv tool dir` | 查看工具安装目录 | `uv tool dir` |
| `uv tool update-shell` | 更新 shell 配置（确保工具 bin 在 PATH） | `uv tool update-shell` |

---

## 六、虚拟环境

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv venv` | 创建虚拟环境 | `uv venv` |
| `uv venv myenv` | 创建指定名称的虚拟环境 | `uv venv myenv` |
| `uv venv --python 3.12` | 指定 Python 版本创建 | `uv venv --python 3.12` |
| `uv venv /path/to/myenv --python 3.12` | 指定目录、名称、Python 版本创建 | `uv venv /path/to/myenv --python 3.12` |
| `uv venv --system-site-packages` | 允许访问系统 site-packages | `uv venv --system-site-packages` |
| `source .venv/bin/activate` | 激活虚拟环境 | `source .venv/bin/activate` |
| `deactivate` | 退出虚拟环境 | `deactivate` |

---

## 七、pip 兼容接口

> uv 提供与 pip 兼容的命令接口。

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv pip install requests` | 安装包 | `uv pip install requests` |
| `uv pip install -r requirements.txt` | 从文件安装 | `uv pip install -r requirements.txt` |
| `uv pip install "django>=5.0"` | 带约束安装 | `uv pip install "django>=5.0"` |
| `uv pip install --no-deps` | 不安装依赖 | `uv pip install --no-deps requests` |
| `uv pip uninstall requests` | 卸载包 | `uv pip uninstall requests` |
| `uv pip list` | 列出已安装的包 | `uv pip list` |
| `uv pip list --outdated` | 列出可升级的包 | `uv pip list --outdated` |
| `uv pip show requests` | 查看包详情 | `uv pip show requests` |
| `uv pip freeze` | 导出已安装包列表 | `uv pip freeze > requirements.txt` |
| `uv pip compile requirements.in` | 编译依赖锁定文件 | `uv pip compile requirements.in -o requirements.txt` |
| `uv pip sync requirements.txt` | 按锁定文件精确同步 | `uv pip sync requirements.txt` |
| `uv pip check` | 检查依赖冲突 | `uv pip check` |

---

## 八、缓存与清理

| 命令 | 说明 | 示例 |
|---|---|---|
| `uv cache dir` | 查看缓存目录 | `uv cache dir` |
| `uv cache clean` | 清理缓存 | `uv cache clean` |
| `uv cache prune` | 清理未使用的缓存项 | `uv cache prune` |
| `uv clean` | 清理项目构建产物 | `uv clean` |

---

## 九、常用工作流

### 新项目从零开始

```bash
# 1. 创建项目（指定 Python 3.12）
uv init my-project --python 3.12
cd my-project

# 2. 添加依赖
uv add django djangorestframework
uv add --dev pytest ruff

# 3. 同步环境
uv sync

# 4. 开始开发
uv run python manage.py runserver
```

### 已有 requirements.txt 迁移

```bash
# 1. 创建项目
uv init --python 3.12

# 2. 从 requirements.txt 导入依赖
uv add -r requirements.txt

# 3. 同步
uv sync
```

### 全局工具管理

```bash
# 安装常用工具
uv tool install ruff
uv tool install mypy
uv tool install pre-commit

# 查看已安装工具
uv tool list

# 升级全部工具
uv tool upgrade --all
```

---

## 关键路径速查

```
/usr/local/uv/                    uv 安装目录
~/.config/uv/uv.toml              配置文件
$UV_CACHE_DIR                     包缓存目录
$UV_TOOL_DIR                      全局工具安装目录
$UV_PYTHON_INSTALL_DIR            Python 解释器安装目录
$UV_PYTHON_BIN_DIR                Python 可执行文件 symlink 目录
$UV_TOOL_BIN_DIR                  工具可执行文件 symlink 目录
```

## 文档链接

- 官方仓库: https://github.com/astral-sh/uv
- 官方文档: https://docs.astral.sh/uv/
- CLI 命令参考: `uv --help`
- 子命令帮助: `uv <command> --help`
