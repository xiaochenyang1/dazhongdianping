<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebDateTime } from '@/core/web_localizations'
import { formatWebTradeDate, localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { fetchCouponDetail } from '@/services/trade'
import type { CouponDetail } from '@/types/trade'

const props = defineProps<{ code: string }>()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))

const coupon = ref<CouponDetail | null>(null)
const loading = ref(false)
const errorMessage = ref('')
const copied = ref(false)

const usableLabel = computed(() => {
  if (!coupon.value) return ''
  return coupon.value.usable ? copy.value.couponDetail.usable : copy.value.couponDetail.unusable
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  copied.value = false
  try {
    coupon.value = await fetchCouponDetail(props.code)
  } catch (error) {
    coupon.value = null
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.couponDetail.loadFailed)
  } finally {
    loading.value = false
  }
}

async function copyCode() {
  if (!coupon.value?.code) return
  try {
    await navigator.clipboard.writeText(coupon.value.code)
    copied.value = true
  } catch {
    copied.value = false
    errorMessage.value = copy.value.couponDetail.copyFailed
  }
}

watch(
  [() => props.code, () => state.region],
  () => {
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.couponDetail.eyebrow }}</p>
        <h1>{{ coupon?.dealTitle || props.code }}</h1>
        <p v-if="coupon">
          {{ coupon.shopName }} · {{ copy.statuses.coupon(coupon.status, coupon.statusText) }} · {{ usableLabel }}
        </p>
      </div>
      <RouterLink class="secondary-button" to="/user/coupons">{{ copy.couponDetail.back }}</RouterLink>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.couponDetail.loading }}</p>

    <template v-else-if="coupon">
      <section class="content-card coupon-detail-card" data-testid="coupon-detail-card">
        <div class="coupon-qr-panel">
          <img
            v-if="coupon.qrImageUrl"
            class="coupon-qr"
            :src="coupon.qrImageUrl"
            :alt="copy.couponDetail.qrAlt(coupon.code)"
            data-testid="coupon-qr-image"
          />
          <p class="muted">{{ copy.couponDetail.verifyHint(coupon.verifyHint) }}</p>
        </div>

        <div class="coupon-meta">
          <p class="eyebrow">{{ copy.couponDetail.code }}</p>
          <strong data-testid="coupon-detail-code">{{ coupon.code }}</strong>
          <div class="hero-actions">
            <button type="button" class="secondary-button" data-testid="copy-coupon-code" @click="copyCode">
              {{ copied ? copy.couponDetail.copied : copy.couponDetail.copyCode }}
            </button>
            <RouterLink class="secondary-button" :to="`/user/orders/${coupon.orderId}`">{{ copy.couponDetail.viewOrder }}</RouterLink>
            <RouterLink class="secondary-button" :to="`/shops/${coupon.shopId}`">{{ copy.couponDetail.viewPlace }}</RouterLink>
          </div>
          <ul class="coupon-facts">
            <li><span>{{ copy.couponDetail.status }}</span><strong>{{ copy.statuses.coupon(coupon.status, coupon.statusText) }}</strong></li>
            <li>
              <span>{{ copy.couponDetail.expiresAt }}</span>
              <strong>{{ coupon.expireAt ? formatWebTradeDate(coupon.expireAt, copy.tag) : copy.couponDetail.noExpiry }}</strong>
            </li>
            <li>
              <span>{{ copy.couponDetail.offerValidity }}</span>
              <strong>
                {{ coupon.validStart ? formatWebTradeDate(coupon.validStart, copy.tag) : copy.common.notAvailable }}
                ~
                {{ coupon.validEnd ? formatWebTradeDate(coupon.validEnd, copy.tag) : copy.common.notAvailable }}
              </strong>
            </li>
            <li v-if="coupon.verifyAt"><span>{{ copy.couponDetail.redeemedAt }}</span><strong>{{ formatWebDateTime(coupon.verifyAt, copy.tag) }}</strong></li>
          </ul>
          <div class="coupon-rules">
            <h2>{{ copy.couponDetail.rules }}</h2>
            <p>{{ coupon.rules || copy.couponDetail.noRules }}</p>
          </div>
        </div>
      </section>
    </template>
  </section>
</template>

<style scoped>
.coupon-detail-card {
  display: grid;
  grid-template-columns: minmax(220px, 280px) 1fr;
  gap: 24px;
  align-items: start;
}
.coupon-qr-panel {
  text-align: center;
}
.coupon-qr {
  width: 240px;
  height: 240px;
  max-width: 100%;
  border-radius: 12px;
  background: #fff;
  border: 1px solid rgba(0, 0, 0, 0.08);
}
.coupon-meta strong[data-testid='coupon-detail-code'] {
  display: block;
  font-size: 1.4rem;
  letter-spacing: 0.04em;
  margin: 8px 0 16px;
}
.coupon-facts {
  list-style: none;
  margin: 20px 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.coupon-facts li {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}
.coupon-facts span {
  color: var(--color-muted, #6b7280);
}
.coupon-rules h2 {
  margin: 0 0 8px;
  font-size: 1rem;
}
@media (max-width: 720px) {
  .coupon-detail-card {
    grid-template-columns: 1fr;
  }
}
</style>
