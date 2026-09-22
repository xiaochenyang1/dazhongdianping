<script setup lang="ts">
import { computed, ref, watch } from 'vue'
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
const sending = ref(false)

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const thread = await fetchConsultThread(props.sessionId)
    session.value = thread.session
    messages.value = thread.messages
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function send() {
  const content = draft.value.trim()
  if (!content || sending.value) return
  sending.value = true
  errorMessage.value = ''
  try {
    const message = await sendConsultMessage(props.sessionId, content)
    messages.value = [...messages.value, message]
    draft.value = ''
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.sendFailed
  } finally {
    sending.value = false
  }
}

watch([() => appState.region, () => props.sessionId], load, { immediate: true })
</script>

<template>
  <section class="consult-chat">
    <header class="consult-chat__head">
      <RouterLink to="/user/consult" class="secondary-button">{{ copy.back }}</RouterLink>
      <h1 v-if="session">{{ session.shopName }}</h1>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.empty }}</p>
    <p v-else-if="messages.length === 0" class="feedback">{{ copy.empty }}</p>

    <ul class="chat-messages">
      <li v-for="m in messages" :key="m.id" :class="m.senderType === 1 ? 'mine' : 'theirs'">
        <span class="who">{{ m.senderType === 1 ? copy.you : copy.merchant }}</span>
        <span class="text">{{ m.content }}</span>
      </li>
    </ul>

    <div class="chat-composer">
      <textarea v-model="draft" rows="2" :placeholder="copy.placeholder" data-testid="consult-input" />
      <button type="button" :disabled="sending" data-testid="consult-send" @click="send">{{ copy.send }}</button>
    </div>
  </section>
</template>
