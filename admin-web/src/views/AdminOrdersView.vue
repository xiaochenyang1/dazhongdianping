<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  auditAdminOrderRefund,
  importAdminChannelStatement,
  listAdminChannelStatementItems,
  listAdminChannelStatements,
  listAdminOrders,
  reconcileAdminOrders,
} from '@/services/admin'
import type {
  AdminChannelStatementBatch,
  AdminChannelStatementItem,
  AdminOrder,
  PageResult,
} from '@/types/admin'

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
const statementFile = ref<File | null>(null)
const statementImporting = ref(false)
const statementError = ref('')
const statementNotice = ref('')
const statementLoading = ref(false)
const statementPageState = ref<PageResult<AdminChannelStatementBatch> | null>(null)
const statementPage = ref(1)
const selectedStatementBatchId = ref<number | null>(null)
const statementItemLoading = ref(false)
const statementItemError = ref('')
const statementItemPageState = ref<PageResult<AdminChannelStatementItem> | null>(null)
const statementItemPage = ref(1)
const statementItemStatus = ref('')
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

function normalizeStatus(value: string) {
  const normalized = value.trim()
  if (!normalized) {
    return undefined
  }
  const parsed = Number(normalized)
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : undefined
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

function statementBatchStatusText(batch: AdminChannelStatementBatch) {
  return batch.status === 1
    ? strings.value.adminOrders.statements.completed
    : strings.value.adminOrders.statements.processing
}

function statementItemStatusText(item: AdminChannelStatementItem) {
  const labels = strings.value.adminOrders.statements.filters
  if (item.reconcileStatus === 'matched') return labels.matched
  if (item.reconcileStatus === 'discrepancy') return labels.discrepancy
  if (item.reconcileStatus === 'unmatched') return labels.unmatched
  if (item.reconcileStatus === 'ignored') return labels.ignored
  return labels.invalid
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminOrders({
      merchantId: normalizeNumber(filters.merchantId),
      shopId: normalizeNumber(filters.shopId),
      userId: normalizeNumber(filters.userId),
      payStatus: normalizeStatus(filters.payStatus),
      refundStatus: normalizeStatus(filters.refundStatus),
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
      result.reconciledRefunds,
    )
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.adminOrders.reconcileError
  } finally {
    reconcileSubmitting.value = false
  }
}

function selectStatementFile(event: Event) {
  const input = event.target as HTMLInputElement
  statementFile.value = input.files?.[0] ?? null
  statementError.value = ''
}

async function loadStatements() {
  statementLoading.value = true
  statementError.value = ''
  try {
    statementPageState.value = await listAdminChannelStatements({ page: statementPage.value, pageSize: 10 })
  } catch (error) {
    statementError.value = error instanceof Error ? error.message : strings.value.adminOrders.statements.loadError
  } finally {
    statementLoading.value = false
  }
}

async function importStatement() {
  if (!statementFile.value) {
    statementError.value = strings.value.adminOrders.statements.chooseFile
    return
  }
  statementImporting.value = true
  statementError.value = ''
  statementNotice.value = ''
  try {
    const batch = await importAdminChannelStatement(statementFile.value)
    statementNotice.value = strings.value.adminOrders.statements.importSuccess(batch.id)
    statementFile.value = null
    statementPage.value = 1
    await loadStatements()
    await openStatementBatch(batch.id)
  } catch (error) {
    statementError.value = error instanceof Error ? error.message : strings.value.adminOrders.statements.importError
  } finally {
    statementImporting.value = false
  }
}

async function goStatementPage(nextPage: number) {
  statementPage.value = Math.max(1, nextPage)
  await loadStatements()
}

async function openStatementBatch(batchId: number) {
  if (selectedStatementBatchId.value === batchId) {
    selectedStatementBatchId.value = null
    statementItemPageState.value = null
    return
  }
  selectedStatementBatchId.value = batchId
  statementItemPage.value = 1
  statementItemStatus.value = ''
  await loadStatementItems()
}

async function loadStatementItems() {
  if (selectedStatementBatchId.value === null) return
  statementItemLoading.value = true
  statementItemError.value = ''
  try {
    statementItemPageState.value = await listAdminChannelStatementItems(selectedStatementBatchId.value, {
      reconcileStatus: statementItemStatus.value || undefined,
      page: statementItemPage.value,
      pageSize: 50,
    })
  } catch (error) {
    statementItemError.value = error instanceof Error ? error.message : strings.value.adminOrders.statements.loadError
  } finally {
    statementItemLoading.value = false
  }
}

async function applyStatementItemFilter() {
  statementItemPage.value = 1
  await loadStatementItems()
}

async function goStatementItemPage(nextPage: number) {
  statementItemPage.value = Math.max(1, nextPage)
  await loadStatementItems()
}

onMounted(() => {
  void load()
  void loadStatements()
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
            <option value="3">{{ strings.adminOrders.refundStatusOptions.processing }}</option>
            <option value="4">{{ strings.adminOrders.refundStatusOptions.failed }}</option>
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
                <p class="code-box" v-if="item.refundChannelRefundTxn">
                  {{ item.refundChannel || strings.adminOrders.paymentChannelFallback }} / {{ item.refundChannelRefundTxn }}
                </p>
                <p class="inline-note" v-if="item.refundAuditReason">{{ strings.adminOrders.auditRemarkLabel(item.refundAuditReason) }}</p>
                <p class="feedback is-error" v-if="item.refundChannelFailureReason">{{ item.refundChannelFailureReason }}</p>
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

    <article class="content-card system-table-card statement-card">
      <div class="system-table-card__meta">
        <div>
          <strong>{{ strings.adminOrders.statements.heading }}</strong>
          <p class="inline-note">{{ strings.adminOrders.statements.description }}</p>
        </div>
        <form v-if="canAuditRefund" class="toolbar-actions statement-upload" @submit.prevent="importStatement">
          <label class="ghost-button statement-file-button">
            {{ statementFile?.name || strings.adminOrders.statements.chooseFile }}
            <input type="file" accept=".csv,text/csv" :disabled="statementImporting" @change="selectStatementFile" />
          </label>
          <button type="submit" class="primary-button" :disabled="statementImporting || !statementFile">
            {{ statementImporting ? strings.adminOrders.statements.importing : strings.adminOrders.statements.importAction }}
          </button>
        </form>
      </div>

      <p v-if="statementError" class="feedback is-error statement-feedback">{{ statementError }}</p>
      <p v-if="statementNotice" class="feedback is-success statement-feedback">{{ statementNotice }}</p>

      <div class="system-table-card__meta">
        <span>{{ statementLoading ? strings.common.loading : strings.adminOrders.statements.batchMeta(statementPageState?.total ?? 0) }}</span>
      </div>
      <div class="table-shell">
        <table>
          <thead>
            <tr>
              <th>{{ strings.adminOrders.statements.batchHeaders.file }}</th>
              <th>{{ strings.adminOrders.statements.batchHeaders.result }}</th>
              <th>{{ strings.adminOrders.statements.batchHeaders.time }}</th>
              <th>{{ strings.adminOrders.statements.batchHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="statementLoading">
              <td colspan="4">{{ strings.common.loading }}</td>
            </tr>
            <tr v-else-if="!(statementPageState?.list.length)">
              <td colspan="4">{{ strings.adminOrders.statements.noBatches }}</td>
            </tr>
            <tr v-for="batch in statementPageState?.list ?? []" :key="batch.id">
              <td>
                <strong>{{ batch.fileName }}</strong>
                <p class="code-box">{{ batch.channel }} / #{{ batch.id }}</p>
              </td>
              <td>
                <span class="status-pill" :class="batch.discrepancyRows || batch.unmatchedRows || batch.invalidRows ? 'status-pill--warn' : 'status-pill--good'">
                  {{ statementBatchStatusText(batch) }}
                </span>
                <p class="inline-note">
                  {{ strings.adminOrders.statements.summary(batch.matchedRows, batch.discrepancyRows, batch.unmatchedRows, batch.invalidRows, batch.ignoredRows) }}
                </p>
              </td>
              <td class="numeric-cell">{{ batch.createdAt }}</td>
              <td>
                <button type="button" class="ghost-button" @click="openStatementBatch(batch.id)">
                  {{ selectedStatementBatchId === batch.id ? strings.adminOrders.statements.closeDetails : strings.adminOrders.statements.viewDetails }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="statementPage <= 1" @click="goStatementPage(statementPage - 1)">
          {{ strings.adminOrders.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.adminOrders.page(statementPage) }}</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!statementPageState?.hasMore" @click="goStatementPage(statementPage + 1)">
          {{ strings.adminOrders.nextPage }}
        </button>
      </div>

      <section v-if="selectedStatementBatchId !== null" class="statement-details">
        <div class="system-table-card__meta">
          <strong>{{ strings.adminOrders.statements.detailHeading(selectedStatementBatchId) }}</strong>
          <div class="toolbar-actions">
            <select v-model="statementItemStatus" @change="applyStatementItemFilter">
              <option value="">{{ strings.adminOrders.statements.filters.all }}</option>
              <option value="matched">{{ strings.adminOrders.statements.filters.matched }}</option>
              <option value="discrepancy">{{ strings.adminOrders.statements.filters.discrepancy }}</option>
              <option value="unmatched">{{ strings.adminOrders.statements.filters.unmatched }}</option>
              <option value="invalid">{{ strings.adminOrders.statements.filters.invalid }}</option>
              <option value="ignored">{{ strings.adminOrders.statements.filters.ignored }}</option>
            </select>
            <span>{{ strings.adminOrders.statements.detailMeta(statementItemPageState?.total ?? 0) }}</span>
          </div>
        </div>
        <p v-if="statementItemError" class="feedback is-error statement-feedback">{{ statementItemError }}</p>
        <div class="table-shell">
          <table>
            <thead>
              <tr>
                <th>{{ strings.adminOrders.statements.itemHeaders.line }}</th>
                <th>{{ strings.adminOrders.statements.itemHeaders.channel }}</th>
                <th>{{ strings.adminOrders.statements.itemHeaders.local }}</th>
                <th>{{ strings.adminOrders.statements.itemHeaders.result }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="statementItemLoading">
                <td colspan="4">{{ strings.common.loading }}</td>
              </tr>
              <tr v-else-if="!(statementItemPageState?.list.length)">
                <td colspan="4">{{ strings.adminOrders.statements.noItems }}</td>
              </tr>
              <tr v-for="item in statementItemPageState?.list ?? []" :key="item.id">
                <td>
                  <strong>#{{ item.lineNo }}</strong>
                  <p class="inline-note">{{ item.transactionType || '--' }}</p>
                </td>
                <td>
                  <p class="code-box">{{ item.channelTransactionId || '--' }}</p>
                  <p class="inline-note">{{ strings.adminOrders.statements.amountSummary(item.amount, item.currency) }} · {{ item.channelStatus || '--' }}</p>
                  <p class="inline-note" v-if="item.occurredAt">{{ item.occurredAt }}</p>
                </td>
                <td>
                  <strong>{{ strings.adminOrders.statements.localSummary(item.localBizType, item.localBizId, item.orderNo) }}</strong>
                  <p class="inline-note">{{ strings.adminOrders.statements.amountSummary(item.localAmount, item.localCurrency) }}</p>
                </td>
                <td>
                  <span class="status-pill" :class="item.reconcileStatus === 'matched' ? 'status-pill--good' : item.reconcileStatus === 'ignored' ? 'status-pill--muted' : 'status-pill--warn'">
                    {{ statementItemStatusText(item) }}
                  </span>
                  <p v-if="item.discrepancyReason" class="inline-note">{{ item.discrepancyReason }}</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="pager">
          <button type="button" class="ghost-button system-pager-button" :disabled="statementItemPage <= 1" @click="goStatementItemPage(statementItemPage - 1)">
            {{ strings.adminOrders.previousPage }}
          </button>
          <span class="numeric-cell">{{ strings.adminOrders.page(statementItemPage) }}</span>
          <button type="button" class="ghost-button system-pager-button" :disabled="!statementItemPageState?.hasMore" @click="goStatementItemPage(statementItemPage + 1)">
            {{ strings.adminOrders.nextPage }}
          </button>
        </div>
      </section>
    </article>
  </section>
</template>
