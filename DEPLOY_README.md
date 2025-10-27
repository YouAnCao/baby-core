# 🚀 Baby Core Docker 部署指南

欢迎使用 Baby Core Docker 部署包！本文档将指引你快速完成部署。

## 📖 文档索引

### 快速开始 ⚡

**5 分钟快速部署** → [`QUICKSTART_DOCKER.md`](./QUICKSTART_DOCKER.md)

适合：想要快速体验，首次部署

### 完整指南 📚

1. **服务器配置** → [`SERVER_SETUP.md`](./SERVER_SETUP.md)
   - Debian 12 从零开始配置
   - Docker 安装
   - 防火墙配置
   - HTTPS 配置

2. **完整部署** → [`DEPLOYMENT_DOCKER.md`](./DEPLOYMENT_DOCKER.md)
   - 详细部署步骤
   - 配置说明
   - 故障排查
   - 安全建议
   - 性能优化

3. **架构说明** → [`DOCKER_DEPLOYMENT_README.md`](./DOCKER_DEPLOYMENT_README.md)
   - 文件结构说明
   - 架构图
   - 配置详解
   - 常用命令

4. **部署总结** → [`DEPLOYMENT_SUMMARY.md`](./DEPLOYMENT_SUMMARY.md)
   - 部署方式对比
   - 快速参考
   - 检查清单

## 🎯 选择你的部署方式

### 方式 1️⃣: 超快速部署（推荐）

```bash
# 1. 配置环境变量
cp .env.example .env
nano .env  # 修改 JWT_SECRET

# 2. 一键部署
chmod +x deploy.sh && ./deploy.sh

# 3. 创建用户
chmod +x init-user-simple.sh && ./init-user-simple.sh

# 4. 访问应用
# http://your-server-ip/baby-core
```

**时间**: 5 分钟  
**文档**: [`QUICKSTART_DOCKER.md`](./QUICKSTART_DOCKER.md)

### 方式 2️⃣: 完整部署（生产环境）

1. 阅读 [`SERVER_SETUP.md`](./SERVER_SETUP.md) 配置服务器
2. 阅读 [`DEPLOYMENT_DOCKER.md`](./DEPLOYMENT_DOCKER.md) 执行部署
3. 配置 HTTPS 和备份

**时间**: 30-60 分钟  
**适合**: 生产环境，长期使用

### 方式 3️⃣: 手动部署（自定义）

```bash
mkdir -p data nginx/logs
docker-compose up -d --build
docker-compose logs -f
```

**文档**: [`DOCKER_DEPLOYMENT_README.md`](./DOCKER_DEPLOYMENT_README.md)

## 📦 部署文件说明

### 核心文件 🔧

| 文件 | 说明 |
|------|------|
| `Dockerfile` | Docker 镜像构建配置 |
| `docker-compose.yml` | 服务编排配置 |
| `.env.example` | 环境变量模板 |
| `nginx/nginx.conf` | Nginx 反向代理配置 |

### 脚本文件 🔨

| 文件 | 说明 |
|------|------|
| `deploy.sh` | 一键部署脚本 |
| `init-user-simple.sh` | 快速创建默认用户 |
| `init-user.sh` | 交互式创建用户 |
| `verify-deployment.sh` | 部署验证脚本 |

### 文档文件 📄

| 文件 | 说明 |
|------|------|
| `QUICKSTART_DOCKER.md` | 5分钟快速开始 |
| `DEPLOYMENT_DOCKER.md` | 完整部署文档 |
| `SERVER_SETUP.md` | 服务器配置指南 |
| `DOCKER_DEPLOYMENT_README.md` | 架构和配置说明 |
| `DEPLOYMENT_SUMMARY.md` | 部署总结 |
| `DEPLOY_README.md` | 本文件 |

## ✅ 部署前检查

- [ ] 服务器已安装 Docker 20.10+
- [ ] 服务器已安装 Docker Compose 2.0+
- [ ] 端口 80 和 8899 未被占用
- [ ] 有足够的磁盘空间（至少 2GB）
- [ ] 防火墙已配置或可以配置

## 🚦 快速开始 3 步骤

### 1️⃣ 配置

```bash
cp .env.example .env
nano .env
```

修改 `JWT_SECRET`:
```env
JWT_SECRET=your-secret-key-here
```

生成密钥：
```bash
openssl rand -base64 32
```

### 2️⃣ 部署

```bash
chmod +x deploy.sh
./deploy.sh
```

### 3️⃣ 创建用户

```bash
chmod +x init-user-simple.sh
./init-user-simple.sh
```

默认登录：
- 用户名: `admin`
- 密码: `admin123`

## 🌐 访问应用

部署完成后，访问：

```
http://your-server-ip/baby-core
```

## 🔍 验证部署

```bash
chmod +x verify-deployment.sh
./verify-deployment.sh
```

## 📱 应用使用

### 主要功能

- 👶 宝宝日常记录（喂奶、换尿布、睡眠等）
- 📊 数据统计和分析
- ⏱️ 计时器功能
- 📱 移动端友好界面

### 访问路径

| 路径 | 说明 |
|------|------|
| `/baby-core` | 首页 |
| `/baby-core/login` | 登录页 |
| `/baby-core/api/*` | API 接口 |

## 🛠️ 常用命令

```bash
# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 备份数据
cp data/baby_tracker.db backups/backup-$(date +%Y%m%d).db
```

## 🆘 遇到问题？

### 1. 运行验证脚本

```bash
./verify-deployment.sh
```

### 2. 查看日志

```bash
docker-compose logs -f
```

### 3. 查阅文档

- **常见问题**: [`DEPLOYMENT_DOCKER.md`](./DEPLOYMENT_DOCKER.md) 故障排查章节
- **详细配置**: [`DOCKER_DEPLOYMENT_README.md`](./DOCKER_DEPLOYMENT_README.md)

### 4. 重新部署

```bash
docker-compose down
./deploy.sh
```

## 🔒 安全建议

✅ **必须做**:
- 修改 `.env` 中的 `JWT_SECRET`
- 修改默认密码 `admin123`
- 配置防火墙

⭐ **建议做**:
- 配置 HTTPS (Let's Encrypt)
- 设置定期备份
- 限制 SSH 访问

## 📊 部署架构

```
┌─────────┐
│  用户   │
└────┬────┘
     │ :80
     ▼
┌─────────┐    ┌─────────────┐    ┌──────────┐
│  Nginx  │───▶│  Baby-Core  │───▶│ SQLite   │
│   :80   │    │    :8899    │    │ Database │
└─────────┘    └─────────────┘    └──────────┘
```

## 📞 支持

- **项目文档**: `/baby-core/README.md`
- **部署问题**: 查看相关文档的故障排查章节

## 🎉 开始使用

现在你已经准备好了！选择一个部署方式开始吧：

- 🚀 快速体验 → [`QUICKSTART_DOCKER.md`](./QUICKSTART_DOCKER.md)
- 📚 完整部署 → [`SERVER_SETUP.md`](./SERVER_SETUP.md)

---

**祝你部署顺利！Happy Tracking! 👶**

**版本**: 1.0.0  
**更新**: 2025-10-27

