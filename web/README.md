# Baby Tracker Web Frontend

Vue 3 前端应用

## 开发

```bash
# 安装依赖
npm install

# 开发服务器
npm run dev

# 构建生产版本
npm run build

# 预览生产构建
npm run preview
```

## 项目结构

- `src/main.js` - 应用入口
- `src/App.vue` - 根组件
- `src/router/` - 路由配置
- `src/stores/` - Pinia 状态管理
- `src/views/` - 页面组件
- `src/components/` - 可复用组件
- `src/api/` - API 客户端
- `src/styles/` - 全局样式

## 技术栈

- Vue 3 (Composition API)
- Vue Router 4
- Pinia (状态管理)
- Axios (HTTP 客户端)
- Vite (构建工具)

## 环境配置

开发模式下，Vite 会自动代理 `/api` 请求到 `http://localhost:8080`

生产构建会输出到 `../backend/dist` 目录，由 Go 后端服务

