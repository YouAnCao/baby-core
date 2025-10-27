#!/bin/bash
# 初始化用户脚本

set -e

echo "=========================================="
echo "Baby Core - 创建初始用户"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查容器是否运行
if ! docker ps | grep -q baby-core; then
    echo -e "${YELLOW}错误: baby-core 容器未运行${NC}"
    echo "请先运行: docker-compose up -d"
    exit 1
fi

echo -e "\n${YELLOW}请输入用户信息:${NC}"
read -p "用户名: " USERNAME
read -sp "密码: " PASSWORD
echo

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "用户名和密码不能为空"
    exit 1
fi

# 生成密码哈希 (使用 Go 程序)
HASH=$(docker exec baby-core /bin/sh -c "cd /app && cat > /tmp/hash.go << 'EOF'
package main
import (
    \"fmt\"
    \"golang.org/x/crypto/bcrypt\"
    \"os\"
)
func main() {
    password := os.Args[1]
    hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    fmt.Print(string(hash))
}
EOF
go run /tmp/hash.go '$PASSWORD'")

# 插入用户到数据库
docker exec baby-core /bin/sh -c "sqlite3 /app/data/baby_tracker.db \"INSERT OR REPLACE INTO users (username, password_hash, created_at, updated_at) VALUES ('$USERNAME', '$HASH', datetime('now'), datetime('now'));\""

echo -e "\n${GREEN}✓ 用户创建成功！${NC}"
echo -e "\n登录信息:"
echo -e "  用户名: ${GREEN}$USERNAME${NC}"
echo -e "  密码: ${GREEN}(已设置)${NC}"
echo -e "\n现在可以使用这些凭据登录 Baby Core 应用"
echo "=========================================="

