<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { waitlistStringsForRegion } from '@/core/web_waitlist_localizations'
import { cancelWaitlist, fetchMyWaitlist } from '@/services/waitlist'
import type { WaitlistEntry } from '@/types/waitlist'

const { state: appState } = useAppContext()
const copy = computed(() => waitlistStringsForRegion(appState.region).mine)

const entries = ref<WaitlistEntry[]>([])
const loading = ref(false)
const errorMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    entries.value = await fetchMyWaitlist()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function cancel(entry: WaitlistEntry) {
  errorMessage.value = ''
  try {
    await cancelWaitlist(entry.id)
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.cancelFailed
  }
}

watch(() => appState.region, load, { immediate: true })
</script>

<template>
  <section class="my-waitlist">
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="entries.length === 0" class="feedback">{{ copy.empty }}</p>

    <ul v-else class="waitlist-list">
      <li v-for="e in entries" :key="e.id" class="waitlist-card" :data-testid="`waitlist-${e.id}`">
        <div class="waitlist-card__head">
          <strong>{{ e.shopName }}</strong>
          <span class="status">{{ copy.statusText(e.status, e.statusText) }}</span>
        </div>
        <p class="waitlist-card__meta">
          {{ copy.tableTypeText(e.tableType, e.tableTypeText) }} · {{ copy.queueNo }} {{ e.queueNo }}
          <template v-if="e.status === 1"> · {{ copy.ahead(e.aheadCount) }}</template>
        </p>
        <button v-if="e.status === 1" type="button" class="link" :data-testid="`cancel-${e.id}`" @click="cancel(e)">
          {{ copy.cancel }}
        </button>
      </li>
    </ul>
  </section>
</template>
