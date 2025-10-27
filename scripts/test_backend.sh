#!/bin/bash

# Test backend startup and API

cd "$(dirname "$0")/../backend"

export PATH="$HOME/.local/go/bin:$PATH"
export GOPATH="$HOME/go"

echo "🚀 Starting backend..."
go run main.go &
BACKEND_PID=$!

echo "Backend PID: $BACKEND_PID"
echo "Waiting for backend to start..."
sleep 5

echo ""
echo "Testing API..."
echo "1. Testing login with correct credentials:"
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  2>/dev/null | python3 -m json.tool || echo "Failed"

echo ""
echo "2. Testing login with wrong credentials:"
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"wrong"}' \
  2>/dev/null

echo ""
echo "Stopping backend..."
kill $BACKEND_PID 2>/dev/null
echo "✅ Test complete"

