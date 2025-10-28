# Telegram 自动备份使用指南

## 📋 概述

这个脚本可以自动将 SQLite 数据库备份到 Telegram Bot，确保数据安全。

## 🚀 快速开始

### 1. 获取 Chat ID（首次使用）

首先需要获取您的 Telegram Chat ID：

```bash
cd /Users/lyon.cao/dev/python/baby-core
./backup-to-telegram.sh --get-chat-id
```

按照提示操作：
1. 在 Telegram 中搜索您的 bot
2. 发送任意消息给 bot（例如：`/start`）
3. 按回车键，脚本会显示您的 Chat ID
4. 复制 Chat ID 并编辑脚本：

```bash
nano backup-to-telegram.sh
# 找到 CHAT_ID="" 这一行
# 修改为: CHAT_ID="你的chat_id"
```

### 2. 测试连接

```bash
./backup-to-telegram.sh --test
```

如果看到 ✅ 测试消息，说明配置成功！

### 3. 手动执行备份

```bash
./backup-to-telegram.sh --backup
```

或者直接运行（默认就是备份）：

```bash
./backup-to-telegram.sh
```

## ⏰ 设置定时备份

使用 crontab 设置定时任务：

```bash
# 编辑 crontab
crontab -e
```

添加以下任意一行（根据需求选择）：

```bash
# 每天凌晨 2 点备份
0 2 * * * cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh

# 每 6 小时备份一次
0 */6 * * * cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh

# 每天中午 12 点和晚上 8 点备份
0 12,20 * * * cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh

# 每周日凌晨 3 点备份
0 3 * * 0 cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh
```

### 查看定时任务

```bash
crontab -l
```

## 📁 备份内容

脚本会创建以下备份：

1. **数据库文件副本** (`baby_tracker_YYYYMMDD_HHMMSS.db`)
2. **SQL 导出文件** (`baby_tracker_YYYYMMDD_HHMMSS.sql`)
3. **压缩包** (`baby_tracker_YYYYMMDD_HHMMSS.tar.gz`) - 发送到 Telegram

所有备份文件保存在 `./backups/` 目录下。

## 🔧 配置选项

编辑脚本中的配置区：

```bash
# Telegram Bot Token（已配置）
BOT_TOKEN="8347789965:AAEMhAszLr8UcLIzgxmqfGtPNq4HiBx9k8E"

# Chat ID（需要填写）
CHAT_ID=""

# 数据库路径
DB_PATH="./data/baby_tracker.db"

# 备份目录
BACKUP_DIR="./backups"

# 保留本地备份的天数（默认7天）
KEEP_DAYS=7
```

## 📊 日志查看

备份日志保存在 `backup-telegram.log`：

```bash
# 查看日志
tail -f backup-telegram.log

# 查看最近的备份记录
tail -n 50 backup-telegram.log
```

## 🔍 常见问题

### Q: 提示 "CHAT_ID未设置"
A: 运行 `./backup-to-telegram.sh --get-chat-id` 获取 Chat ID，然后编辑脚本填入。

### Q: 提示 "curl未安装"
A: 安装 curl：
```bash
# macOS
brew install curl

# Ubuntu/Debian
sudo apt-get install curl
```

### Q: 提示 "未安装sqlite3命令"
A: 这不影响备份，只是不会生成 SQL 格式。如需安装：
```bash
# macOS
brew install sqlite3

# Ubuntu/Debian
sudo apt-get install sqlite3
```

### Q: 定时任务没有执行
A: 检查以下几点：
1. crontab 中的路径是否正确（使用绝对路径）
2. 脚本是否有执行权限（`chmod +x backup-to-telegram.sh`）
3. 查看系统日志：`grep CRON /var/log/syslog`（Linux）或 `/var/log/system.log`（macOS）

### Q: 文件太大无法发送
A: Telegram Bot API 限制文件大小为 50MB。如果数据库超过此限制：
1. 考虑只发送 SQL 导出文件
2. 或使用其他备份方案（如云存储）

## 🔐 安全建议

1. **保护 Bot Token**：不要将包含 token 的脚本上传到公共仓库
2. **定期检查备份**：确认备份文件可以正常恢复
3. **多重备份**：建议同时使用其他备份方案（如云存储、本地备份）

## 📝 命令参考

```bash
# 查看帮助
./backup-to-telegram.sh --help

# 获取 Chat ID
./backup-to-telegram.sh --get-chat-id

# 测试连接
./backup-to-telegram.sh --test

# 执行备份
./backup-to-telegram.sh --backup
./backup-to-telegram.sh  # 等同于上面
```

## 🔄 恢复数据

从 Telegram 下载备份文件后：

```bash
# 解压备份
tar -xzf baby_tracker_YYYYMMDD_HHMMSS.tar.gz

# 停止应用
docker-compose down  # 或其他停止方式

# 恢复数据库
cp baby_tracker_YYYYMMDD_HHMMSS.db data/baby_tracker.db

# 或者从 SQL 恢复
sqlite3 data/baby_tracker.db < baby_tracker_YYYYMMDD_HHMMSS.sql

# 重启应用
docker-compose up -d
```

## 📈 监控备份状态

在 Telegram 中，您会收到类似这样的消息：

```
🗄️ Baby Tracker 数据库备份

📅 时间: 2025-10-28 14:30:00
💾 原始大小: 2.3MB
📦 压缩大小: 856KB
🔒 状态: 备份成功
```

## 💡 进阶使用

### 备份到多个 Chat

如需发送到多个聊天，可以修改脚本或创建多个副本。

### 自定义备份频率

根据数据重要性调整 crontab 频率：
- **低频更新**：每天一次
- **中频更新**：每 6 小时
- **高频更新**：每 2-3 小时

### 结合其他备份方案

```bash
# 同时备份到 Telegram 和本地
./backup-to-telegram.sh
cp ./backups/latest.tar.gz /path/to/external/drive/
```

## 📞 支持

如有问题，请检查：
1. 日志文件 `backup-telegram.log`
2. Telegram Bot API 文档
3. 脚本中的错误信息

---

✅ **配置完成后，您的数据将自动安全备份到 Telegram！**

