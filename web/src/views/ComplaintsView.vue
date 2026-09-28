<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { complaintStringsForRegion, localizeWebComplaintError } from '@/core/web_complaint_localizations'
import { fetchMyComplaints } from '@/services/complaint'
import type { ComplaintTicket } from '@/types/complaint'

const { state: appState } = useAppContext()
const copy = computed(() => complaintStringsForRegion(appState.region))

const tickets = ref<ComplaintTicket[]>([])
const loading = ref(false)
const errorMessage = ref('')
const statusFilter = ref<number | ''>('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const page = await fetchMyComplaints(statusFilter.value === '' ? undefined : Number(statusFilter.value))
    tickets.value = page.list
  } catch (error) {
    errorMessage.value = localizeWebComplaintError(copy.value, error, copy.value.list.loadFailed)
  } finally {
    loading.value = false
  }
}

watch([() => appState.region, statusFilter], load, { immediate: true })
</script>

<template>
  <section class="complaints">
    <header class="complaints__head">
      <p class="eyebrow">{{ copy.list.eyebrow }}</p>
      <h1>{{ copy.list.title }}</h1>
      <p class="summary">{{ copy.list.summary }}</p>
      <div class="toolbar">
        <select v-model="statusFilter">
          <option value="">{{ copy.list.all }}</option>
          <option :value="1">{{ copy.list.statusText(1) }}</option>
          <option :value="2">{{ copy.list.statusText(2) }}</option>
          <option :value="3">{{ copy.list.statusText(3) }}</option>
          <option :value="4">{{ copy.list.statusText(4) }}</option>
        </select>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.list.loading }}</p>
    <p v-else-if="tickets.length === 0" class="feedback">{{ copy.list.empty }}</p>

    <ul v-else class="ticket-list">
      <li v-for="t in tickets" :key="t.id" class="ticket-card">
        <div class="ticket-card__head">
          <strong>{{ t.title }}</strong>
          <span class="status">{{ copy.list.statusText(t.status, t.statusText) }}</span>
        </div>
        <p class="ticket-card__meta">
          {{ copy.list.typeText(t.type, t.typeText) }} · {{ t.shopName }} · {{ copy.list.submittedAt }} {{ t.createdAt }}
        </p>
        <p class="ticket-card__content">{{ t.content }}</p>
        <p v-if="t.merchantReply" class="ticket-card__reply">
          {{ copy.list.merchantReply }}: {{ t.merchantReply }}
        </p>
        <p v-if="t.resolution" class="ticket-card__resolution">
          {{ copy.list.resolution }}: {{ t.resolution }}
        </p>
        <RouterLink class="ticket-card__link" :to="`/user/complaints/${t.id}`">{{ copy.list.view }}</RouterLink>
      </li>
    </ul>
  </section>
</template>
