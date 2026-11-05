<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
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
    const thread = await fetchConsultThread(props.sessionId)
    if (current !== revision) return
    session.value = thread.session
    merge(thread.messages)
    errorMessage.value = ''
  } catch (error) {
    if (current !== revision) return
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    if (current === revision) { loading.value = false; fetching = false }
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
      <button type="button" :disabled="loading" data-testid="consult-refresh" @click="load">{{ copy.refresh }}</button>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}
      <button type="button" :disabled="loading" data-testid="consult-retry" @click="load">{{ copy.retry }}</button>
    </p>
    <p v-if="sendError" class="feedback is-error" role="alert">{{ sendError }}</p>
    <p v-if="loading && !session" class="feedback">{{ copy.loading }}</p>
    <p v-if="session && messages.length === 0" class="feedback">{{ copy.empty }}</p>

    <ul class="chat-messages">
      <li v-for="m in messages" :key="m.id" :class="m.senderType === 1 ? 'mine' : 'theirs'">
        <span class="who">{{ m.senderType === 1 ? copy.you : copy.merchant }}</span>
        <span class="text">{{ m.content }}</span>
      </li>
    </ul>

    <div class="chat-composer">
      <textarea v-model="draft" rows="2" maxlength="2000" :disabled="sending || !session" :placeholder="copy.placeholder" data-testid="consult-input" />
      <button type="button" :disabled="sending || !session" data-testid="consult-send" @click="send">{{ sending ? copy.sending : copy.send }}</button>
    </div>
  </section>
</template>
