#!/bin/bash
# Baby Core - 删除用户

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Baby Core - 删除用户"
echo "=========================================="

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "\n${YELLOW}用法:${NC}"
    echo "  $0 <username>"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 admin"
    echo ""
    exit 1
fi

USERNAME=$1

# 检查容器是否运行
if ! docker ps | grep -q baby-core; then
    echo -e "${RED}错误: baby-core 容器未运行${NC}"
    echo "请先运行: docker-compose up -d"
    exit 1
fi

# 确认删除
echo -e "\n${YELLOW}警告: 即将删除用户 '$USERNAME'${NC}"
read -p "确认删除? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

# 转义单引号
SAFE_USERNAME=$(echo "$USERNAME" | sed "s/'/''/g")

# 检查用户是否存在
USER_EXISTS=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "SELECT COUNT(*) FROM users WHERE username='$SAFE_USERNAME';")

if [ "$USER_EXISTS" -eq 0 ]; then
    echo -e "${YELLOW}用户 '$USERNAME' 不存在${NC}"
    exit 1
fi

# 删除用户
docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "DELETE FROM users WHERE username='$SAFE_USERNAME';"

echo -e "\n${GREEN}✓ 用户 '$USERNAME' 已删除${NC}"
echo ""

