<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { fetchConsultMessages, fetchConsultSessions, sendConsultMessage, type ConsultMessage, type ConsultSession } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), { permissions: () => [] })
const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const copy = computed(() => strings.value.consult)
const canReply = computed(() => props.permissions.includes('consult:reply'))
const loading = ref(true)
const error = ref('')
const threadError = ref('')
const sendError = ref('')
const sessions = ref<ConsultSession[]>([])
const activeId = ref<number | null>(null)
const messages = ref<ConsultMessage[]>([])
const draft = ref('')
const sending = ref(false)
const threadReady = ref(false)
let scope = 0
let threadRevision = 0
let listPending = false
let threadPending = false
let timer: number | undefined

function merge(incoming: ConsultMessage[]) {
  const byId = new Map(messages.value.map((message) => [message.id, message]))
  incoming.forEach((message) => byId.set(message.id, message))
  messages.value = [...byId.values()].sort((a, b) => a.id - b.id)
}

function clearThread() {
  threadRevision++
  threadPending = false
  activeId.value = null
  messages.value = []
  draft.value = ''
  sending.value = false
  threadReady.value = false
  threadError.value = ''
  sendError.value = ''
}

async function loadSessions() {
  if (listPending) return
  const current = scope
  listPending = true
  loading.value = true
  try {
    const result = await fetchConsultSessions()
    if (current !== scope) return
    sessions.value = result
    error.value = ''
    if (activeId.value !== null && !result.some((item) => item.id === activeId.value)) clearThread()
  } catch (cause) {
    if (current === scope) error.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    if (current === scope) { loading.value = false; listPending = false }
  }
}

async function loadMessages() {
  if (threadPending || activeId.value === null) return
  const current = threadRevision
  const id = activeId.value
  threadPending = true
  try {
    const thread = await fetchConsultMessages(id)
    if (current !== threadRevision) return
    merge(thread.messages)
    threadReady.value = true
    threadError.value = ''
    const target = sessions.value.find((item) => item.id === id)
    if (target) target.unread = 0
  } catch (cause) {
    if (current === threadRevision) threadError.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    if (current === threadRevision) threadPending = false
  }
}

async function openSession(session: ConsultSession) {
  if (activeId.value !== session.id) {
    clearThread()
    activeId.value = session.id
  }
  await loadMessages()
}

async function send() {
  if (!canReply.value || activeId.value === null || sending.value || !threadReady.value) return
  const content = draft.value.trim()
  if (!content) { sendError.value = copy.value.sendRequired; return }
  const current = threadRevision
  const id = activeId.value
  sending.value = true
  sendError.value = ''
  try {
    const message = await sendConsultMessage(id, content)
    if (current !== threadRevision) return
    merge([message])
    draft.value = ''
  } catch (cause) {
    if (current === threadRevision) sendError.value = cause instanceof Error ? cause.message : copy.value.sendError
  } finally {
    if (current === threadRevision) sending.value = false
  }
}

function poll() {
  if (document.visibilityState === 'hidden') return
  void loadSessions()
  void loadMessages()
}

watch(() => state.region, () => {
  scope++
  listPending = false
  sessions.value = []
  error.value = ''
  clearThread()
  void loadSessions()
}, { immediate: true })

onMounted(() => {
  timer = window.setInterval(poll, 3000)
  document.addEventListener('visibilitychange', poll)
  window.addEventListener('online', poll)
})
onUnmounted(() => {
  scope++
  threadRevision++
  window.clearInterval(timer)
  document.removeEventListener('visibilitychange', poll)
  window.removeEventListener('online', poll)
})
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">{{ copy.summary }}</span>
      <button type="button" :disabled="loading" @click="poll">{{ strings.common.refresh }}</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading && sessions.length === 0" class="muted">{{ strings.common.loading }}</p>

    <div v-else class="consult-layout">
      <ul class="consult-sessions">
        <li v-if="sessions.length === 0" class="muted">{{ copy.sessionsEmpty }}</li>
        <li
          v-for="session in sessions"
          :key="session.id"
          :class="{ active: session.id === activeId }"
        >
          <button type="button" :data-testid="`session-${session.id}`" @click="openSession(session)">
            <strong>{{ session.userNickname }}</strong>
            <span class="muted">{{ session.shopName }}</span>
            <span class="preview">{{ session.lastMessage }}</span>
            <span v-if="session.unread > 0" class="badge">{{ copy.unreadBadge(session.unread) }}</span>
          </button>
        </li>
      </ul>

      <div class="consult-thread">
        <p v-if="activeId == null" class="muted">{{ copy.selectHint }}</p>
        <template v-else>
          <p v-if="threadError" class="error" role="alert">{{ threadError }}
            <button type="button" data-testid="consult-retry" @click="loadMessages">{{ strings.common.refresh }}</button>
          </p>
          <p v-if="sendError" class="error" role="alert">{{ sendError }}</p>
          <p v-if="messages.length === 0" class="muted">{{ copy.messagesEmpty }}</p>
          <ul class="messages">
            <li v-for="m in messages" :key="m.id" :class="m.senderType === 2 ? 'mine' : 'theirs'">
              <span class="who">{{ m.senderType === 2 ? copy.you : copy.customer }}</span>
              <span class="text">{{ m.content }}</span>
            </li>
          </ul>
          <div v-if="canReply" class="composer">
            <textarea v-model="draft" rows="2" maxlength="2000" :disabled="sending || !threadReady" :placeholder="copy.inputPlaceholder" data-testid="consult-input" />
            <button type="button" :disabled="sending || !threadReady" data-testid="consult-send" @click="send">{{ sending ? strings.common.loading : copy.send }}</button>
          </div>
          <p v-else class="muted">{{ copy.readOnly }}</p>
        </template>
      </div>
    </div>
  </section>
</template>
