# Baby Core 服务器部署指南 - 软删除功能更新

## 📦 更新内容

**版本**: v1.1 - 软删除功能
**提交**: 6db00a4
**日期**: 2025-10-28

### ✨ 新功能

1. **软删除记录**
   - 点击"删除"按钮后，记录变灰并显示横线
   - 已删除记录显示"恢复"按钮
   - 数据不会真正删除，可随时恢复

2. **智能排序**
   - 记录按时间顺序排列
   - 保持时间线的连续性
   - 已删除和未删除记录混合显示

3. **视觉优化**
   - 类型标签保持颜色（喂养=蓝色，尿布=棕色）
   - 已删除记录通过灰色背景和横线标识
   - 低调不喧宾夺主的设计

4. **时区修复**
   - Docker容器时区设置为 Asia/Shanghai
   - 解决时间少一天的问题

## 🚀 服务器部署步骤

### 方式一：使用补丁脚本 + 原有部署脚本（推荐）

```bash
# 1. SSH登录服务器
ssh user@your-server

# 2. 进入项目目录
cd /path/to/baby-core

# 3. 拉取最新代码
git pull origin main

# 4. 运行补丁脚本（处理数据库迁移）
./patch-soft-delete.sh

# 5. 运行原有部署脚本
./deploy.sh
```

### 方式二：手动部署

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 停止现有服务
docker-compose down

# 3. 迁移数据库（如果数据库已存在）
sqlite3 data/baby_tracker.db < sql/004_soft_delete.sql

# 4. 重新构建镜像
docker-compose build --no-cache baby-core

# 5. 启动服务
docker-compose up -d

# 6. 查看状态
docker-compose ps
docker-compose logs -f baby-core
```

## ✅ 部署验证

### 1. 检查容器状态

```bash
docker-compose ps
# 应该看到 baby-core 和 nginx 都是 Up 状态
```

### 2. 检查时区

```bash
docker-compose exec baby-core date
# 应该显示正确的北京时间
```

### 3. 检查数据库字段

```bash
docker-compose exec baby-core sh -c "sqlite3 /app/data/baby_tracker.db 'PRAGMA table_info(records);'"
# 应该能看到 deleted_at 字段
```

### 4. 检查日志

```bash
docker-compose logs baby-core --tail=50
# 检查是否有错误信息
```

### 5. 功能测试

访问应用: `http://your-server-ip/baby-core`

1. 登录系统
2. 创建一条测试记录
3. 点击"删除"按钮
   - ✅ 记录应该变灰
   - ✅ 内容应该有横线
   - ✅ 类型标签应该保持颜色
   - ✅ 右侧按钮变为绿色"恢复"
4. 点击"恢复"按钮
   - ✅ 记录恢复正常
   - ✅ 按钮变回红色"删除"
5. 刷新页面
   - ✅ 删除状态保持

## 📋 文件清单

### 修改的文件

```
backend/
├── handlers/records.go      # 添加RestoreRecord接口
├── main.go                   # 添加恢复路由
└── models/record.go          # 软删除和恢复方法

web/src/
├── api/index.js              # 添加restoreRecord API
├── components/RecordList.vue # 删除/恢复按钮和样式
└── views/Tracking.vue        # 事件处理

Dockerfile                    # 添加时区配置
```

### 新增的文件

```
sql/004_soft_delete.sql       # 数据库迁移脚本
patch-soft-delete.sh          # 补丁部署脚本
SOFT_DELETE_FEATURE.md        # 功能说明
SOFT_DELETE_FIX.md            # 设计说明
START_AND_TEST.md             # 测试指南
SERVER_DEPLOY_GUIDE.md        # 本文档
```

## 🔧 数据库变更

### 新增字段

```sql
ALTER TABLE records ADD COLUMN deleted_at DATETIME DEFAULT NULL;
```

### 新增索引

```sql
CREATE INDEX idx_records_deleted_at ON records(deleted_at);
CREATE INDEX idx_records_user_deleted ON records(user_id, deleted_at);
```

## 🔙 回滚方案

如果部署后发现问题，可以回滚到上一个版本：

```bash
# 1. 回滚代码
git log --oneline  # 查看提交历史
git reset --hard <previous-commit-hash>

# 2. 重新部署
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**注意**: 数据库的 `deleted_at` 字段不会被删除，但不会影响系统运行。

## 🐛 故障排查

### 问题1: 创建记录时报500错误

**原因**: 数据库缺少 `deleted_at` 字段

**解决**:
```bash
# 停止服务
docker-compose down

# 应用迁移
sqlite3 data/baby_tracker.db < sql/004_soft_delete.sql

# 重启服务
docker-compose up -d
```

### 问题2: 时间显示不正确

**原因**: 容器时区未设置

**解决**:
```bash
# 检查容器时区
docker-compose exec baby-core date

# 如果不正确，重新构建镜像
docker-compose build --no-cache baby-core
docker-compose up -d
```

### 问题3: 删除功能不工作

**解决**:
```bash
# 1. 检查日志
docker-compose logs baby-core --tail=100

# 2. 检查前端构建文件
docker-compose exec baby-core ls -la /app/dist/

# 3. 清除浏览器缓存
# 在浏览器中按 Ctrl+Shift+Delete 清除缓存
```

## 📊 性能影响

- **数据库**: 新增2个索引，查询性能不受影响
- **存储**: 每条已删除记录增加8字节（deleted_at时间戳）
- **API响应**: 响应体略微增加（is_deleted字段）
- **总体影响**: 可忽略不计

## 🔒 安全说明

- 软删除的记录仍然存在于数据库中
- 只有记录所有者可以删除和恢复自己的记录
- JWT认证保持不变
- 建议定期清理长期未恢复的软删除记录

## 📞 支持

如有问题，请查看:
- `SOFT_DELETE_FEATURE.md` - 功能详细说明
- `SOFT_DELETE_FIX.md` - 设计理念
- `START_AND_TEST.md` - 本地测试指南

---

**部署完成后，别忘了测试软删除功能！** 🎉

