<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { ticketStringsForRegion } from '@/core/web_ticket_localizations'
import { createTicket, fetchMyTickets, fetchTicket, replyTicket } from '@/services/ticket'
import type { SupportTicket } from '@/types/ticket'

const route = useRoute()
const { state } = useAppContext()
const copy = computed(() => ticketStringsForRegion(state.region))

const tickets = ref<SupportTicket[]>([])
const selected = ref<SupportTicket | null>(null)
const loading = ref(false)
const errorMessage = ref('')
const subject = ref('')
const content = ref('')
const shopId = ref(route.query.shopId ? String(route.query.shopId) : '')
const reply = ref('')
const submitting = ref(false)

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const page = await fetchMyTickets()
    tickets.value = page.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function open(id: number) {
  errorMessage.value = ''
  try {
    selected.value = await fetchTicket(id)
    reply.value = ''
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

async function submit() {
  submitting.value = true
  errorMessage.value = ''
  try {
    const created = await createTicket({
      subject: subject.value.trim(),
      content: content.value.trim(),
      shopId: shopId.value ? Number(shopId.value) : 0,
    })
    subject.value = ''
    content.value = ''
    await load()
    await open(created.id)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    submitting.value = false
  }
}

async function sendReply() {
  if (!selected.value) return
  submitting.value = true
  errorMessage.value = ''
  try {
    selected.value = await replyTicket(selected.value.id, reply.value.trim())
    reply.value = ''
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    submitting.value = false
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="tickets">
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>

    <form class="ticket-form" @submit.prevent="submit">
      <label class="field">
        <span>{{ copy.subject }}</span>
        <input v-model="subject" required maxlength="128" data-testid="ticket-subject" />
      </label>
      <label class="field">
        <span>{{ copy.content }}</span>
        <textarea v-model="content" required maxlength="2000" rows="4" data-testid="ticket-content" />
      </label>
      <label class="field">
        <span>{{ copy.shopId }}</span>
        <input v-model="shopId" type="number" min="0" data-testid="ticket-shop" />
      </label>
      <button class="primary-button" type="submit" :disabled="submitting" data-testid="ticket-submit">
        {{ submitting ? copy.submitting : copy.submit }}
      </button>
    </form>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="tickets.length === 0" class="feedback">{{ copy.empty }}</p>

    <ul v-else class="ticket-list">
      <li v-for="ticket in tickets" :key="ticket.id">
        <button type="button" class="secondary-button" :data-testid="`ticket-${ticket.id}`" @click="open(ticket.id)">
          {{ ticket.subject }} · {{ copy.status(ticket.status, ticket.statusText) }}
        </button>
      </li>
    </ul>

    <article v-if="selected" class="ticket-detail" :data-testid="`ticket-detail-${selected.id}`">
      <h2>{{ selected.subject }}</h2>
      <p>{{ selected.content }}</p>
      <ul>
        <li v-for="message in selected.messages ?? []" :key="message.id">
          {{ message.content }}
        </li>
      </ul>
      <form v-if="selected.status === 1 || selected.status === 2" @submit.prevent="sendReply">
        <label class="field">
          <span>{{ copy.reply }}</span>
          <textarea v-model="reply" required maxlength="2000" rows="3" data-testid="ticket-reply" />
        </label>
        <button class="primary-button" type="submit" :disabled="submitting">{{ copy.send }}</button>
      </form>
      <p v-else class="feedback">{{ copy.closed }}</p>
    </article>
  </section>
</template>
