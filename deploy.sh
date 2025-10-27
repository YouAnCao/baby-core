#!/bin/bash
# Baby Core 部署脚本

set -e

echo "=========================================="
echo "Baby Core 部署脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Docker
echo -e "\n${YELLOW}检查 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker 环境检查通过${NC}"

# 检查 .env 文件
echo -e "\n${YELLOW}检查环境变量配置...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}未找到 .env 文件，从 .env.example 创建...${NC}"
    cp .env.example .env
    echo -e "${RED}警告: 请编辑 .env 文件并设置 JWT_SECRET！${NC}"
    read -p "按 Enter 继续或 Ctrl+C 退出..."
fi

# 创建必要的目录
echo -e "\n${YELLOW}创建必要的目录...${NC}"
mkdir -p data
mkdir -p nginx/logs

echo -e "${GREEN}✓ 目录创建完成${NC}"

# 停止旧容器
echo -e "\n${YELLOW}停止现有容器...${NC}"
docker-compose down

# 构建镜像
echo -e "\n${YELLOW}构建 Docker 镜像...${NC}"
docker-compose build --no-cache

# 启动服务
echo -e "\n${YELLOW}启动服务...${NC}"
docker-compose up -d

# 等待服务启动
echo -e "\n${YELLOW}等待服务启动...${NC}"
sleep 5

# 检查服务状态
echo -e "\n${YELLOW}检查服务状态...${NC}"
docker-compose ps

# 健康检查
echo -e "\n${YELLOW}执行健康检查...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8899/ | grep -q "200\|404"; then
    echo -e "${GREEN}✓ Baby Core 后端服务运行正常 (端口 8899)${NC}"
else
    echo -e "${RED}✗ Baby Core 后端服务可能未正常启动${NC}"
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ | grep -q "200\|404"; then
    echo -e "${GREEN}✓ Nginx 服务运行正常 (端口 80)${NC}"
else
    echo -e "${RED}✗ Nginx 服务可能未正常启动${NC}"
fi

echo -e "\n=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo -e "=========================================="
echo -e "\n访问地址:"
echo -e "  - 应用: ${GREEN}http://your-server-ip/baby-core${NC}"
echo -e "  - API: ${GREEN}http://your-server-ip/baby-core/api${NC}"
echo -e "\n查看日志:"
echo -e "  - Baby Core: ${YELLOW}docker-compose logs -f baby-core${NC}"
echo -e "  - Nginx: ${YELLOW}docker-compose logs -f nginx${NC}"
echo -e "  - 所有服务: ${YELLOW}docker-compose logs -f${NC}"
echo -e "\n停止服务:"
echo -e "  ${YELLOW}docker-compose down${NC}"
echo -e "\n重启服务:"
echo -e "  ${YELLOW}docker-compose restart${NC}"
echo -e "\n=========================================="

