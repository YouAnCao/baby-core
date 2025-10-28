# 🧪 备份脚本测试指南

## 问题修复说明

✅ **已修复**: 日志输出混入函数返回值导致"File name too long"错误

### 修复内容
1. `log()` 函数输出重定向到 stderr，不影响函数返回值
2. 添加了更好的错误处理
3. 使用 `local` 关键字避免变量污染

---

## 快速测试

### 1. 测试连接（确认Telegram通信正常）

```bash
cd /Users/lyon.cao/dev/python/baby-core
./backup-to-telegram.sh --test
```

**预期结果**: 
- ✅ 测试消息已发送到Telegram
- Telegram 中收到测试消息

### 2. 测试备份（完整备份流程）

```bash
./backup-to-telegram.sh --backup
```

**预期输出**:
```
[2025-10-28 12:30:00] ==========================================
[2025-10-28 12:30:00] 开始执行备份任务
[2025-10-28 12:30:00] ==========================================
[2025-10-28 12:30:00] 开始备份数据库...
[2025-10-28 12:30:00] 复制数据库文件...
[2025-10-28 12:30:00] 导出SQL格式...
[2025-10-28 12:30:00] 警告: 未安装sqlite3命令，跳过SQL导出
[2025-10-28 12:30:00] 压缩备份文件...
[2025-10-28 12:30:00] 备份文件创建成功: ./backups/baby_tracker_XXXXXX.tar.gz
[2025-10-28 12:30:00] 原始数据库大小: 68K
[2025-10-28 12:30:00] 压缩后大小: 4.0K
[2025-10-28 12:30:00] 开始上传到Telegram...
[2025-10-28 12:30:01] ✅ 文件上传成功
[2025-10-28 12:30:01] 清理旧备份文件...
[2025-10-28 12:30:01] 清理完成
[2025-10-28 12:30:01] ==========================================
[2025-10-28 12:30:01] 备份任务完成
[2025-10-28 12:30:01] ==========================================
```

**验证要点**:
- ✅ 没有 "File name too long" 错误
- ✅ 文件成功上传到 Telegram
- ✅ Telegram 中收到带有备份信息的文件

### 3. 检查备份文件

```bash
# 查看备份目录
ls -lh /Users/lyon.cao/dev/python/baby-core/backups/

# 查看日志
cat /Users/lyon.cao/dev/python/baby-core/backup-telegram.log
```

### 4. 验证备份文件完整性

```bash
# 解压查看备份内容
cd /Users/lyon.cao/dev/python/baby-core/backups/
tar -tzf baby_tracker_XXXXXX.tar.gz

# 应该显示:
# baby_tracker_XXXXXX.db
```

---

## 常见问题排查

### ❌ 错误: "CHAT_ID未设置"
**解决**: 运行 `./backup-to-telegram.sh --get-chat-id` 获取并设置 Chat ID

### ❌ 错误: "数据库文件不存在"
**解决**: 检查 `DB_PATH` 变量是否正确指向数据库文件
```bash
# 确认数据库路径
ls -lh /Users/lyon.cao/dev/python/baby-core/data/baby_tracker.db
```

### ❌ 错误: "curl未安装"
**解决**: 
```bash
# macOS
brew install curl
```

### ⚠️ 警告: "未安装sqlite3命令"
**说明**: 这不影响备份，只是不会生成 SQL 格式
**可选安装**:
```bash
# macOS
brew install sqlite3
```

### ❌ Telegram 发送失败
**排查步骤**:
1. 检查 Bot Token 是否正确
2. 检查 Chat ID 是否正确
3. 检查网络连接
4. 查看详细错误日志：`cat backup-telegram.log`

---

## 高级测试

### 测试定时任务（不实际添加到crontab）

```bash
# 模拟 cron 执行环境
cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh >> cron.log 2>&1

# 查看执行结果
cat cron.log
```

### 压力测试（连续备份）

```bash
# 执行3次备份，确保稳定性
for i in {1..3}; do
    echo "第 $i 次备份..."
    ./backup-to-telegram.sh
    sleep 2
done
```

### 测试大文件（如果数据库较大）

```bash
# 查看文件大小
du -h data/baby_tracker.db

# 如果超过 50MB，Telegram 会拒绝
# 可以考虑只备份 SQL 格式或使用其他方案
```

---

## 性能指标

### 正常执行时间参考
- **小数据库** (<1MB): 1-2 秒
- **中等数据库** (1-10MB): 2-5 秒
- **大数据库** (10-50MB): 5-15 秒

### 网络传输时间
- 取决于文件大小和网络速度
- Telegram API 上传速度通常为 1-5 MB/s

---

## 成功标志

当你看到以下内容，说明一切正常：

1. **日志中**: `✅ 文件上传成功`
2. **Telegram 中**: 收到带有以下信息的文件
   ```
   🗄️ Baby Tracker 数据库备份
   
   📅 时间: 2025-10-28 12:30:00
   💾 原始大小: 68K
   📦 压缩大小: 4.0K
   🔒 状态: 备份成功
   ```
3. **本地**: `./backups/` 目录中有压缩文件

---

## 下一步

测试成功后，设置定时任务：

```bash
# 使用配置向导
./setup-backup.sh

# 或手动添加
crontab -e
# 添加: 0 2 * * * cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh
```

---

## 监控建议

### 每日检查（前几天）
```bash
# 查看最近的备份
ls -lt backups/ | head -5

# 查看日志中的错误
grep ERROR backup-telegram.log
```

### 每周检查（稳定后）
```bash
# 确认定时任务运行正常
grep "备份任务完成" backup-telegram.log | tail -10

# 确认 Telegram 中有备份文件
```

---

## 回滚说明

如需回滚到之前版本，可以从 Git 历史中恢复（如果有版本控制）

或者重新下载原始脚本后再次配置。

---

✅ **祝贺！完成测试后，您的数据备份系统就可以自动运行了！**

