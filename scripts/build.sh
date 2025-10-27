#!/bin/bash

# Build script for Baby Tracker application
# This script builds both frontend and backend for production deployment

set -e

echo "🚀 Building Baby Tracker Application..."

# Build frontend
echo "📦 Building frontend..."
cd web
npm install
npm run build
cd ..

# Build backend
echo "🔨 Building backend..."
cd backend
go mod download
go build -o baby-tracker main.go
cd ..

echo "✅ Build complete!"
echo ""
echo "To run the application:"
echo "  cd backend"
echo "  ./baby-tracker"
echo ""
echo "The application will be available at http://localhost:8080"
echo "Default credentials: admin / admin123"

