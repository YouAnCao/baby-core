# Baby Tracker - 宝宝记录系统

一个简洁的宝宝日常记录应用，用于快速记录喂养、尿布更换等日常照顾信息。

## 项目结构

```
baby-core/
├── backend/      # Golang REST API 后端
├── web/          # Vue 3 前端
└── sql/          # SQLite 数据库架构
```

## 技术栈

### 后端
- **语言**: Go 1.21+
- **路由**: Chi
- **数据库**: SQLite3
- **认证**: JWT

### 前端
- **框架**: Vue 3 (Composition API)
- **构建工具**: Vite
- **状态管理**: Pinia
- **HTTP 客户端**: Axios

## 快速开始

### 前置要求

- Go 1.21 或更高版本
- Node.js 18+ 和 npm

### 安装和运行

#### 1. 安装后端依赖

```bash
cd backend
go mod download
```

#### 2. 安装前端依赖

```bash
cd web
npm install
```

#### 3. 开发模式运行

**终端 1 - 启动后端**:
```bash
cd backend
go run main.go
```

后端将在 `http://localhost:8080` 运行

**终端 2 - 启动前端开发服务器**:
```bash
cd web
npm run dev
```

前端开发服务器将在 `http://localhost:5173` 运行

#### 4. 生产模式部署

```bash
# 构建前端
cd web
npm run build

# 运行后端（会自动服务前端静态文件）
cd ../backend
go build -o baby-tracker
./baby-tracker
```

访问 `http://localhost:8080` 即可使用应用

## 默认登录信息

- **用户名**: admin
- **密码**: admin123

> ⚠️ 首次登录时会自动设置此密码，请在生产环境中及时修改

## 环境变量配置

可以通过环境变量自定义配置：

```bash
# 服务器端口（默认: 8080）
PORT=8080

# 数据库路径（默认: ./baby_tracker.db）
DB_PATH=./baby_tracker.db

# JWT 密钥（生产环境请务必修改）
JWT_SECRET=your-secret-key-change-in-production
```

## 功能特性

### 当前功能
- ✅ 用户登录认证（JWT）
- ✅ 快速记录喂养（母乳左/右、奶瓶）
- ✅ **⏱️ 喂奶计时器**（实时计时、目标提醒、提示音）**NEW!**
- ✅ 快速记录尿布（尿尿、粑粑、都有）
- ✅ 按日期查看历史记录
- ✅ 记事本风格界面设计

### 计划功能
- 📋 AI 分析（Gemini/GPT 集成）
- 📋 7 天数据对比
- 📋 数据导出功能

## API 接口

### 公开接口
- `POST /api/login` - 用户登录

### 受保护接口（需要 JWT Token）
- `POST /api/records` - 创建记录
- `GET /api/records?date=YYYY-MM-DD` - 获取指定日期的记录
- `DELETE /api/records?id=<record_id>` - 删除记录
- `GET /api/records/summary` - 获取汇总（待实现）

## 数据结构

### 喂养记录 (feeding)
```json
{
  "record_type": "feeding",
  "record_time": "2025-10-28T09:13:00Z",
  "details": {
    "method": "breast_left|breast_right|bottle",
    "duration_minutes": 15,
    "amount_ml": 30
  }
}
```

### 尿布记录 (diaper)
```json
{
  "record_type": "diaper",
  "record_time": "2025-10-28T09:35:00Z",
  "details": {
    "has_urine": true,
    "urine_amount": "少量|普通|大量",
    "has_stool": true,
    "stool_amount": "少量|普通|大量"
  }
}
```

## 安全说明

1. **密码加密**: 使用 MD5 + Salt（生产环境建议升级为 bcrypt）
2. **JWT 认证**: Token 有效期 7 天
3. **CORS 配置**: 开发环境允许本地端口访问
4. **用户隔离**: 用户只能访问自己的记录

## 部署建议

### 单服务器部署
1. 构建前端静态文件
2. 编译 Go 后端
3. 将编译后的二进制文件和数据库部署到服务器
4. 使用 systemd 或 supervisor 管理进程

### 资源占用
- 内存: ~20-50MB
- 磁盘: ~10-20MB（含数据库）
- CPU: 极低

## 许可证

本项目为个人使用项目。

## 作者

Lyon Cao

