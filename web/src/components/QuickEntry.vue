<template>
  <div class="quick-entry">
    <h2>快速记录</h2>
    
    <div class="entry-section">
      <h3>喂养</h3>
      <div class="button-group">
        <button @click="openFeedingModal('breast_left')" class="action-btn feeding">
          母乳-左
        </button>
        <button @click="openFeedingModal('breast_right')" class="action-btn feeding">
          母乳-右
        </button>
        <button @click="openFeedingModal('bottle')" class="action-btn feeding">
          奶瓶
        </button>
      </div>
    </div>

    <div class="entry-section">
      <h3>尿布</h3>
      <div class="button-group">
        <button @click="openDiaperModal('urine')" class="action-btn diaper">
          尿尿
        </button>
        <button @click="openDiaperModal('stool')" class="action-btn diaper">
          粑粑
        </button>
        <button @click="openDiaperModal('both')" class="action-btn diaper">
          都有
        </button>
      </div>
    </div>

    <!-- Feeding Modal -->
    <div v-if="showFeedingModal" class="modal-overlay" @click="closeFeedingModal">
      <div class="modal-content" @click.stop>
        <h3>{{ getFeedingTypeLabel() }}</h3>
        
        <!-- 计时器模式（母乳） -->
        <div v-if="feedingData.isTimerMode">
          <div class="timer-display">
            <div class="timer-time">{{ formatTime(feedingData.timerSeconds) }}</div>
            <div v-if="feedingData.targetSeconds > 0" class="timer-target">
              目标: {{ formatTime(feedingData.targetSeconds) }}
            </div>
          </div>
          
          <div v-if="!feedingData.isTimerRunning" class="timer-controls">
            <button @click="startTimer" class="start-btn">开始计时</button>
          </div>
          
          <div v-else class="timer-controls">
            <div class="quick-time-buttons">
              <button @click="addTargetTime(1)" class="time-btn">+1分钟</button>
              <button @click="addTargetTime(5)" class="time-btn">+5分钟</button>
              <button @click="addTargetTime(10)" class="time-btn">+10分钟</button>
            </div>
          </div>
          
          <div class="form-group">
            <label>备注</label>
            <textarea v-model="feedingData.notes" rows="2"></textarea>
          </div>
          
          <div class="modal-actions">
            <button @click="closeFeedingModal" class="cancel-btn">取消</button>
            <button 
              @click="submitFeeding" 
              class="submit-btn"
              :disabled="!feedingData.isTimerRunning && feedingData.timerSeconds === 0">
              结束并保存
            </button>
          </div>
        </div>
        
        <!-- 普通模式（奶瓶） -->
        <div v-else>
          <div class="form-group">
            <label>奶量（ml）</label>
            <input type="number" v-model="feedingData.amount" min="1" />
          </div>
          <div class="form-group">
            <label>备注</label>
            <textarea v-model="feedingData.notes" rows="2"></textarea>
          </div>
          <div class="modal-actions">
            <button @click="closeFeedingModal" class="cancel-btn">取消</button>
            <button @click="submitFeeding" class="submit-btn">保存</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Diaper Modal -->
    <div v-if="showDiaperModal" class="modal-overlay" @click="closeDiaperModal">
      <div class="modal-content" @click.stop>
        <h3>记录尿布</h3>
        <div v-if="diaperData.hasUrine" class="form-group">
          <label>尿量</label>
          <select v-model="diaperData.urineAmount">
            <option value="少量">少量</option>
            <option value="普通">普通</option>
            <option value="大量">大量</option>
          </select>
        </div>
        <div v-if="diaperData.hasStool" class="form-group">
          <label>便量</label>
          <select v-model="diaperData.stoolAmount">
            <option value="少量">少量</option>
            <option value="普通">普通</option>
            <option value="大量">大量</option>
          </select>
        </div>
        <div class="form-group">
          <label>备注</label>
          <textarea v-model="diaperData.notes" rows="2"></textarea>
        </div>
        <div class="modal-actions">
          <button @click="closeDiaperModal" class="cancel-btn">取消</button>
          <button @click="submitDiaper" class="submit-btn">保存</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineEmits, defineProps, onUnmounted } from 'vue'
import { recordsAPI } from '../api'

const props = defineProps({
  currentDate: String
})

const emit = defineEmits(['record-created'])

const showFeedingModal = ref(false)
const showDiaperModal = ref(false)
let timerInterval = null
let audioContext = null

const feedingData = ref({
  method: '',
  duration: 10,
  amount: 30,
  notes: '',
  isTimerMode: false,
  timerSeconds: 0,
  targetSeconds: 0,
  startTime: null,
  isTimerRunning: false
})

const diaperData = ref({
  hasUrine: false,
  urineAmount: '普通',
  hasStool: false,
  stoolAmount: '普通',
  notes: ''
})

function openFeedingModal(method) {
  feedingData.value = {
    method,
    duration: 10,
    amount: 30,
    notes: '',
    isTimerMode: method !== 'bottle', // 母乳使用计时器模式
    timerSeconds: 0,
    targetSeconds: 0,
    startTime: null,
    isTimerRunning: false
  }
  showFeedingModal.value = true
}

function closeFeedingModal() {
  stopTimer()
  showFeedingModal.value = false
}

function formatTime(seconds) {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

function startTimer() {
  if (feedingData.value.isTimerRunning) return
  
  feedingData.value.isTimerRunning = true
  feedingData.value.startTime = new Date()
  
  timerInterval = setInterval(() => {
    feedingData.value.timerSeconds++
    
    // 检查是否达到目标时间
    if (feedingData.value.targetSeconds > 0 && 
        feedingData.value.timerSeconds === feedingData.value.targetSeconds) {
      playNotificationSound()
    }
  }, 1000)
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
  feedingData.value.isTimerRunning = false
}

function addTargetTime(minutes) {
  feedingData.value.targetSeconds += minutes * 60
}

function playNotificationSound() {
  // 创建简单的提示音
  try {
    if (!audioContext) {
      audioContext = new (window.AudioContext || window.webkitAudioContext)()
    }
    
    const oscillator = audioContext.createOscillator()
    const gainNode = audioContext.createGain()
    
    oscillator.connect(gainNode)
    gainNode.connect(audioContext.destination)
    
    oscillator.frequency.value = 800
    oscillator.type = 'sine'
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime)
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5)
    
    oscillator.start(audioContext.currentTime)
    oscillator.stop(audioContext.currentTime + 0.5)
    
    // 播放两次提示音
    setTimeout(() => {
      const osc2 = audioContext.createOscillator()
      const gain2 = audioContext.createGain()
      osc2.connect(gain2)
      gain2.connect(audioContext.destination)
      osc2.frequency.value = 800
      osc2.type = 'sine'
      gain2.gain.setValueAtTime(0.3, audioContext.currentTime)
      gain2.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5)
      osc2.start(audioContext.currentTime)
      osc2.stop(audioContext.currentTime + 0.5)
    }, 600)
  } catch (e) {
    console.warn('Audio notification not supported:', e)
  }
}

onUnmounted(() => {
  stopTimer()
})

function openDiaperModal(type) {
  diaperData.value = {
    hasUrine: type === 'urine' || type === 'both',
    urineAmount: '普通',
    hasStool: type === 'stool' || type === 'both',
    stoolAmount: '普通',
    notes: ''
  }
  showDiaperModal.value = true
}

function closeDiaperModal() {
  showDiaperModal.value = false
}

function getFeedingTypeLabel() {
  const labels = {
    breast_left: '母乳-左',
    breast_right: '母乳-右',
    bottle: '奶瓶'
  }
  return labels[feedingData.value.method]
}

async function submitFeeding() {
  try {
    let details
    let recordTime
    
    if (feedingData.value.isTimerMode && feedingData.value.startTime) {
      // 计时器模式：记录开始和结束时间
      const endTime = new Date()
      const durationMinutes = Math.round(feedingData.value.timerSeconds / 60)
      
      details = {
        method: feedingData.value.method,
        start_time: feedingData.value.startTime.toISOString(),
        end_time: endTime.toISOString(),
        duration_minutes: durationMinutes,
        target_minutes: feedingData.value.targetSeconds > 0 ? Math.round(feedingData.value.targetSeconds / 60) : null
      }
      recordTime = feedingData.value.startTime.toISOString()
    } else {
      // 普通模式
      details = {
        method: feedingData.value.method,
        duration_minutes: feedingData.value.method !== 'bottle' ? parseInt(feedingData.value.duration) : null,
        amount_ml: feedingData.value.method === 'bottle' ? parseInt(feedingData.value.amount) : null
      }
      recordTime = new Date().toISOString()
    }

    await recordsAPI.createRecord({
      record_type: 'feeding',
      record_time: recordTime,
      details: JSON.stringify(details),
      notes: feedingData.value.notes
    })

    closeFeedingModal()
    emit('record-created')
  } catch (err) {
    console.error('Failed to create feeding record:', err)
    alert('保存失败，请重试')
  }
}

async function submitDiaper() {
  try {
    const details = {
      has_urine: diaperData.value.hasUrine,
      urine_amount: diaperData.value.hasUrine ? diaperData.value.urineAmount : null,
      has_stool: diaperData.value.hasStool,
      stool_amount: diaperData.value.hasStool ? diaperData.value.stoolAmount : null
    }

    await recordsAPI.createRecord({
      record_type: 'diaper',
      record_time: new Date().toISOString(),
      details: JSON.stringify(details),
      notes: diaperData.value.notes
    })

    closeDiaperModal()
    emit('record-created')
  } catch (err) {
    console.error('Failed to create diaper record:', err)
    alert('保存失败，请重试')
  }
}
</script>

<style scoped>
.quick-entry {
  background: rgba(255, 255, 255, 0.95);
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  margin-bottom: 24px;
}

h2 {
  margin: 0 0 20px 0;
  color: #5a4a3a;
  font-size: 22px;
}

.entry-section {
  margin-bottom: 20px;
}

.entry-section:last-child {
  margin-bottom: 0;
}

h3 {
  margin: 0 0 12px 0;
  color: #6d5940;
  font-size: 18px;
}

.button-group {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.action-btn {
  flex: 1;
  min-width: 100px;
  padding: 14px 20px;
  border: none;
  border-radius: 8px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  color: white;
}

.action-btn.feeding {
  background: #7ba3d4;
}

.action-btn.feeding:hover {
  background: #5a8bc4;
}

.action-btn.diaper {
  background: #d4a57b;
}

.action-btn.diaper:hover {
  background: #c4905a;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: white;
  padding: 30px;
  border-radius: 12px;
  width: 100%;
  max-width: 400px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-content h3 {
  margin: 0 0 20px 0;
  color: #5a4a3a;
  font-size: 20px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  color: #5a4a3a;
  font-weight: 500;
  font-size: 16px;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 10px 12px;
  border: 2px solid #d4c5b9;
  border-radius: 6px;
  font-size: 16px;
  background: #fefdfb;
  box-sizing: border-box;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #8b7355;
}

.modal-actions {
  display: flex;
  gap: 12px;
  margin-top: 24px;
}

.cancel-btn,
.submit-btn {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;
}

.cancel-btn {
  background: #d4c5b9;
  color: #5a4a3a;
}

.cancel-btn:hover {
  background: #c4b5a9;
}

.submit-btn {
  background: #8b7355;
  color: white;
}

.submit-btn:hover {
  background: #6d5940;
}

.submit-btn:disabled {
  background: #b4a494;
  cursor: not-allowed;
}

/* Timer Styles */
.timer-display {
  text-align: center;
  padding: 30px 20px;
  background: #fefdfb;
  border-radius: 8px;
  margin-bottom: 20px;
  border: 2px solid #d4c5b9;
}

.timer-time {
  font-size: 48px;
  font-weight: 600;
  color: #5a4a3a;
  font-family: 'Courier New', monospace;
  letter-spacing: 4px;
}

.timer-target {
  margin-top: 8px;
  font-size: 16px;
  color: #8b7355;
}

.timer-controls {
  margin-bottom: 20px;
}

.start-btn {
  width: 100%;
  padding: 16px;
  background: #5a8b5a;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;
}

.start-btn:hover {
  background: #4a7a4a;
}

.quick-time-buttons {
  display: flex;
  gap: 8px;
}

.time-btn {
  flex: 1;
  padding: 12px;
  background: #7ba3d4;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;
}

.time-btn:hover {
  background: #5a8bc4;
}
</style>

