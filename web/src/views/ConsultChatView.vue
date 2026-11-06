<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { consultStringsForRegion } from '@/core/web_consult_localizations'
import { fetchConsultThread, sendConsultMessage } from '@/services/consult'
import type { ConsultMessage, ConsultSession } from '@/types/consult'

const props = defineProps<{ sessionId: number }>()

const { state: appState } = useAppContext()
const copy = computed(() => consultStringsForRegion(appState.region).chat)

const session = ref<ConsultSession | null>(null)
const messages = ref<ConsultMessage[]>([])
const draft = ref('')
const loading = ref(false)
const errorMessage = ref('')
const sendError = ref('')
const sending = ref(false)
const hasOlder = ref(false)
const historyLoading = ref(false)
const historyError = ref('')
const messageList = ref<HTMLElement | null>(null)
let nextBeforeId: number | null = null
let nextAfterId = 0
let revision = 0
let fetching = false
let timer: number | undefined

function merge(incoming: ConsultMessage[]) {
  const byId = new Map(messages.value.map((message) => [message.id, message]))
  incoming.forEach((message) => byId.set(message.id, message))
  messages.value = [...byId.values()].sort((a, b) => a.id - b.id)
}

async function load() {
  if (fetching) return
  const current = revision
  fetching = true
  loading.value = true
  try {
    // Keep the server read cursor separate from locally sent messages. Advancing it on send
    // could skip a merchant reply committed between the last poll and that send.
    for (let batch = 0; batch < 5; batch++) {
      const initial = session.value === null
      const thread = initial
        ? await fetchConsultThread(props.sessionId)
        : await fetchConsultThread(props.sessionId, { afterId: nextAfterId })
      if (current !== revision) return
      const list = messageList.value
      const atBottom = !list || list.scrollHeight - list.scrollTop - list.clientHeight < 48
      session.value = thread.session
      merge(thread.messages)
      if (initial) {
        hasOlder.value = thread.hasMore ?? false
        nextBeforeId = thread.nextBeforeId ?? thread.messages[0]?.id ?? null
      }
      nextAfterId = thread.nextAfterId ?? thread.messages[thread.messages.length - 1]?.id ?? nextAfterId
      errorMessage.value = ''
      await nextTick()
      if (current !== revision) return
      if (atBottom && messageList.value) messageList.value.scrollTop = messageList.value.scrollHeight
      if (initial || !thread.hasMore || document.visibilityState === 'hidden') break
    }
  } catch (error) {
    if (current !== revision) return
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    if (current === revision) { loading.value = false; fetching = false }
  }
}

async function loadOlder() {
  if (historyLoading.value || !hasOlder.value || nextBeforeId === null) return
  const current = revision
  historyLoading.value = true
  historyError.value = ''
  try {
    const thread = await fetchConsultThread(props.sessionId, { beforeId: nextBeforeId })
    if (current !== revision) return
    const list = messageList.value
    const height = list?.scrollHeight ?? 0
    const top = list?.scrollTop ?? 0
    merge(thread.messages)
    hasOlder.value = thread.hasMore
    nextBeforeId = thread.nextBeforeId
    await nextTick()
    if (current === revision && list) list.scrollTop = top + list.scrollHeight - height
  } catch (error) {
    if (current === revision) historyError.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    if (current === revision) historyLoading.value = false
  }
}

async function send() {
  const content = draft.value.trim()
  if (!content || sending.value || !session.value) return
  const current = revision
  const sessionId = props.sessionId
  sending.value = true
  sendError.value = ''
  try {
    const message = await sendConsultMessage(sessionId, content)
    if (current !== revision) return
    merge([message])
    draft.value = ''
    await nextTick()
    if (current === revision && messageList.value) messageList.value.scrollTop = messageList.value.scrollHeight
  } catch (error) {
    if (current !== revision) return
    sendError.value = error instanceof Error ? error.message : copy.value.sendFailed
  } finally {
    if (current === revision) sending.value = false
  }
}

function poll() {
  if (document.visibilityState !== 'hidden') void load()
}

watch([() => appState.region, () => props.sessionId], () => {
  revision++
  fetching = false
  sending.value = false
  session.value = null
  messages.value = []
  draft.value = ''
  hasOlder.value = false
  historyLoading.value = false
  historyError.value = ''
  nextBeforeId = null
  nextAfterId = 0
  errorMessage.value = ''
  sendError.value = ''
  void load()
}, { immediate: true })

onMounted(() => {
  timer = window.setInterval(poll, 3000)
  document.addEventListener('visibilitychange', poll)
  window.addEventListener('online', poll)
})
onUnmounted(() => {
  revision++
  window.clearInterval(timer)
  document.removeEventListener('visibilitychange', poll)
  window.removeEventListener('online', poll)
})
</script>

<template>
  <section class="consult-chat">
    <header class="consult-chat__head">
      <RouterLink to="/user/consult" class="secondary-button">{{ copy.back }}</RouterLink>
      <h1 v-if="session">{{ session.shopName }}</h1>
      <button type="button" class="secondary-button" :disabled="loading" data-testid="consult-refresh" @click="load">{{ copy.refresh }}</button>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}
      <button type="button" :disabled="loading" data-testid="consult-retry" @click="load">{{ copy.retry }}</button>
    </p>
    <p v-if="sendError" class="feedback is-error" role="alert">{{ sendError }}</p>
    <p v-if="loading && !session" class="feedback">{{ copy.loading }}</p>
    <p v-if="session && messages.length === 0" class="feedback">{{ copy.empty }}</p>

    <button v-if="hasOlder" type="button" class="secondary-button history-button" :disabled="historyLoading" data-testid="consult-load-older" @click="loadOlder">{{ historyLoading ? copy.loading : copy.loadOlder }}</button>
    <p v-if="historyError" class="feedback is-error" role="alert">{{ historyError }}</p>
    <ul ref="messageList" class="chat-messages">
      <li v-for="m in messages" :key="m.id" :class="m.senderType === 1 ? 'mine' : 'theirs'">
        <span class="who">{{ m.senderType === 1 ? copy.you : copy.merchant }}</span>
        <span class="text">{{ m.content }}</span>
      </li>
    </ul>

    <div class="chat-composer">
      <textarea v-model="draft" rows="2" maxlength="2000" :disabled="sending || !session" :aria-label="copy.placeholder" :placeholder="copy.placeholder" data-testid="consult-input" />
      <button type="button" class="primary-button" :disabled="sending || !session" data-testid="consult-send" @click="send">{{ sending ? copy.sending : copy.send }}</button>
    </div>
  </section>
</template>

<style scoped>
.consult-chat {
  max-width: 900px;
  margin: 0 auto;
  padding: 24px;
  border: 1px solid var(--line);
  border-radius: 24px;
  background: var(--surface-strong);
}
.consult-chat__head { display: flex; align-items: center; flex-wrap: wrap; gap: 16px; margin-bottom: 20px; }
.consult-chat__head h1 { flex: 1; margin: 0; font-size: 1.4rem; }
.history-button { display: block; margin: 0 auto 12px; }
.chat-messages {
  height: 50vh;
  overflow-y: auto;
  overflow-anchor: none;
  list-style: none;
  margin: 0;
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: var(--surface-panel);
}
.chat-messages li { width: fit-content; max-width: 85%; margin-bottom: 12px; padding: 10px 14px; border-radius: 14px; background: #fff; border: 1px solid var(--line); }
.chat-messages .mine { margin-left: auto; background: #fce8d8; }
.who { display: block; margin-bottom: 4px; color: var(--text-soft); font-size: 0.75rem; font-weight: 700; }
.text { white-space: pre-wrap; overflow-wrap: anywhere; }
.chat-composer { display: flex; align-items: flex-end; gap: 12px; margin-top: 16px; }
.chat-composer textarea { flex: 1; min-width: 0; resize: vertical; padding: 12px; border: 1px solid var(--line-strong); border-radius: 12px; background: #fff; color: var(--text); }
.chat-composer textarea:focus-visible { outline: 2px solid var(--brand); outline-offset: 2px; }
@media (max-width: 600px) {
  .consult-chat { padding: 16px; }
  .consult-chat__head h1 { flex-basis: 100%; order: -1; }
  .chat-messages { padding: 10px; }
  .chat-composer { flex-wrap: wrap; }
  .chat-composer textarea { flex-basis: 100%; }
  .chat-composer button { margin-left: auto; }
}
</style>
