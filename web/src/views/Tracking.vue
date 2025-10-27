<template>
  <div class="tracking-container">
    <header class="header">
      <h1>宝宝日记</h1>
      <button class="logout-btn" @click="handleLogout">退出</button>
    </header>

    <div class="content">
      <div class="date-selector">
        <button @click="changeDate(-1)" class="date-nav-btn">◀</button>
        <input 
          type="date" 
          v-model="selectedDate"
          @change="loadRecords"
          class="date-input"
        />
        <button @click="changeDate(1)" class="date-nav-btn">▶</button>
        <button @click="goToToday" class="today-btn">今天</button>
      </div>

      <QuickEntry @record-created="handleRecordCreated" :current-date="selectedDate" />
      
      <RecordList 
        :records="records" 
        :loading="loading" 
        @refresh="loadRecords" 
        @delete="handleDelete"
        @restore="handleRestore"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { recordsAPI } from '../api'
import QuickEntry from '../components/QuickEntry.vue'
import RecordList from '../components/RecordList.vue'

const router = useRouter()
const authStore = useAuthStore()

const selectedDate = ref(formatDate(new Date()))
const records = ref([])
const loading = ref(false)

function formatDate(date) {
  // 使用本地时区格式化日期，避免UTC时区问题
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function changeDate(days) {
  const current = new Date(selectedDate.value)
  current.setDate(current.getDate() + days)
  selectedDate.value = formatDate(current)
  loadRecords()
}

function goToToday() {
  selectedDate.value = formatDate(new Date())
  loadRecords()
}

async function loadRecords() {
  loading.value = true
  try {
    const response = await recordsAPI.getRecords(selectedDate.value)
    records.value = response.data.records || []
  } catch (err) {
    console.error('Failed to load records:', err)
  } finally {
    loading.value = false
  }
}

function handleRecordCreated() {
  loadRecords()
}

async function handleDelete(recordId) {
  try {
    await recordsAPI.deleteRecord(recordId)
    await loadRecords()
  } catch (err) {
    console.error('Failed to delete record:', err)
    alert('删除失败，请重试')
  }
}

async function handleRestore(recordId) {
  try {
    await recordsAPI.restoreRecord(recordId)
    await loadRecords()
  } catch (err) {
    console.error('Failed to restore record:', err)
    alert('恢复失败，请重试')
  }
}

function handleLogout() {
  authStore.clearAuth()
  router.push('/login')
}

onMounted(() => {
  loadRecords()
})
</script>

<style scoped>
.tracking-container {
  min-height: 100vh;
  padding-bottom: 40px;
}

.header {
  background: rgba(139, 115, 85, 0.95);
  color: white;
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.header h1 {
  margin: 0;
  font-size: 24px;
}

.logout-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid white;
  padding: 8px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
  transition: background 0.3s;
}

.logout-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.content {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.date-selector {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 24px;
  justify-content: center;
}

.date-input {
  padding: 10px 16px;
  border: 2px solid #d4c5b9;
  border-radius: 8px;
  font-size: 16px;
  background: #fefdfb;
  min-width: 150px;
}

.date-nav-btn {
  background: #8b7355;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  transition: background 0.3s;
}

.date-nav-btn:hover {
  background: #6d5940;
}

.today-btn {
  background: #5a8b5a;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  transition: background 0.3s;
}

.today-btn:hover {
  background: #4a7a4a;
}
</style>

