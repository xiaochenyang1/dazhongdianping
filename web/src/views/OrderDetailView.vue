<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useStripeCheckout } from '@/composables/useStripeCheckout'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { cancelOrder, completeMockPayment, fetchOrder, payOrder, refundOrder } from '@/services/trade'
import { formatMoney } from '@/lib/currency'
import type { PaymentIntent, TradeOrder } from '@/types/trade'

const props = defineProps<{ orderId: number }>()
const route = useRoute()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))

const order = ref<TradeOrder | null>(null)
const intent = ref<PaymentIntent | null>(null)
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const confirming = ref(false)
const pollTimedOut = ref(false)
const cardElement = ref<HTMLElement | null>(null)
const stripeCheckout = useStripeCheckout(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY || '')
const needsStripe = computed(() => Boolean(intent.value?.clientSecret))

const POLL_INTERVAL_MS = 1500
const POLL_MAX_TRIES = 12
let pollRequestId = 0
let pollTimer: ReturnType<typeof setTimeout> | null = null

const canCancel = computed(() => order.value?.payStatus === 0 && order.value?.status === 1)
const canRefund = computed(() => order.value?.payStatus === 1 && !order.value?.refund)
const refundBanner = computed(() => {
  const marker = String(route.query.refund || '')
  if (marker === 'approved') return copy.value.orderDetail.refundApproved
  if (marker === 'rejected') return copy.value.orderDetail.refundRejected
  return ''
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    order.value = await fetchOrder(props.orderId)
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orderDetail.loadFailed)
  } finally {
    loading.value = false
  }
}

function stopPolling() {
  pollRequestId += 1
  if (pollTimer) {
    clearTimeout(pollTimer)
    pollTimer = null
  }
}

async function pollOrderUntilPaid() {
  const requestId = ++pollRequestId
  confirming.value = true
  pollTimedOut.value = false
  successMessage.value = copy.value.orderDetail.stripeProcessing
  for (let attempt = 0; attempt < POLL_MAX_TRIES; attempt += 1) {
    try {
      const next = await fetchOrder(props.orderId)
      if (requestId !== pollRequestId) return
      if (next?.payStatus === 1) {
        order.value = next
        intent.value = null
        successMessage.value = ''
        confirming.value = false
        pollTimedOut.value = false
        return
      }
      order.value = next
    } catch {
      // Transient fetch errors are retried by the next tick; keep the current
      // success banner visible so the user knows payment was received.
    }
    await new Promise<void>((resolve) => {
      pollTimer = setTimeout(resolve, POLL_INTERVAL_MS)
    })
    if (requestId !== pollRequestId) return
  }
  confirming.value = false
  pollTimedOut.value = true
  successMessage.value = copy.value.orderDetail.stripeReceived
}

async function pay() {
  acting.value = true
  errorMessage.value = ''
  try {
    intent.value = await payOrder(props.orderId)
    if (intent.value?.clientSecret) {
      await nextTick()
      if (cardElement.value) {
        await stripeCheckout.mount(cardElement.value, intent.value.clientSecret)
      }
    }
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orderDetail.paymentFailed)
  } finally {
    acting.value = false
  }
}

async function confirmCard() {
  errorMessage.value = ''
  const ok = await stripeCheckout.confirm()
  if (!ok) {
    errorMessage.value = stripeCheckout.error.value || copy.value.orderDetail.stripePaymentFailed
    return
  }
  stripeCheckout.unmount()
  intent.value = null
  await pollOrderUntilPaid()
}

async function complete() {
  acting.value = true
  errorMessage.value = ''
  try {
    order.value = await completeMockPayment(props.orderId)
    intent.value = null
    successMessage.value = copy.value.orderDetail.mockPaymentSuccess
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orderDetail.mockPaymentFailed)
  } finally {
    acting.value = false
  }
}

async function cancel() {
  if (!window.confirm(copy.value.orderDetail.cancelConfirm)) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    order.value = await cancelOrder(props.orderId)
    successMessage.value = copy.value.orderDetail.cancelSuccess
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orderDetail.cancelFailed)
  } finally {
    acting.value = false
  }
}

async function refund() {
  const reason = window.prompt(copy.value.orderDetail.refundPrompt, copy.value.orderDetail.refundDefaultReason)
  if (!reason || !reason.trim()) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    order.value = await refundOrder(props.orderId, reason.trim())
    successMessage.value = copy.value.orderDetail.refundSuccess
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orderDetail.refundFailed)
  } finally {
    acting.value = false
  }
}

watch(
  [() => props.orderId, () => state.region],
  () => {
    stopPolling()
    confirming.value = false
    pollTimedOut.value = false
    intent.value = null
    successMessage.value = ''
    void load()
  },
  { immediate: true },
)

onBeforeUnmount(() => stopPolling())
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.orderDetail.order }} {{ order?.orderNo || props.orderId }}</p>
        <h1>{{ order?.dealTitle || copy.orderDetail.title }}</h1>
        <p v-if="order">
          {{ order.shopName }} · {{ formatMoney(order.amount, order.currency) }} ·
          {{ copy.statuses.pay(order.payStatus, order.payStatusText) }}
        </p>
      </div>
      <RouterLink class="secondary-button" to="/user/orders">{{ copy.orderDetail.back }}</RouterLink>
    </div>

    <p v-if="refundBanner" class="feedback is-success" data-testid="refund-result-banner">{{ refundBanner }}</p>
    <p v-if="successMessage" class="feedback is-success" data-testid="order-success">{{ successMessage }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="loading" class="feedback">{{ copy.orderDetail.loading }}</p>
    <div v-if="pollTimedOut" class="hero-actions">
      <button class="secondary-button" type="button" :disabled="loading" data-testid="order-refresh" @click="load">
        {{ copy.orderDetail.refreshOrder }}
      </button>
    </div>

    <template v-else-if="order">
      <div class="hero-actions">
        <button
          v-if="order.payStatus === 0 && !intent && order.status === 1"
          class="primary-button"
          type="button"
          :disabled="acting"
          data-testid="order-pay"
          @click="pay"
        >
          {{ copy.orderDetail.startPayment }}
        </button>
        <div v-if="intent && needsStripe" class="stripe-card-block">
          <div ref="cardElement" data-testid="stripe-card-element" class="stripe-card-element"></div>
          <button
            class="primary-button"
            type="button"
            data-testid="stripe-pay-confirm"
            :disabled="!stripeCheckout.ready.value || stripeCheckout.processing.value"
            @click="confirmCard"
          >
            {{ copy.orderDetail.stripePayment }}
          </button>
        </div>
        <button
          v-if="intent && !needsStripe"
          class="primary-button"
          type="button"
          :disabled="acting"
          data-testid="mock-pay-complete"
          @click="complete"
        >
          {{ copy.orderDetail.completeMockPayment(intent.channel) }}
        </button>
        <button
          v-if="canCancel"
          class="secondary-button"
          type="button"
          data-testid="order-cancel"
          :disabled="acting"
          @click="cancel"
        >
          {{ copy.orderDetail.cancel }}
        </button>
        <button
          v-if="canRefund"
          class="secondary-button"
          type="button"
          data-testid="order-refund"
          :disabled="acting"
          @click="refund"
        >
          {{ copy.orderDetail.requestRefund }}
        </button>
      </div>

      <section v-if="order.refund" class="content-card" data-testid="order-refund-card">
        <h2>{{ copy.orderDetail.refundProgress }}</h2>
        <p>
          <span class="status-pill">{{ copy.statuses.refund(order.refund.status, order.refund.statusText) }}</span>
          · {{ copy.orderDetail.amount }} {{ formatMoney(order.refund.amount, order.currency) }}
        </p>
        <p>{{ copy.orderDetail.reason }}: {{ order.refund.reason || copy.common.notAvailable }}</p>
        <p v-if="order.refund.auditReason">{{ copy.orderDetail.auditNote }}: {{ order.refund.auditReason }}</p>
        <p class="muted">
          {{ copy.orderDetail.requestedAt }}
          {{ order.refund.createdAt ? formatWebDateTime(order.refund.createdAt, copy.tag) : copy.common.notAvailable }}
          <template v-if="order.refund.auditedAt">
            · {{ copy.orderDetail.auditedAt }} {{ formatWebDateTime(order.refund.auditedAt, copy.tag) }}
          </template>
        </p>
      </section>

      <section v-if="order.coupons?.length" class="content-card">
        <h2>{{ copy.orderDetail.vouchers }}</h2>
        <div class="tag-row">
          <RouterLink
            v-for="coupon in order.coupons"
            :key="coupon.id"
            class="secondary-button"
            :data-testid="`order-coupon-link-${coupon.code}`"
            :to="`/user/coupons/${encodeURIComponent(coupon.code)}`"
          >
            {{ coupon.code }} · {{ copy.statuses.coupon(coupon.status, coupon.statusText) }}
          </RouterLink>
        </div>
        <p class="muted">{{ copy.orderDetail.voucherHint }}</p>
      </section>
    </template>
  </section>
</template>
