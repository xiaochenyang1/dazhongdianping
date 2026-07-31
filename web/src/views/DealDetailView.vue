<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import {
  formatWebTradeDate,
  localizeWebTradeError,
  tradeStringsForRegion,
} from '@/core/web_trade_localizations'
import { formatMoney } from '@/lib/currency'
import { createOrder, fetchDeal } from '@/services/trade'
import type { DealDetail } from '@/types/trade'

const props = defineProps<{ dealId: number }>()
const router = useRouter()
const { state: appState } = useAppContext()
const { state: sessionState, openAuthDialog } = useUserSession()
const copy = computed(() => tradeStringsForRegion(appState.region))
const deal = ref<DealDetail | null>(null)
const quantity = ref(1)
const loading = ref(true)
const errorMessage = ref('')
let requestSequence = 0

async function load() {
  const request = ++requestSequence
  loading.value = true
  errorMessage.value = ''
  deal.value = null
  try {
    const result = await fetchDeal(props.dealId)
    if (request === requestSequence) deal.value = result
  } catch (error) {
    if (request === requestSequence) {
      errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.deal.loadFailed)
    }
  } finally {
    if (request === requestSequence) loading.value = false
  }
}

async function buy() {
  if (!sessionState.accessToken) {
    openAuthDialog({ mode: 'password', redirectTo: `/deals/${props.dealId}` })
    return
  }
  try {
    const order = await createOrder(props.dealId, quantity.value)
    await router.push(`/user/orders/${order.id}`)
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.deal.createOrderFailed)
  }
}

watch([() => props.dealId, () => appState.region], () => void load(), { immediate: true })
</script>

<template>
  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
  <p v-else-if="loading" class="feedback">{{ copy.deal.loading }}</p>
  <section v-else-if="deal" class="detail-hero">
    <img :src="deal.coverImage" :alt="deal.title" class="detail-hero__image" />
    <div class="detail-hero__body">
      <p class="eyebrow">{{ deal.shopName }} · {{ copy.deal.sold(deal.soldCount) }}</p>
      <h1>{{ deal.title }}</h1>
      <p class="detail-hero__summary">{{ deal.rules }}</p>
      <div class="detail-hero__stats">
        <div><span>{{ copy.deal.offerPrice }}</span><strong>{{ formatMoney(deal.price, deal.currency) }}</strong></div>
        <div><span>{{ copy.deal.originalPrice }}</span><strong>{{ formatMoney(deal.originalPrice, deal.currency) }}</strong></div>
        <div><span>{{ copy.deal.validUntil }}</span><strong>{{ formatWebTradeDate(deal.validEnd, copy.tag) }}</strong></div>
      </div>
      <div class="dish-list">
        <div v-for="item in deal.items" :key="item.id" class="dish-card">
          <span>{{ item.name }} × {{ item.quantity }}</span>
          <strong>{{ formatMoney(item.price, deal.currency) }}</strong>
        </div>
      </div>
      <div class="hero-actions">
        <label class="field">
          <span>{{ copy.deal.quantity }}</span>
          <input v-model.number="quantity" type="number" min="1" max="20" />
        </label>
        <button class="primary-button" @click="buy">{{ copy.deal.buyNow }}</button>
      </div>
    </div>
  </section>
</template>
