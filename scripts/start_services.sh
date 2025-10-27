#!/bin/bash

# Start all Baby Tracker services

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "🚀 Starting Baby Tracker services..."
echo "Project root: $PROJECT_ROOT"
echo ""

# Set up Go environment
export PATH="$HOME/.local/go/bin:$PATH"
export GOPATH="$HOME/go"

# Start backend
echo "Starting backend..."
cd "$PROJECT_ROOT/backend"
nohup ./baby-tracker > /tmp/baby-backend.log 2>&1 &
echo "  ✅ Backend started (PID: $!)"
echo "  📝 Logs: /tmp/baby-backend.log"

sleep 2

# Start frontend
echo "Starting frontend..."
cd "$PROJECT_ROOT/web"
nohup npm run dev > /tmp/baby-frontend.log 2>&1 &
echo "  ✅ Frontend started (PID: $!)"
echo "  📝 Logs: /tmp/baby-frontend.log"

sleep 3

echo ""
echo "================================"
echo "✅ All services started!"
echo ""
echo "🌐 Access the application:"
echo "   Frontend: http://localhost:5173"
echo "   Backend:  http://localhost:8080"
echo ""
echo "🔐 Login credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📝 View logs:"
echo "   tail -f /tmp/baby-backend.log"
echo "   tail -f /tmp/baby-frontend.log"
echo ""
echo "🛑 Stop services:"
echo "   bash $PROJECT_ROOT/scripts/stop_services.sh"
echo "================================"

