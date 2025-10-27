<template>
  <div class="login-container">
    <div class="login-card">
      <h1>宝宝记录</h1>
      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="username">用户名</label>
          <input
            id="username"
            v-model="username"
            type="text"
            placeholder="请输入用户名"
            required
            autocomplete="username"
          />
        </div>
        <div class="form-group">
          <label for="password">密码</label>
          <input
            id="password"
            v-model="password"
            type="password"
            placeholder="请输入密码"
            required
            autocomplete="current-password"
          />
        </div>
        <button type="submit" :disabled="loading">
          {{ loading ? '登录中...' : '登录' }}
        </button>
        <div v-if="error" class="error-message">
          {{ error }}
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { authAPI } from '../api'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

const handleLogin = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await authAPI.login(username.value, password.value)
    authStore.setAuth(response.data.token, response.data.user)
    router.push('/')
  } catch (err) {
    error.value = '登录失败请稍后再试'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
}

.login-card {
  background: rgba(255, 255, 255, 0.95);
  padding: 40px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

h1 {
  text-align: center;
  margin-bottom: 30px;
  color: #5a4a3a;
  font-size: 28px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 8px;
  color: #5a4a3a;
  font-weight: 500;
  font-size: 16px;
}

input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #d4c5b9;
  border-radius: 8px;
  font-size: 16px;
  background: #fefdfb;
  box-sizing: border-box;
  transition: border-color 0.3s;
}

input:focus {
  outline: none;
  border-color: #8b7355;
}

button {
  width: 100%;
  padding: 14px;
  background: #8b7355;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;
}

button:hover:not(:disabled) {
  background: #6d5940;
}

button:disabled {
  background: #b4a494;
  cursor: not-allowed;
}

.error-message {
  margin-top: 16px;
  padding: 12px;
  background: #ffe5e5;
  color: #c33;
  border-radius: 8px;
  text-align: center;
  font-size: 15px;
}
</style>

