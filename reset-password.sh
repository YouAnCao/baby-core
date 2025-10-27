#!/bin/bash
# Baby Core - 重置用户密码

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Baby Core - 重置密码"
echo "=========================================="

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "\n${YELLOW}用法:${NC}"
    echo "  $0 <username> [new_password]"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 admin newpassword123"
    echo "  $0 admin  # 交互式输入新密码"
    echo ""
    exit 1
fi

USERNAME=$1

if [ $# -eq 1 ]; then
    read -sp "请输入新密码: " NEW_PASSWORD
    echo ""
    read -sp "再次输入新密码: " NEW_PASSWORD2
    echo ""
    
    if [ "$NEW_PASSWORD" != "$NEW_PASSWORD2" ]; then
        echo -e "${RED}错误: 两次密码输入不一致${NC}"
        exit 1
    fi
else
    NEW_PASSWORD=$2
fi

# 验证输入
if [ -z "$NEW_PASSWORD" ]; then
    echo -e "${RED}错误: 密码不能为空${NC}"
    exit 1
fi

# 检查容器是否运行
if ! docker ps | grep -q baby-core; then
    echo -e "${RED}错误: baby-core 容器未运行${NC}"
    echo "请先运行: docker-compose up -d"
    exit 1
fi

# 转义单引号
SAFE_USERNAME=$(echo "$USERNAME" | sed "s/'/''/g")

# 检查用户是否存在
USER_EXISTS=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "SELECT COUNT(*) FROM users WHERE username='$SAFE_USERNAME';")

if [ "$USER_EXISTS" -eq 0 ]; then
    echo -e "${RED}错误: 用户 '$USERNAME' 不存在${NC}"
    exit 1
fi

# 生成新密码哈希
echo -e "\n${BLUE}生成新密码哈希...${NC}"

HASH=$(docker exec baby-core /bin/sh -c "cat > /tmp/hashgen.go << 'GOEOF'
package main
import (
    \"fmt\"
    \"os\"
    \"golang.org/x/crypto/bcrypt\"
)
func main() {
    if len(os.Args) < 2 {
        os.Exit(1)
    }
    hash, err := bcrypt.GenerateFromPassword([]byte(os.Args[1]), bcrypt.DefaultCost)
    if err != nil {
        os.Exit(1)
    }
    fmt.Print(string(hash))
}
GOEOF
cd /tmp && go run hashgen.go '$NEW_PASSWORD' && rm -f hashgen.go" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 生成密码哈希失败${NC}"
    exit 1
fi

# 更新密码
SAFE_HASH=$(echo "$HASH" | sed "s/'/''/g")

docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "UPDATE users 
     SET password_hash='$SAFE_HASH', updated_at=datetime('now')
     WHERE username='$SAFE_USERNAME';"

echo -e "${GREEN}✓ 密码重置成功${NC}"
echo ""
echo -e "${BLUE}用户信息:${NC}"
echo -e "  用户名: ${GREEN}$USERNAME${NC}"
echo -e "  新密码: ${GREEN}(已设置)${NC}"
echo ""

