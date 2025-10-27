# 软删除功能说明

## 功能概述

为baby-core项目添加了记录软删除功能，用户可以标记删除记录并随时恢复。

## 实现的功能

### 1. 后端改动

#### 数据库迁移
- 新增 `sql/004_soft_delete.sql` 迁移脚本
- 为 `records` 表添加 `deleted_at` 字段（可为NULL）
- 添加相关索引以优化查询性能

#### 模型层（models/record.go）
- Record结构体新增 `DeletedAt` 和 `IsDeleted` 字段
- 新增 `SoftDeleteRecord()` 方法：标记记录为已删除
- 新增 `RestoreRecord()` 方法：恢复已删除的记录
- 更新所有查询方法以支持软删除字段
- 查询结果自动按删除状态排序（正常记录在前）

#### API接口（handlers/records.go）
- 修改 `DeleteRecord` 接口使用软删除
- 新增 `RestoreRecord` 接口（PUT /api/records/restore?id=xxx）
- 添加路由配置到 main.go

### 2. 前端改动

#### API调用（api/index.js）
- 新增 `restoreRecord(id)` 方法

#### 记录列表组件（components/RecordList.vue）
- 每条记录右侧添加操作按钮
- 正常记录显示"删除"按钮（红色）
- 已删除记录显示"恢复"按钮（绿色）
- 已删除记录视觉效果：
  - 置灰背景（#f5f5f5）
  - 降低透明度（70%）
  - 内容中间添加横线
  - 所有文字和标签变为灰色

#### 跟踪页面（views/Tracking.vue）
- 添加 `handleDelete()` 处理删除操作
- 添加 `handleRestore()` 处理恢复操作
- 操作完成后自动刷新记录列表

## 设计特点

### 视觉设计
- 已删除记录采用低调的灰色调，不影响正常记录的阅读
- 横线效果清晰标记删除状态
- 按钮颜色直观（删除=红色，恢复=绿色）
- 保持原有温馨暖色调设计风格

### 用户体验
- 点击按钮时显示"处理中..."状态，防止重复操作
- 操作失败时显示友好的错误提示
- 已删除记录自动排列在列表底部
- 支持随时恢复误删的记录

### 技术亮点
- 真正的软删除，数据不会丢失
- 数据库层面的软删除，保证数据一致性
- 前后端类型安全的实现
- 响应式设计，按钮hover有视觉反馈

## 使用方法

### 应用数据库迁移

运行迁移脚本以添加软删除支持：

```bash
cd backend
sqlite3 baby_tracker.db < ../sql/004_soft_delete.sql
```

### 重新编译和部署

```bash
# 重新构建后端
cd backend
go build -o baby-tracker

# 重新构建前端
cd ../web
npm run build

# 复制前端构建产物到后端
cp -r dist ../backend/

# 重启服务
cd ../backend
./baby-tracker
```

### 使用Docker部署

```bash
# 重新构建镜像
docker-compose build

# 重启服务
docker-compose up -d
```

## API接口说明

### 软删除记录
```
DELETE /api/records?id={record_id}
Authorization: Bearer {token}
```

### 恢复记录
```
PUT /api/records/restore?id={record_id}
Authorization: Bearer {token}
```

### 获取记录（包含已删除）
```
GET /api/records?date={YYYY-MM-DD}
Authorization: Bearer {token}
```
返回的记录中，`is_deleted` 字段标记删除状态。

## 注意事项

1. 现有数据库需要运行迁移脚本才能使用此功能
2. 已删除的记录仍然会在列表中显示，只是样式不同
3. 如需永久删除记录，可以使用原有的 `DeleteRecord` 函数（代码中保留但不在API中公开）
4. 建议定期清理长期未恢复的软删除记录

## 未来优化方向

- 添加"隐藏已删除记录"的筛选选项
- 添加批量删除/恢复功能
- 添加永久删除的管理界面
- 设置自动清理超过X天的软删除记录

