# 部署指南

## 生产环境部署

### 系统要求

- Go 1.21+
- Node.js 18+
- SQLite3 (通常系统自带)
- Linux/macOS/Windows 服务器

### 部署步骤

#### 1. 构建应用

```bash
# 克隆或上传代码到服务器
cd baby-core

# 构建前端
cd web
npm install
npm run build
cd ..

# 构建后端
cd backend
go mod download
go build -o baby-tracker main.go
```

#### 2. 配置环境

创建 `.env` 文件或设置环境变量：

```bash
export PORT=8080
export DB_PATH=/var/lib/baby-tracker/baby_tracker.db
export JWT_SECRET="your-very-long-and-secure-random-secret-key"
```

#### 3. 创建系统服务 (Linux systemd)

创建文件 `/etc/systemd/system/baby-tracker.service`:

```ini
[Unit]
Description=Baby Tracker Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/baby-tracker/backend
ExecStart=/opt/baby-tracker/backend/baby-tracker
Restart=always
RestartSec=10

# Environment variables
Environment="PORT=8080"
Environment="DB_PATH=/var/lib/baby-tracker/baby_tracker.db"
Environment="JWT_SECRET=your-secure-secret-key"

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable baby-tracker
sudo systemctl start baby-tracker
sudo systemctl status baby-tracker
```

#### 4. 配置 Nginx 反向代理（推荐）

创建 Nginx 配置 `/etc/nginx/sites-available/baby-tracker`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

启用站点：

```bash
sudo ln -s /etc/nginx/sites-available/baby-tracker /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 5. 配置 HTTPS (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### Docker 部署（可选）

创建 `Dockerfile`:

```dockerfile
# Build frontend
FROM node:18 AS frontend-builder
WORKDIR /app/web
COPY web/package*.json ./
RUN npm install
COPY web/ ./
RUN npm run build

# Build backend
FROM golang:1.21 AS backend-builder
WORKDIR /app/backend
COPY backend/go.* ./
RUN go mod download
COPY backend/ ./
COPY --from=frontend-builder /app/web/dist ./dist
RUN CGO_ENABLED=1 go build -o baby-tracker main.go

# Final stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates sqlite3 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=backend-builder /app/backend/baby-tracker .
COPY --from=backend-builder /app/backend/dist ./dist
COPY sql/ ./sql/

ENV PORT=8080
ENV DB_PATH=/data/baby_tracker.db
ENV JWT_SECRET=change-me-in-production

EXPOSE 8080
VOLUME ["/data"]

CMD ["./baby-tracker"]
```

构建和运行：

```bash
docker build -t baby-tracker .
docker run -d \
  -p 8080:8080 \
  -v baby-tracker-data:/data \
  -e JWT_SECRET=your-secret-key \
  --name baby-tracker \
  baby-tracker
```

### 安全建议

1. **修改默认密码**: 首次登录后立即修改 admin 账户密码
2. **配置 HTTPS**: 生产环境必须使用 HTTPS
3. **防火墙设置**: 只开放必要端口（80, 443）
4. **JWT 密钥**: 使用强随机密钥，至少 32 字符
5. **定期备份**: 定期备份 SQLite 数据库文件
6. **日志监控**: 使用 journalctl 或日志收集工具监控应用
7. **更新维护**: 定期更新依赖和系统补丁

### 备份与恢复

#### 备份数据库

```bash
# 简单备份
cp /var/lib/baby-tracker/baby_tracker.db /backup/baby_tracker_$(date +%Y%m%d).db

# 使用 SQLite 备份
sqlite3 /var/lib/baby-tracker/baby_tracker.db ".backup /backup/baby_tracker.db"

# 定时备份 (crontab)
0 2 * * * cp /var/lib/baby-tracker/baby_tracker.db /backup/baby_tracker_$(date +\%Y\%m\%d).db
```

#### 恢复数据库

```bash
# 停止服务
sudo systemctl stop baby-tracker

# 恢复数据库
cp /backup/baby_tracker.db /var/lib/baby-tracker/baby_tracker.db

# 启动服务
sudo systemctl start baby-tracker
```

### 性能优化

1. **SQLite 优化**: 数据库已配置索引，通常无需额外优化
2. **Gzip 压缩**: Nginx 配置中启用 gzip 压缩静态资源
3. **缓存策略**: 配置静态文件缓存头
4. **连接池**: SQLite 单连接，已优化

### 监控

```bash
# 查看服务状态
sudo systemctl status baby-tracker

# 查看日志
sudo journalctl -u baby-tracker -f

# 查看资源使用
htop
ps aux | grep baby-tracker
```

### 故障排查

#### 服务无法启动
- 检查端口是否被占用: `sudo netstat -tlnp | grep 8080`
- 检查文件权限: `ls -la /opt/baby-tracker/backend/baby-tracker`
- 查看详细日志: `sudo journalctl -u baby-tracker -n 100`

#### 数据库错误
- 检查数据库文件权限
- 确保数据库目录存在且可写
- 尝试重建数据库（注意备份）

#### 性能问题
- 检查磁盘空间: `df -h`
- 检查内存使用: `free -m`
- 检查数据库大小: `ls -lh /var/lib/baby-tracker/baby_tracker.db`
- 如数据库过大，考虑归档旧数据

## 开发环境部署

参见 [QUICKSTART.md](QUICKSTART.md)

