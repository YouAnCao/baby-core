# Multi-stage build
FROM node:18-alpine AS frontend-builder

WORKDIR /app/web
COPY web/package*.json ./
RUN npm install
COPY web/ ./
RUN npm run build

# Go backend build
FROM golang:1.21-alpine AS backend-builder

# Install build dependencies for CGO (required by SQLite driver)
RUN apk add --no-cache gcc musl-dev sqlite-dev

WORKDIR /app
COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ ./
# Copy built frontend from previous stage
COPY --from=frontend-builder /app/backend/dist ./dist

# Build with CGO enabled, using musl-compatible flags for Alpine Linux
RUN CGO_ENABLED=1 GOOS=linux CGO_CFLAGS="-D_LARGEFILE64_SOURCE" \
    go build -a -installsuffix cgo -ldflags="-s -w" -o baby-tracker .

# Final runtime stage
FROM alpine:latest

# Install runtime dependencies and timezone data
RUN apk --no-cache add ca-certificates sqlite tzdata

# Set timezone to Asia/Shanghai
ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /app

# Copy binary and static files
COPY --from=backend-builder /app/baby-tracker .
COPY --from=backend-builder /app/dist ./dist
# Copy SQL files from build context
COPY sql ./sql

# Create data directory for database
RUN mkdir -p /app/data

# Expose port
EXPOSE 8899

# Set environment variables
ENV PORT=8899
ENV DB_PATH=/app/data/baby_tracker.db
ENV JWT_SECRET=change-this-in-production

# Run the binary
CMD ["./baby-tracker"]

