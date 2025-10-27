# Baby Core Docker 部署说明

本文档概述了 Baby Core 应用的 Docker 部署配置。

## 📋 文件说明

### 核心配置文件

- **`Dockerfile`**: 多阶段构建配置
  - 第一阶段: 构建 Vue.js 前端
  - 第二阶段: 构建 Go 后端
  - 第三阶段: 创建精简的运行时镜像

- **`docker-compose.yml`**: Docker Compose 编排配置
  - 定义 `nginx` 和 `baby-core` 两个服务
  - 配置网络、卷和健康检查

- **`nginx/nginx.conf`**: Nginx 反向代理配置
  - 将 `/baby-core` 路径代理到后端服务
  - 将 `/baby-core/api` 请求代理到后端 API

- **`.env.example`**: 环境变量模板
  - JWT 密钥配置
  - 端口配置
  - 数据库路径配置

- **`.dockerignore`**: Docker 构建忽略文件
  - 排除不必要的文件以加快构建速度

### 部署脚本

- **`deploy.sh`**: 一键部署脚本
  - 检查 Docker 环境
  - 创建必要目录
  - 构建和启动服务
  - 执行健康检查

- **`init-user-simple.sh`**: 快速创建默认用户
  - 创建用户名 `admin`，密码 `admin123`

- **`init-user.sh`**: 交互式创建自定义用户
  - 可以指定用户名和密码

### 文档

- **`QUICKSTART_DOCKER.md`**: 5 分钟快速部署指南
- **`DEPLOYMENT_DOCKER.md`**: 完整部署文档
- **`SERVER_SETUP.md`**: 从零开始的服务器配置指南
- **`DOCKER_DEPLOYMENT_README.md`**: 本文件

## 🏗️ 架构说明

```
┌─────────────────────────────────────────────────┐
│                   用户浏览器                      │
└─────────────────┬───────────────────────────────┘
                  │
                  │ HTTP (端口 80)
                  ▼
┌─────────────────────────────────────────────────┐
│              Nginx 反向代理                       │
│  - 路径: /baby-core -> baby-core:8899           │
│  - 路径: /baby-core/api -> baby-core:8899/api  │
└─────────────────┬───────────────────────────────┘
                  │
                  │ Docker 网络
                  ▼
┌─────────────────────────────────────────────────┐
│            Baby Core 后端服务                     │
│  - Go 应用                                       │
│  - 端口: 8899                                    │
│  - 静态文件服务 + API                             │
└─────────────────┬───────────────────────────────┘
                  │
                  │ 文件系统
                  ▼
┌─────────────────────────────────────────────────┐
│              SQLite 数据库                        │
│  - 路径: ./data/baby_tracker.db                 │
└─────────────────────────────────────────────────┘
```

## 🚀 快速开始

### 1. 基本要求

- Docker 20.10+
- Docker Compose 2.0+

### 2. 部署步骤

```bash
# 1. 克隆或上传项目到服务器
cd baby-core

# 2. 配置环境变量
cp .env.example .env
nano .env  # 修改 JWT_SECRET

# 3. 一键部署
chmod +x deploy.sh
./deploy.sh

# 4. 创建用户
chmod +x init-user-simple.sh
./init-user-simple.sh
```

### 3. 访问应用

```
http://your-server-ip/baby-core
```

## 📦 服务配置

### Nginx 服务

- **镜像**: `nginx:latest`
- **端口**: 80
- **配置文件**: `./nginx/nginx.conf`
- **日志目录**: `./nginx/logs`

### Baby Core 服务

- **构建**: 从 `Dockerfile`
- **端口**: 8899
- **数据卷**: `./data` (持久化数据库)
- **环境变量**: 从 `.env` 文件加载

## 🔧 配置项

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PORT` | 后端服务端口 | 8899 |
| `DB_PATH` | 数据库文件路径 | /app/data/baby_tracker.db |
| `JWT_SECRET` | JWT 密钥（必须修改） | your-secret-key-change-in-production |
| `TZ` | 时区 | Asia/Shanghai |

### 端口映射

| 主机端口 | 容器端口 | 服务 | 说明 |
|---------|---------|------|------|
| 80 | 80 | nginx | 前端访问入口 |
| 8899 | 8899 | baby-core | 后端服务（可选直接访问） |

### 访问路径

| 路径 | 说明 |
|------|------|
| `/baby-core` | 应用首页 |
| `/baby-core/login` | 登录页面 |
| `/baby-core/api/*` | API 接口 |

## 📁 数据持久化

### 数据库

- **位置**: `./data/baby_tracker.db`
- **类型**: SQLite
- **备份**: 建议定期备份此文件

### 日志

- **Nginx 日志**: `./nginx/logs/`
- **应用日志**: 通过 `docker-compose logs` 查看

## 🔐 安全配置

### 必须执行的安全措施

1. **修改 JWT_SECRET**
   ```bash
   # 生成强密码
   openssl rand -base64 32
   # 将结果写入 .env 文件
   ```

2. **修改默认密码**
   - 首次登录后立即修改 `admin` 用户密码

3. **配置防火墙**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw enable
   ```

### 推荐的安全措施

1. **配置 HTTPS**
   - 使用 Let's Encrypt 免费证书
   - 参考 `SERVER_SETUP.md` 中的 HTTPS 配置章节

2. **定期备份**
   - 设置自动备份任务
   - 保留多个备份版本

3. **监控日志**
   - 定期检查访问日志和错误日志
   - 警惕异常访问模式

## 🛠️ 常用命令

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重新构建
docker-compose up -d --build
```

### 用户管理

```bash
# 创建默认用户 (admin/admin123)
./init-user-simple.sh

# 创建自定义用户
./init-user.sh
```

### 数据管理

```bash
# 备份数据库
cp data/baby_tracker.db backups/baby_tracker.db.$(date +%Y%m%d)

# 恢复数据库
docker-compose down
cp backups/baby_tracker.db.20251027 data/baby_tracker.db
docker-compose up -d
```

### 维护

```bash
# 清理未使用的 Docker 资源
docker system prune -a

# 查看 Docker 磁盘使用
docker system df

# 更新镜像
docker-compose pull
docker-compose up -d
```

## 🐛 故障排查

### 常见问题

#### 1. 端口被占用

```bash
# 检查端口占用
sudo netstat -tulpn | grep -E '80|8899'

# 修改端口（在 docker-compose.yml 中）
```

#### 2. 容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查配置文件
docker exec nginx-server nginx -t
```

#### 3. 无法访问应用

```bash
# 检查防火墙
sudo ufw status

# 检查容器状态
docker-compose ps

# 测试连接
curl http://localhost/baby-core/
```

#### 4. 数据库错误

```bash
# 检查数据目录权限
ls -la data/

# 修复权限
chmod 755 data/
chmod 644 data/*.db

# 重新初始化（会丢失数据！）
docker-compose down
rm data/baby_tracker.db
docker-compose up -d
```

## 📚 相关文档

- [快速开始指南](./QUICKSTART_DOCKER.md) - 5 分钟快速部署
- [完整部署文档](./DEPLOYMENT_DOCKER.md) - 详细的部署说明
- [服务器配置指南](./SERVER_SETUP.md) - Debian 12 从零开始配置
- [项目主 README](./README.md) - 项目介绍和功能说明

## 🤝 支持

遇到问题？

1. 查看日志: `docker-compose logs -f`
2. 检查文档: 阅读相关文档章节
3. 搜索问题: Google 搜索错误信息

## 📝 更新日志

### 2025-10-27
- 初始 Docker 部署配置
- 多阶段构建优化
- Nginx 反向代理配置
- 自动部署脚本
- 完整文档集

---

**注意**: 本部署方案适用于小型到中型应用。对于大规模生产环境，建议考虑：
- 使用 Kubernetes 进行容器编排
- 配置负载均衡
- 使用外部数据库（PostgreSQL/MySQL）
- 配置 CDN 加速
- 实施监控和告警系统

