# Baby Core v1.0 → v1.1 升级指南

## 📦 版本信息

- **当前版本**: v1.0
- **目标版本**: v1.1 (软删除功能)
- **升级类型**: 功能增强
- **数据库变更**: ✅ 需要迁移
- **停机时间**: 约2-5分钟

## ✨ 新功能概述

### 软删除功能
- ✅ 删除记录后记录变灰并显示横线（数据保留）
- ✅ 一键恢复已删除记录
- ✅ 记录按时间顺序自然排列
- ✅ 类型标签保持原色（易于识别）

### 问题修复
- ✅ 时区修复（Docker容器使用Asia/Shanghai）
- ✅ 时间显示正确（不再少一天）

## 🚀 升级步骤（3步）

### 前置条件
- 已部署v1.0版本
- 有SSH访问权限
- Docker和docker-compose已安装

### Step 1: 拉取最新代码

```bash
# SSH登录服务器
ssh user@your-server

# 进入项目目录
cd /path/to/baby-core

# 拉取最新代码
git pull origin main
```

### Step 2: 运行数据库迁移补丁

```bash
# 执行补丁脚本
./patch-soft-delete.sh
```

**脚本会自动**：
- ✅ 检查容器状态
- ✅ 备份现有数据库
- ✅ 添加 `deleted_at` 字段
- ✅ 验证迁移成功

**预期输出**：
```
==========================================
Baby Core v1.0 → v1.1 升级补丁
软删除功能数据库迁移
==========================================

[步骤 1/2] 迁移现有数据库...

✓ 检测到正在运行的 baby-core 容器
✓ 数据库文件存在
检查数据库结构...

准备应用迁移脚本...
创建数据库备份...
✓ 备份已创建: data/baby_tracker_backup_20251028_041234.db

应用软删除迁移...
✓ 数据库迁移成功！
✓ deleted_at 字段已添加

[步骤 2/2] 准备重新部署...

==========================================
数据库迁移完成！
==========================================

📋 下一步操作:
   运行部署脚本以应用新代码:
   ./deploy.sh
```

### Step 3: 重新部署应用

```bash
# 运行部署脚本
./deploy.sh
```

**部署脚本会**：
- 停止现有容器
- 重新构建包含软删除功能的镜像
- 启动新容器
- 执行健康检查

**完成标志**：
```
==========================================
部署完成！
==========================================

访问地址:
  - 应用: http://your-server-ip/baby-core
  - API: http://your-server-ip/baby-core/api
```

## ✅ 验证升级

### 1. 检查容器状态
```bash
docker-compose ps
# 应该看到 baby-core 和 nginx 都是 Up (healthy)
```

### 2. 检查时区
```bash
docker-compose exec baby-core date
# 应该显示正确的北京时间
```

### 3. 检查数据库
```bash
docker-compose exec baby-core sqlite3 /app/data/baby_tracker.db "PRAGMA table_info(records);" | grep deleted
# 应该看到: 8|deleted_at|DATETIME|0|NULL|0
```

### 4. 功能测试

访问应用: `http://your-server-ip/baby-core`

1. ✅ 登录系统
2. ✅ 创建一条测试记录
3. ✅ 点击"删除"按钮
   - 记录应该变灰
   - 显示横线
   - 类型标签保持颜色
   - 按钮变为绿色"恢复"
4. ✅ 点击"恢复"按钮
   - 记录恢复正常
   - 按钮变回红色"删除"
5. ✅ 刷新页面，状态保持

## 📊 技术细节

### 数据库变更

**新增字段**：
```sql
ALTER TABLE records ADD COLUMN deleted_at DATETIME DEFAULT NULL;
```

**新增索引**：
```sql
CREATE INDEX idx_records_deleted_at ON records(deleted_at);
CREATE INDEX idx_records_user_deleted ON records(user_id, deleted_at);
```

### 修改的文件
- `backend/models/record.go` - 软删除逻辑
- `backend/handlers/records.go` - 恢复接口
- `backend/main.go` - 路由配置
- `web/src/components/RecordList.vue` - UI和样式
- `web/src/api/index.js` - API调用
- `web/src/views/Tracking.vue` - 事件处理
- `Dockerfile` - 时区配置

### 新增的文件
- `sql/004_soft_delete.sql` - 迁移脚本
- `patch-soft-delete.sh` - 补丁脚本
- `SOFT_DELETE_FEATURE.md` - 功能说明
- `SERVER_DEPLOY_GUIDE.md` - 部署指南

## 🔙 回滚方案

如果升级后发现问题，可以回滚：

### 方案1: 回滚代码（推荐）
```bash
# 回滚到v1.0
git reset --hard <v1.0-commit-hash>

# 重新部署
./deploy.sh
```

**注意**: `deleted_at`字段会保留但不影响系统运行。

### 方案2: 恢复数据库备份
```bash
# 进入容器
docker-compose exec baby-core sh

# 恢复备份
cp /app/data/baby_tracker_backup_*.db /app/data/baby_tracker.db

# 退出并重启
exit
docker-compose restart baby-core
```

## 💡 常见问题

### Q1: 升级需要停机吗？
A: 需要短暂停机（2-5分钟），在运行`./deploy.sh`期间。

### Q2: 现有数据会丢失吗？
A: 不会。软删除只是添加新字段，所有数据保持完整。

### Q3: 升级失败怎么办？
A: 
1. 检查日志: `docker-compose logs baby-core`
2. 如有备份，可以恢复
3. 参考回滚方案

### Q4: 可以跳过迁移脚本直接部署吗？
A: 不推荐。虽然系统会自动创建新字段，但可能导致短暂的500错误。

### Q5: 旧版本的记录会显示为已删除吗？
A: 不会。旧记录的`deleted_at`为NULL，显示为正常记录。

## 📞 技术支持

如遇问题，请：
1. 查看容器日志: `docker-compose logs -f baby-core`
2. 查看数据库状态: 见上方验证部分
3. 查看详细文档:
   - `SERVER_DEPLOY_GUIDE.md` - 详细部署说明
   - `SOFT_DELETE_FEATURE.md` - 功能说明
   - `DEPLOY_SUMMARY.md` - 部署摘要

## 📝 升级检查清单

部署前：
- [ ] 已备份数据库（可选）
- [ ] 已通知用户短暂停机
- [ ] 已拉取最新代码

部署中：
- [ ] 运行 `patch-soft-delete.sh` 成功
- [ ] 运行 `./deploy.sh` 成功
- [ ] 容器启动正常

部署后：
- [ ] 容器状态健康
- [ ] 时区显示正确
- [ ] 可以创建记录
- [ ] 删除功能正常（记录变灰）
- [ ] 恢复功能正常
- [ ] 通知用户服务恢复

---

**预计总时长**: 5-10分钟
**建议操作时间**: 低峰期
**风险等级**: 低（有回滚方案+数据备份）

🎉 **祝升级顺利！**

