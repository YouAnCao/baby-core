# 软删除功能 - 启动和测试说明

## ✅ 准备工作已完成

1. ✅ 数据库已添加 `deleted_at` 字段
2. ✅ 后端代码已更新并编译（包含软删除功能）
3. ✅ 前端代码已更新并构建
4. ✅ 所有文件都是最新的

## 🚀 手动启动服务（推荐）

### 步骤1：打开终端并进入backend目录

```bash
cd /Users/lyon.cao/dev/python/baby-core/backend
```

### 步骤2：直接运行服务

```bash
./baby-tracker
```

你应该看到类似输出：
```
2025/10/28 03:59:00 Database initialized successfully
2025/10/28 03:59:00 Server starting on http://localhost:8080
```

**保持这个终端窗口打开！服务将在前台运行。**

## 🧪 测试软删除功能

### 方法1：浏览器测试（最简单）

1. **打开浏览器**
   ```
   http://localhost:8080
   ```

2. **登录**
   - 用户名：`admin`
   - 密码：`admin123`

3. **创建记录并测试**
   - 创建一条喂养或尿布记录
   - 点击记录右侧的红色"删除"按钮
   - **观察：** 记录变灰、出现横线、按钮变成绿色"恢复"
   - 点击绿色"恢复"按钮
   - **观察：** 记录恢复正常、按钮变回红色"删除"

### 方法2：API测试（打开新终端）

保持服务运行，打开**新的终端窗口**，执行以下命令：

```bash
# 设置服务器地址
SERVER="http://localhost:8080"

# 1. 登录获取token
TOKEN=$(curl -s $SERVER/api/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Token: ${TOKEN:0:50}..."

# 2. 创建测试记录
RECORD=$(curl -s $SERVER/api/records \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "record_type": "feeding",
    "record_time": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "details": "{\"method\":\"breast_left\",\"duration_minutes\":15}",
    "notes": "软删除测试"
  }')

RECORD_ID=$(echo $RECORD | grep -o '"id":[0-9]*' | cut -d':' -f2)
echo "创建的记录ID: $RECORD_ID"

# 3. 软删除记录
echo ""
echo "执行删除..."
curl -s "$SERVER/api/records?id=$RECORD_ID" \
  -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  -w "HTTP状态码: %{http_code}\n"

# 4. 检查数据库（记录应该还在，但deleted_at有值）
echo ""
echo "数据库检查："
cd /Users/lyon.cao/dev/python/baby-core/backend
sqlite3 baby_tracker.db "SELECT id, record_type, 
  CASE WHEN deleted_at IS NULL THEN '正常' ELSE '已删除' END as status,
  datetime(deleted_at) as deleted_time
FROM records WHERE id=$RECORD_ID;"

# 5. 恢复记录
echo ""
echo "执行恢复..."
curl -s "$SERVER/api/records/restore?id=$RECORD_ID" \
  -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -w "HTTP状态码: %{http_code}\n"

# 6. 再次检查数据库
echo ""
echo "恢复后数据库检查："
sqlite3 baby_tracker.db "SELECT id, record_type, 
  CASE WHEN deleted_at IS NULL THEN '正常' ELSE '已删除' END as status
FROM records WHERE id=$RECORD_ID;"
```

## ✅ 成功标志

如果看到以下情况，说明功能正常：

1. **浏览器测试**
   - ✅ 删除后记录变灰并出现横线
   - ✅ 删除后按钮变成绿色"恢复"
   - ✅ 恢复后记录变回正常
   - ✅ 刷新页面后状态保持

2. **API/数据库测试**
   - ✅ 删除后数据库status显示"已删除"
   - ✅ 记录仍然存在于数据库中
   - ✅ deleted_at字段有时间值
   - ✅ 恢复后status变回"正常"
   - ✅ deleted_at字段变为空

## ❌ 问题排查

### 服务启动失败

```bash
# 检查端口占用
lsof -i :8080

# 如果有进程占用，杀掉它
kill -9 <PID>

# 重新启动
cd /Users/lyon.cao/dev/python/baby-core/backend
./baby-tracker
```

### 记录被物理删除而不是软删除

如果数据库检查发现记录完全消失了，说明服务可能使用了旧代码。解决方法：

```bash
# 1. 停止服务（在服务运行的终端按 Ctrl+C）

# 2. 确保所有旧进程都停止
killall -9 baby-tracker

# 3. 重新编译
cd /Users/lyon.cao/dev/python/baby-core/backend
rm baby-tracker
$HOME/.local/go/bin/go build -o baby-tracker

# 4. 验证软删除代码已包含
strings baby-tracker | grep "UPDATE records SET deleted_at = CURRENT_TIMESTAMP"
# 应该能看到输出

# 5. 重新启动
./baby-tracker
```

### 浏览器没有看到新功能

```bash
# 清除浏览器缓存
# 或使用无痕/隐私模式打开
# 或强制刷新（Cmd+Shift+R 或 Ctrl+Shift+R）
```

## 📝 快速验证脚本

如果你想快速验证软删除是否工作，运行这个一键测试：

```bash
cd /Users/lyon.cao/dev/python/baby-core/backend && \
sqlite3 baby_tracker.db "PRAGMA table_info(records);" | grep deleted_at && \
echo "✓ 数据库字段正常" && \
strings baby-tracker | grep -q "UPDATE records SET deleted_at = CURRENT_TIMESTAMP" && \
echo "✓ 可执行文件包含软删除代码" && \
echo "" && \
echo "✅ 一切准备就绪！现在启动服务测试吧！"
```

## 🎯 推荐测试流程

1. **启动服务**（终端1）
   ```bash
   cd /Users/lyon.cao/dev/python/baby-core/backend
   ./baby-tracker
   ```

2. **打开浏览器**
   - 访问 http://localhost:8080
   - 登录并测试删除/恢复功能

3. **查看数据库验证**（终端2）
   ```bash
   cd /Users/lyon.cao/dev/python/baby-core/backend
   sqlite3 baby_tracker.db "SELECT id, record_type, deleted_at IS NOT NULL as is_deleted FROM records ORDER BY id DESC LIMIT 5;"
   ```

## 停止服务

在运行服务的终端按 `Ctrl+C` 即可停止。

---

**备注：** 所有代码修改已完成并经过验证，直接启动即可测试！

