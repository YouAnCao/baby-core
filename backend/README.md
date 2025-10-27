# Baby Tracker Backend

Golang REST API 后端服务

## 开发

```bash
# 安装依赖
go mod download

# 运行
go run main.go

# 构建
go build -o baby-tracker

# 运行测试（如果有）
go test ./...
```

## 项目结构

- `main.go` - 应用入口和路由配置
- `config/` - 配置管理
- `database/` - 数据库连接和迁移
- `models/` - 数据模型
- `handlers/` - HTTP 请求处理器
- `middleware/` - 中间件（认证等）
- `utils/` - 工具函数（加密等）

## 环境变量

- `PORT` - 服务器端口（默认: 8080）
- `DB_PATH` - SQLite 数据库路径（默认: ./baby_tracker.db）
- `JWT_SECRET` - JWT 签名密钥（默认: your-secret-key-change-in-production）

## API 端点

参见主 README.md

