#!/bin/bash

# Stop all Baby Tracker services

echo "🛑 Stopping Baby Tracker services..."

# Stop backend
echo "Stopping backend..."
pkill -f "baby-tracker" && echo "  ✅ Backend stopped" || echo "  ℹ️  Backend not running"

# Stop frontend
echo "Stopping frontend..."
pkill -f "vite.*baby-tracker" && echo "  ✅ Frontend stopped" || echo "  ℹ️  Frontend not running"

echo ""
echo "✅ All services stopped"

