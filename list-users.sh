#!/bin/bash
# Baby Core - 列出所有用户

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Baby Core - 用户列表"
echo "=========================================="

# 检查容器是否运行
if ! docker ps | grep -q baby-core; then
    echo -e "${YELLOW}错误: baby-core 容器未运行${NC}"
    echo "请先运行: docker-compose up -d"
    exit 1
fi

# 查询用户列表
echo -e "\n${BLUE}数据库中的用户:${NC}\n"

docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "SELECT 
        id,
        username,
        datetime(created_at, 'localtime') as created_at,
        datetime(updated_at, 'localtime') as updated_at
     FROM users
     ORDER BY id;" \
    -header -column

echo ""
echo "=========================================="

