# Debian 12 服务器完整安装指南

本指南将指导您从零开始在 Debian 12 服务器上部署 Baby Core 应用。

## 系统要求

- Debian 12 (Bookworm)
- 最小 1GB RAM
- 最小 10GB 磁盘空间
- Root 或 sudo 权限

## 第一步：更新系统

```bash
# 更新软件包列表
sudo apt update

# 升级所有软件包
sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git vim net-tools
```

## 第二步：安装 Docker

```bash
# 安装 Docker 官方脚本
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 将当前用户添加到 docker 组（可选，避免每次使用 sudo）
sudo usermod -aG docker $USER

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker ps
```

## 第三步：安装 Docker Compose

```bash
# 方式 1: 使用 apt 安装（推荐）
sudo apt install -y docker-compose-plugin

# 方式 2: 手动安装最新版本
# DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
# sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker compose version
```

## 第四步：配置防火墙（如果使用 UFW）

```bash
# 安装 UFW（如果未安装）
sudo apt install -y ufw

# 配置基本规则
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 允许 SSH（重要！）
sudo ufw allow ssh
sudo ufw allow 22/tcp

# 允许 HTTP 和 HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许后端端口（如果需要直接访问）
sudo ufw allow 8899/tcp

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

## 第五步：上传项目文件

### 方式 1: 使用 SCP

在本地机器上：
```bash
# 压缩项目
cd /path/to/baby-core
tar -czf baby-core.tar.gz --exclude=node_modules --exclude=data --exclude=.git .

# 上传到服务器
scp baby-core.tar.gz user@your-server-ip:/home/user/
```

在服务器上：
```bash
# 创建目录并解压
mkdir -p ~/baby-core
cd ~/baby-core
tar -xzf ~/baby-core.tar.gz
```

### 方式 2: 使用 Git

```bash
# 克隆仓库
cd ~
git clone https://github.com/yourusername/baby-core.git
cd baby-core
```

## 第六步：配置应用

```bash
cd ~/baby-core

# 创建环境变量文件
cp .env.example .env

# 编辑环境变量
nano .env
```

**重要**: 修改以下配置：
```env
JWT_SECRET=your-very-secret-key-at-least-32-characters-long-123456
PORT=8899
DB_PATH=/app/data/baby_tracker.db
TZ=Asia/Shanghai
```

生成强密码的方法：
```bash
# 生成随机密码
openssl rand -base64 32
```

## 第七步：部署应用

```bash
# 添加执行权限
chmod +x deploy.sh init-user-simple.sh

# 运行部署脚本
./deploy.sh
```

或者手动部署：
```bash
# 创建必要的目录
mkdir -p data nginx/logs

# 构建并启动服务
docker-compose up -d --build

# 查看日志
docker-compose logs -f
```

## 第八步：创建初始用户

```bash
# 等待服务完全启动（大约 10-30 秒）
sleep 30

# 创建默认用户
./init-user-simple.sh

# 输出类似：
# ✓ 默认用户创建成功！
# 
# 登录信息:
#   用户名: admin
#   密码: admin123
```

## 第九步：验证部署

```bash
# 检查容器状态
docker-compose ps

# 应该看到两个容器都在运行：
# NAME            COMMAND                  SERVICE      STATUS       PORTS
# baby-core       "./baby-tracker"         baby-core    Up           0.0.0.0:8899->8899/tcp
# nginx-server    "/docker-entrypoint.…"   nginx        Up           0.0.0.0:80->80/tcp

# 测试后端
curl http://localhost:8899/

# 测试前端
curl http://localhost/baby-core/
```

## 第十步：访问应用

在浏览器中打开：
```
http://your-server-ip/baby-core
```

使用以下凭据登录：
- 用户名: `admin`
- 密码: `admin123`

**重要**: 首次登录后请立即修改密码！

## 配置 HTTPS（可选但推荐）

### 使用 Let's Encrypt 免费证书

```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 停止 Docker 容器中的 Nginx（临时）
docker-compose stop nginx

# 安装系统 Nginx（用于获取证书）
sudo apt install -y nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 证书获取后，停止系统 Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# 修改 docker-compose.yml，添加证书映射
# 在 nginx 服务的 volumes 中添加：
#   - /etc/letsencrypt:/etc/letsencrypt:ro

# 重启容器
docker-compose up -d

# 设置自动续期
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

## 维护任务

### 查看日志

```bash
# 所有服务
docker-compose logs -f

# 只看后端
docker-compose logs -f baby-core

# 只看 Nginx
docker-compose logs -f nginx
```

### 备份数据

```bash
# 创建备份目录
mkdir -p ~/backups

# 备份数据库
cp data/baby_tracker.db ~/backups/baby_tracker.db.$(date +%Y%m%d_%H%M%S)

# 或使用脚本自动备份
cat > ~/backup-baby-core.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=~/backups
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)
cp ~/baby-core/data/baby_tracker.db $BACKUP_DIR/baby_tracker.db.$DATE
# 保留最近 30 天的备份
find $BACKUP_DIR -name "baby_tracker.db.*" -mtime +30 -delete
echo "Backup completed: baby_tracker.db.$DATE"
EOF

chmod +x ~/backup-baby-core.sh

# 设置定时任务（每天凌晨 2 点备份）
(crontab -l 2>/dev/null; echo "0 2 * * * ~/backup-baby-core.sh") | crontab -
```

### 更新应用

```bash
cd ~/baby-core

# 备份数据
cp data/baby_tracker.db data/baby_tracker.db.backup.$(date +%Y%m%d)

# 拉取最新代码（如果使用 Git）
git pull

# 重新构建并启动
docker-compose down
docker-compose up -d --build

# 查看日志确认启动成功
docker-compose logs -f
```

### 监控磁盘空间

```bash
# 查看磁盘使用
df -h

# 查看 Docker 磁盘使用
docker system df

# 清理未使用的 Docker 资源
docker system prune -a
```

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
sudo netstat -tulpn | grep -E '80|8899'

# 重新构建
docker-compose down
docker-compose up -d --build
```

### 无法访问网页

```bash
# 检查防火墙
sudo ufw status

# 检查 Nginx 配置
docker exec nginx-server nginx -t

# 检查容器网络
docker network ls
docker network inspect baby-core_nginx-network
```

### 数据库权限错误

```bash
# 检查数据目录权限
ls -la data/

# 修复权限
sudo chown -R $USER:$USER data/
chmod 755 data/
chmod 644 data/*.db
```

## 性能优化

### 1. 限制日志文件大小

编辑 `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

重启 Docker:
```bash
sudo systemctl restart docker
docker-compose up -d
```

### 2. 配置 Nginx 缓存

在 `nginx/nginx.conf` 中添加缓存配置（已包含在提供的配置中）。

### 3. 定期清理

```bash
# 每周清理 Docker
docker system prune -f

# 清理旧日志
find nginx/logs -name "*.log" -mtime +30 -delete
```

## 安全建议

1. **修改默认密码**: 首次登录后立即修改
2. **使用强 JWT 密钥**: 在 `.env` 中设置至少 32 字符
3. **配置 HTTPS**: 使用 Let's Encrypt 免费证书
4. **定期备份**: 设置自动备份任务
5. **限制 SSH 访问**: 使用密钥认证，禁用密码登录
6. **保持系统更新**: 定期运行 `sudo apt update && sudo apt upgrade`
7. **使用防火墙**: 只开放必要端口

## 监控建议

考虑安装监控工具：

```bash
# 安装 htop 监控资源
sudo apt install -y htop

# 安装 docker stats 查看容器资源使用
docker stats
```

## 完成！

现在您的 Baby Core 应用应该已经在 Debian 12 服务器上成功运行了。

访问地址: `http://your-server-ip/baby-core`

---

最后更新: 2025-10-27

