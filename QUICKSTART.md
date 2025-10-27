# 快速开始指南

## 最快启动方式

### 开发模式

```bash
# 1. 进入项目目录
cd baby-core

# 2. 安装依赖
cd backend && go mod download && cd ..
cd web && npm install && cd ..

# 3. 启动（需要两个终端）

# 终端 1 - 后端
cd backend
go run main.go

# 终端 2 - 前端  
cd web
npm run dev
```

然后访问: http://localhost:5173

### 生产模式

```bash
# 1. 构建
chmod +x scripts/build.sh
./scripts/build.sh

# 2. 运行
cd backend
./baby-tracker
```

然后访问: http://localhost:8080

## 默认登录

- 用户名: `admin`
- 密码: `admin123`

## 使用说明

### 记录喂养
1. 点击"母乳-左"、"母乳-右"或"奶瓶"按钮
2. 母乳记录时长（分钟），奶瓶记录奶量（ml）
3. 可添加备注
4. 点击"保存"

### 记录尿布
1. 点击"尿尿"、"粑粑"或"都有"按钮
2. 选择量的大小（少量/普通/大量）
3. 可添加备注
4. 点击"保存"

### 查看历史
- 使用日期选择器切换日期
- 点击"今天"按钮快速返回今天
- 使用左右箭头导航前后日期

## 故障排查

### 后端启动失败
- 确保 Go 版本 >= 1.21
- 确保 8080 端口未被占用
- 检查 go.mod 依赖是否正确下载

### 前端启动失败  
- 确保 Node.js 版本 >= 18
- 删除 node_modules 重新安装: `rm -rf node_modules && npm install`
- 确保 5173 端口未被占用

### 无法登录
- 检查后端是否正常运行
- 确认使用默认凭据: admin / admin123
- 查看浏览器控制台错误信息

### 数据库问题
- 数据库文件位置: `backend/baby_tracker.db`
- 删除数据库文件可重置所有数据
- 首次运行会自动创建数据库

## 环境变量（可选）

```bash
# 修改服务器端口
export PORT=3000

# 修改数据库路径
export DB_PATH=/path/to/database.db

# 修改 JWT 密钥（生产环境必须修改）
export JWT_SECRET=your-very-secure-secret-key
```

## 下一步

- 阅读完整 README: [README.md](README.md)
- 查看 API 文档了解接口详情
- 准备 AI 集成功能的实现

