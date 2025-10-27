# 验证清单

在首次运行应用前，请按照此清单验证项目完整性。

## 📁 文件结构验证

### SQL 文件
- [ ] `sql/001_init.sql` 存在
- [ ] `sql/002_records.sql` 存在
- [ ] `sql/003_ai_analysis.sql` 存在

### 后端文件
- [ ] `backend/main.go` 存在
- [ ] `backend/go.mod` 存在
- [ ] `backend/config/config.go` 存在
- [ ] `backend/database/db.go` 存在
- [ ] `backend/models/user.go` 存在
- [ ] `backend/models/record.go` 存在
- [ ] `backend/handlers/auth.go` 存在
- [ ] `backend/handlers/records.go` 存在
- [ ] `backend/middleware/auth.go` 存在
- [ ] `backend/utils/crypto.go` 存在

### 前端文件
- [ ] `web/package.json` 存在
- [ ] `web/vite.config.js` 存在
- [ ] `web/index.html` 存在
- [ ] `web/src/main.js` 存在
- [ ] `web/src/App.vue` 存在
- [ ] `web/src/router/index.js` 存在
- [ ] `web/src/stores/auth.js` 存在
- [ ] `web/src/api/index.js` 存在
- [ ] `web/src/views/Login.vue` 存在
- [ ] `web/src/views/Tracking.vue` 存在
- [ ] `web/src/components/QuickEntry.vue` 存在
- [ ] `web/src/components/RecordList.vue` 存在
- [ ] `web/src/styles/main.css` 存在

### 文档和脚本
- [ ] `README.md` 存在
- [ ] `QUICKSTART.md` 存在
- [ ] `DEPLOYMENT.md` 存在
- [ ] `.gitignore` 存在
- [ ] `scripts/build.sh` 存在且可执行
- [ ] `scripts/dev.sh` 存在且可执行

## 🔧 环境验证

### 开发环境
```bash
# 检查 Go 版本（需要 1.21+）
go version

# 检查 Node.js 版本（需要 18+）
node --version

# 检查 npm 版本
npm --version
```

预期输出：
- Go: `go version go1.21.x` 或更高
- Node: `v18.x.x` 或更高
- npm: `9.x.x` 或更高

## 🚀 功能测试清单

### 后端测试

#### 1. 安装依赖
```bash
cd backend
go mod download
```
- [ ] 无错误信息
- [ ] 成功下载所有依赖

#### 2. 启动后端
```bash
go run main.go
```
预期输出：
```
Database initialized successfully
Server starting on http://localhost:8080
```
- [ ] 成功启动
- [ ] 监听 8080 端口
- [ ] 数据库文件 `baby_tracker.db` 已创建

#### 3. 测试登录 API
```bash
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```
预期输出：包含 `token` 和 `user` 的 JSON
- [ ] 返回 200 状态码
- [ ] 返回 JWT token
- [ ] 返回用户信息

### 前端测试

#### 1. 安装依赖
```bash
cd web
npm install
```
- [ ] 无错误信息
- [ ] 成功安装所有依赖
- [ ] 创建 `node_modules` 目录

#### 2. 启动开发服务器
```bash
npm run dev
```
预期输出：
```
VITE ready in XXX ms
➜ Local: http://localhost:5173/
```
- [ ] 成功启动
- [ ] 监听 5173 端口
- [ ] 可以访问 http://localhost:5173

#### 3. 测试登录页面
访问: http://localhost:5173/login

检查项：
- [ ] 页面正常加载
- [ ] 显示"宝宝记录"标题
- [ ] 显示用户名输入框
- [ ] 显示密码输入框
- [ ] 显示"登录"按钮
- [ ] 背景显示记事本纹理

#### 4. 测试登录功能
输入：
- 用户名: `admin`
- 密码: `admin123`

点击"登录"

预期结果：
- [ ] 成功登录
- [ ] 跳转到主页面（/）
- [ ] 显示"宝宝日记"标题
- [ ] 显示日期选择器
- [ ] 显示快速记录按钮

#### 5. 测试喂养记录
点击"母乳-左"按钮

预期结果：
- [ ] 弹出记录模态框
- [ ] 显示"记录喂养"标题
- [ ] 显示"母乳-左"类型
- [ ] 显示"时长（分钟）"输入框
- [ ] 有"取消"和"保存"按钮

输入时长: `15`
点击"保存"

预期结果：
- [ ] 模态框关闭
- [ ] 在记录列表中显示新记录
- [ ] 记录显示正确的时间
- [ ] 记录显示"母乳-左 15分钟"

#### 6. 测试尿布记录
点击"尿尿"按钮

预期结果：
- [ ] 弹出记录模态框
- [ ] 显示"尿量"选择器
- [ ] 默认选中"普通"
- [ ] 有"取消"和"保存"按钮

点击"保存"

预期结果：
- [ ] 模态框关闭
- [ ] 在记录列表中显示新记录
- [ ] 记录显示"尿尿(普通)"

#### 7. 测试日期导航
点击左箭头按钮

预期结果：
- [ ] 日期减少一天
- [ ] 记录列表清空（昨天没有记录）

点击"今天"按钮

预期结果：
- [ ] 回到今天日期
- [ ] 显示今天的记录

#### 8. 测试登出
点击"退出"按钮

预期结果：
- [ ] 跳转到登录页面
- [ ] Token 被清除
- [ ] 尝试访问 `/` 自动跳转到 `/login`

## 🎨 UI/UX 验证

### 桌面浏览器
- [ ] 记事本背景纹理显示正常
- [ ] 字体大小适中（18px+）
- [ ] 按钮点击有视觉反馈
- [ ] 颜色搭配舒适
- [ ] 布局居中对齐

### 移动浏览器
打开浏览器开发者工具，切换到移动设备模式

- [ ] 页面自适应屏幕宽度
- [ ] 按钮大小适合触摸
- [ ] 文字清晰可读
- [ ] 模态框在小屏幕上显示正常
- [ ] 日期选择器工作正常

## 🔐 安全验证

### 认证测试
```bash
# 未登录访问受保护端点
curl http://localhost:8080/api/records
```
预期: 返回 401 Unauthorized
- [ ] 正确返回 401

```bash
# 使用错误的 token
curl http://localhost:8080/api/records \
  -H "Authorization: Bearer invalid-token"
```
预期: 返回 401 Unauthorized
- [ ] 正确返回 401

### 密码测试
尝试用错误密码登录

预期：
- [ ] 显示"登录失败请稍后再试"
- [ ] 不显示具体错误原因（安全）

## 📊 性能验证

### 响应时间
- [ ] 登录响应 < 500ms
- [ ] 记录创建响应 < 300ms
- [ ] 记录查询响应 < 300ms
- [ ] 页面加载 < 2s

### 资源使用
```bash
# 查看后端进程
ps aux | grep baby-tracker
```
- [ ] 内存使用 < 100MB
- [ ] CPU 使用率低

## 🏗️ 构建验证

### 前端构建
```bash
cd web
npm run build
```
预期：
- [ ] 构建成功
- [ ] 在 `../backend/dist` 创建文件
- [ ] 包含 `index.html`
- [ ] 包含 `assets/` 目录

### 后端构建
```bash
cd backend
go build -o baby-tracker main.go
```
预期：
- [ ] 编译成功
- [ ] 创建可执行文件 `baby-tracker`
- [ ] 文件大小合理（~10-20MB）

### 运行生产版本
```bash
./baby-tracker
```
访问: http://localhost:8080

预期：
- [ ] 可以访问应用
- [ ] 功能与开发模式一致
- [ ] 静态文件正常加载

## ✅ 最终检查

- [ ] 所有文件结构验证通过
- [ ] 环境版本符合要求
- [ ] 后端测试全部通过
- [ ] 前端测试全部通过
- [ ] UI/UX 验证通过
- [ ] 安全验证通过
- [ ] 性能验证通过
- [ ] 构建验证通过

## 🎉 验证完成

如果所有检查项都已完成，恭喜！项目已经可以正式使用了。

## 📝 问题记录

如果有任何检查项未通过，请在此记录：

```
日期: 
问题描述: 
解决方案: 
```

## 🆘 常见问题

### Go 依赖下载失败
```bash
go env -w GOPROXY=https://goproxy.cn,direct
```

### npm 安装失败
```bash
npm config set registry https://registry.npmmirror.com
```

### 端口被占用
```bash
# 查找占用进程
lsof -i :8080
lsof -i :5173

# 杀死进程
kill -9 <PID>
```

### 数据库锁定
```bash
# 删除数据库重建
rm backend/baby_tracker.db
# 重新启动后端
```

