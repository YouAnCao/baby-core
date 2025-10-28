# 🚀 Telegram 备份 - 快速开始

## 一键配置（推荐）

```bash
cd /Users/lyon.cao/dev/python/baby-core
./setup-backup.sh
```

按照向导提示完成配置，大约需要 2-3 分钟。

---

## 手动配置（3 步）

### 第 1 步：获取 Chat ID

```bash
cd /Users/lyon.cao/dev/python/baby-core
./backup-to-telegram.sh --get-chat-id
```

1. 在 Telegram 搜索您的 bot
2. 发送消息 `/start`
3. 复制显示的 Chat ID

### 第 2 步：配置 Chat ID

编辑脚本：
```bash
nano backup-to-telegram.sh
```

找到并修改：
```bash
CHAT_ID=""  # 改为 CHAT_ID="你的chat_id"
```

保存退出（Ctrl+X, Y, Enter）

### 第 3 步：设置定时任务

```bash
crontab -e
```

添加以下内容（每天凌晨2点备份）：
```bash
0 2 * * * cd /Users/lyon.cao/dev/python/baby-core && ./backup-to-telegram.sh
```

---

## 测试

```bash
# 测试连接
./backup-to-telegram.sh --test

# 测试备份
./backup-to-telegram.sh
```

检查 Telegram 是否收到文件 ✅

---

## 常用命令

```bash
# 手动备份
./backup-to-telegram.sh

# 查看日志
tail -f backup-telegram.log

# 查看定时任务
crontab -l

# 编辑定时任务
crontab -e
```

---

## 备份频率建议

| 更新频率 | Crontab 配置 | 说明 |
|---------|-------------|------|
| 低 | `0 2 * * *` | 每天凌晨2点 |
| 中 | `0 */6 * * *` | 每6小时 |
| 高 | `0 */3 * * *` | 每3小时 |
| 自定义 | `0 12,20 * * *` | 每天12点和20点 |

---

## 文件说明

- **backup-to-telegram.sh** - 主备份脚本
- **setup-backup.sh** - 快速配置向导
- **BACKUP_GUIDE.md** - 详细使用指南
- **crontab-example.txt** - 定时任务配置示例
- **backup-telegram.log** - 备份日志
- **backups/** - 本地备份文件目录（保留7天）

---

## 需要帮助？

查看详细文档：
```bash
cat BACKUP_GUIDE.md
```

或运行：
```bash
./backup-to-telegram.sh --help
```

---

**✨ 配置完成后，您的数据会自动备份到 Telegram，安全无忧！**

