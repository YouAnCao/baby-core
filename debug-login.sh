#!/bin/bash
# Baby Core 登录问题诊断脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Baby Core 登录问题诊断"
echo "=========================================="

# 1. 检查容器状态
echo -e "\n${BLUE}1. 检查容器状态${NC}"
if docker ps | grep -q baby-core; then
    echo -e "${GREEN}✓ baby-core 容器正在运行${NC}"
    docker ps | grep baby-core
else
    echo -e "${RED}✗ baby-core 容器未运行！${NC}"
    echo "请运行: docker-compose up -d"
    exit 1
fi

# 2. 检查数据库文件
echo -e "\n${BLUE}2. 检查数据库文件${NC}"
DB_SIZE=$(docker exec baby-core ls -lh /app/data/baby_tracker.db 2>/dev/null | awk '{print $5}')
if [ -n "$DB_SIZE" ]; then
    echo -e "${GREEN}✓ 数据库文件存在 (大小: $DB_SIZE)${NC}"
else
    echo -e "${RED}✗ 数据库文件不存在！${NC}"
    echo "数据库未初始化，容器可能启动失败"
fi

# 3. 检查数据库表
echo -e "\n${BLUE}3. 检查数据库表${NC}"
TABLES=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db ".tables" 2>/dev/null)
if echo "$TABLES" | grep -q "users"; then
    echo -e "${GREEN}✓ users 表存在${NC}"
    echo "表列表: $TABLES"
else
    echo -e "${RED}✗ users 表不存在！${NC}"
    echo "表列表: $TABLES"
    echo "数据库结构可能有问题"
fi

# 4. 查看 users 表结构
echo -e "\n${BLUE}4. users 表结构${NC}"
docker exec baby-core sqlite3 /app/data/baby_tracker.db ".schema users" 2>/dev/null

# 5. 列出所有用户
echo -e "\n${BLUE}5. 数据库中的用户${NC}"
USER_COUNT=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
echo "用户总数: $USER_COUNT"

if [ "$USER_COUNT" -gt 0 ]; then
    echo -e "\n用户列表:"
    docker exec baby-core sqlite3 /app/data/baby_tracker.db \
        "SELECT id, username, datetime(created_at, 'localtime') as created 
         FROM users 
         ORDER BY id;" \
        -header -column 2>/dev/null
else
    echo -e "${YELLOW}⚠ 数据库中没有用户！${NC}"
    echo "请运行: ./create-user.sh username password"
fi

# 6. 检查特定用户
echo -e "\n${BLUE}6. 检查 'feifei' 用户${NC}"
FEIFEI_EXISTS=$(docker exec baby-core sqlite3 /app/data/baby_tracker.db \
    "SELECT COUNT(*) FROM users WHERE username='feifei';" 2>/dev/null || echo "0")

if [ "$FEIFEI_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✓ 用户 'feifei' 存在${NC}"
    docker exec baby-core sqlite3 /app/data/baby_tracker.db \
        "SELECT id, username, 
                length(password_hash) as hash_length,
                datetime(created_at, 'localtime') as created
         FROM users WHERE username='feifei';" \
        -header -column 2>/dev/null
else
    echo -e "${YELLOW}⚠ 用户 'feifei' 不存在${NC}"
fi

# 7. 测试密码哈希
echo -e "\n${BLUE}7. 测试密码哈希生成 (MD5+Salt)${NC}"
TEST_SALT=$(openssl rand -hex 16)
TEST_HASH=$(echo -n "feifei080240${TEST_SALT}" | md5sum | awk '{print $1}')

if [ -n "$TEST_HASH" ] && [ ${#TEST_HASH} -eq 32 ]; then
    echo -e "${GREEN}✓ 密码哈希生成正常${NC}"
    echo "Salt 长度: ${#TEST_SALT} (应为32)"
    echo "Hash 长度: ${#TEST_HASH} (应为32)"
    echo "算法: MD5 + Salt"
else
    echo -e "${RED}✗ 密码哈希生成失败${NC}"
fi

# 8. 查看后端日志
echo -e "\n${BLUE}8. 最近的后端日志 (最后20行)${NC}"
echo "========================================"
docker logs baby-core --tail 20 2>&1
echo "========================================"

# 9. 测试登录接口
echo -e "\n${BLUE}9. 测试登录 API${NC}"
LOGIN_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8899/api/login \
    -H "Content-Type: application/json" \
    -d '{"username":"feifei","password":"feifei080240"}' 2>/dev/null || echo "CURL_FAILED")

if echo "$LOGIN_RESPONSE" | grep -q "HTTP_CODE:200"; then
    echo -e "${GREEN}✓ 登录成功！${NC}"
    echo "$LOGIN_RESPONSE"
elif echo "$LOGIN_RESPONSE" | grep -q "HTTP_CODE:401"; then
    echo -e "${YELLOW}⚠ 登录失败 (401 Unauthorized)${NC}"
    echo "可能原因:"
    echo "  - 用户名或密码错误"
    echo "  - 用户不存在"
    echo "  - 密码哈希不匹配"
    echo -e "\n响应内容:"
    echo "$LOGIN_RESPONSE"
else
    echo -e "${RED}✗ API 请求失败${NC}"
    echo "$LOGIN_RESPONSE"
fi

# 总结
echo -e "\n=========================================="
echo -e "${BLUE}诊断总结${NC}"
echo "=========================================="

if [ "$USER_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}问题: 数据库中没有用户${NC}"
    echo "解决方案: ./create-user.sh feifei feifei080240"
elif [ "$FEIFEI_EXISTS" -eq 0 ]; then
    echo -e "${YELLOW}问题: 用户 feifei 不存在${NC}"
    echo "解决方案: ./create-user.sh feifei feifei080240"
else
    echo -e "${YELLOW}问题: 用户存在但登录失败${NC}"
    echo "可能原因:"
    echo "  1. 密码哈希生成有问题"
    echo "  2. 密码输入错误"
    echo "  3. 后端认证逻辑问题"
    echo ""
    echo "建议操作:"
    echo "  1. 重新创建用户: ./create-user.sh feifei feifei080240"
    echo "  2. 或重置密码: ./reset-password.sh feifei feifei080240"
    echo "  3. 查看完整日志: docker logs baby-core -f"
fi

echo "=========================================="

