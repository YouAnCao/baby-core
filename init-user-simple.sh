#!/bin/bash
# 简单的初始化用户脚本（使用默认凭据）

set -e

echo "创建默认用户..."

# 默认用户名和密码
USERNAME=${1:-admin}
PASSWORD=${2:-admin123}

# 检查容器是否运行
if ! docker ps | grep -q baby-core; then
    echo "错误: baby-core 容器未运行"
    echo "请先运行: docker-compose up -d"
    exit 1
fi

# BCrypt 哈希 "admin123" (cost=10)
# 这个哈希是预先生成的，密码是 "admin123"
PASSWORD_HASH='$2a$10$N9qo8uLOickgx2ZMRZoMye7I8mWFBjUDVF3pXSEWQJLQ5YP3KMQKS'

if [ "$PASSWORD" != "admin123" ]; then
    echo "警告: 自定义密码需要在容器内生成哈希"
    echo "使用 init-user.sh 脚本代替"
    exit 1
fi

# 插入默认用户
docker exec baby-core sqlite3 /app/data/baby_tracker.db "INSERT OR REPLACE INTO users (id, username, password_hash, created_at, updated_at) VALUES (1, '$USERNAME', '$PASSWORD_HASH', datetime('now'), datetime('now'));"

echo "✓ 默认用户创建成功！"
echo ""
echo "登录信息:"
echo "  用户名: $USERNAME"
echo "  密码: admin123"
echo ""
echo "请登录后立即修改密码！"

