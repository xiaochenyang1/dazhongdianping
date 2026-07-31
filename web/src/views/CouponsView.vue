<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebTradeDate, localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { fetchCoupons } from '@/services/trade'
import type { Coupon } from '@/types/trade'

const route = useRoute()
const router = useRouter()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))

const coupons = ref<Coupon[]>([])
const loading = ref(false)
const errorMessage = ref('')
const highlightCode = ref('')

const statusTabs = computed(() => [
  { value: undefined as number | undefined, label: copy.value.statuses.all },
  ...[1, 2, 3, 4].map((value) => ({ value, label: copy.value.statuses.coupon(value) })),
])

const activeStatus = computed<number | undefined>(() => {
  const raw = route.query.status
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

function statusLabel(status?: number) {
  return status == null ? copy.value.statuses.all : copy.value.statuses.coupon(status)
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchCoupons(activeStatus.value, 1, 50)
    coupons.value = result.list
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.coupons.loadFailed)
  } finally {
    loading.value = false
  }
}

async function switchStatus(status?: number) {
  const query: Record<string, string> = {}
  if (status != null) query.status = String(status)
  if (highlightCode.value) query.code = highlightCode.value
  await router.replace({ path: '/user/coupons', query })
}

watch(
  [() => route.query.status, () => route.query.code, () => state.region],
  async () => {
    const rawCode = route.query.code
    highlightCode.value = String(Array.isArray(rawCode) ? rawCode[0] || '' : rawCode || '')
    await load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.coupons.eyebrow }}</p>
        <h1>{{ copy.coupons.title }}</h1>
        <p>
          {{ copy.coupons.currentFilter(statusLabel(activeStatus)) }}
          <template v-if="highlightCode"> · {{ copy.coupons.highlightedCode(highlightCode) }}</template>
        </p>
      </div>
    </div>

    <div class="hero-actions" style="margin-bottom: 16px">
      <button
        v-for="tab in statusTabs"
        :key="String(tab.value ?? 'all')"
        type="button"
        class="secondary-button"
        :class="{ 'is-active': activeStatus === tab.value }"
        :data-testid="`coupon-tab-${tab.value ?? 'all'}`"
        @click="switchStatus(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.coupons.loading }}</p>
    <p v-else-if="coupons.length === 0" class="feedback">{{ copy.coupons.empty }}</p>

    <div v-else class="rank-grid">
      <RouterLink
        v-for="coupon in coupons"
        :key="coupon.id"
        class="rank-card"
        :class="{ 'is-highlight': highlightCode && highlightCode === coupon.code }"
        :data-testid="`coupon-card-${coupon.code}`"
        :to="`/user/coupons/${encodeURIComponent(coupon.code)}`"
      >
        <img :src="coupon.coverImage" :alt="coupon.dealTitle" />
        <div class="rank-card__body">
          <h2>{{ coupon.dealTitle }}</h2>
          <strong>{{ coupon.code }}</strong>
          <span>
            {{ coupon.shopName }} · {{ copy.statuses.coupon(coupon.status, coupon.statusText) }} ·
            {{ copy.coupons.expiresAt }}
            {{ coupon.expireAt ? formatWebTradeDate(coupon.expireAt, copy.tag) : copy.coupons.noExpiry }}
          </span>
          <span class="muted">{{ copy.coupons.viewDetails }}</span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>

<style scoped>
.rank-card.is-highlight {
  outline: 2px solid var(--color-primary, #ff6633);
  box-shadow: 0 0 0 4px rgba(255, 102, 51, 0.12);
}
.secondary-button.is-active {
  background: var(--color-primary, #ff6633);
  color: #fff;
  border-color: transparent;
}
</style>
