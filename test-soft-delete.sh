#!/bin/bash

# 软删除功能测试脚本

set -e

echo "🧹 清理旧进程..."
killall -9 baby-tracker 2>/dev/null || true
sleep 2

echo "🚀 启动服务..."
cd "$(dirname "$0")/backend"

# 启动服务
./baby-tracker &
SERVER_PID=$!
echo "服务PID: $SERVER_PID"

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 3

# 测试函数
test_soft_delete() {
    local SERVER="http://localhost:8080"
    
    echo ""
    echo "=== 1. 登录获取Token ==="
    TOKEN=$(curl -s $SERVER/api/login \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"admin123"}' \
      | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$TOKEN" ]; then
        echo "❌ 登录失败"
        kill $SERVER_PID
        exit 1
    fi
    echo "✓ 登录成功"
    
    echo ""
    echo "=== 2. 创建测试记录 ==="
    RECORD_RESPONSE=$(curl -s $SERVER/api/records \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d "{
        \"record_type\": \"feeding\",
        \"record_time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"details\": \"{\\\"method\\\":\\\"breast_left\\\",\\\"duration_minutes\\\":15}\",
        \"notes\": \"软删除测试 - $(date +%H:%M:%S)\"
      }")
    
    RECORD_ID=$(echo $RECORD_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    if [ -z "$RECORD_ID" ]; then
        echo "❌ 创建记录失败"
        echo "响应: $RECORD_RESPONSE"
        kill $SERVER_PID
        exit 1
    fi
    echo "✓ 记录创建成功，ID: $RECORD_ID"
    
    echo ""
    echo "=== 3. 软删除记录 ==="
    DELETE_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      "$SERVER/api/records?id=$RECORD_ID" \
      -X DELETE \
      -H "Authorization: Bearer $TOKEN")
    
    if [ "$DELETE_HTTP_CODE" != "204" ]; then
        echo "❌ 删除失败，HTTP状态码: $DELETE_HTTP_CODE"
        kill $SERVER_PID
        exit 1
    fi
    echo "✓ 删除请求成功（HTTP 204）"
    
    echo ""
    echo "=== 4. 验证数据库（记录应该标记为已删除）==="
    DB_RESULT=$(sqlite3 baby_tracker.db \
      "SELECT id, deleted_at IS NOT NULL as is_deleted FROM records WHERE id=$RECORD_ID")
    
    if echo "$DB_RESULT" | grep -q "|1$"; then
        echo "✓ 数据库验证成功：记录已软删除（deleted_at有值）"
        echo "  数据库结果: $DB_RESULT"
    else
        echo "❌ 数据库验证失败：记录未被软删除"
        echo "  数据库结果: $DB_RESULT"
        echo "  这说明记录被硬删除了！"
        kill $SERVER_PID
        exit 1
    fi
    
    echo ""
    echo "=== 5. 通过API获取记录（应该看到is_deleted=true）==="
    API_RESULT=$(curl -s "$SERVER/api/records?date=$(date +%Y-%m-%d)" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$API_RESULT" | grep -q "\"id\":$RECORD_ID.*\"is_deleted\":true"; then
        echo "✓ API返回正确：is_deleted=true"
    else
        echo "⚠️  API中找不到该记录或is_deleted字段"
        echo "  (记录可能在不同的日期)"
    fi
    
    echo ""
    echo "=== 6. 恢复记录 ==="
    RESTORE_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      "$SERVER/api/records/restore?id=$RECORD_ID" \
      -X PUT \
      -H "Authorization: Bearer $TOKEN")
    
    if [ "$RESTORE_HTTP_CODE" != "204" ]; then
        echo "❌ 恢复失败，HTTP状态码: $RESTORE_HTTP_CODE"
        kill $SERVER_PID
        exit 1
    fi
    echo "✓ 恢复请求成功（HTTP 204）"
    
    echo ""
    echo "=== 7. 验证恢复结果 ==="
    DB_RESULT_AFTER=$(sqlite3 baby_tracker.db \
      "SELECT id, deleted_at IS NOT NULL as is_deleted FROM records WHERE id=$RECORD_ID")
    
    if echo "$DB_RESULT_AFTER" | grep -q "|0$"; then
        echo "✓ 数据库验证成功：记录已恢复（deleted_at为NULL）"
        echo "  数据库结果: $DB_RESULT_AFTER"
    else
        echo "❌ 数据库验证失败：记录未恢复"
        echo "  数据库结果: $DB_RESULT_AFTER"
        kill $SERVER_PID
        exit 1
    fi
    
    echo ""
    echo "=== 8. 清理测试记录 ==="
    curl -s "$SERVER/api/records?id=$RECORD_ID" \
      -X DELETE \
      -H "Authorization: Bearer $TOKEN" > /dev/null
    echo "✓ 测试记录已删除"
    
    echo ""
    echo "🎉 所有测试通过！软删除功能工作正常！"
}

# 运行测试
if test_soft_delete; then
    echo ""
    echo "📍 服务仍在运行，PID: $SERVER_PID"
    echo "   访问: http://localhost:8080"
    echo ""
    echo "   停止服务: kill $SERVER_PID"
    echo "   或按 Ctrl+C"
    echo ""
    
    # 保持服务运行
    wait $SERVER_PID
else
    echo "❌ 测试失败"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

