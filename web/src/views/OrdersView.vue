<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { fetchOrders, cancelOrder, refundOrder } from '@/services/trade'
import { formatMoney } from '@/lib/currency'
import type { TradeOrder } from '@/types/trade'

const route = useRoute()
const router = useRouter()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))

const orders = ref<TradeOrder[]>([])
const loading = ref(false)
const actingId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')

const statusTabs = computed(() => [
  { value: undefined as number | undefined, label: copy.value.statuses.all },
  ...[0, 1, 2, 3].map((value) => ({ value, label: copy.value.statuses.pay(value) })),
])

const activePayStatus = computed<number | undefined>(() => {
  const raw = route.query.payStatus
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

function payStatusLabel(status?: number) {
  return status == null ? copy.value.statuses.all : copy.value.statuses.pay(status)
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchOrders(activePayStatus.value, 1, 50)
    orders.value = result.list
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orders.loadFailed)
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
    successMessage.value = copy.value.orders.cancelSuccess(order.orderNo)
    await load()
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orders.cancelFailed)
  } finally {
    actingId.value = null
  }
}

async function refund(order: TradeOrder) {
  if (actingId.value != null) return
  const reason = window.prompt(copy.value.orders.refundPrompt, copy.value.orders.refundDefaultReason)
  if (!reason || !reason.trim()) return
  actingId.value = order.id
  successMessage.value = ''
  errorMessage.value = ''
  try {
    await refundOrder(order.id, reason.trim())
    successMessage.value = copy.value.orders.refundSuccess(order.orderNo)
    await load()
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orders.refundFailed)
  } finally {
    actingId.value = null
  }
}

watch(
  [() => route.query.payStatus, () => state.region],
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
        <p class="eyebrow">{{ copy.orders.eyebrow }}</p>
        <h1>{{ copy.orders.title }}</h1>
        <p>{{ copy.orders.currentFilter(payStatusLabel(activePayStatus)) }}</p>
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
    <p v-if="loading" class="feedback">{{ copy.orders.loading }}</p>
    <p v-else-if="orders.length === 0" class="feedback">{{ copy.orders.empty }}</p>

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
            {{ order.shopName }} · {{ copy.orders.quantity(order.quantity) }} ·
            {{ formatMoney(order.amount, order.currency) }}
          </p>
          <p class="muted">{{ copy.orders.orderNo(order.orderNo) }}</p>
          <span class="status-pill">{{ copy.statuses.pay(order.payStatus, order.payStatusText) }}</span>
        </div>
        <div class="form-actions">
          <RouterLink class="secondary-button" :to="`/user/orders/${order.id}`">
            {{ copy.orders.viewDetails }}
          </RouterLink>
          <button
            v-if="order.payStatus === 0 && order.status === 1"
            type="button"
            class="secondary-button"
            :data-testid="`order-cancel-${order.id}`"
            :disabled="actingId === order.id"
            @click="cancel(order)"
          >
            {{ actingId === order.id ? copy.common.processing : copy.orders.cancel }}
          </button>
          <button
            v-if="order.payStatus === 1"
            type="button"
            class="secondary-button"
            :data-testid="`order-refund-${order.id}`"
            :disabled="actingId === order.id"
            @click="refund(order)"
          >
            {{ actingId === order.id ? copy.common.processing : copy.orders.refund }}
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
