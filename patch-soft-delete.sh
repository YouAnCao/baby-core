#!/bin/bash

# Baby Core v1.0 → v1.1 软删除功能补丁脚本
# 用于已部署的生产环境升级
#
# 使用步骤:
#   1. git pull origin main  (获取最新代码)
#   2. ./patch-soft-delete.sh  (迁移数据库)
#   3. ./deploy.sh  (重新构建和部署)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo -e "Baby Core v1.0 → v1.1 升级补丁"
echo -e "软删除功能数据库迁移"
echo -e "==========================================${NC}\n"

# 检查Docker是否安装
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: docker-compose 未安装${NC}"
    exit 1
fi

# 检查迁移脚本是否存在
if [ ! -f "sql/004_soft_delete.sql" ]; then
    echo -e "${RED}错误: 迁移脚本 sql/004_soft_delete.sql 不存在${NC}"
    echo "请确保已经运行 git pull 获取最新代码"
    exit 1
fi

echo -e "${YELLOW}[步骤 1/2] 迁移现有数据库...${NC}\n"

# 检查容器是否在运行
if docker-compose ps | grep -q "baby-core.*Up"; then
    echo "✓ 检测到正在运行的 baby-core 容器"
    echo ""
    
    # 在运行中的容器内迁移
    echo "检查数据库..."
    
    # 检查数据库是否存在
    DB_EXISTS=$(docker-compose exec -T baby-core sh -c "[ -f /app/data/baby_tracker.db ] && echo 'yes' || echo 'no'" 2>/dev/null)
    
    if [ "$DB_EXISTS" = "yes" ]; then
        echo "✓ 数据库文件存在"
        
        # 检查是否已有deleted_at字段
        echo "检查数据库结构..."
        HAS_DELETED_AT=$(docker-compose exec -T baby-core sh -c "sqlite3 /app/data/baby_tracker.db 'PRAGMA table_info(records);'" 2>/dev/null | grep -c "deleted_at" || echo "0")
        
        if [ "$HAS_DELETED_AT" = "0" ]; then
            echo ""
            echo -e "${YELLOW}准备应用迁移脚本...${NC}"
            
            # 备份数据库（可选但推荐）
            echo "创建数据库备份..."
            BACKUP_NAME="baby_tracker_backup_$(date +%Y%m%d_%H%M%S).db"
            docker-compose exec -T baby-core sh -c "cp /app/data/baby_tracker.db /app/data/$BACKUP_NAME"
            echo -e "${GREEN}✓ 备份已创建: data/$BACKUP_NAME${NC}"
            echo ""
            
            # 执行迁移
            echo "应用软删除迁移..."
            docker-compose exec -T baby-core sh -c "sqlite3 /app/data/baby_tracker.db < /app/sql/004_soft_delete.sql"
            
            # 验证
            VERIFY=$(docker-compose exec -T baby-core sh -c "sqlite3 /app/data/baby_tracker.db 'PRAGMA table_info(records);'" 2>/dev/null | grep -c "deleted_at" || echo "0")
            
            if [ "$VERIFY" -gt 0 ]; then
                echo -e "${GREEN}✓ 数据库迁移成功！${NC}"
                echo -e "${GREEN}✓ deleted_at 字段已添加${NC}"
            else
                echo -e "${RED}✗ 迁移验证失败${NC}"
                echo "尝试从备份恢复..."
                docker-compose exec -T baby-core sh -c "cp /app/data/$BACKUP_NAME /app/data/baby_tracker.db"
                exit 1
            fi
        else
            echo -e "${GREEN}✓ 数据库已包含 deleted_at 字段${NC}"
            echo "数据库已是最新版本，无需迁移"
        fi
    else
        echo -e "${YELLOW}⚠ 容器内数据库文件不存在${NC}"
        echo "这可能是首次部署，数据库将在重新部署后自动创建"
    fi
    
else
    # 容器未运行，尝试直接操作data目录
    echo -e "${YELLOW}⚠ baby-core 容器未运行${NC}"
    
    if [ -f "./data/baby_tracker.db" ]; then
        echo "发现本地数据库文件: ./data/baby_tracker.db"
        echo -e "${YELLOW}数据库迁移将在重新部署时自动完成${NC}"
    else
        echo "未发现数据库文件，这可能是首次部署"
    fi
fi

echo ""
echo -e "${YELLOW}[步骤 2/2] 准备重新部署...${NC}\n"

echo -e "${GREEN}=========================================="
echo -e "数据库迁移完成！"
echo -e "==========================================${NC}"
echo ""
echo -e "📋 ${YELLOW}下一步操作:${NC}"
echo -e "   运行部署脚本以应用新代码:"
echo -e "   ${GREEN}./deploy.sh${NC}"
echo ""
echo -e "   这将会:"
echo -e "   1. 停止现有容器"
echo -e "   2. 重新构建包含软删除功能的镜像"
echo -e "   3. 启动新容器"
echo ""
echo -e "✨ ${YELLOW}新功能预览:${NC}"
echo -e "   • 点击'删除'按钮 → 记录变灰并显示横线"
echo -e "   • 点击'恢复'按钮 → 恢复已删除的记录"
echo -e "   • 记录按时间顺序排列"
echo -e "   • 时区修复（Asia/Shanghai）"
echo ""

exit 0
