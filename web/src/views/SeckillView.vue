<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { campaignStringsForRegion, localizeWebCampaignError } from '@/core/web_campaign_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { formatMoney } from '@/lib/currency'
import { claimSeckill, fetchSeckill } from '@/services/campaign'
import type { SeckillEvent } from '@/types/campaign'

const { state } = useAppContext()
const { state: session, openAuthDialog } = useUserSession()
const router = useRouter()
const copy = computed(() => campaignStringsForRegion(state.region))
const events = ref<SeckillEvent[]>([])
const loading = ref(false)
const actingId = ref<number | null>(null)
const errorMessage = ref('')
let scopeVersion = 0
let loadVersion = 0

async function load() {
  const request = ++loadVersion
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchSeckill()
    if (request === loadVersion) events.value = result
  } catch (error) {
    if (request === loadVersion) errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.loadFailed)
  } finally {
    if (request === loadVersion) loading.value = false
  }
}

function available(event: SeckillEvent) {
  return event.availableStock ?? Math.max(0, event.stock - event.sold)
}

async function claim(event: SeckillEvent) {
  if (actingId.value !== null) return
  if (!session.accessToken) {
    openAuthDialog({ mode: 'password', redirectTo: '/marketing/seckill' })
    return
  }
  const scope = scopeVersion
  actingId.value = event.id
  errorMessage.value = ''
  try {
    const result = await claimSeckill(event.id)
    if (scope === scopeVersion) await router.push(`/user/orders/${result.orderId}`)
  } catch (error) {
    if (scope === scopeVersion) errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.purchaseFailed)
  } finally {
    if (scope === scopeVersion) actingId.value = null
  }
}

watch([() => state.region, () => session.accessToken, () => session.currentUser?.id], () => {
  scopeVersion++
  actingId.value = null
  events.value = []
  void load()
}, { immediate: true })
onBeforeUnmount(() => { scopeVersion++; loadVersion++ })
</script>

<template>
  <section class="page-section">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ copy.seckillEyebrow }}</p>
        <h1>{{ copy.seckillTitle }}</h1>
        <p>{{ copy.purchaseRules }}</p>
      </div>
    </header>
    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <button v-if="errorMessage" type="button" class="secondary-button" :disabled="loading" data-testid="seckill-retry" @click="load">{{ copy.retry }}</button>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="events.length === 0 && !errorMessage" class="feedback">{{ copy.empty }}</p>
    <div v-else class="rank-list">
      <article v-for="event in events" :key="event.id" class="content-card" :data-testid="`seckill-${event.id}`">
        <h2>{{ event.title }}</h2>
        <p><strong>{{ formatMoney(event.seckillPrice, event.currency) }}</strong> · {{ copy.remaining(available(event)) }}</p>
        <p v-if="event.endAt" class="muted">{{ copy.endsAt }} {{ formatWebDateTime(event.endAt, copy.tag) }}</p>
        <div class="hero-actions">
          <RouterLink class="secondary-button" :to="`/deals/${event.dealId}`">{{ copy.offerDetails }}</RouterLink>
          <RouterLink v-if="event.orderId" class="primary-button" :to="`/user/orders/${event.orderId}`">{{ copy.viewOrder }}</RouterLink>
          <button v-else type="button" class="primary-button"
            :disabled="actingId !== null || available(event) <= 0 || event.participationStatus === 0"
            :data-testid="`seckill-buy-${event.id}`" @click="claim(event)">
            {{ actingId === event.id ? copy.buying : event.participationStatus === 0 ? copy.limitReached : available(event) <= 0 ? copy.soldOut : copy.claim }}
          </button>
        </div>
      </article>
    </div>
  </section>
</template>
