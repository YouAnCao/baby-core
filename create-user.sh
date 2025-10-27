#!/bin/bash
# Baby Core - 创建指定用户脚本
# 用法: ./create-user.sh <username> <password>

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Baby Core - 创建用户"
echo "=========================================="

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "\n${YELLOW}用法:${NC}"
    echo "  $0 <username> <password>"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 admin mypassword123"
    echo "  $0 john secretpass"
    echo ""
    echo -e "${YELLOW}或者交互式输入:${NC}"
    read -p "用户名: " USERNAME
    read -sp "密码: " PASSWORD
    echo ""
elif [ $# -eq 1 ]; then
    USERNAME=$1
    read -sp "请输入密码: " PASSWORD
    echo ""
elif [ $# -eq 2 ]; then
    USERNAME=$1
    PASSWORD=$2
else
    echo -e "${RED}错误: 参数过多${NC}"
    echo "用法: $0 <username> <password>"
    exit 1
fi

# 验证输入
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}错误: 用户名和密码不能为空${NC}"
    exit 1
fi

# 检查容器是否运行
echo -e "\n${BLUE}检查容器状态...${NC}"
if ! docker ps | grep -q baby-core; then
    echo -e "${RED}错误: baby-core 容器未运行${NC}"
    echo "请先运行: docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✓ 容器运行正常${NC}"

# 生成 salt 和密码哈希
echo -e "\n${BLUE}生成 salt 和密码哈希...${NC}"

# 生成随机 salt (16字节，32个十六进制字符)
SALT=$(openssl rand -hex 16)
echo "Salt: $SALT"

# 使用 MD5 生成密码哈希
HASH=$(echo -n "${PASSWORD}${SALT}" | md5sum | awk '{print $1}')
echo "Hash: $HASH"

echo -e "${GREEN}✓ 密码哈希生成成功${NC}"

# 插入用户到数据库
echo -e "\n${BLUE}插入用户到数据库...${NC}"

# 转义单引号
SAFE_USERNAME=$(echo "$USERNAME" | sed "s/'/''/g")
SAFE_HASH=$(echo "$HASH" | sed "s/'/''/g")
SAFE_SALT=$(echo "$SALT" | sed "s/'/''/g")

# 执行 SQL 插入
RESULT=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "INSERT OR REPLACE INTO users (username, password_hash, salt, created_at, updated_at) 
     VALUES ('$SAFE_USERNAME', '$SAFE_HASH', '$SAFE_SALT', datetime('now'), datetime('now'));" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 插入用户失败${NC}"
    echo "$RESULT"
    exit 1
fi

# 验证用户是否创建成功
USER_COUNT=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "SELECT COUNT(*) FROM users WHERE username='$SAFE_USERNAME';")

if [ "$USER_COUNT" -eq 0 ]; then
    echo -e "${RED}错误: 用户创建失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 用户创建成功${NC}"

# 显示结果
echo ""
echo "=========================================="
echo -e "${GREEN}用户创建完成！${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}登录信息:${NC}"
echo -e "  用户名: ${GREEN}$USERNAME${NC}"
echo -e "  密码:   ${GREEN}(已设置)${NC}"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "  - 现在可以使用这些凭据登录应用"
echo "  - 访问: http://your-server-ip/baby-core"
echo "  - 建议首次登录后修改密码"
echo ""
echo "=========================================="

