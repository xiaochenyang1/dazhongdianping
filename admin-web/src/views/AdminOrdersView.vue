<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { auditAdminOrderRefund, listAdminOrders, reconcileAdminOrders } from '@/services/admin'
import type { AdminOrder, PageResult } from '@/types/admin'

const { state, hasPermission } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canAuditRefund = hasPermission('data:order:write')
const pageSize = 20
const loading = ref(false)
const errorMessage = ref('')
const pageState = ref<PageResult<AdminOrder> | null>(null)
const auditingOrderId = ref<number | null>(null)
const auditReason = ref('')
const auditSubmitting = ref(false)
const auditError = ref('')
const auditNotice = ref('')
const reconcileSubmitting = ref(false)
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
  const channel = item.paymentChannel || item.payMethod || strings.value.adminOrders.paymentChannelFallback
  return item.paymentChannelTxn ? `${channel} / ${item.paymentChannelTxn}` : channel
}

function payStatusText(item: AdminOrder) {
  return strings.value.adminOrders.payStatusText(item.payStatus, item.payStatusText)
}

function refundStatusText(item: AdminOrder) {
  return strings.value.adminOrders.refundStatusText(item.refundStatus ?? 0, item.refundStatusText)
}

function refundSummary(item: AdminOrder) {
  if (!item.refundId) {
    return strings.value.adminOrders.noRefundRequest
  }
  return strings.value.adminOrders.refundSummary(
    refundStatusText(item),
    item.refundReason || strings.value.adminOrders.noReason,
  )
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
    errorMessage.value = error instanceof Error ? error.message : strings.value.adminOrders.loadError
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

function openAudit(item: AdminOrder) {
  auditingOrderId.value = item.id
  auditReason.value = ''
  auditError.value = ''
  auditNotice.value = ''
}

function closeAudit() {
  auditingOrderId.value = null
  auditReason.value = ''
  auditError.value = ''
}

async function submitAudit(decision: 'approve' | 'reject') {
  if (auditingOrderId.value === null) {
    return
  }
  const reason = auditReason.value.trim()
  if (!reason) {
    auditError.value = strings.value.adminOrders.auditReasonRequired
    return
  }
  auditSubmitting.value = true
  auditError.value = ''
  try {
    const updated = await auditAdminOrderRefund(auditingOrderId.value, { decision, reason })
    if (pageState.value) {
      pageState.value = {
        ...pageState.value,
        list: pageState.value.list.map((item) => (item.id === updated.id ? updated : item)),
      }
    }
    auditNotice.value = strings.value.adminOrders.auditNotice(updated.orderNo, decision)
    closeAudit()
  } catch (error) {
    auditError.value = error instanceof Error ? error.message : strings.value.adminOrders.auditSubmitError
  } finally {
    auditSubmitting.value = false
  }
}

async function runReconcile() {
  reconcileSubmitting.value = true
  errorMessage.value = ''
  try {
    const result = await reconcileAdminOrders()
    auditNotice.value = strings.value.adminOrders.reconcileNotice(
      result.closedOrders,
      result.restoredStockOrders,
      result.failedPayments,
    )
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.adminOrders.reconcileError
  } finally {
    reconcileSubmitting.value = false
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.adminOrders.eyebrow }}</p>
        <h1>{{ strings.adminOrders.heading }}</h1>
        <p>{{ strings.adminOrders.description(state.region) }}</p>
      </div>
      <div v-if="canAuditRefund" class="toolbar-actions">
        <button type="button" class="primary-button" :disabled="reconcileSubmitting" @click="runReconcile">
          {{ reconcileSubmitting ? strings.adminOrders.reconcileRunning : strings.adminOrders.reconcileRun }}
        </button>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="auditNotice" class="feedback is-success">{{ auditNotice }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? strings.adminOrders.metaLoading : strings.adminOrders.metaSummary(pageState?.total ?? 0) }}</span>
        <span>{{ strings.adminOrders.metaDescription }}</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.adminOrders.filters.merchantId }}</span>
          <input
            name="admin-order-merchant-id"
            v-model="filters.merchantId"
            inputmode="numeric"
            :placeholder="strings.adminOrders.placeholders.merchantId"
          />
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.shopId }}</span>
          <input
            name="admin-order-shop-id"
            v-model="filters.shopId"
            inputmode="numeric"
            :placeholder="strings.adminOrders.placeholders.shopId"
          />
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.userId }}</span>
          <input
            name="admin-order-user-id"
            v-model="filters.userId"
            inputmode="numeric"
            :placeholder="strings.adminOrders.placeholders.userId"
          />
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.payStatus }}</span>
          <select name="admin-order-pay-status" v-model="filters.payStatus">
            <option value="">{{ strings.adminOrders.payStatusOptions.all }}</option>
            <option value="0">{{ strings.adminOrders.payStatusOptions.pending }}</option>
            <option value="1">{{ strings.adminOrders.payStatusOptions.paid }}</option>
            <option value="2">{{ strings.adminOrders.payStatusOptions.refunded }}</option>
            <option value="3">{{ strings.adminOrders.payStatusOptions.partialRefund }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.refundStatus }}</span>
          <select name="admin-order-refund-status" v-model="filters.refundStatus">
            <option value="">{{ strings.adminOrders.refundStatusOptions.all }}</option>
            <option value="0">{{ strings.adminOrders.refundStatusOptions.pending }}</option>
            <option value="1">{{ strings.adminOrders.refundStatusOptions.success }}</option>
            <option value="2">{{ strings.adminOrders.refundStatusOptions.rejected }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.orderNo }}</span>
          <input
            name="admin-order-order-no"
            v-model="filters.orderNo"
            :placeholder="strings.adminOrders.placeholders.orderNo"
          />
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.dateFrom }}</span>
          <input name="admin-order-date-from" v-model="filters.dateFrom" type="date" />
        </label>
        <label class="field">
          <span>{{ strings.adminOrders.filters.dateTo }}</span>
          <input name="admin-order-date-to" v-model="filters.dateTo" type="date" />
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">{{ strings.adminOrders.applyFilters }}</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.adminOrders.tableHeaders.time }}</th>
              <th>{{ strings.adminOrders.tableHeaders.order }}</th>
              <th>{{ strings.adminOrders.tableHeaders.merchantShop }}</th>
              <th>{{ strings.adminOrders.tableHeaders.user }}</th>
              <th>{{ strings.adminOrders.tableHeaders.amount }}</th>
              <th>{{ strings.adminOrders.tableHeaders.payment }}</th>
              <th>{{ strings.adminOrders.tableHeaders.refund }}</th>
              <th v-if="canAuditRefund">{{ strings.adminOrders.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canAuditRefund ? 8 : 7" class="table-empty">{{ strings.adminOrders.loadingRow }}</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td :colspan="canAuditRefund ? 8 : 7" class="table-empty">{{ strings.adminOrders.empty }}</td>
            </tr>
            <tr v-for="item in pageState?.list" :key="item.id">
              <td class="numeric-cell">{{ item.createdAt }}</td>
              <td>
                <strong>{{ item.orderNo }}</strong>
                <p class="inline-note">{{ item.dealTitle || strings.adminOrders.dealFallback(item.dealId) }}</p>
              </td>
              <td>
                <strong>{{ item.merchantName || strings.adminOrders.merchantFallback(item.merchantId) }}</strong>
                <p class="code-box">{{ item.shopName || strings.adminOrders.shopFallback(item.shopId) }}</p>
              </td>
              <td>
                <strong>{{ item.userNickname || strings.adminOrders.userFallback(item.userId) }}</strong>
                <p class="code-box">{{ item.account || strings.adminOrders.userFallback(item.userId) }}</p>
              </td>
              <td>
                <strong>{{ item.amount }} {{ item.currency }}</strong>
                <p class="inline-note">{{ strings.adminOrders.amountSummary(item.quantity, item.unitPrice) }}</p>
              </td>
              <td>
                <span class="status-pill" :class="item.payStatus === 1 || item.payStatus === 2 ? 'status-pill--good' : 'status-pill--warn'">
                  {{ payStatusText(item) }}
                </span>
                <p class="inline-note">{{ paymentSummary(item) }}</p>
                <p class="inline-note" v-if="item.paidAt">{{ strings.adminOrders.paidAt(item.paidAt) }}</p>
              </td>
              <td>
                <span class="status-pill" :class="item.refundId ? (item.refundStatus === 1 ? 'status-pill--good' : item.refundStatus === 2 ? 'status-pill--muted' : 'status-pill--warn') : 'status-pill--muted'">
                  {{ item.refundId ? refundStatusText(item) : strings.adminOrders.noRefund }}
                </span>
                <p class="inline-note">{{ refundSummary(item) }}</p>
                <p class="inline-note" v-if="item.refundAuditReason">{{ strings.adminOrders.auditRemarkLabel(item.refundAuditReason) }}</p>
              </td>
              <td v-if="canAuditRefund">
                <template v-if="item.refundId && item.refundStatus === 0">
                  <button
                    v-if="auditingOrderId !== item.id"
                    type="button"
                    class="ghost-button"
                    @click="openAudit(item)"
                  >
                    {{ strings.adminOrders.refundArbitration }}
                  </button>
                  <div v-else class="field">
                    <textarea
                      name="admin-refund-audit-reason"
                      v-model="auditReason"
                      rows="2"
                      :placeholder="strings.adminOrders.placeholders.auditReason"
                    ></textarea>
                    <p v-if="auditError" class="feedback is-error">{{ auditError }}</p>
                    <div class="toolbar-actions">
                      <button type="button" class="primary-button" :disabled="auditSubmitting" @click="submitAudit('approve')">
                        {{ strings.adminOrders.approveRefund }}
                      </button>
                      <button type="button" class="ghost-button" :disabled="auditSubmitting" @click="submitAudit('reject')">
                        {{ strings.adminOrders.rejectRefund }}
                      </button>
                      <button type="button" class="ghost-button" :disabled="auditSubmitting" @click="closeAudit">{{ strings.common.cancel }}</button>
                    </div>
                  </div>
                </template>
                <span v-else class="inline-note">{{ strings.adminOrders.noPendingRefund }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="filters.page <= 1" @click="goPage(filters.page - 1)">
          {{ strings.adminOrders.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.adminOrders.page(filters.page) }}</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!pageState?.hasMore" @click="goPage(filters.page + 1)">
          {{ strings.adminOrders.nextPage }}
        </button>
      </div>
    </article>
  </section>
</template>
