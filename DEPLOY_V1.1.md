# Baby Core v1.1 部署指南 - 覆盖更新方式

## ⚠️ 重要提示

**此部署方式会重建数据库，所有现有数据将丢失！**

如果生产环境有重要数据，请先备份！

## 📦 更新内容

- ✨ 软删除功能（删除后可恢复）
- 🎨 记录按时间排序
- 🕐 时区修复（Asia/Shanghai）
- 🎨 类型标签保持颜色识别

## 🚀 部署步骤

### 方式1：有现有数据（需备份）

```bash
# 1. 备份现有数据库
docker-compose exec baby-core cp /app/data/baby_tracker.db /app/data/baby_tracker_backup_$(date +%Y%m%d).db

# 可选：导出到本地
docker cp baby-core:/app/data/baby_tracker_backup_*.db ./

# 2. 停止服务
docker-compose down

# 3. 删除旧数据库
rm -rf data/baby_tracker.db

# 4. 拉取最新代码
git pull origin main

# 5. 重新部署
./deploy.sh
```

### 方式2：无重要数据或全新部署

```bash
# 1. 停止服务
docker-compose down

# 2. 清空数据
rm -rf data/

# 3. 拉取最新代码
git pull origin main

# 4. 部署
./deploy.sh
```

### 方式3：首次部署

```bash
git clone <repo-url>
cd baby-core
./deploy.sh
```

## ✅ 验证

```bash
# 1. 检查容器状态
docker-compose ps

# 2. 检查数据库结构（应该有deleted_at字段）
docker-compose exec baby-core sqlite3 /app/data/baby_tracker.db "PRAGMA table_info(records);" | grep deleted_at

# 3. 检查时区
docker-compose exec baby-core date

# 4. 访问应用测试
curl http://localhost/
```

## 🧪 功能测试

访问应用 http://localhost （或你的域名）

1. 登录（admin / admin123）
2. 创建一条记录
3. 点击"删除"按钮 → 记录变灰并显示横线
4. 点击"恢复"按钮 → 记录恢复正常

## 📝 技术变更

### 数据库Schema更新
- 新增字段：`deleted_at DATETIME DEFAULT NULL`
- 新增索引：`idx_records_deleted_at`, `idx_records_user_deleted`

### 代码更新
- 后端：软删除和恢复API
- 前端：删除/恢复按钮和样式
- Docker：时区配置

## 🔄 数据迁移（如需保留数据）

如果你有重要的现有数据需要迁移，可以手动操作：

```bash
# 1. 备份数据
docker-compose exec baby-core sqlite3 /app/data/baby_tracker.db ".dump" > backup.sql

# 2. 部署新版本（会创建新数据库）
docker-compose down
rm data/baby_tracker.db
git pull origin main
./deploy.sh

# 3. 导入数据
docker-compose exec -T baby-core sqlite3 /app/data/baby_tracker.db < backup.sql

# 注意：新版本的数据库已包含deleted_at字段，旧数据的deleted_at会是NULL（正常状态）
```

## 📚 相关文档

- `SOFT_DELETE_FEATURE.md` - 功能详细说明
- `SOFT_DELETE_FIX.md` - 设计说明
- `SERVER_DEPLOY_GUIDE.md` - 服务器配置

## 🆘 遇到问题？

### 500错误
```bash
# 检查日志
docker-compose logs baby-core --tail=50

# 检查数据库
docker-compose exec baby-core sqlite3 /app/data/baby_tracker.db "PRAGMA table_info(records);"
```

### 时间不对
```bash
# 检查容器时区
docker-compose exec baby-core date

# 应该显示正确的北京时间
```

### 重新部署
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

**预计时间**: 5分钟  
**停机时间**: 2-5分钟  
**数据影响**: ⚠️ 会重建数据库

