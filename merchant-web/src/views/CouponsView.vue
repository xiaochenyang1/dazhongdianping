<script setup lang="ts">
import { computed, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { verifyCoupon, type MerchantCoupon } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const code = ref('')
const loading = ref(false)
const error = ref('')
const notice = ref('')
const result = ref<MerchantCoupon | null>(null)
const history = ref<MerchantCoupon[]>([])
const canVerify = computed(() => props.permissions.includes('coupon:verify'))

function couponStatusText(coupon: MerchantCoupon) {
  return strings.value.coupons.statusText(coupon.status, coupon.statusText)
}

function dealLabel(coupon: MerchantCoupon) {
  return coupon.dealTitle || strings.value.coupons.dealFallback(coupon.dealId)
}

function shopLabel(coupon: MerchantCoupon) {
  return coupon.shopName || strings.value.coupons.shopFallback(coupon.shopId)
}

async function submit() {
  if (!canVerify.value) {
    error.value = strings.value.coupons.missingPermission('coupon:verify')
    return
  }
  const normalized = code.value.trim()
  if (!normalized) {
    error.value = strings.value.coupons.codeRequired
    return
  }
  loading.value = true
  error.value = ''
  notice.value = ''
  try {
    const coupon = await verifyCoupon(normalized)
    result.value = coupon
    history.value = [coupon, ...history.value.filter((item) => item.code !== coupon.code)].slice(0, 8)
    notice.value = strings.value.coupons.verifySuccess(coupon.code)
    code.value = ''
  } catch (cause) {
    result.value = null
    error.value = cause instanceof Error ? cause.message : strings.value.coupons.verifyError
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">{{ strings.coupons.eyebrow }}</p>
        <strong>{{ strings.coupons.heading }}</strong>
        <p class="muted">{{ strings.coupons.description }}</p>
      </div>
    </div>

    <p v-if="!canVerify" class="error" role="alert">{{ strings.coupons.missingPermission('coupon:verify') }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text">{{ notice }}</p>

    <article class="card verify-card">
      <form class="verify-form" @submit.prevent="submit">
        <label>
          <span>{{ strings.coupons.codeLabel }}</span>
          <input
            v-model="code"
            name="coupon-code"
            data-testid="coupon-code-input"
            maxlength="64"
            autocomplete="off"
            :placeholder="strings.coupons.codePlaceholder"
            :disabled="!canVerify || loading"
          />
        </label>
        <button
          type="submit"
          class="primary-action"
          data-testid="coupon-verify-submit"
          :disabled="!canVerify || loading"
        >
          {{ loading ? strings.coupons.verifying : strings.coupons.verify }}
        </button>
      </form>
    </article>

    <article v-if="result" class="card result-card" data-testid="coupon-verify-result">
      <p class="eyebrow">{{ strings.coupons.latestResultHeading }}</p>
      <h3>{{ dealLabel(result) }}</h3>
      <p><strong>{{ strings.coupons.fieldLabels.code }}</strong>{{ result.code }}</p>
      <p><strong>{{ strings.coupons.fieldLabels.shop }}</strong>{{ shopLabel(result) }}</p>
      <p><strong>{{ strings.coupons.fieldLabels.status }}</strong>{{ couponStatusText(result) }}</p>
      <p v-if="result.verifyAt"><strong>{{ strings.coupons.fieldLabels.verifiedAt }}</strong>{{ result.verifyAt }}</p>
      <p v-if="result.expireAt"><strong>{{ strings.coupons.fieldLabels.expireAt }}</strong>{{ result.expireAt }}</p>
    </article>

    <article v-if="history.length" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.coupons.historyHeaders.code }}</th>
            <th>{{ strings.coupons.historyHeaders.deal }}</th>
            <th>{{ strings.coupons.historyHeaders.shop }}</th>
            <th>{{ strings.coupons.historyHeaders.status }}</th>
            <th>{{ strings.coupons.historyHeaders.verifiedAt }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in history" :key="`${item.id}-${item.code}`">
            <td>{{ item.code }}</td>
            <td>{{ dealLabel(item) }}</td>
            <td>{{ shopLabel(item) }}</td>
            <td>{{ couponStatusText(item) }}</td>
            <td>{{ item.verifyAt || '--' }}</td>
          </tr>
        </tbody>
      </table>
    </article>
  </section>
</template>
