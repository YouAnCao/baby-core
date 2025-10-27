#!/bin/bash

# Baby Core 软删除功能补丁脚本
# 在运行 deploy.sh 之前执行此脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo -e "Baby Core 软删除功能补丁 v1.1"
echo -e "==========================================${NC}\n"

# ============================================
# 1. 数据库迁移（如果数据库已存在）
# ============================================
echo -e "${YELLOW}[1/2] 检查并迁移现有数据库...${NC}"

DB_PATH="./data/baby_tracker.db"

if [ -f "$DB_PATH" ]; then
    echo "发现现有数据库: $DB_PATH"
    
    # 检查是否已经有deleted_at字段
    HAS_DELETED_AT=$(sqlite3 "$DB_PATH" "PRAGMA table_info(records);" 2>/dev/null | grep -c "deleted_at" || true)
    
    if [ "$HAS_DELETED_AT" -eq 0 ]; then
        echo "应用软删除迁移脚本..."
        sqlite3 "$DB_PATH" < sql/004_soft_delete.sql
        echo -e "${GREEN}✓ 数据库迁移完成 - 已添加 deleted_at 字段${NC}"
        
        # 验证
        sqlite3 "$DB_PATH" "PRAGMA table_info(records);" | grep "deleted_at" && \
        echo -e "${GREEN}✓ 验证通过${NC}"
    else
        echo -e "${GREEN}✓ 数据库已包含 deleted_at 字段，跳过迁移${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 数据库文件不存在${NC}"
    echo "这是正常的，如果是首次部署，数据库会在首次启动时自动创建"
    echo "迁移脚本已准备好，会在容器启动时自动应用"
fi

echo ""

# ============================================
# 2. 创建初始化脚本（供Docker容器使用）
# ============================================
echo -e "${YELLOW}[2/2] 准备Docker初始化脚本...${NC}"

cat > init-db.sh << 'EOF'
#!/bin/sh
# Docker容器启动时的数据库初始化脚本

DB_PATH="/app/data/baby_tracker.db"

# 如果数据库已存在，检查并应用迁移
if [ -f "$DB_PATH" ]; then
    echo "检查数据库迁移..."
    HAS_DELETED_AT=$(sqlite3 "$DB_PATH" "PRAGMA table_info(records);" 2>/dev/null | grep -c "deleted_at" || true)
    
    if [ "$HAS_DELETED_AT" -eq 0 ]; then
        echo "应用软删除迁移..."
        sqlite3 "$DB_PATH" < /app/sql/004_soft_delete.sql
        echo "✓ 迁移完成"
    fi
fi

# 启动应用
exec ./baby-tracker
EOF

chmod +x init-db.sh
echo -e "${GREEN}✓ 初始化脚本已创建${NC}"

echo ""

# ============================================
# 完成提示
# ============================================
echo -e "${GREEN}=========================================="
echo -e "补丁应用完成！"
echo -e "==========================================${NC}"
echo ""
echo -e "📝 ${YELLOW}已完成的工作:${NC}"
echo -e "  ✓ 数据库迁移（如果数据库存在）"
echo -e "  ✓ 准备初始化脚本"
echo ""
echo -e "🚀 ${YELLOW}下一步操作:${NC}"
echo -e "  运行原有的部署脚本:"
echo -e "  ${GREEN}./deploy.sh${NC}"
echo ""
echo -e "📋 ${YELLOW}新增功能:${NC}"
echo -e "  • 软删除记录（点击删除后记录变灰）"
echo -e "  • 恢复已删除记录（点击恢复按钮）"
echo -e "  • 时区修复（Asia/Shanghai）"
echo -e "  • 记录按时间顺序排列"
echo ""
echo -e "📚 ${YELLOW}详细文档:${NC}"
echo -e "  • SOFT_DELETE_FEATURE.md - 功能说明"
echo -e "  • SOFT_DELETE_FIX.md - 设计说明"
echo ""

exit 0

