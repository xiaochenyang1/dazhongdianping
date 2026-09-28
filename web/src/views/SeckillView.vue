<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { campaignStringsForRegion } from '@/core/web_campaign_localizations'
import { claimSeckill, fetchSeckill } from '@/services/campaign'
import type { SeckillEvent } from '@/types/campaign'

const { state } = useAppContext()
const copy = computed(() => campaignStringsForRegion(state.region))
const events = ref<SeckillEvent[]>([])
const loading = ref(false)
const errorMessage = ref('')
const success = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    events.value = await fetchSeckill()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function claim(event: SeckillEvent) {
  errorMessage.value = ''
  success.value = ''
  try {
    const result = await claimSeckill(event.id)
    success.value = `#${result.claimId}`
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section>
    <header>
      <p class="eyebrow">{{ copy.seckillEyebrow }}</p>
      <h1>{{ copy.seckillTitle }}</h1>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="success" class="feedback">{{ success }}</p>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="events.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-else>
      <li v-for="event in events" :key="event.id" :data-testid="`seckill-${event.id}`">
        <h2>{{ event.title }}</h2>
        <p>{{ event.seckillPrice }} {{ event.currency }} · {{ copy.stock }} {{ event.sold }}/{{ event.stock }}</p>
        <button type="button" class="primary-button" @click="claim(event)">{{ copy.claim }}</button>
      </li>
    </ul>
  </section>
</template>
