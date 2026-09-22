<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebTradeDate } from '@/core/web_trade_localizations'
import { localizeWebMarketingError, marketingStringsForRegion } from '@/core/web_marketing_localizations'
import { fetchMyCoupons } from '@/services/marketing'
import type { UserCoupon } from '@/types/marketing'

const route = useRoute()
const router = useRouter()
const { state } = useAppContext()
const copy = computed(() => marketingStringsForRegion(state.region))

const coupons = ref<UserCoupon[]>([])
const loading = ref(false)
const errorMessage = ref('')

const statusTabs = computed(() => [
  { value: undefined as number | undefined, label: copy.value.wallet.all },
  ...[1, 2, 3].map((value) => ({ value, label: copy.value.wallet.statusText(value) })),
])

const activeStatus = computed<number | undefined>(() => {
  const raw = route.query.status
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchMyCoupons(activeStatus.value, 1, 50)
    coupons.value = result.list
  } catch (error) {
    errorMessage.value = localizeWebMarketingError(copy.value, error, copy.value.wallet.loadFailed)
  } finally {
    loading.value = false
  }
}

async function switchStatus(status?: number) {
  const query: Record<string, string> = {}
  if (status != null) query.status = String(status)
  await router.replace({ path: '/user/marketing-coupons', query })
}

function thresholdText(coupon: UserCoupon) {
  return coupon.type === 2 || coupon.thresholdAmount <= 0
    ? copy.value.wallet.noThreshold
    : copy.value.wallet.thresholdLabel(coupon.thresholdAmount, coupon.currency)
}

watch([() => route.query.status, () => state.region], () => void load(), { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.wallet.eyebrow }}</p>
        <h1>{{ copy.wallet.title }}</h1>
        <p>{{ copy.wallet.summary }}</p>
      </div>
      <RouterLink class="secondary-button" to="/coupons/center">{{ copy.center.eyebrow }}</RouterLink>
    </div>

    <div class="hero-actions" style="margin-bottom: 16px">
      <button
        v-for="tab in statusTabs"
        :key="String(tab.value ?? 'all')"
        type="button"
        class="secondary-button"
        :class="{ 'is-active': activeStatus === tab.value }"
        :data-testid="`mkt-coupon-tab-${tab.value ?? 'all'}`"
        @click="switchStatus(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.wallet.loading }}</p>
    <p v-else-if="coupons.length === 0" class="feedback">{{ copy.wallet.empty }}</p>

    <div v-else class="rank-grid">
      <article
        v-for="coupon in coupons"
        :key="coupon.id"
        class="rank-card"
        :data-testid="`mkt-coupon-${coupon.id}`"
      >
        <div class="rank-card__body">
          <h2>{{ coupon.name }}</h2>
          <strong>{{ coupon.discountAmount }} {{ coupon.currency }}</strong>
          <span>{{ thresholdText(coupon) }} · {{ copy.wallet.statusText(coupon.status, coupon.statusText) }}</span>
          <span class="muted">
            {{ copy.wallet.expiresAt }}
            {{ coupon.expireAt ? formatWebTradeDate(coupon.expireAt, copy.tag) : copy.wallet.noExpiry }}
          </span>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.secondary-button.is-active {
  background: var(--color-primary, #ff6633);
  color: #fff;
  border-color: transparent;
}
</style>
