<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { fetchConsultMessages, fetchConsultSessions, sendConsultMessage, type ConsultMessage, type ConsultSession, type ConsultSessionQuery } from '@/services/merchant'

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
const activeSession = ref<ConsultSession | null>(null)
const unreadOnly = ref(false)
const pageIndex = ref(0)
const hasMore = ref(false)
let cursors: ConsultSessionQuery[] = [{}]
const messages = ref<ConsultMessage[]>([])
const draft = ref('')
const sending = ref(false)
const threadReady = ref(false)
const hasOlder = ref(false)
const historyLoading = ref(false)
const historyError = ref('')
const messageList = ref<HTMLElement | null>(null)
let nextBeforeId: number | null = null
let nextAfterId = 0
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
  activeSession.value = null
  messages.value = []
  draft.value = ''
  sending.value = false
  threadReady.value = false
  threadError.value = ''
  sendError.value = ''
  hasOlder.value = false
  historyLoading.value = false
  historyError.value = ''
  nextBeforeId = null
  nextAfterId = 0
}

async function loadSessions(index = pageIndex.value) {
  if (listPending) return
  const current = scope
  listPending = true
  loading.value = true
  try {
    const result = await fetchConsultSessions({ ...cursors[index], unreadOnly: unreadOnly.value })
    if (current !== scope) return
    sessions.value = result.list
    pageIndex.value = index
    hasMore.value = result.hasMore
    cursors = cursors.slice(0, index + 1)
    if (result.hasMore && result.nextBeforeId != null && result.nextBeforeUpdatedAt != null) {
      cursors.push({ beforeId: result.nextBeforeId, beforeUpdatedAt: result.nextBeforeUpdatedAt })
    }
    error.value = ''
    // A paged/filtered list cannot prove that the selected thread was deleted or revoked.
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
    for (let batch = 0; batch < 5; batch++) {
      const initial = !threadReady.value
      const thread = initial ? await fetchConsultMessages(id) : await fetchConsultMessages(id, { afterId: nextAfterId })
      if (current !== threadRevision) return
      const list = messageList.value
      const atBottom = !list || list.scrollHeight - list.scrollTop - list.clientHeight < 48
      merge(thread.messages)
      if (initial) {
        hasOlder.value = thread.hasMore ?? false
        nextBeforeId = thread.nextBeforeId ?? thread.messages[0]?.id ?? null
      }
      nextAfterId = thread.nextAfterId ?? thread.messages[thread.messages.length - 1]?.id ?? nextAfterId
      threadReady.value = true
      threadError.value = ''
      activeSession.value = thread.session
      const target = sessions.value.find((item) => item.id === id)
      if (target) target.unread = thread.session.unread
      await nextTick()
      if (current !== threadRevision) return
      if (atBottom && messageList.value) messageList.value.scrollTop = messageList.value.scrollHeight
      if (initial || !thread.hasMore || document.visibilityState === 'hidden') break
    }
  } catch (cause) {
    if (current === threadRevision) threadError.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    if (current === threadRevision) threadPending = false
  }
}

async function loadOlder() {
  if (historyLoading.value || !hasOlder.value || nextBeforeId === null || activeId.value === null) return
  const current = threadRevision
  historyLoading.value = true
  historyError.value = ''
  try {
    const thread = await fetchConsultMessages(activeId.value, { beforeId: nextBeforeId })
    if (current !== threadRevision) return
    const list = messageList.value
    const height = list?.scrollHeight ?? 0
    const top = list?.scrollTop ?? 0
    merge(thread.messages)
    hasOlder.value = thread.hasMore
    nextBeforeId = thread.nextBeforeId
    await nextTick()
    if (current === threadRevision && list) list.scrollTop = top + list.scrollHeight - height
  } catch (cause) {
    if (current === threadRevision) historyError.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    if (current === threadRevision) historyLoading.value = false
  }
}

async function openSession(session: ConsultSession) {
  if (activeId.value !== session.id) {
    clearThread()
    activeId.value = session.id
    activeSession.value = session
  }
  await loadMessages()
}

async function send() {
  if (!canReply.value || activeId.value === null || sending.value || !threadReady.value || threadError.value) return
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
    await nextTick()
    if (current === threadRevision && messageList.value) messageList.value.scrollTop = messageList.value.scrollHeight
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

function resetList() {
  scope++
  listPending = false
  sessions.value = []
  cursors = [{}]
  pageIndex.value = 0
  hasMore.value = false
  error.value = ''
  void loadSessions(0)
}

watch(unreadOnly, resetList)
watch(() => state.region, () => {
  clearThread()
  resetList()
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
      <button type="button" :disabled="loading" @click="loadSessions(0); loadMessages()">{{ strings.common.refresh }}</button>
    </div>
    <label class="unread-filter"><input v-model="unreadOnly" type="checkbox" data-testid="sessions-unread" />{{ copy.unreadOnly }}</label>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading && sessions.length === 0" class="muted">{{ strings.common.loading }}</p>

    <div class="consult-layout">
      <ul class="consult-sessions">
        <li v-if="!loading && !error && sessions.length === 0" class="muted">{{ unreadOnly ? copy.noUnread : copy.sessionsEmpty }}</li>
        <li
          v-for="session in sessions"
          :key="session.id"
          :class="{ active: session.id === activeId }"
        >
          <button type="button" :aria-pressed="session.id === activeId" :data-testid="`session-${session.id}`" @click="openSession(session)">
            <strong>{{ session.userNickname }}</strong>
            <span class="muted">{{ session.shopName }}</span>
            <span class="preview">{{ session.lastMessage }}</span>
            <span v-if="session.unread > 0" class="badge">{{ copy.unreadBadge(session.unread) }}</span>
          </button>
        </li>
        <li class="session-pager">
          <button type="button" :disabled="loading || pageIndex === 0" data-testid="sessions-previous" @click="loadSessions(pageIndex - 1)">{{ copy.previous }}</button>
          <span>{{ pageIndex + 1 }}</span>
          <button type="button" :disabled="loading || !hasMore" data-testid="sessions-next" @click="loadSessions(pageIndex + 1)">{{ copy.next }}</button>
        </li>
      </ul>

      <div class="consult-thread">
        <p v-if="activeId == null" class="muted">{{ copy.selectHint }}</p>
        <template v-else>
          <header v-if="activeSession" class="thread-heading"><strong>{{ activeSession.userNickname }}</strong><span class="muted">{{ activeSession.shopName }}</span></header>
          <p v-if="threadError" class="error" role="alert">{{ threadError }}
            <button type="button" data-testid="consult-retry" @click="loadMessages">{{ strings.common.refresh }}</button>
          </p>
          <p v-if="sendError" class="error" role="alert">{{ sendError }}</p>
          <p v-if="messages.length === 0" class="muted">{{ copy.messagesEmpty }}</p>
          <button v-if="hasOlder" type="button" class="history-button" :disabled="historyLoading" data-testid="consult-load-older" @click="loadOlder">{{ historyLoading ? strings.common.loading : copy.loadOlder }}</button>
          <p v-if="historyError" class="error" role="alert">{{ historyError }}</p>
          <ul ref="messageList" class="messages">
            <li v-for="m in messages" :key="m.id" :class="m.senderType === 2 ? 'mine' : 'theirs'">
              <span class="who">{{ m.senderType === 2 ? copy.you : copy.customer }}</span>
              <span class="text">{{ m.content }}</span>
            </li>
          </ul>
          <div v-if="canReply" class="composer">
            <textarea v-model="draft" rows="2" maxlength="2000" :disabled="sending || !threadReady" :aria-label="copy.inputPlaceholder" :placeholder="copy.inputPlaceholder" data-testid="consult-input" />
            <button type="button" class="primary-action" :disabled="sending || !threadReady || !!threadError" data-testid="consult-send" @click="send">{{ sending ? strings.common.loading : copy.send }}</button>
          </div>
          <p v-else class="muted">{{ copy.readOnly }}</p>
        </template>
      </div>
    </div>
  </section>
</template>

<style scoped>
.unread-filter { display: flex; align-items: center; gap: 8px; margin-bottom: 16px; }
.session-pager { display: flex; align-items: center; gap: 4px; margin-top: 12px; }
.session-pager button { padding: 8px; text-align: center; }
.thread-heading { display: grid; gap: 4px; margin-bottom: 16px; }
.consult-layout { display: grid; grid-template-columns: minmax(180px, 28%) minmax(0, 1fr); border: 1px solid var(--line); border-radius: 18px; overflow: hidden; background: var(--paper); }
.consult-sessions { list-style: none; margin: 0; padding: 12px; border-right: 1px solid var(--line); max-height: 75vh; overflow-y: auto; }
.consult-sessions button { display: grid; gap: 6px; width: 100%; padding: 14px; text-align: left; border: 1px solid transparent; border-radius: 12px; background: transparent; color: var(--ink); cursor: pointer; }
.consult-sessions button:hover, .consult-sessions .active button { background: var(--accent-soft); border-color: var(--line); }
.consult-sessions strong, .preview { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.consult-sessions .muted { font-size: 0.8rem; }
.preview { font-size: 0.875rem; }
.badge { justify-self: start; border-radius: 20px; padding: 3px 8px; background: var(--accent); color: #fff; font-size: 0.75rem; }
.consult-thread { min-width: 0; padding: 20px; }
.history-button { display: block; margin: 0 auto 12px; padding: 8px 14px; border: 1px solid var(--line); border-radius: 11px; color: var(--accent-dark); background: #fff; cursor: pointer; }
.messages { height: 50vh; overflow-y: auto; overflow-anchor: none; list-style: none; margin: 0; padding: 12px; border-radius: 12px; background: #f5f1ea; }
.messages li { width: fit-content; max-width: 85%; margin-bottom: 12px; padding: 10px 14px; border: 1px solid var(--line); border-radius: 14px; background: #fff; }
.messages .mine { margin-left: auto; background: var(--accent-soft); }
.who { display: block; margin-bottom: 4px; font-size: 0.75rem; color: var(--muted); font-weight: 700; }
.text { white-space: pre-wrap; overflow-wrap: anywhere; }
.composer { display: flex; align-items: flex-end; gap: 12px; margin-top: 16px; }
.composer textarea { flex: 1; min-width: 0; resize: vertical; padding: 12px; border: 1px solid var(--line); border-radius: 11px; background: #fff; color: var(--ink); }
.composer textarea:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
@media (max-width: 1000px) {
  .consult-layout { grid-template-columns: 1fr; }
  .consult-sessions { max-height: 180px; border-right: 0; border-bottom: 1px solid var(--line); }
}
@media (max-width: 500px) {
  .consult-thread { padding: 12px; }
  .composer { flex-wrap: wrap; }
  .composer textarea { flex-basis: 100%; }
  .composer button { margin-left: auto; }
}
</style>
