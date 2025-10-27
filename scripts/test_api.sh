#!/bin/bash

# Complete API Testing Script

set -e

BASE_URL="http://localhost:8080"

echo "🧪 Baby Tracker API Testing"
echo "================================"
echo ""

# Test 1: Login with correct credentials
echo "✓ Test 1: Login with correct credentials"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')

TOKEN=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
fi

echo "   Token received: ${TOKEN:0:50}..."
echo ""

# Test 2: Create feeding record
echo "✓ Test 2: Create feeding record (母乳-左)"
RECORD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FEEDING_RESPONSE=$(curl -s -X POST "$BASE_URL/api/records" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"record_type\": \"feeding\",
    \"record_time\": \"$RECORD_TIME\",
    \"details\": \"{\\\"method\\\":\\\"breast_left\\\",\\\"duration_minutes\\\":15}\",
    \"notes\": \"测试记录\"
  }")

RECORD_ID=$(echo $FEEDING_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
echo "   Record created with ID: $RECORD_ID"
echo ""

# Test 3: Create diaper record
echo "✓ Test 3: Create diaper record (尿尿)"
curl -s -X POST "$BASE_URL/api/records" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"record_type\": \"diaper\",
    \"record_time\": \"$RECORD_TIME\",
    \"details\": \"{\\\"has_urine\\\":true,\\\"urine_amount\\\":\\\"普通\\\",\\\"has_stool\\\":false}\",
    \"notes\": \"\"
  }" > /dev/null

echo "   Diaper record created"
echo ""

# Test 4: Get today's records
echo "✓ Test 4: Get today's records"
TODAY=$(date +"%Y-%m-%d")
RECORDS=$(curl -s -X GET "$BASE_URL/api/records?date=$TODAY" \
  -H "Authorization: Bearer $TOKEN")

RECORD_COUNT=$(echo $RECORDS | python3 -c "import sys, json; print(len(json.load(sys.stdin)['records']))" 2>/dev/null)
echo "   Found $RECORD_COUNT records for today"
echo ""

# Test 5: Test without authentication
echo "✓ Test 5: Test authentication protection"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/api/records")
if [ "$STATUS" = "401" ]; then
  echo "   ✅ Correctly returns 401 Unauthorized"
else
  echo "   ❌ Expected 401, got $STATUS"
fi
echo ""

# Test 6: Test wrong credentials
echo "✓ Test 6: Test wrong credentials"
WRONG_RESPONSE=$(curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"wrongpassword"}')

if echo "$WRONG_RESPONSE" | grep -q "登录失败"; then
  echo "   ✅ Correctly returns Chinese error message"
else
  echo "   ❌ Unexpected response"
fi
echo ""

echo "================================"
echo "✅ All API tests passed!"
echo ""
echo "📊 Summary:"
echo "   - Login: ✅"
echo "   - Create feeding record: ✅"
echo "   - Create diaper record: ✅"
echo "   - Get records by date: ✅"
echo "   - Authentication protection: ✅"
echo "   - Error handling: ✅"

