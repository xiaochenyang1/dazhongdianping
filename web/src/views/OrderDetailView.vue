<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { completeMockPayment, fetchOrder, payOrder } from '@/services/trade'
import { formatMoney } from '@/lib/currency'
import type { PaymentIntent, TradeOrder } from '@/types/trade'

const props = defineProps<{ orderId: number }>()
const order = ref<TradeOrder | null>(null)
const intent = ref<PaymentIntent | null>(null)
const errorMessage = ref('')

async function load() {
  order.value = await fetchOrder(props.orderId)
}

async function pay() {
  try {
    intent.value = await payOrder(props.orderId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '支付发起失败'
  }
}

async function complete() {
  try {
    order.value = await completeMockPayment(props.orderId)
    intent.value = null
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '模拟支付失败'
  }
}

onMounted(() => {
  void load().catch((error) => {
    errorMessage.value = error instanceof Error ? error.message : '订单加载失败'
  })
})
</script>

<template>
  <section v-if="order" class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">订单 {{ order.orderNo }}</p>
        <h1>{{ order.dealTitle }}</h1>
        <p>{{ order.shopName }} · {{ formatMoney(order.amount, order.currency) }} · {{ order.payStatusText }}</p>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <div class="hero-actions">
      <button v-if="order.payStatus === 0 && !intent" class="primary-button" type="button" @click="pay">发起支付</button>
      <button v-if="intent" class="primary-button" type="button" @click="complete">模拟 {{ intent.channel }} 支付成功</button>
    </div>

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
  </section>
</template>
