<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { complaintStringsForRegion, localizeWebComplaintError } from '@/core/web_complaint_localizations'
import { fetchComplaint } from '@/services/complaint'
import type { ComplaintTicket } from '@/types/complaint'

const props = defineProps<{ complaintId: number }>()

const { state: appState } = useAppContext()
const copy = computed(() => complaintStringsForRegion(appState.region))

const ticket = ref<ComplaintTicket | null>(null)
const loading = ref(false)
const errorMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    ticket.value = await fetchComplaint(props.complaintId)
  } catch (error) {
    errorMessage.value = localizeWebComplaintError(copy.value, error, copy.value.list.loadFailed)
  } finally {
    loading.value = false
  }
}

watch([() => appState.region, () => props.complaintId], load, { immediate: true })
</script>

<template>
  <section class="complaint-detail">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.list.loading }}</p>
    <article v-else-if="ticket">
      <header>
        <p class="eyebrow">{{ ticket.ticketNo }}</p>
        <h1>{{ ticket.title }}</h1>
        <p class="summary">
          {{ copy.list.typeText(ticket.type, ticket.typeText) }} ·
          {{ ticket.shopName }} ·
          {{ copy.list.statusText(ticket.status, ticket.statusText) }}
        </p>
      </header>

      <p class="content">{{ ticket.content }}</p>

      <section class="block">
        <h2>{{ copy.list.merchantReply }}</h2>
        <p>{{ ticket.merchantReply || copy.list.noReply }}</p>
      </section>

      <section v-if="ticket.resolution" class="block">
        <h2>{{ copy.list.resolution }}</h2>
        <p>{{ ticket.resolution }}</p>
      </section>

      <ol v-if="ticket.logs && ticket.logs.length" class="timeline">
        <li v-for="log in ticket.logs" :key="log.id">
          <span class="time">{{ log.createdAt }}</span>
          <span class="who">{{ log.actorTypeText }} · {{ log.actionText }}</span>
          <span v-if="log.remark" class="remark">{{ log.remark }}</span>
        </li>
      </ol>
    </article>
  </section>
</template>
