# Baby Core Docker 部署快速指南

这是一个快速部署指南，帮助您在 5 分钟内完成 Baby Core 的 Docker 部署。

## 前置要求

确保服务器上已安装：
- Docker
- Docker Compose

## 快速部署步骤

### 1. 上传项目文件到服务器

```bash
# 在本地压缩项目
cd /path/to/baby-core
tar -czf baby-core.tar.gz .

# 上传到服务器
scp baby-core.tar.gz user@your-server:/home/user/

# 在服务器上解压
ssh user@your-server
cd /home/user
mkdir baby-core && tar -xzf baby-core.tar.gz -C baby-core
cd baby-core
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量（重要！修改 JWT_SECRET）
nano .env
```

将 `JWT_SECRET` 修改为一个强密码：
```env
JWT_SECRET=your-very-long-secret-key-here-at-least-32-characters
```

### 3. 一键部署

```bash
# 方式 1：使用部署脚本（推荐）
chmod +x deploy.sh
./deploy.sh

# 方式 2：手动部署
mkdir -p data nginx/logs
docker-compose up -d --build
```

### 4. 创建初始用户

```bash
# 创建默认用户 (用户名: admin, 密码: admin123)
chmod +x init-user-simple.sh
./init-user-simple.sh

# 或者创建自定义用户
chmod +x init-user.sh
./init-user.sh
```

### 5. 访问应用

在浏览器中打开：
```
http://your-server-ip/baby-core
```

使用刚才创建的用户名和密码登录。

## 完成！🎉

应用现在应该已经运行了。

## 常用命令

```bash
# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新应用
git pull
docker-compose up -d --build
```

## 端口说明

- **80**: Nginx（前端访问端口）
- **8899**: Baby Core 后端服务

## 访问路径

- **应用首页**: `http://your-server-ip/baby-core`
- **登录页面**: `http://your-server-ip/baby-core/login`
- **API接口**: `http://your-server-ip/baby-core/api`

## 数据位置

- **数据库**: `./data/baby_tracker.db`
- **日志**: `./nginx/logs/`

## 备份

```bash
# 备份数据库
cp data/baby_tracker.db backups/baby_tracker.db.$(date +%Y%m%d)
```

## 故障排查

### 无法访问

1. 检查防火墙：
```bash
sudo ufw allow 80/tcp
sudo ufw allow 8899/tcp
```

2. 检查服务状态：
```bash
docker-compose ps
docker-compose logs
```

### 登录失败

确保已创建用户：
```bash
./init-user-simple.sh
```

### 数据库错误

重新初始化：
```bash
docker-compose down
rm -f data/baby_tracker.db
docker-compose up -d
./init-user-simple.sh
```

## 更多帮助

详细文档请查看 [DEPLOYMENT_DOCKER.md](./DEPLOYMENT_DOCKER.md)

---

如有问题，请检查日志：
```bash
docker-compose logs -f baby-core
```

