# Docker 常用命令速查

## 一、安装

> 本仓库 `docker/Dockerfile` 提供预配置开发环境，无需手动安装 Docker 内各工具。

| 命令 | 说明 |
|---|---|
| `docker build -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile .` | 使用仓库 `docker/Dockerfile` 构建镜像（在仓库根目录执行） |
| `docker build --no-cache -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile .` | 强制重新构建，忽略缓存 |

---

## 二、构建

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker build -t <name>:<tag> .` | 构建镜像（默认读取 `./Dockerfile`） | `docker build -t myapp:latest .` |
| `docker build -f <path> .` | 指定 Dockerfile 路径构建 | `docker build -f docker/Dockerfile .` |
| `docker build --build-arg KEY=VALUE .` | 传递构建参数 | `docker build --build-arg NODE_ENV=production .` |
| `docker build --platform linux/amd64 .` | 指定目标平台 | `docker build --platform linux/arm64 .` |
| `docker build -t <name> --target <stage> .` | 构建到指定多阶段构建阶段 | `docker build --target builder .` |
| `docker build --no-cache .` | 不使用构建缓存 | `docker build --no-cache -t myapp .` |
| `docker build -t <name> . --progress=plain` | 显示完整构建输出（不加折叠） | `docker build -t myapp . --progress=plain` |

---

## 三、运行

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker run -it <image>` | 交互式启动，分配 TTY | `docker run -it ubuntu26.04-custom:v0.1` |
| `docker run -it --rm <image>` | 运行，退出后自动删除容器 | `docker run -it --rm ubuntu26.04-custom:v0.1` |
| `docker run -d <image>` | 后台运行 | `docker run -d --name myapp nginx` |
| `docker run -p 8080:80 <image>` | 端口映射（宿主机:容器） | `docker run -p 3000:3000 myapp` |
| `docker run -v $(pwd):/workspace <image>` | 挂载当前目录到容器 | `docker run -it -v $(pwd):/workspace ubuntu26.04-custom:v0.1` |
| `docker run -v <name>:/path <image>` | 挂载命名数据卷 | `docker run -v dev-cache:/root/.cache ubuntu26.04-custom:v0.1` |
| `docker run -e KEY=VALUE <image>` | 设置环境变量 | `docker run -e NODE_ENV=production myapp` |
| `docker run --env-file .env <image>` | 从文件加载环境变量 | `docker run --env-file .env ubuntu26.04-custom:v0.1` |
| `docker run --name <name> <image>` | 指定容器名称 | `docker run --name dev-env ubuntu26.04-custom:v0.1` |
| `docker run --memory="512m" <image>` | 限制内存使用 | `docker run --memory=512m myapp` |
| `docker run --cpus="2" <image>` | 限制 CPU 使用 | `docker run --cpus=2 myapp` |

**本仓库用法：**

```bash
# 基础运行
docker run -it --rm ubuntu26.04-custom:v0.1

# 挂载当前目录 + 保留包缓存
docker run -it --rm -v $(pwd):/workspace -v dev-cache:/root/.cache ubuntu26.04-custom:v0.1
```

---

## 四、镜像管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker images` | 列出本地镜像 | `docker images` |
| `docker pull <image>` | 拉取镜像 | `docker pull ubuntu:26.04` |
| `docker push <image>` | 推送镜像到仓库 | `docker push myapp:latest` |
| `docker tag <src> <dst>` | 为镜像打标签 | `docker tag ubuntu26.04-custom:v0.1 myrepo/config-files:v1` |
| `docker rmi <image>` | 删除镜像 | `docker rmi ubuntu26.04-custom:v0.1` |
| `docker rmi $(docker images -q)` | 删除所有镜像 | `docker rmi $(docker images -q)` |
| `docker image history <image>` | 查看镜像构建历史（层） | `docker image history ubuntu26.04-custom:v0.1` |
| `docker image inspect <image>` | 查看镜像详细信息 | `docker image inspect ubuntu26.04-custom:v0.1` |
| `docker save -o file.tar <image>` | 导出镜像为 tar 文件 | `docker save -o dev-env.tar ubuntu26.04-custom:v0.1` |
| `docker load -i file.tar` | 从 tar 文件导入镜像 | `docker load -i dev-env.tar` |

---

## 五、容器管理

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker ps` | 列出运行中的容器 | `docker ps` |
| `docker ps -a` | 列出所有容器（含已停止） | `docker ps -a` |
| `docker stop <container>` | 停止容器 | `docker stop myapp` |
| `docker start <container>` | 启动已停止的容器 | `docker start myapp` |
| `docker restart <container>` | 重启容器 | `docker restart myapp` |
| `docker exec -it <container> bash` | 进入运行中的容器 | `docker exec -it myapp bash` |
| `docker logs <container>` | 查看容器日志 | `docker logs myapp` |
| `docker logs -f <container>` | 持续跟踪容器日志 | `docker logs -f myapp` |
| `docker logs --tail 100 <container>` | 查看最后 100 行日志 | `docker logs --tail 100 myapp` |
| `docker cp <container>:/path .` | 从容器复制文件到宿主机 | `docker cp myapp:/workspace/output .` |
| `docker cp . <container>:/path` | 从宿主机复制文件到容器 | `docker cp config.json myapp:/workspace/` |
| `docker inspect <container>` | 查看容器详细信息 | `docker inspect myapp` |
| `docker stats` | 查看容器资源使用（CPU/内存） | `docker stats` |
| `docker rename <old> <new>` | 重命名容器 | `docker rename old-name new-name` |

---

## 六、Docker Compose

> 多容器编排。配置文件 `docker-compose.yml`。

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker compose up` | 启动所有服务（前台） | `docker compose up` |
| `docker compose up -d` | 启动所有服务（后台） | `docker compose up -d` |
| `docker compose up --build` | 重新构建并启动 | `docker compose up --build` |
| `docker compose down` | 停止并删除所有服务 | `docker compose down` |
| `docker compose down -v` | 停止并删除数据卷 | `docker compose down -v` |
| `docker compose ps` | 查看服务状态 | `docker compose ps` |
| `docker compose logs` | 查看所有服务日志 | `docker compose logs` |
| `docker compose logs <service>` | 查看指定服务日志 | `docker compose logs web` |
| `docker compose exec <service> bash` | 进入服务容器 | `docker compose exec web bash` |
| `docker compose restart <service>` | 重启指定服务 | `docker compose restart database` |
| `docker compose build` | 仅构建（不启动） | `docker compose build` |
| `docker compose build --no-cache` | 强制重新构建 | `docker compose build --no-cache` |
| `docker compose pull` | 拉取依赖镜像 | `docker compose pull` |

---

## 七、数据卷与网络

### 数据卷

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker volume ls` | 列出所有数据卷 | `docker volume ls` |
| `docker volume create <name>` | 创建数据卷 | `docker volume create dev-cache` |
| `docker volume inspect <name>` | 查看数据卷详情 | `docker volume inspect dev-cache` |
| `docker volume rm <name>` | 删除数据卷 | `docker volume rm dev-cache` |
| `docker volume prune` | 清理未使用的数据卷 | `docker volume prune` |

### 网络

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker network ls` | 列出所有网络 | `docker network ls` |
| `docker network create <name>` | 创建网络 | `docker network create mynet` |
| `docker network connect <net> <container>` | 将容器加入网络 | `docker network connect mynet myapp` |
| `docker network disconnect <net> <container>` | 将容器移出网络 | `docker network disconnect mynet myapp` |
| `docker network inspect <name>` | 查看网络详情 | `docker network inspect mynet` |
| `docker network rm <name>` | 删除网络 | `docker network rm mynet` |

---

## 八、清理

> 清理无用资源，释放磁盘空间。

| 命令 | 说明 | 示例 |
|---|---|---|
| `docker container prune` | 删除所有已停止的容器 | `docker container prune -f` |
| `docker image prune` | 删除未使用的镜像 | `docker image prune -a -f` |
| `docker volume prune` | 删除未使用的数据卷 | `docker volume prune -f` |
| `docker network prune` | 删除未使用的网络 | `docker network prune -f` |
| `docker system prune` | 一键清理（停止的容器 + 未使用的网络 + dangling 镜像） | `docker system prune -f` |
| `docker system prune -a` | 深度清理（含所有未使用的镜像） | `docker system prune -a -f` |
| `docker system df` | 查看磁盘使用情况 | `docker system df` |
| `docker system df -v` | 查看详细磁盘使用 | `docker system df -v` |
| `docker builder prune` | 清理构建缓存 | `docker builder prune -a -f` |

---

## 九、常用工作流

### 本仓库开发环境

```bash
# 1. 构建镜像
docker build -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile .

# 2. 交互式使用
docker run -it --rm -v $(pwd):/workspace -v dev-cache:/root/.cache ubuntu26.04-custom:v0.1

# 3. 日常更新（拉取最新配置后重新构建）
git pull
docker build -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile .
```

### 多服务本地开发

```bash
# 1. 启动（后台）
docker compose up -d

# 2. 查看日志
docker compose logs -f

# 3. 仅重启某个服务
docker compose restart api

# 4. 停止
docker compose down
```

### 镜像发布

```bash
# 1. 构建并打标签
docker build -t ubuntu26.04-custom:v0.1 -f docker/Dockerfile .
docker tag ubuntu26.04-custom:v0.1 myrepo/config-files:v1.0

# 2. 推送
docker push myrepo/config-files:v1.0
```

### 故障排查

```bash
# 进入运行中的容器
docker exec -it <container> bash

# 查看容器最近日志
docker logs --tail 200 <container>

# 检查容器资源占用
docker stats --no-stream

# 查看容器完整配置（环境变量、挂载、网络等）
docker inspect <container> | less
```

### 磁盘清理（定期执行）

```bash
# 查看占用
docker system df

# 深度清理
docker system prune -a --volumes -f
```

---

## 关键路径速查

```
docker/Dockerfile              本仓库 Dockerfile
docker/.dockerignore           构建上下文排除规则
/var/lib/docker/               Docker 数据目录
/var/lib/docker/volumes/       数据卷存储
~/.docker/                     用户级 Docker 配置
```

**本仓库容器内关键路径：**

```
/usr/local/uv/                 uv 安装目录
/usr/local/uv/python/          Python 解释器（uv 托管）
/usr/local/bin/                Python/工具可执行文件软链
/usr/local/lib/node_modules/   npm 全局包
/root/.config/                 各工具配置目录
/root/.hermes/                 Hermes Agent 配置与技能
/workspace/                    默认工作目录
```

## 文档链接

- 官方文档: https://docs.docker.com/
- Dockerfile 参考: https://docs.docker.com/reference/dockerfile/
- Docker Hub: https://hub.docker.com/
- Compose 文档: https://docs.docker.com/compose/
- CLI 命令参考: `docker --help`
- 子命令帮助: `docker <command> --help`
