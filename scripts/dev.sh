#!/bin/bash

# Development script for Baby Tracker application
# This script starts both backend and frontend in development mode

echo "🚀 Starting Baby Tracker in development mode..."
echo ""
echo "Backend will run on: http://localhost:8080"
echo "Frontend will run on: http://localhost:5173"
echo ""

# Function to kill background processes on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit
}

trap cleanup EXIT INT TERM

# Start backend
echo "Starting backend..."
cd backend
go run main.go &
BACKEND_PID=$!
cd ..

# Wait a bit for backend to start
sleep 2

# Start frontend
echo "Starting frontend..."
cd web
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "✅ Services started!"
echo "   Backend PID: $BACKEND_PID"
echo "   Frontend PID: $FRONTEND_PID"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for processes
wait

