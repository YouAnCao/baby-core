#!/bin/bash

#######################################
# SQLite to Telegram Backup Script
# 
# 功能：定时备份SQLite数据库到Telegram Bot
# 作者：Auto Generated
# 日期：2025-10-28
#######################################

set -e

# ==================== 配置区 ====================

# Telegram Bot Token
BOT_TOKEN="8347789965:AAEMhAszLr8UcLIzgxmqfGtPNq4HiBx9k8E"

# Chat ID (需要先获取，运行 ./backup-to-telegram.sh --get-chat-id)
CHAT_ID=""

# 数据库路径
DB_PATH="./data/baby_tracker.db"

# 备份目录
BACKUP_DIR="./backups"

# 日志文件
LOG_FILE="./backup-telegram.log"

# 保留本地备份的天数
KEEP_DAYS=7

# ==================== 函数定义 ====================

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 获取Chat ID
get_chat_id() {
    log "正在获取Chat ID..."
    echo ""
    echo "================================================"
    echo "请按以下步骤获取您的Chat ID："
    echo "1. 在Telegram中搜索并打开您的bot"
    echo "2. 发送任意消息给bot（例如：/start 或 hello）"
    echo "3. 按回车键继续..."
    echo "================================================"
    read -p ""
    
    RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")
    
    # 检查是否有消息
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        # 提取所有chat_id
        CHAT_IDS=$(echo "$RESPONSE" | grep -o '"chat":{"id":[0-9-]*' | grep -o '[0-9-]*$' | sort -u)
        
        if [ -z "$CHAT_IDS" ]; then
            echo ""
            echo "❌ 未找到消息。请确保："
            echo "   1. 已向bot发送过消息"
            echo "   2. Bot Token正确"
            echo ""
            return 1
        fi
        
        echo ""
        echo "✅ 找到以下Chat ID："
        echo "$CHAT_IDS"
        echo ""
        echo "请将其中一个Chat ID复制到脚本的CHAT_ID变量中"
        echo ""
        echo "完整的更新信息："
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        echo ""
        echo "❌ 获取更新失败："
        echo "$RESPONSE"
        return 1
    fi
}

# 发送消息到Telegram
send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="Markdown" > /dev/null
}

# 发送文件到Telegram
send_file() {
    local file_path="$1"
    local caption="$2"
    
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
        -F chat_id="${CHAT_ID}" \
        -F document=@"${file_path}" \
        -F caption="${caption}")
    
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        return 0
    else
        log "发送文件失败: $RESPONSE"
        return 1
    fi
}

# 备份数据库
backup_database() {
    log "开始备份数据库..."
    
    # 检查数据库文件是否存在
    if [ ! -f "$DB_PATH" ]; then
        error_exit "数据库文件不存在: $DB_PATH"
    fi
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 生成备份文件名
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/baby_tracker_${TIMESTAMP}.db"
    SQL_BACKUP="${BACKUP_DIR}/baby_tracker_${TIMESTAMP}.sql"
    
    # 复制数据库文件
    log "复制数据库文件..."
    cp "$DB_PATH" "$BACKUP_FILE"
    
    # 导出为SQL格式（可选）
    log "导出SQL格式..."
    if command -v sqlite3 &> /dev/null; then
        sqlite3 "$DB_PATH" .dump > "$SQL_BACKUP"
        log "SQL导出成功: $SQL_BACKUP"
    else
        log "警告: 未安装sqlite3命令，跳过SQL导出"
        SQL_BACKUP=""
    fi
    
    # 压缩备份文件
    log "压缩备份文件..."
    COMPRESSED_FILE="${BACKUP_DIR}/baby_tracker_${TIMESTAMP}.tar.gz"
    
    if [ -n "$SQL_BACKUP" ]; then
        tar -czf "$COMPRESSED_FILE" -C "$BACKUP_DIR" \
            "$(basename $BACKUP_FILE)" \
            "$(basename $SQL_BACKUP)"
    else
        tar -czf "$COMPRESSED_FILE" -C "$BACKUP_DIR" \
            "$(basename $BACKUP_FILE)"
    fi
    
    log "备份文件创建成功: $COMPRESSED_FILE"
    
    # 获取文件大小
    FILE_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
    DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
    
    log "原始数据库大小: $DB_SIZE"
    log "压缩后大小: $FILE_SIZE"
    
    echo "$COMPRESSED_FILE"
}

# 上传到Telegram
upload_to_telegram() {
    local backup_file="$1"
    
    log "开始上传到Telegram..."
    
    # 检查Chat ID
    if [ -z "$CHAT_ID" ]; then
        error_exit "CHAT_ID未设置。请运行 ./backup-to-telegram.sh --get-chat-id 获取"
    fi
    
    # 准备说明信息
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    FILE_SIZE=$(du -h "$backup_file" | cut -f1)
    DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
    
    CAPTION="🗄️ Baby Tracker 数据库备份
    
📅 时间: ${TIMESTAMP}
💾 原始大小: ${DB_SIZE}
📦 压缩大小: ${FILE_SIZE}
🔒 状态: 备份成功"
    
    # 发送文件
    if send_file "$backup_file" "$CAPTION"; then
        log "✅ 文件上传成功"
        send_message "✅ 数据库备份完成！"
        return 0
    else
        error_exit "文件上传失败"
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log "清理旧备份文件..."
    
    # 删除超过KEEP_DAYS天的备份
    find "$BACKUP_DIR" -name "baby_tracker_*.tar.gz" -type f -mtime +${KEEP_DAYS} -delete
    find "$BACKUP_DIR" -name "baby_tracker_*.db" -type f -mtime +${KEEP_DAYS} -delete
    find "$BACKUP_DIR" -name "baby_tracker_*.sql" -type f -mtime +${KEEP_DAYS} -delete
    
    log "清理完成"
}

# 显示帮助
show_help() {
    cat << EOF
SQLite to Telegram Backup Script

用法:
    $0 [选项]

选项:
    --backup          执行备份（默认操作）
    --get-chat-id     获取Telegram Chat ID
    --test            测试Telegram连接
    --help            显示此帮助信息

配置:
    在脚本中修改以下变量：
    - BOT_TOKEN: Telegram Bot Token
    - CHAT_ID: Telegram Chat ID
    - DB_PATH: 数据库文件路径
    - BACKUP_DIR: 备份目录

定时任务:
    添加到crontab实现定时备份：
    
    # 每天凌晨2点备份
    0 2 * * * cd /path/to/baby-core && ./backup-to-telegram.sh --backup
    
    # 每6小时备份一次
    0 */6 * * * cd /path/to/baby-core && ./backup-to-telegram.sh --backup
    
    # 每天中午12点和晚上8点备份
    0 12,20 * * * cd /path/to/baby-core && ./backup-to-telegram.sh --backup

示例:
    # 首次使用，获取Chat ID
    $0 --get-chat-id
    
    # 执行备份
    $0 --backup
    
    # 测试连接
    $0 --test

EOF
}

# 测试Telegram连接
test_connection() {
    log "测试Telegram连接..."
    
    if [ -z "$CHAT_ID" ]; then
        error_exit "CHAT_ID未设置。请运行 ./backup-to-telegram.sh --get-chat-id 获取"
    fi
    
    # 测试发送消息
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="🧪 测试消息 - Baby Tracker 备份脚本连接正常！")
    
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        log "✅ Telegram连接测试成功"
        echo ""
        echo "✅ 测试消息已发送到Telegram"
        return 0
    else
        log "❌ Telegram连接测试失败"
        echo "Response: $RESPONSE"
        return 1
    fi
}

# 执行完整备份流程
run_backup() {
    log "=========================================="
    log "开始执行备份任务"
    log "=========================================="
    
    # 检查依赖
    if ! command -v curl &> /dev/null; then
        error_exit "curl未安装，请先安装curl"
    fi
    
    # 备份数据库
    BACKUP_FILE=$(backup_database)
    
    # 上传到Telegram
    upload_to_telegram "$BACKUP_FILE"
    
    # 清理旧备份
    cleanup_old_backups
    
    log "=========================================="
    log "备份任务完成"
    log "=========================================="
}

# ==================== 主程序 ====================

# 创建日志文件
touch "$LOG_FILE"

# 解析命令行参数
case "${1:-}" in
    --get-chat-id)
        get_chat_id
        ;;
    --test)
        test_connection
        ;;
    --backup|"")
        run_backup
        ;;
    --help|-h)
        show_help
        ;;
    *)
        echo "未知选项: $1"
        echo "使用 --help 查看帮助"
        exit 1
        ;;
esac

exit 0

