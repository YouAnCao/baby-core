# 🎯 快速访问指南

## 📍 立即访问

### 1. 打开浏览器
在浏览器中访问:
```
http://localhost:5173
```

### 2. 登录
```
用户名: admin
密码: admin123
```

### 3. 开始使用
- 点击快速按钮记录喂养和尿布
- 使用日期选择器查看历史记录

---

## 🎛️ 服务控制

### 启动服务
```bash
cd ~/dev/python/baby-core
bash scripts/start_services.sh
```

### 停止服务
```bash
cd ~/dev/python/baby-core
bash scripts/stop_services.sh
```

### 测试 API
```bash
cd ~/dev/python/baby-core
bash scripts/test_api.sh
```

---

## 📱 使用说明

### 记录喂养
1. 点击对应按钮:
   - **母乳-左**: 记录左侧母乳喂养
   - **母乳-右**: 记录右侧母乳喂养
   - **奶瓶**: 记录奶瓶喂养

2. 输入详情:
   - 母乳: 输入时长（分钟）
   - 奶瓶: 输入奶量（ml）

3. 点击"保存"

### 记录尿布
1. 点击对应按钮:
   - **尿尿**: 只有尿
   - **粑粑**: 只有粑粑
   - **都有**: 尿和粑粑都有

2. 选择量:
   - 少量
   - 普通
   - 大量

3. 点击"保存"

### 查看历史
- **左右箭头**: 切换前后日期
- **日期选择**: 直接选择某一天
- **今天按钮**: 快速返回今天

---

## 🆘 常见问题

### Q: 无法访问页面?
A: 确保服务正在运行:
```bash
lsof -i :5173  # 检查前端
lsof -i :8080  # 检查后端
```

### Q: 登录失败?
A: 确认使用正确的用户名和密码:
- 用户名: admin
- 密码: admin123

### Q: 数据丢失?
A: 数据存储在:
```
~/dev/python/baby-core/backend/baby_tracker.db
```
定期备份此文件!

---

## 📞 帮助

查看详细文档:
- `README.md` - 完整说明
- `DEPLOYMENT_STATUS.md` - 部署状态
- `VERIFICATION_CHECKLIST.md` - 验证清单

---

**享受使用! 🍼👶**

