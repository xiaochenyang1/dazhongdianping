<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  fetchConsultMessages,
  fetchConsultSessions,
  sendConsultMessage,
  type ConsultMessage,
  type ConsultSession,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const copy = computed(() => strings.value.consult)
const canReply = computed(() => props.permissions.includes('consult:reply'))

const loading = ref(true)
const error = ref('')
const sessions = ref<ConsultSession[]>([])
const activeId = ref<number | null>(null)
const messages = ref<ConsultMessage[]>([])
const draft = ref('')

async function loadSessions() {
  loading.value = true
  error.value = ''
  try {
    sessions.value = await fetchConsultSessions()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    loading.value = false
  }
}

async function openSession(session: ConsultSession) {
  activeId.value = session.id
  error.value = ''
  try {
    const thread = await fetchConsultMessages(session.id)
    messages.value = thread.messages
    // 打开后未读清零，刷新列表徽标。
    const target = sessions.value.find((s) => s.id === session.id)
    if (target) target.unread = 0
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.loadError
  }
}

async function send() {
  if (!canReply.value || activeId.value == null) return
  const content = draft.value.trim()
  if (!content) {
    error.value = copy.value.sendRequired
    return
  }
  error.value = ''
  try {
    const message = await sendConsultMessage(activeId.value, content)
    messages.value = [...messages.value, message]
    draft.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.sendError
  }
}

onMounted(loadSessions)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">{{ copy.summary }}</span>
      <button type="button" @click="loadSessions">{{ strings.common.refresh }}</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>

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
          <p v-if="messages.length === 0" class="muted">{{ copy.messagesEmpty }}</p>
          <ul class="messages">
            <li v-for="m in messages" :key="m.id" :class="m.senderType === 2 ? 'mine' : 'theirs'">
              <span class="who">{{ m.senderType === 2 ? copy.you : copy.customer }}</span>
              <span class="text">{{ m.content }}</span>
            </li>
          </ul>
          <div v-if="canReply" class="composer">
            <textarea v-model="draft" rows="2" :placeholder="copy.inputPlaceholder" data-testid="consult-input" />
            <button type="button" data-testid="consult-send" @click="send">{{ copy.send }}</button>
          </div>
          <p v-else class="muted">{{ copy.readOnly }}</p>
        </template>
      </div>
    </div>
  </section>
</template>
