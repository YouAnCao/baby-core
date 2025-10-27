#!/bin/bash
# Baby Core 部署验证脚本

set -e

echo "=========================================="
echo "Baby Core 部署验证"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUCCESS=0
FAILED=0

# 检查函数
check() {
    local name=$1
    local command=$2
    
    echo -n "检查 $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 通过${NC}"
        ((SUCCESS++))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        ((FAILED++))
        return 1
    fi
}

# HTTP 检查函数
check_http() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "检查 $name... "
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [[ "$status" == "$expected" ]] || [[ "$status" =~ ^(200|404)$ ]]; then
        echo -e "${GREEN}✓ 通过 (HTTP $status)${NC}"
        ((SUCCESS++))
        return 0
    else
        echo -e "${RED}✗ 失败 (HTTP $status)${NC}"
        ((FAILED++))
        return 1
    fi
}

echo -e "\n${YELLOW}[1/5] 检查 Docker 环境${NC}"
check "Docker 已安装" "command -v docker"
check "Docker 正在运行" "docker ps"
check "Docker Compose 已安装" "docker compose version"

echo -e "\n${YELLOW}[2/5] 检查容器状态${NC}"
check "Baby Core 容器运行中" "docker ps | grep -q baby-core"
check "Nginx 容器运行中" "docker ps | grep -q nginx-server"

echo -e "\n${YELLOW}[3/5] 检查网络连通性${NC}"
check "容器网络存在" "docker network ls | grep -q baby-core_nginx-network"

echo -e "\n${YELLOW}[4/5] 检查服务响应${NC}"
check_http "后端服务 (8899)" "http://localhost:8899/" "200"
check_http "Nginx 服务 (80)" "http://localhost/baby-core/" "200"

echo -e "\n${YELLOW}[5/5] 检查数据持久化${NC}"
check "数据目录存在" "test -d data"
check "Nginx 日志目录存在" "test -d nginx/logs"

# 额外检查
echo -e "\n${YELLOW}[额外检查]${NC}"

# 检查环境变量文件
if [ -f .env ]; then
    echo -e "检查 .env 文件... ${GREEN}✓ 存在${NC}"
    if grep -q "your-secret-key-change-in-production" .env 2>/dev/null; then
        echo -e "  ${YELLOW}⚠ 警告: JWT_SECRET 仍使用默认值，请修改！${NC}"
    else
        echo -e "  ${GREEN}✓ JWT_SECRET 已自定义${NC}"
    fi
else
    echo -e "检查 .env 文件... ${RED}✗ 不存在${NC}"
    echo -e "  ${YELLOW}请运行: cp .env.example .env${NC}"
fi

# 检查数据库
if [ -f data/baby_tracker.db ]; then
    echo -e "检查数据库文件... ${GREEN}✓ 存在${NC}"
    local db_size=$(du -h data/baby_tracker.db | cut -f1)
    echo -e "  数据库大小: $db_size"
else
    echo -e "检查数据库文件... ${YELLOW}⚠ 不存在（首次运行正常）${NC}"
fi

# 显示容器状态
echo -e "\n${YELLOW}容器详细状态:${NC}"
docker-compose ps

# 显示端口监听
echo -e "\n${YELLOW}端口监听状态:${NC}"
if command -v netstat > /dev/null 2>&1; then
    netstat -tuln | grep -E ':(80|8899)\s' | head -5
elif command -v ss > /dev/null 2>&1; then
    ss -tuln | grep -E ':(80|8899)\s' | head -5
fi

# 总结
echo -e "\n=========================================="
echo -e "验证结果汇总"
echo -e "=========================================="
echo -e "通过: ${GREEN}$SUCCESS${NC} 项"
echo -e "失败: ${RED}$FAILED${NC} 项"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有检查通过！部署成功！${NC}"
    echo -e "\n访问应用:"
    echo -e "  ${GREEN}http://localhost/baby-core${NC}"
    echo -e "  或"
    echo -e "  ${GREEN}http://your-server-ip/baby-core${NC}"
    echo -e "\n下一步:"
    echo -e "  1. 运行 ${YELLOW}./init-user-simple.sh${NC} 创建用户"
    echo -e "  2. 访问应用并登录"
    echo -e "  3. 修改默认密码"
    exit 0
else
    echo -e "\n${RED}❌ 部署验证失败，请检查错误信息${NC}"
    echo -e "\n故障排查:"
    echo -e "  - 查看日志: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  - 重启服务: ${YELLOW}docker-compose restart${NC}"
    echo -e "  - 重新部署: ${YELLOW}./deploy.sh${NC}"
    exit 1
fi

