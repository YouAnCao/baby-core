# Baby Core v1.1 - 最新修复汇总

## 🐛 修复的问题

### 1. ✅ 日期显示问题
**问题**: 前端显示的日期少一天（显示27日，实际是28日）

**原因**: 使用`toISOString()`返回UTC时间，在UTC+8时区会少一天

**解决**: 
```javascript
// 错误：
date.toISOString().split('T')[0]  // 返回UTC日期

// 正确：
const year = date.getFullYear()
const month = String(date.getMonth() + 1).padStart(2, '0')
const day = String(date.getDate()).padStart(2, '0')
return `${year}-${month}-${day}`  // 返回本地日期
```

**影响文件**: `web/src/views/Tracking.vue`

---

### 2. ✅ 提交时日期错误
**问题**: 虽然抬头显示正确日期，但提交记录时还是昨天的日期

**原因**: 提交时没有使用父组件传入的`currentDate`，而是直接用`new Date()`

**解决**: 
- 添加`getCurrentDateTime()`函数
- 使用`props.currentDate`构建正确的日期时间
- 包含正确的时区信息（+08:00）

**影响文件**: `web/src/components/QuickEntry.vue`

---

### 3. ✅ 计时器息屏归零
**问题**: 开始计时后，手机息屏或切换应用，再进入时计时归零

**原因**: 计时器状态只保存在内存中，页面失去焦点后状态丢失

**解决**: 
- 使用`localStorage`持久化计时器状态
- 保存**开始时间**而非累计秒数
- 页面恢复时根据开始时间重新计算
- 自动恢复计时器界面和运行状态

**实现细节**:
```javascript
// 保存到localStorage
{
  method: 'breast_left',
  startTime: '2025-10-28T04:30:15.123Z',
  targetSeconds: 300,
  notes: '备注'
}

// 恢复时重新计算
const elapsedSeconds = Math.floor((now - startTime) / 1000)
```

**影响文件**: `web/src/components/QuickEntry.vue`

---

## 🎯 测试场景

### 场景1: 日期显示
1. ✅ 打开应用，查看顶部日期显示
2. ✅ 应该显示今天的日期（2025-10-28）
3. ✅ 点击前后切换日期按钮，日期正确变化

### 场景2: 提交日期
1. ✅ 切换到昨天（2025-10-27）
2. ✅ 创建一条喂养记录
3. ✅ 记录应该保存为 2025-10-27，而不是今天

### 场景3: 计时器持久化
1. ✅ 点击"母乳-左"，开始计时
2. ✅ 手机息屏或切换到其他应用
3. ✅ 等待1-2分钟
4. ✅ 返回应用，计时器应该继续运行，时间正确累计
5. ✅ 刷新页面，计时器界面自动恢复并继续运行
6. ✅ 点击"结束并保存"，记录保存成功
7. ✅ 再次打开"母乳-左"，计时器从0开始（已清除旧状态）

---

## 🚀 部署到服务器

```bash
# 1. 停止服务
docker-compose down

# 2. 清空旧数据库（可选，如无重要数据）
rm -rf data/

# 3. 拉取最新代码
git pull origin main

# 4. 重新部署
./deploy.sh
```

**或者保留数据（可选）**:
```bash
# 1. 备份数据库
docker-compose exec baby-core sqlite3 /app/data/baby_tracker.db ".dump" > backup.sql

# 2. 部署新版本
docker-compose down
rm data/baby_tracker.db
git pull origin main
./deploy.sh

# 3. 恢复数据
docker-compose exec -T baby-core sqlite3 /app/data/baby_tracker.db < backup.sql
```

---

## 📊 更新统计

### 提交历史
```
db0f79b fix: 修复日期提交和计时器持久化问题
a84b54a fix: 修复前端日期显示时区问题
f1b3022 refactor: 改为覆盖更新方式，简化部署
```

### 修改的文件
- `web/src/views/Tracking.vue` - 日期显示修复
- `web/src/components/QuickEntry.vue` - 日期提交和计时器持久化
- `backend/dist/` - 重新构建的前端资源

### 代码变更
- 新增 `getCurrentDateTime()` 函数
- 新增 `saveTimerState()` 函数
- 新增 `restoreTimerState()` 函数
- 修改 `formatDate()` 函数
- 修改 `startTimer()` 函数
- 修改 `stopTimer()` 函数
- 添加 `onMounted` 生命周期钩子

---

## ✨ 现在可用的功能

1. ✅ **软删除功能** - 删除记录后可恢复
2. ✅ **正确的日期显示** - 匹配用户本地时区
3. ✅ **正确的日期提交** - 使用选择的日期
4. ✅ **计时器持久化** - 息屏/切换应用后继续计时
5. ✅ **Docker时区修复** - 容器使用Asia/Shanghai
6. ✅ **记录排序优化** - 按时间自然排序
7. ✅ **类型标签可识别** - 删除状态下保持颜色

---

## 📝 技术细节

### localStorage结构
```javascript
// Key: 'feeding_timer_state'
{
  "method": "breast_left",
  "startTime": "2025-10-28T04:30:15.123Z",
  "targetSeconds": 300,
  "notes": "备注内容"
}
```

### 时间格式
```javascript
// 提交给后端的格式（包含时区）
"2025-10-28T16:30:45.123+08:00"

// 显示给用户的格式
"2025-10-28"
```

### 计时器恢复逻辑
1. 页面加载时检查localStorage
2. 如果有保存的状态，计算已运行时间
3. 恢复界面（打开弹窗）
4. 重新启动计时器interval
5. 提交成功或取消时清除localStorage

---

**预计测试时间**: 5分钟  
**部署时间**: 5-10分钟  
**风险等级**: 低 ✅

🎉 **所有问题已修复，可以部署！**

