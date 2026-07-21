<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { listAdminOrders } from '@/services/admin'
import type { AdminOrder, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const pageSize = 20
const loading = ref(false)
const errorMessage = ref('')
const pageState = ref<PageResult<AdminOrder> | null>(null)
const filters = reactive({
  merchantId: '',
  shopId: '',
  userId: '',
  payStatus: '',
  refundStatus: '',
  orderNo: '',
  dateFrom: '',
  dateTo: '',
  page: 1,
})

function normalizeNumber(value: string) {
  const normalized = value.trim()
  if (!normalized) {
    return undefined
  }
  const parsed = Number(normalized)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined
}

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized ? normalized : undefined
}

function normalizeDate(value: string) {
  return value.trim() || undefined
}

function paymentSummary(item: AdminOrder) {
  const channel = item.paymentChannel || item.payMethod || '--'
  return item.paymentChannelTxn ? `${channel} / ${item.paymentChannelTxn}` : channel
}

function refundSummary(item: AdminOrder) {
  if (!item.refundId) {
    return '无退款申请'
  }
  return `${item.refundStatusText || '申请中'} · ${item.refundReason || '无原因'}`
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminOrders({
      merchantId: normalizeNumber(filters.merchantId),
      shopId: normalizeNumber(filters.shopId),
      userId: normalizeNumber(filters.userId),
      payStatus: normalizeNumber(filters.payStatus),
      refundStatus: normalizeNumber(filters.refundStatus),
      orderNo: normalizeText(filters.orderNo),
      dateFrom: normalizeDate(filters.dateFrom),
      dateTo: normalizeDate(filters.dateTo),
      page: filters.page,
      pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '订单数据加载失败'
  } finally {
    loading.value = false
  }
}

async function applyFilters() {
  filters.page = 1
  await load()
}

async function goPage(nextPage: number) {
  filters.page = Math.max(1, nextPage)
  await load()
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">Orders & Reconciliation</p>
        <h1>订单退款</h1>
        <p>当前区域 {{ state.region }}。先把订单、支付流水和退款状态看明白，再谈什么对账补偿。</p>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? '加载中...' : `共 ${pageState?.total ?? 0} 条订单` }}</span>
        <span>支持按商户、门店、用户、支付/退款状态、订单号和日期范围筛选。</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>商户 ID</span>
          <input name="admin-order-merchant-id" v-model="filters.merchantId" inputmode="numeric" placeholder="例如 1001" />
        </label>
        <label class="field">
          <span>门店 ID</span>
          <input name="admin-order-shop-id" v-model="filters.shopId" inputmode="numeric" placeholder="例如 10001" />
        </label>
        <label class="field">
          <span>用户 ID</span>
          <input name="admin-order-user-id" v-model="filters.userId" inputmode="numeric" placeholder="例如 9001" />
        </label>
        <label class="field">
          <span>支付状态</span>
          <select name="admin-order-pay-status" v-model="filters.payStatus">
            <option value="">全部</option>
            <option value="0">待支付</option>
            <option value="1">已支付</option>
            <option value="2">已退款</option>
            <option value="3">部分退款</option>
          </select>
        </label>
        <label class="field">
          <span>退款状态</span>
          <select name="admin-order-refund-status" v-model="filters.refundStatus">
            <option value="">全部</option>
            <option value="0">申请中</option>
            <option value="1">退款成功</option>
            <option value="2">已驳回</option>
          </select>
        </label>
        <label class="field">
          <span>订单号</span>
          <input name="admin-order-order-no" v-model="filters.orderNo" placeholder="例如 ADMIN-ORDER-001" />
        </label>
        <label class="field">
          <span>起始日期</span>
          <input name="admin-order-date-from" v-model="filters.dateFrom" type="date" />
        </label>
        <label class="field">
          <span>结束日期</span>
          <input name="admin-order-date-to" v-model="filters.dateTo" type="date" />
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">应用筛选</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>时间</th>
              <th>订单</th>
              <th>商户 / 门店</th>
              <th>用户</th>
              <th>金额</th>
              <th>支付</th>
              <th>退款</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7" class="table-empty">订单数据加载中...</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="7" class="table-empty">当前筛选下没有订单，条件别拧得太邪乎。</td>
            </tr>
            <tr v-for="item in pageState?.list" :key="item.id">
              <td class="numeric-cell">{{ item.createdAt }}</td>
              <td>
                <strong>{{ item.orderNo }}</strong>
                <p class="inline-note">{{ item.dealTitle || `deal:${item.dealId}` }}</p>
              </td>
              <td>
                <strong>{{ item.merchantName || `merchant:${item.merchantId}` }}</strong>
                <p class="code-box">{{ item.shopName || `shop:${item.shopId}` }}</p>
              </td>
              <td>
                <strong>{{ item.userNickname || `user:${item.userId}` }}</strong>
                <p class="code-box">{{ item.account || `user:${item.userId}` }}</p>
              </td>
              <td>
                <strong>{{ item.amount }} {{ item.currency }}</strong>
                <p class="inline-note">x{{ item.quantity }} · 单价 {{ item.unitPrice }}</p>
              </td>
              <td>
                <span class="status-pill" :class="item.payStatus === 1 || item.payStatus === 2 ? 'status-pill--good' : 'status-pill--warn'">
                  {{ item.payStatusText }}
                </span>
                <p class="inline-note">{{ paymentSummary(item) }}</p>
                <p class="inline-note" v-if="item.paidAt">支付时间：{{ item.paidAt }}</p>
              </td>
              <td>
                <span class="status-pill" :class="item.refundId ? (item.refundStatus === 1 ? 'status-pill--good' : item.refundStatus === 2 ? 'status-pill--muted' : 'status-pill--warn') : 'status-pill--muted'">
                  {{ item.refundId ? item.refundStatusText : '无退款' }}
                </span>
                <p class="inline-note">{{ refundSummary(item) }}</p>
                <p class="inline-note" v-if="item.refundAuditReason">审核备注：{{ item.refundAuditReason }}</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="filters.page <= 1" @click="goPage(filters.page - 1)">
          上一页
        </button>
        <span class="numeric-cell">第 {{ filters.page }} 页</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!pageState?.hasMore" @click="goPage(filters.page + 1)">
          下一页
        </button>
      </div>
    </article>
  </section>
</template>
