<template>
  <div class="record-list">
    <h2>今日记录</h2>
    
    <div v-if="loading" class="loading">
      加载中...
    </div>
    
    <div v-else-if="records.length === 0" class="empty">
      暂无记录
    </div>
    
    <div v-else class="records">
      <div 
        v-for="record in records" 
        :key="record.id" 
        class="record-item"
        :class="{ 'deleted': record.is_deleted }"
      >
        <div class="record-content">
          <div class="record-header">
            <span class="record-type" :class="record.record_type">
              {{ getRecordTypeLabel(record.record_type) }}
            </span>
            <span class="record-time">{{ formatTime(record.record_time) }}</span>
          </div>
          <div class="record-details">
            {{ formatDetails(record) }}
          </div>
          <div v-if="record.notes" class="record-notes">
            备注: {{ record.notes }}
          </div>
        </div>
        <div class="record-actions">
          <button 
            v-if="!record.is_deleted"
            @click="handleDelete(record.id)"
            class="action-btn delete-btn"
            :disabled="actionLoading === record.id"
          >
            {{ actionLoading === record.id ? '处理中...' : '删除' }}
          </button>
          <button 
            v-else
            @click="handleRestore(record.id)"
            class="action-btn restore-btn"
            :disabled="actionLoading === record.id"
          >
            {{ actionLoading === record.id ? '处理中...' : '恢复' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { defineProps, defineEmits, ref } from 'vue'

defineProps({
  records: Array,
  loading: Boolean
})

const emit = defineEmits(['delete', 'restore'])

const actionLoading = ref(null)

async function handleDelete(id) {
  actionLoading.value = id
  try {
    await emit('delete', id)
  } finally {
    actionLoading.value = null
  }
}

async function handleRestore(id) {
  actionLoading.value = id
  try {
    await emit('restore', id)
  } finally {
    actionLoading.value = null
  }
}

function getRecordTypeLabel(type) {
  const labels = {
    feeding: '喂养',
    diaper: '尿布',
    other: '其他'
  }
  return labels[type] || type
}

function formatTime(timeString) {
  const date = new Date(timeString)
  return date.toLocaleTimeString('zh-CN', { 
    hour: '2-digit', 
    minute: '2-digit',
    hour12: false 
  })
}

function formatDetails(record) {
  try {
    const details = JSON.parse(record.details)
    
    if (record.record_type === 'feeding') {
      const method = {
        breast_left: '母乳-左',
        breast_right: '母乳-右',
        bottle: '奶瓶'
      }[details.method]
      
      // 计时器模式
      if (details.start_time && details.end_time) {
        const startTime = new Date(details.start_time)
        const endTime = new Date(details.end_time)
        const startStr = startTime.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', hour12: false })
        const endStr = endTime.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', hour12: false })
        
        let result = `${method} ${startStr} - ${endStr} (${details.duration_minutes}分钟)`
        if (details.target_minutes) {
          result += ` 目标${details.target_minutes}分`
        }
        return result
      }
      // 普通模式
      else if (details.duration_minutes) {
        return `${method} ${details.duration_minutes}分钟`
      } else if (details.amount_ml) {
        return `${method} ${details.amount_ml}ml`
      }
      return method
    }
    
    if (record.record_type === 'diaper') {
      const parts = []
      if (details.has_urine) {
        parts.push(`尿尿(${details.urine_amount})`)
      }
      if (details.has_stool) {
        parts.push(`粑粑(${details.stool_amount})`)
      }
      return parts.join(' + ')
    }
    
    return JSON.stringify(details)
  } catch (err) {
    return record.details
  }
}
</script>

<style scoped>
.record-list {
  background: rgba(255, 255, 255, 0.95);
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

h2 {
  margin: 0 0 20px 0;
  color: #5a4a3a;
  font-size: 22px;
}

.loading,
.empty {
  text-align: center;
  padding: 40px 20px;
  color: #8b7355;
  font-size: 18px;
}

.records {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.record-item {
  background: #fefdfb;
  border: 2px solid #e8dfd5;
  border-radius: 8px;
  padding: 16px;
  transition: all 0.3s;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.record-item:hover {
  border-color: #d4c5b9;
}

/* 已删除记录的样式 */
.record-item.deleted {
  background: #f5f5f5;
  border-color: #d0d0d0;
  opacity: 0.7;
}

.record-item.deleted .record-content {
  position: relative;
}

.record-item.deleted .record-content::after {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  width: 100%;
  height: 1.5px;
  background: #999;
  transform: translateY(-50%);
  pointer-events: none;
}

.record-item.deleted .record-time,
.record-item.deleted .record-details,
.record-item.deleted .record-notes {
  color: #999 !important;
}

/* 已删除记录的类型标签保持原有颜色，只降低不透明度 */
.record-item.deleted .record-type {
  opacity: 0.6;
}

.record-content {
  flex: 1;
  min-width: 0;
}

.record-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.record-type {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  transition: background 0.3s;
}

.record-type.feeding {
  background: #7ba3d4;
}

.record-type.diaper {
  background: #d4a57b;
}

.record-type.other {
  background: #8b8b8b;
}

.record-time {
  color: #8b7355;
  font-size: 16px;
  font-weight: 500;
}

.record-details {
  color: #5a4a3a;
  font-size: 18px;
  margin-bottom: 6px;
}

.record-notes {
  color: #8b7355;
  font-size: 15px;
  font-style: italic;
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #e8dfd5;
}

.record-actions {
  flex-shrink: 0;
}

.action-btn {
  padding: 6px 16px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
}

.action-btn:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.delete-btn {
  background: #ff6b6b;
  color: white;
}

.delete-btn:hover:not(:disabled) {
  background: #ff5252;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(255, 107, 107, 0.3);
}

.restore-btn {
  background: #51cf66;
  color: white;
}

.restore-btn:hover:not(:disabled) {
  background: #40c057;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(81, 207, 102, 0.3);
}
</style>

