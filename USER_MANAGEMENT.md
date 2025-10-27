# 用户管理指南

本文档介绍如何管理 Baby Core 应用的用户账户。

## 📋 用户管理脚本

### 1. 创建用户 - `create-user.sh` ⭐

创建新用户账户，支持指定用户名和密码。

**用法**:

```bash
# 方式 1: 命令行参数
./create-user.sh <username> <password>

# 方式 2: 只指定用户名，密码交互输入
./create-user.sh <username>

# 方式 3: 完全交互式
./create-user.sh
```

**示例**:

```bash
# 创建用户 admin，密码 mypassword123
./create-user.sh admin mypassword123

# 创建用户 john，密码会提示输入
./create-user.sh john

# 交互式创建用户
./create-user.sh
# 然后输入用户名和密码
```

**功能**:
- ✅ 自动生成 bcrypt 密码哈希
- ✅ 支持命令行参数和交互式输入
- ✅ 如果用户已存在，会替换（更新）
- ✅ 自动记录创建/更新时间
- ✅ 验证用户创建成功

---

### 2. 列出用户 - `list-users.sh`

显示数据库中所有用户的列表。

**用法**:

```bash
./list-users.sh
```

**输出示例**:

```
==========================================
Baby Core - 用户列表
==========================================

数据库中的用户:

id  username  created_at           updated_at
--  --------  -------------------  -------------------
1   admin     2025-10-28 03:15:22  2025-10-28 03:15:22
2   john      2025-10-28 03:20:45  2025-10-28 03:20:45
3   mary      2025-10-28 03:25:10  2025-10-28 03:25:10

==========================================
```

---

### 3. 重置密码 - `reset-password.sh`

重置指定用户的密码。

**用法**:

```bash
# 方式 1: 命令行指定新密码
./reset-password.sh <username> <new_password>

# 方式 2: 交互式输入新密码（推荐，更安全）
./reset-password.sh <username>
```

**示例**:

```bash
# 重置 admin 的密码为 newpass123
./reset-password.sh admin newpass123

# 交互式重置密码（会提示输入两次新密码）
./reset-password.sh admin
```

**功能**:
- ✅ 验证用户是否存在
- ✅ 交互式输入时会要求确认密码
- ✅ 自动更新 updated_at 时间戳
- ✅ 生成新的 bcrypt 哈希

---

### 4. 删除用户 - `delete-user.sh`

删除指定的用户账户。

**用法**:

```bash
./delete-user.sh <username>
```

**示例**:

```bash
./delete-user.sh john
```

**交互过程**:

```
==========================================
Baby Core - 删除用户
==========================================

警告: 即将删除用户 'john'
确认删除? (yes/no): yes

✓ 用户 'john' 已删除
```

**注意**:
- ⚠️ 删除操作不可恢复
- ⚠️ 需要输入 `yes` 确认删除
- ⚠️ 会检查用户是否存在

---

## 🚀 快速开始

### 首次部署后创建管理员

```bash
# 方式 1: 使用默认用户脚本
./init-user-simple.sh
# 创建: admin / admin123

# 方式 2: 使用自定义用户脚本
./create-user.sh admin MySecurePassword123
```

### 创建多个用户

```bash
# 为家人创建账户
./create-user.sh dad password1
./create-user.sh mom password2
./create-user.sh grandma password3
```

### 查看所有用户

```bash
./list-users.sh
```

### 重置忘记的密码

```bash
# 交互式重置（推荐）
./reset-password.sh admin

# 或直接指定新密码
./reset-password.sh admin NewPassword123
```

### 删除不需要的用户

```bash
./delete-user.sh old_user
```

---

## 📖 完整使用流程示例

### 场景 1: 新系统设置

```bash
# 1. 部署应用
./deploy.sh

# 2. 创建管理员账户
./create-user.sh admin SecurePass123

# 3. 创建家庭成员账户
./create-user.sh dad DadPass123
./create-user.sh mom MomPass123

# 4. 查看所有用户
./list-users.sh

# 5. 访问应用并登录
# http://your-server-ip/baby-core
```

### 场景 2: 密码管理

```bash
# 用户忘记密码
./reset-password.sh john

# 或管理员重置密码
./reset-password.sh john NewTempPassword123
```

### 场景 3: 用户管理

```bash
# 列出所有用户
./list-users.sh

# 删除离职或不再使用的账户
./delete-user.sh old_account

# 验证删除
./list-users.sh
```

---

## 🔒 安全建议

### 密码安全

1. **使用强密码**
   - 至少 8 个字符
   - 包含大小写字母、数字和特殊字符
   - 避免使用常见密码

2. **定期更换密码**
   ```bash
   ./reset-password.sh username
   ```

3. **不要在命令行中明文输入密码**
   ```bash
   # ❌ 不推荐（密码会留在 shell 历史中）
   ./create-user.sh admin password123
   
   # ✅ 推荐（交互式输入）
   ./create-user.sh admin
   ```

### 用户管理

1. **及时删除不用的账户**
   ```bash
   ./delete-user.sh unused_user
   ```

2. **定期审查用户列表**
   ```bash
   ./list-users.sh
   ```

3. **首次登录后修改默认密码**
   - 如果使用了 `init-user-simple.sh`，请立即修改 admin/admin123

---

## 🛠️ 故障排查

### 容器未运行

**错误**:
```
错误: baby-core 容器未运行
```

**解决方案**:
```bash
# 启动容器
docker-compose up -d

# 验证容器状态
docker-compose ps
```

### 密码哈希生成失败

**错误**:
```
错误: 生成密码哈希失败
```

**可能原因**:
- 容器内缺少必要的 Go 依赖
- 密码包含特殊字符导致 shell 解析错误

**解决方案**:
```bash
# 使用交互式输入（避免特殊字符问题）
./create-user.sh username

# 或检查容器日志
docker-compose logs baby-core
```

### 数据库权限问题

**错误**:
```
错误: 插入用户失败
```

**解决方案**:
```bash
# 检查数据目录权限
ls -la data/

# 修复权限
chmod 755 data/
chmod 644 data/*.db

# 重启容器
docker-compose restart baby-core
```

---

## 📊 技术细节

### 密码存储

- 使用 **bcrypt** 算法加密密码
- Cost factor: **10**（默认）
- 每个密码生成唯一的盐值
- 密码哈希不可逆

### 数据库结构

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 脚本工作原理

1. **create-user.sh**
   - 在容器内创建临时 Go 程序
   - 使用 `golang.org/x/crypto/bcrypt` 生成哈希
   - 通过 `INSERT OR REPLACE` 插入/更新用户
   - 清理临时文件

2. **list-users.sh**
   - 直接查询 SQLite 数据库
   - 格式化输出表格

3. **reset-password.sh**
   - 检查用户是否存在
   - 生成新密码哈希
   - 使用 `UPDATE` 更新密码和时间戳

4. **delete-user.sh**
   - 确认操作
   - 使用 `DELETE` 删除用户记录

---

## 🎯 常用命令速查

```bash
# 创建用户（交互式）
./create-user.sh

# 创建指定用户
./create-user.sh username password

# 列出所有用户
./list-users.sh

# 重置密码（交互式）
./reset-password.sh username

# 删除用户
./delete-user.sh username

# 创建默认管理员（admin/admin123）
./init-user-simple.sh
```

---

## 📝 相关文档

- [快速开始指南](./QUICKSTART_DOCKER.md)
- [完整部署文档](./DEPLOYMENT_DOCKER.md)
- [服务器配置指南](./SERVER_SETUP.md)
- [部署入口文档](./DEPLOY_README.md)

---

**更新日期**: 2025-10-28  
**版本**: 1.0.0

