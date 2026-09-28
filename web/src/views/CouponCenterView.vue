<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { localizeWebMarketingError, marketingStringsForRegion } from '@/core/web_marketing_localizations'
import { claimCoupon, fetchCouponCenter } from '@/services/marketing'
import type { CouponCenterItem } from '@/types/marketing'

const { state: appState } = useAppContext()
const { state: sessionState, openAuthDialog } = useUserSession()
const copy = computed(() => marketingStringsForRegion(appState.region))

const items = ref<CouponCenterItem[]>([])
const loading = ref(false)
const errorMessage = ref('')
const feedbackMessage = ref('')
const claimingId = ref<number | null>(null)

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    items.value = await fetchCouponCenter()
  } catch (error) {
    errorMessage.value = localizeWebMarketingError(copy.value, error, copy.value.center.loadFailed)
  } finally {
    loading.value = false
  }
}

async function claim(item: CouponCenterItem) {
  if (!sessionState.accessToken) {
    openAuthDialog({ mode: 'password', redirectTo: '/coupons/center' })
    return
  }
  claimingId.value = item.templateId
  feedbackMessage.value = ''
  errorMessage.value = ''
  try {
    await claimCoupon(item.templateId)
    feedbackMessage.value = copy.value.center.claimSuccess(item.name)
    await load()
  } catch (error) {
    errorMessage.value = localizeWebMarketingError(copy.value, error, copy.value.center.claimFailed)
  } finally {
    claimingId.value = null
  }
}

function thresholdText(item: CouponCenterItem) {
  return item.type === 2 || item.thresholdAmount <= 0
    ? copy.value.center.noThreshold
    : copy.value.center.thresholdLabel(item.thresholdAmount, item.currency)
}

function actionLabel(item: CouponCenterItem) {
  if (item.soldOut) return copy.value.center.soldOut
  if (item.claimed) return copy.value.center.claimed
  return copy.value.center.claim
}

watch(() => appState.region, () => void load(), { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.center.eyebrow }}</p>
        <h1>{{ copy.center.title }}</h1>
        <p>{{ copy.center.summary }}</p>
      </div>
      <RouterLink class="secondary-button" to="/user/marketing-coupons">{{ copy.wallet.eyebrow }}</RouterLink>
    </div>

    <p v-if="feedbackMessage" class="feedback is-success" data-testid="coupon-center-feedback">{{ feedbackMessage }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.center.loading }}</p>
    <p v-else-if="items.length === 0" class="feedback">{{ copy.center.empty }}</p>

    <div v-else class="rank-grid">
      <article
        v-for="item in items"
        :key="item.templateId"
        class="rank-card"
        :data-testid="`coupon-center-${item.templateId}`"
      >
        <div class="rank-card__body">
          <p class="eyebrow">{{ item.typeText }}</p>
          <h2>{{ item.name }}</h2>
          <strong>{{ item.discountAmount }} {{ item.currency }}</strong>
          <span>{{ thresholdText(item) }} · {{ copy.center.validDays(item.validDays) }}</span>
          <button
            type="button"
            class="primary-button"
            :disabled="!item.claimable || claimingId === item.templateId"
            :data-testid="`coupon-center-claim-${item.templateId}`"
            @click="claim(item)"
          >
            {{ claimingId === item.templateId ? copy.center.claiming : actionLabel(item) }}
          </button>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.feedback.is-success {
  color: var(--color-primary, #ff6633);
}
</style>
