import axios from 'axios'
import { useAuthStore } from '../stores/auth'
import router from '../router'

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor to add JWT token
api.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore()
    if (authStore.token) {
      config.headers.Authorization = `Bearer ${authStore.token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const authStore = useAuthStore()
      authStore.clearAuth()
      router.push('/login')
    }
    return Promise.reject(error)
  }
)

// API methods
export const authAPI = {
  login(username, password) {
    return api.post('/login', { username, password })
  }
}

export const recordsAPI = {
  createRecord(data) {
    return api.post('/records', data)
  },
  getRecords(date) {
    return api.get('/records', { params: { date } })
  },
  deleteRecord(id) {
    return api.delete('/records', { params: { id } })
  },
  restoreRecord(id) {
    return api.put('/records/restore', null, { params: { id } })
  },
  getSummary() {
    return api.get('/records/summary')
  }
}

export default api

