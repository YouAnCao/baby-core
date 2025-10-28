#!/bin/bash

#######################################
# Telegram 备份快速配置脚本
#######################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="/Users/lyon.cao/dev/python/baby-core"
BACKUP_SCRIPT="${PROJECT_DIR}/backup-to-telegram.sh"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Telegram 备份快速配置向导            ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# 检查备份脚本是否存在
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo -e "${RED}❌ 错误: 找不到备份脚本 $BACKUP_SCRIPT${NC}"
    exit 1
fi

# 确保脚本有执行权限
chmod +x "$BACKUP_SCRIPT"
echo -e "${GREEN}✓${NC} 已设置脚本执行权限"

# 步骤 1: 检查 Chat ID 是否已配置
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 1: 检查配置${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

CURRENT_CHAT_ID=$(grep '^CHAT_ID=' "$BACKUP_SCRIPT" | cut -d'"' -f2)

if [ -z "$CURRENT_CHAT_ID" ]; then
    echo -e "${YELLOW}⚠ Chat ID 未配置${NC}"
    echo ""
    echo "需要获取您的 Telegram Chat ID。请按照以下步骤操作："
    echo ""
    echo "1. 在 Telegram 中搜索并打开您的 bot"
    echo "   (Bot Token: 8347789965:AAEMhAszLr8UcLIzgxmqfGtPNq4HiBx9k8E)"
    echo ""
    echo "2. 发送任意消息给 bot（例如：/start 或 hello）"
    echo ""
    read -p "按回车键继续获取 Chat ID..." 
    
    # 获取 Chat ID
    cd "$PROJECT_DIR"
    "$BACKUP_SCRIPT" --get-chat-id
    
    echo ""
    read -p "请输入您的 Chat ID: " NEW_CHAT_ID
    
    if [ -z "$NEW_CHAT_ID" ]; then
        echo -e "${RED}❌ Chat ID 不能为空${NC}"
        exit 1
    fi
    
    # 更新脚本中的 Chat ID
    sed -i.bak "s/^CHAT_ID=\"\"/CHAT_ID=\"${NEW_CHAT_ID}\"/" "$BACKUP_SCRIPT"
    echo -e "${GREEN}✓${NC} Chat ID 已配置: $NEW_CHAT_ID"
else
    echo -e "${GREEN}✓${NC} Chat ID 已配置: $CURRENT_CHAT_ID"
fi

# 步骤 2: 测试连接
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 2: 测试 Telegram 连接${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$PROJECT_DIR"
if "$BACKUP_SCRIPT" --test; then
    echo -e "${GREEN}✓${NC} Telegram 连接正常"
else
    echo -e "${RED}❌ Telegram 连接失败，请检查配置${NC}"
    exit 1
fi

# 步骤 3: 执行首次备份
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 3: 执行首次备份${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -p "是否立即执行一次备份测试？(y/n): " DO_BACKUP

if [[ "$DO_BACKUP" =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"
    "$BACKUP_SCRIPT" --backup
    echo -e "${GREEN}✓${NC} 备份完成，请检查 Telegram"
else
    echo "跳过备份测试"
fi

# 步骤 4: 配置定时任务
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 4: 配置定时备份${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo "请选择备份频率："
echo ""
echo "  1) 每天凌晨 2 点备份（推荐）"
echo "  2) 每 6 小时备份一次"
echo "  3) 每 3 小时备份一次"
echo "  4) 每天 2 次（中午12点、晚上8点）"
echo "  5) 每周备份（周日凌晨 3 点）"
echo "  6) 手动配置（不自动添加）"
echo ""
read -p "请选择 (1-6): " CHOICE

CRON_LINE=""

case $CHOICE in
    1)
        CRON_LINE="0 2 * * * cd ${PROJECT_DIR} && ./backup-to-telegram.sh >> ${PROJECT_DIR}/cron.log 2>&1"
        echo "已选择：每天凌晨 2 点备份"
        ;;
    2)
        CRON_LINE="0 */6 * * * cd ${PROJECT_DIR} && ./backup-to-telegram.sh >> ${PROJECT_DIR}/cron.log 2>&1"
        echo "已选择：每 6 小时备份一次"
        ;;
    3)
        CRON_LINE="0 */3 * * * cd ${PROJECT_DIR} && ./backup-to-telegram.sh >> ${PROJECT_DIR}/cron.log 2>&1"
        echo "已选择：每 3 小时备份一次"
        ;;
    4)
        CRON_LINE="0 12,20 * * * cd ${PROJECT_DIR} && ./backup-to-telegram.sh >> ${PROJECT_DIR}/cron.log 2>&1"
        echo "已选择：每天 2 次（中午12点、晚上8点）"
        ;;
    5)
        CRON_LINE="0 3 * * 0 cd ${PROJECT_DIR} && ./backup-to-telegram.sh >> ${PROJECT_DIR}/cron.log 2>&1"
        echo "已选择：每周备份（周日凌晨 3 点）"
        ;;
    6)
        echo "跳过自动配置"
        echo "请查看 crontab-example.txt 文件手动配置"
        ;;
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

if [ -n "$CRON_LINE" ]; then
    echo ""
    echo "准备添加以下 crontab 任务："
    echo ""
    echo "  $CRON_LINE"
    echo ""
    read -p "是否添加？(y/n): " ADD_CRON
    
    if [[ "$ADD_CRON" =~ ^[Yy]$ ]]; then
        # 检查是否已存在相同的任务
        if crontab -l 2>/dev/null | grep -q "backup-to-telegram.sh"; then
            echo -e "${YELLOW}⚠ 检测到已存在的备份任务${NC}"
            echo ""
            crontab -l | grep "backup-to-telegram.sh"
            echo ""
            read -p "是否替换现有任务？(y/n): " REPLACE_CRON
            
            if [[ "$REPLACE_CRON" =~ ^[Yy]$ ]]; then
                # 删除旧任务，添加新任务
                (crontab -l 2>/dev/null | grep -v "backup-to-telegram.sh"; echo "$CRON_LINE") | crontab -
                echo -e "${GREEN}✓${NC} 已替换 crontab 任务"
            else
                echo "保持现有任务不变"
            fi
        else
            # 添加新任务
            (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
            echo -e "${GREEN}✓${NC} 已添加 crontab 任务"
        fi
        
        echo ""
        echo "当前的 crontab 任务："
        crontab -l
    else
        echo "跳过添加 crontab 任务"
    fi
fi

# 完成
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  配置完成！                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "📝 快速参考："
echo ""
echo "  查看定时任务:   crontab -l"
echo "  手动备份:       cd ${PROJECT_DIR} && ./backup-to-telegram.sh"
echo "  查看备份日志:   tail -f ${PROJECT_DIR}/backup-telegram.log"
echo "  查看定时日志:   tail -f ${PROJECT_DIR}/cron.log"
echo "  测试连接:       cd ${PROJECT_DIR} && ./backup-to-telegram.sh --test"
echo ""
echo -e "${BLUE}📚 详细文档请查看: BACKUP_GUIDE.md${NC}"
echo ""

exit 0

