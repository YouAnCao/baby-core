# Baby Core Docker 部署指南

本指南将帮助您在 Debian 12 服务器上使用 Docker 部署 Baby Core 应用。

## 系统要求

- Debian 12 (或其他 Linux 发行版)
- Docker 20.10+
- Docker Compose 2.0+
- 至少 1GB 可用内存
- 至少 2GB 可用磁盘空间

## 架构说明

- **后端**: Go 应用运行在端口 8899
- **前端**: Vue.js 静态文件由 Go 服务提供，通过 Nginx 代理
- **访问路径**: `/baby-core`
- **API路径**: `/baby-core/api`

## 快速部署

### 1. 安装 Docker 和 Docker Compose (如果尚未安装)

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 安装 Docker Compose
sudo apt install docker-compose-plugin -y

# 验证安装
docker --version
docker compose version
```

### 2. 准备项目文件

```bash
# 上传 baby-core 目录到服务器
# 例如: scp -r baby-core user@server:/home/user/

# 进入项目目录
cd baby-core
```

### 3. 配置环境变量

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑环境变量（重要！）
nano .env
```

**必须修改的配置**:
- `JWT_SECRET`: 设置一个强密码，用于 JWT 令牌加密

```env
JWT_SECRET=your-very-secret-key-here-change-this
PORT=8899
DB_PATH=/app/data/baby_tracker.db
TZ=Asia/Shanghai
```

### 4. 执行部署

```bash
# 添加执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

或者手动执行：

```bash
# 创建必要的目录
mkdir -p data nginx/logs

# 构建并启动服务
docker-compose up -d --build

# 查看服务状态
docker-compose ps
```

## 访问应用

部署完成后，通过浏览器访问：

- **应用地址**: `http://your-server-ip/baby-core`
- **API地址**: `http://your-server-ip/baby-core/api`

默认登录凭据（需要先创建用户）：
```bash
# 进入容器创建用户
docker exec -it baby-core /bin/sh
cd /app
# 运行种子脚本（如果有的话）
```

## 常用操作

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 只看 Baby Core 后端日志
docker-compose logs -f baby-core

# 只看 Nginx 日志
docker-compose logs -f nginx
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 只重启 Baby Core
docker-compose restart baby-core

# 只重启 Nginx
docker-compose restart nginx
```

### 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（谨慎！）
docker-compose down -v
```

### 更新应用

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build

# 如果需要清理旧镜像
docker image prune -f
```

### 数据备份

```bash
# 备份数据库
cp data/baby_tracker.db data/baby_tracker.db.backup.$(date +%Y%m%d_%H%M%S)

# 或者导出整个 data 目录
tar -czf baby-core-backup-$(date +%Y%m%d_%H%M%S).tar.gz data/
```

### 数据恢复

```bash
# 恢复数据库
docker-compose down
cp data/baby_tracker.db.backup.YYYYMMDD_HHMMSS data/baby_tracker.db
docker-compose up -d
```

## 目录结构

```
baby-core/
├── backend/              # Go 后端源码
├── web/                  # Vue.js 前端源码
├── nginx/                # Nginx 配置
│   ├── nginx.conf       # Nginx 主配置文件
│   └── logs/            # Nginx 日志目录
├── data/                 # 数据持久化目录
│   └── baby_tracker.db  # SQLite 数据库
├── Dockerfile            # Docker 构建文件
├── docker-compose.yml    # Docker Compose 配置
├── .env                  # 环境变量配置
├── .env.example          # 环境变量示例
└── deploy.sh             # 部署脚本
```

## Nginx 配置说明

Nginx 配置文件位于 `nginx/nginx.conf`，主要功能：

1. **反向代理**: 将 `/baby-core` 路径的请求代理到后端服务
2. **API代理**: 将 `/baby-core/api` 请求代理到后端 API
3. **Gzip压缩**: 启用 Gzip 压缩以提高传输效率
4. **日志记录**: 记录访问日志和错误日志

## 故障排查

### 1. 服务无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
sudo netstat -tulpn | grep -E '80|8899'

# 检查容器状态
docker-compose ps
```

### 2. 数据库错误

```bash
# 检查数据目录权限
ls -la data/

# 重新初始化数据库
docker-compose down
rm -f data/baby_tracker.db
docker-compose up -d
```

### 3. 前端无法访问

```bash
# 检查 Nginx 配置
docker exec -it nginx-server nginx -t

# 重新加载 Nginx 配置
docker exec -it nginx-server nginx -s reload

# 检查防火墙
sudo ufw status
sudo ufw allow 80/tcp
```

### 4. API 请求失败

```bash
# 测试后端健康
curl http://localhost:8899/

# 测试 API 端点
curl http://localhost:8899/api/records

# 检查 CORS 配置
# 如果有跨域问题，需要修改后端 CORS 设置
```

## 安全建议

1. **修改 JWT 密钥**: 在 `.env` 文件中设置强密码
2. **使用 HTTPS**: 配置 SSL 证书（推荐使用 Let's Encrypt）
3. **限制访问**: 使用防火墙限制不必要的端口访问
4. **定期备份**: 定期备份数据库文件
5. **更新依赖**: 定期更新 Docker 镜像和系统包

## 配置 HTTPS (可选)

如果需要配置 HTTPS，可以使用 Certbot：

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取证书
sudo certbot --nginx -d your-domain.com

# 证书会自动续期
sudo systemctl status certbot.timer
```

然后修改 `docker-compose.yml`，添加 443 端口映射：

```yaml
nginx:
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - /etc/letsencrypt:/etc/letsencrypt:ro
```

## 性能优化

1. **调整 Nginx worker 进程数**
2. **启用 HTTP/2**
3. **配置缓存策略**
4. **使用 CDN 加速静态资源**

## 监控和维护

建议定期检查：
- 磁盘空间使用情况
- 日志文件大小
- 数据库文件大小
- 容器运行状态

## 支持

如有问题，请查看：
- 项目 README.md
- 日志文件
- Docker Compose 文档

---

更新日期: 2025-10-27

