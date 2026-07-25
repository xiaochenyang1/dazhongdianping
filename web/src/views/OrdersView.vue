<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { fetchOrders, cancelOrder, refundOrder } from '@/services/trade'
import { formatMoney } from '@/lib/currency'
import type { TradeOrder } from '@/types/trade'

const route = useRoute()
const router = useRouter()

const orders = ref<TradeOrder[]>([])
const loading = ref(false)
const actingId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')

const statusTabs = [
  { value: undefined as number | undefined, label: '全部' },
  { value: 0, label: '待支付' },
  { value: 1, label: '已支付' },
  { value: 2, label: '已退款' },
  { value: 3, label: '部分退款' },
]

const activePayStatus = computed<number | undefined>(() => {
  const raw = route.query.payStatus
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

function payStatusLabel(status?: number) {
  if (status === 0) return '待支付'
  if (status === 1) return '已支付'
  if (status === 2) return '已退款'
  if (status === 3) return '部分退款'
  return '全部'
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchOrders(activePayStatus.value, 1, 50)
    orders.value = result.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '订单加载失败'
  } finally {
    loading.value = false
  }
}

async function switchPayStatus(status?: number) {
  const query: Record<string, string> = {}
  if (status != null) query.payStatus = String(status)
  await router.replace({ path: '/user/orders', query })
}

async function cancel(order: TradeOrder) {
  if (actingId.value != null) return
  actingId.value = order.id
  successMessage.value = ''
  errorMessage.value = ''
  try {
    await cancelOrder(order.id)
    successMessage.value = `订单 ${order.orderNo} 已取消`
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '取消订单失败'
  } finally {
    actingId.value = null
  }
}

async function refund(order: TradeOrder) {
  if (actingId.value != null) return
  const reason = window.prompt('退款原因', '行程有变')
  if (!reason || !reason.trim()) return
  actingId.value = order.id
  successMessage.value = ''
  errorMessage.value = ''
  try {
    await refundOrder(order.id, reason.trim())
    successMessage.value = `订单 ${order.orderNo} 已提交退款申请`
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '申请退款失败'
  } finally {
    actingId.value = null
  }
}

onMounted(() => {
  void load()
})

watch(
  () => route.query.payStatus,
  () => {
    void load()
  },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">我的订单</p>
        <h1>支付状态和订单状态分开看，账才不会乱。</h1>
        <p>当前筛选：{{ payStatusLabel(activePayStatus) }}</p>
      </div>
    </div>

    <div class="hero-actions" style="margin-bottom: 16px">
      <button
        v-for="tab in statusTabs"
        :key="String(tab.value ?? 'all')"
        type="button"
        class="secondary-button"
        :class="{ 'is-active': activePayStatus === tab.value }"
        :data-testid="`order-tab-${tab.value ?? 'all'}`"
        @click="switchPayStatus(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="loading" class="feedback">订单加载中...</p>
    <p v-else-if="orders.length === 0" class="feedback">当前筛选下暂无订单。</p>

    <div v-else class="rank-list">
      <article
        v-for="order in orders"
        :key="order.id"
        class="content-card rank-item"
        :data-testid="`order-card-${order.id}`"
      >
        <img :src="order.coverImage" :alt="order.dealTitle" />
        <div class="rank-item__body">
          <RouterLink :to="`/user/orders/${order.id}`">
            <h2>{{ order.dealTitle }}</h2>
          </RouterLink>
          <p>
            {{ order.shopName }} · 数量 {{ order.quantity }} ·
            {{ formatMoney(order.amount, order.currency) }}
          </p>
          <p class="muted">订单号 {{ order.orderNo }}</p>
          <span class="status-pill">{{ order.payStatusText }}</span>
        </div>
        <div class="form-actions">
          <RouterLink class="secondary-button" :to="`/user/orders/${order.id}`">
            查看详情
          </RouterLink>
          <button
            v-if="order.payStatus === 0 && order.status === 1"
            type="button"
            class="secondary-button"
            :data-testid="`order-cancel-${order.id}`"
            :disabled="actingId === order.id"
            @click="cancel(order)"
          >
            {{ actingId === order.id ? '处理中...' : '取消' }}
          </button>
          <button
            v-if="order.payStatus === 1"
            type="button"
            class="secondary-button"
            :data-testid="`order-refund-${order.id}`"
            :disabled="actingId === order.id"
            @click="refund(order)"
          >
            {{ actingId === order.id ? '处理中...' : '退款' }}
          </button>
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
.muted {
  color: var(--muted, #6b7280);
  font-size: 13px;
}
</style>
