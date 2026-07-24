<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { cancelOrder, completeMockPayment, fetchOrder, payOrder, refundOrder } from '@/services/trade'
import { formatMoney } from '@/lib/currency'
import type { PaymentIntent, TradeOrder } from '@/types/trade'

const props = defineProps<{ orderId: number }>()
const route = useRoute()

const order = ref<TradeOrder | null>(null)
const intent = ref<PaymentIntent | null>(null)
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const canCancel = computed(() => order.value?.payStatus === 0 && order.value?.status === 1)
const canRefund = computed(() => order.value?.payStatus === 1 && !order.value?.refund)
const refundBanner = computed(() => {
  const marker = String(route.query.refund || '')
  if (marker === 'approved') return '退款已通过，订单状态已更新。'
  if (marker === 'rejected') return '退款已驳回，可查看审核说明。'
  return ''
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    order.value = await fetchOrder(props.orderId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '订单加载失败'
  } finally {
    loading.value = false
  }
}

async function pay() {
  acting.value = true
  errorMessage.value = ''
  try {
    intent.value = await payOrder(props.orderId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '支付发起失败'
  } finally {
    acting.value = false
  }
}

async function complete() {
  acting.value = true
  errorMessage.value = ''
  try {
    order.value = await completeMockPayment(props.orderId)
    intent.value = null
    successMessage.value = '模拟支付成功，券码已生成。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '模拟支付失败'
  } finally {
    acting.value = false
  }
}

async function cancel() {
  if (!window.confirm('确认取消这张未支付订单？')) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    order.value = await cancelOrder(props.orderId)
    successMessage.value = '订单已取消。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '取消失败'
  } finally {
    acting.value = false
  }
}

async function refund() {
  const reason = window.prompt('退款原因', '行程有变')
  if (!reason || !reason.trim()) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    order.value = await refundOrder(props.orderId, reason.trim())
    successMessage.value = '退款申请已提交，等待商户或平台处理。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '退款申请失败'
  } finally {
    acting.value = false
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">订单 {{ order?.orderNo || props.orderId }}</p>
        <h1>{{ order?.dealTitle || '订单详情' }}</h1>
        <p v-if="order">
          {{ order.shopName }} · {{ formatMoney(order.amount, order.currency) }} · {{ order.payStatusText }}
        </p>
      </div>
      <RouterLink class="secondary-button" to="/user/orders">返回订单列表</RouterLink>
    </div>

    <p v-if="refundBanner" class="feedback is-success" data-testid="refund-result-banner">{{ refundBanner }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="loading" class="feedback">订单加载中...</p>

    <template v-else-if="order">
      <div class="hero-actions">
        <button
          v-if="order.payStatus === 0 && !intent && order.status === 1"
          class="primary-button"
          type="button"
          :disabled="acting"
          @click="pay"
        >
          发起支付
        </button>
        <button
          v-if="intent"
          class="primary-button"
          type="button"
          :disabled="acting"
          data-testid="mock-pay-complete"
          @click="complete"
        >
          模拟 {{ intent.channel }} 支付成功
        </button>
        <button
          v-if="canCancel"
          class="secondary-button"
          type="button"
          data-testid="order-cancel"
          :disabled="acting"
          @click="cancel"
        >
          取消订单
        </button>
        <button
          v-if="canRefund"
          class="secondary-button"
          type="button"
          data-testid="order-refund"
          :disabled="acting"
          @click="refund"
        >
          申请退款
        </button>
      </div>

      <section v-if="order.refund" class="content-card" data-testid="order-refund-card">
        <h2>退款进度</h2>
        <p>
          <span class="status-pill">{{ order.refund.statusText }}</span>
          · 金额 {{ formatMoney(order.refund.amount, order.currency) }}
        </p>
        <p>申请原因：{{ order.refund.reason || '—' }}</p>
        <p v-if="order.refund.auditReason">审核说明：{{ order.refund.auditReason }}</p>
        <p class="muted">
          申请时间 {{ order.refund.createdAt || '—' }}
          <template v-if="order.refund.auditedAt"> · 审核时间 {{ order.refund.auditedAt }}</template>
        </p>
      </section>

      <section v-if="order.coupons?.length" class="content-card">
        <h2>券码</h2>
        <div class="tag-row">
          <RouterLink
            v-for="coupon in order.coupons"
            :key="coupon.id"
            class="secondary-button"
            :data-testid="`order-coupon-link-${coupon.code}`"
            :to="`/user/coupons/${encodeURIComponent(coupon.code)}`"
          >
            {{ coupon.code }} · {{ coupon.statusText }}
          </RouterLink>
        </div>
        <p class="muted">点击券码可查看核销二维码与使用规则。</p>
      </section>
    </template>
  </section>
</template>
