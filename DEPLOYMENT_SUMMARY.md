# Baby Core Docker 部署总结

## 📦 部署包内容

本部署包包含了在 Debian 12 服务器上使用 Docker 部署 Baby Core 应用所需的所有文件。

### 核心文件

```
baby-core/
├── Dockerfile                      # Docker 镜像构建文件
├── docker-compose.yml              # Docker Compose 编排配置
├── .env.example                    # 环境变量模板
├── .dockerignore                   # Docker 构建忽略文件
├── nginx/
│   └── nginx.conf                 # Nginx 反向代理配置
├── deploy.sh                       # 一键部署脚本 ⭐
├── init-user-simple.sh            # 快速创建用户脚本
├── init-user.sh                   # 交互式创建用户脚本
└── verify-deployment.sh           # 部署验证脚本
```

### 文档文件

```
├── QUICKSTART_DOCKER.md           # 快速开始指南（5分钟） ⭐
├── DEPLOYMENT_DOCKER.md           # 完整部署文档
├── SERVER_SETUP.md                # 服务器从零配置指南
├── DOCKER_DEPLOYMENT_README.md    # 部署配置说明
└── DEPLOYMENT_SUMMARY.md          # 本文件
```

## 🚀 部署方式选择

### 方式一：快速部署（推荐新手）⭐

适合：首次部署，想要快速体验

```bash
# 1. 上传项目到服务器
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

# 5. 验证部署
chmod +x verify-deployment.sh
./verify-deployment.sh
```

**预计时间**: 5-10 分钟

**参考文档**: `QUICKSTART_DOCKER.md`

### 方式二：完整部署（推荐生产环境）

适合：生产环境，需要详细配置

1. 按照 `SERVER_SETUP.md` 配置服务器
2. 按照 `DEPLOYMENT_DOCKER.md` 进行完整部署
3. 配置 HTTPS 证书
4. 设置定时备份
5. 配置监控

**预计时间**: 30-60 分钟

**参考文档**: `SERVER_SETUP.md` + `DEPLOYMENT_DOCKER.md`

### 方式三：手动部署（推荐高级用户）

适合：需要自定义配置

```bash
# 手动执行每个步骤
mkdir -p data nginx/logs
docker-compose build
docker-compose up -d
docker-compose logs -f
```

**参考文档**: `DOCKER_DEPLOYMENT_README.md`

## 🎯 快速开始步骤

### 1. 前置准备

**在服务器上安装**:
- Docker 20.10+
- Docker Compose 2.0+

**如果未安装**，参考 `SERVER_SETUP.md` 第二、三步。

### 2. 上传项目

```bash
# 方式 A: 使用 SCP
tar -czf baby-core.tar.gz .
scp baby-core.tar.gz user@server:/home/user/

# 方式 B: 使用 Git
git clone https://your-repo/baby-core.git
```

### 3. 配置环境

```bash
cd baby-core
cp .env.example .env
nano .env
```

**必须修改**:
```env
JWT_SECRET=your-generated-secret-key-here
```

生成密钥:
```bash
openssl rand -base64 32
```

### 4. 执行部署

```bash
chmod +x deploy.sh
./deploy.sh
```

### 5. 创建用户

```bash
chmod +x init-user-simple.sh
./init-user-simple.sh
```

默认凭据:
- 用户名: `admin`
- 密码: `admin123`

### 6. 访问应用

```
http://your-server-ip/baby-core
```

## 📊 部署架构

```
Internet
    │
    ▼
┌─────────────────┐
│  Nginx (80)     │ ◄── 反向代理
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Baby-Core       │ ◄── Go 应用 + Vue 前端
│   (8899)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SQLite DB      │ ◄── 数据持久化
│  (./data/)      │
└─────────────────┘
```

## 🔑 关键配置

### 端口映射

| 服务 | 外部端口 | 内部端口 | 用途 |
|------|---------|---------|------|
| Nginx | 80 | 80 | 前端访问 |
| Baby-Core | 8899 | 8899 | 后端服务 |

### 访问路径

| 路径 | 说明 |
|------|------|
| `/baby-core` | 应用首页 |
| `/baby-core/login` | 登录页面 |
| `/baby-core/api/*` | API 接口 |

### 数据目录

| 路径 | 说明 |
|------|------|
| `./data/` | 数据库目录 |
| `./nginx/logs/` | Nginx 日志 |

## ⚙️ 常用操作

### 查看状态

```bash
docker-compose ps
docker-compose logs -f
```

### 重启服务

```bash
docker-compose restart
```

### 停止服务

```bash
docker-compose down
```

### 更新应用

```bash
docker-compose down
docker-compose up -d --build
```

### 备份数据

```bash
cp data/baby_tracker.db backups/baby_tracker.db.$(date +%Y%m%d)
```

## 🔒 安全检查清单

- [ ] 修改 `.env` 中的 `JWT_SECRET`
- [ ] 修改默认用户密码（admin/admin123）
- [ ] 配置防火墙（只开放 80, 443, SSH）
- [ ] 配置 HTTPS 证书（推荐 Let's Encrypt）
- [ ] 设置定期备份任务
- [ ] 限制 SSH 访问（密钥认证）
- [ ] 定期更新系统和 Docker 镜像

## 📚 文档导航

### 按用户类型

**新手用户**:
1. 阅读 `QUICKSTART_DOCKER.md`
2. 执行 5 分钟部署
3. 遇到问题查看 `DEPLOYMENT_DOCKER.md` 故障排查章节

**高级用户**:
1. 阅读 `DOCKER_DEPLOYMENT_README.md` 了解架构
2. 根据需要自定义配置
3. 参考 `DEPLOYMENT_DOCKER.md` 的高级配置

**运维人员**:
1. 阅读 `SERVER_SETUP.md` 配置服务器
2. 按照 `DEPLOYMENT_DOCKER.md` 部署
3. 设置监控和备份

### 按场景

**首次部署**: `QUICKSTART_DOCKER.md`

**生产环境**: `SERVER_SETUP.md` → `DEPLOYMENT_DOCKER.md`

**故障排查**: `DEPLOYMENT_DOCKER.md` 故障排查章节

**安全加固**: `SERVER_SETUP.md` 安全建议章节

**性能优化**: `DEPLOYMENT_DOCKER.md` 性能优化章节

## 🆘 获取帮助

### 遇到问题？

1. **查看日志**
   ```bash
   docker-compose logs -f
   ```

2. **运行验证脚本**
   ```bash
   ./verify-deployment.sh
   ```

3. **检查服务状态**
   ```bash
   docker-compose ps
   ```

4. **查看文档**
   - 故障排查: `DEPLOYMENT_DOCKER.md`
   - 服务器配置: `SERVER_SETUP.md`

### 常见问题

**Q: 无法访问应用**
A: 检查防火墙和容器状态
```bash
sudo ufw status
docker-compose ps
```

**Q: 登录失败**
A: 确保已创建用户
```bash
./init-user-simple.sh
```

**Q: 数据库错误**
A: 检查数据目录权限
```bash
ls -la data/
chmod 755 data/
```

## ✅ 验证清单

部署完成后，确认以下项目：

- [ ] Docker 容器正常运行 (`docker-compose ps`)
- [ ] 可以访问 `http://server-ip/baby-core`
- [ ] 可以正常登录
- [ ] API 请求正常工作
- [ ] 数据库文件已创建 (`data/baby_tracker.db`)
- [ ] 日志正常记录 (`nginx/logs/`)
- [ ] `.env` 文件配置正确
- [ ] JWT_SECRET 已修改
- [ ] 默认密码已修改

运行验证脚本:
```bash
./verify-deployment.sh
```

## 🎉 部署成功！

如果所有检查通过，恭喜你成功部署了 Baby Core！

**下一步**:
1. 使用应用，熟悉功能
2. 设置定期备份
3. 考虑配置 HTTPS
4. 邀请家人使用

**支持**:
- 项目 README: `README.md`
- 问题反馈: GitHub Issues

---

**部署包版本**: 1.0.0  
**更新日期**: 2025-10-27  
**适用系统**: Debian 12 / Ubuntu 20.04+ / CentOS 8+

**Happy Tracking! 👶**

