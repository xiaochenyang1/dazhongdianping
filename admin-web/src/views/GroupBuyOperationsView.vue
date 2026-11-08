<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  disposeAdminGroupBuyFailedRefund,
  getAdminGroupBuySummary,
  listAdminGroupBuyFailedRefunds,
  listAdminGroupBuyTeams,
  reconcileAdminGroupBuyTeam,
} from '@/services/admin'
import type {
  AdminGroupBuyFailedRefund,
  AdminGroupBuySummary,
  AdminGroupBuyTeam,
  PageResult,
} from '@/types/admin'

const zhCopy = {
  eyebrow: '交易可观测与补偿',
  heading: '拼团运维中心',
  description: '查看最近 24 小时成团与支付表现，并定位退款、发券、库存释放异常。补偿操作幂等执行；渠道明确失败的退款只报告失败，需核对渠道流水后人工处置。',
  refresh: '刷新',
  loading: '加载中...',
  metrics: {
    total: '新建拼团', active: '进行中', formed: '已成团', expired: '已过期',
    conversion: '支付转化', problems: '异常项',
  },
  alertHeading: '当前告警',
  healthy: '当前没有发现需要处理的拼团异常。',
  refundHeading: '渠道失败退款核验',
  refundDescription: '先在支付渠道后台核对真实资金结果，再记录核验结论。记录“未退款”会保留告警；确认“已退款”只补齐本地状态，不会再次发起退款。',
  noFailedRefunds: '当前没有需要人工核验的渠道失败退款。',
  refundHeaders: {
    order: '订单 / 拼团', provider: '渠道回执', failure: '失败原因', review: '核验记录', actions: '人工处置',
  },
  providerReference: '渠道核验编号',
  dispositionNote: '核验备注',
  markNotRefunded: '确认渠道未退款',
  markRefunded: '确认渠道已退款',
  disposing: '提交中...',
  dispositionRequired: '请填写渠道核验编号和核验备注。',
  confirmRefunded: '确认已在支付渠道后台核对到实际退款成功？此操作会补齐本地退款、库存和用户通知状态，但不会再次调用退款接口。',
  unresolvedResult: '已记录渠道未退款，告警继续保留，系统不会自动重提。',
  resolvedResult: '已确认渠道退款成功，本地状态已补齐，相关告警已解除。',
  dispositionError: '退款核验结果提交失败。',
  listHeading: '拼团列表',
  allStatuses: '全部状态',
  open: '进行中', formed: '已成团', expired: '已过期',
  problemOnly: '只看异常',
  headers: {
    team: '拼团', campaign: '活动 / 门店', progress: '成员 / 支付', status: '状态',
    refunds: '退款', vouchers: '发券', inventory: '库存', expireAt: '截止时间', actions: '操作',
  },
  pending: '处理中',
  failed: '失败',
  missing: '缺失',
  unreleased: '未释放',
  normal: '正常',
  reconcile: '执行补偿',
  reconciling: '补偿中...',
  result: (vouchers: number, expired: number, failures: number) =>
    `补偿完成：补发券 ${vouchers}，处理过期订单 ${expired}，失败 ${failures}`,
  empty: '暂无符合条件的拼团。',
  previous: '上一页',
  next: '下一页',
  page: (page: number) => `第 ${page} 页`,
  loadError: '拼团运维数据加载失败。',
  actionError: '拼团补偿执行失败。',
  readOnly: '当前账号只有查看权限。',
}

const enCopy = {
  eyebrow: 'Transaction observability and recovery',
  heading: 'Group-buy Operations',
  description: 'Inspect the last 24 hours of team and payment performance. Recovery is idempotent; terminal refund failures are reported for provider verification and manual disposition.',
  refresh: 'Refresh',
  loading: 'Loading...',
  metrics: {
    total: 'New teams', active: 'Active', formed: 'Formed', expired: 'Expired',
    conversion: 'Payment conversion', problems: 'Issues',
  },
  alertHeading: 'Active alerts',
  healthy: 'No group-buy operational issues are currently detected.',
  refundHeading: 'Terminal refund verification',
  refundDescription: 'Verify the actual funds in the provider console first. “Not refunded” keeps the alert open; “Refunded” only reconciles local state and never resubmits the refund.',
  noFailedRefunds: 'No terminal provider refund failures require verification.',
  refundHeaders: {
    order: 'Order / team', provider: 'Provider receipt', failure: 'Failure', review: 'Last review', actions: 'Manual disposition',
  },
  providerReference: 'Provider verification reference',
  dispositionNote: 'Verification note',
  markNotRefunded: 'Provider did not refund',
  markRefunded: 'Provider refunded',
  disposing: 'Submitting...',
  dispositionRequired: 'Enter the provider verification reference and note.',
  confirmRefunded: 'Confirm the provider console shows a successful refund? This reconciles local refund, inventory, and notification state without calling the refund API again.',
  unresolvedResult: 'Provider non-refund recorded. The alert remains open and no retry was submitted.',
  resolvedResult: 'Provider refund confirmed. Local state was reconciled and the alert was resolved.',
  dispositionError: 'Failed to submit the refund verification result.',
  listHeading: 'Teams',
  allStatuses: 'All statuses',
  open: 'Active', formed: 'Formed', expired: 'Expired',
  problemOnly: 'Issues only',
  headers: {
    team: 'Team', campaign: 'Campaign / shop', progress: 'Members / paid', status: 'Status',
    refunds: 'Refunds', vouchers: 'Vouchers', inventory: 'Inventory', expireAt: 'Deadline', actions: 'Actions',
  },
  pending: 'Pending',
  failed: 'Failed',
  missing: 'Missing',
  unreleased: 'Unreleased',
  normal: 'Normal',
  reconcile: 'Run recovery',
  reconciling: 'Recovering...',
  result: (vouchers: number, expired: number, failures: number) =>
    `Recovery complete: ${vouchers} vouchers issued, ${expired} expired orders processed, ${failures} failures`,
  empty: 'No matching teams.',
  previous: 'Previous',
  next: 'Next',
  page: (page: number) => `Page ${page}`,
  loadError: 'Failed to load group-buy operations.',
  actionError: 'Failed to reconcile the group-buy team.',
  readOnly: 'This account has read-only access.',
}

const { state } = useAdminSession()
const copy = computed(() => state.region === 'EU' ? enCopy : zhCopy)
const canWrite = computed(() => state.permissions.includes('data:order:write'))
const summary = ref<AdminGroupBuySummary | null>(null)
const teams = ref<PageResult<AdminGroupBuyTeam> | null>(null)
const failedRefunds = ref<PageResult<AdminGroupBuyFailedRefund> | null>(null)
const statusFilter = ref('')
const problemOnly = ref(true)
const page = ref(1)
const refundPage = ref(1)
const loading = ref(false)
const errorMessage = ref('')
const actionMessage = ref('')
const reconcilingId = ref<number | null>(null)
const disposingId = ref<number | null>(null)
const providerReferences = ref<Record<number, string>>({})
const dispositionNotes = ref<Record<number, string>>({})

const problemCount = computed(() => {
  if (!summary.value) return 0
  return summary.value.failedRefunds
    + summary.value.missingCouponOrders
    + summary.value.unreleasedInventoryOrders
    + summary.value.overdueActiveTeams
})

const paymentConversion = computed(() => {
  if (!summary.value?.memberOrders) return '0%'
  return `${Math.round(summary.value.paidOrders / summary.value.memberOrders * 100)}%`
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const query = {
      status: statusFilter.value ? Number(statusFilter.value) : undefined,
      problemOnly: problemOnly.value,
      page: page.value,
      pageSize: 20,
    }
    const [nextSummary, nextTeams, nextFailedRefunds] = await Promise.all([
      getAdminGroupBuySummary(),
      listAdminGroupBuyTeams(query),
      listAdminGroupBuyFailedRefunds({ page: refundPage.value, pageSize: 20 }),
    ])
    summary.value = nextSummary
    teams.value = nextTeams
    failedRefunds.value = nextFailedRefunds
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadError
  } finally {
    loading.value = false
  }
}

async function disposeRefund(
  refund: AdminGroupBuyFailedRefund,
  outcome: 'provider_refunded' | 'provider_not_refunded',
) {
  if (!canWrite.value || disposingId.value !== null) return
  const providerReference = (providerReferences.value[refund.refundId] ?? '').trim()
  const note = (dispositionNotes.value[refund.refundId] ?? '').trim()
  if (!providerReference || !note) {
    errorMessage.value = copy.value.dispositionRequired
    return
  }
  if (outcome === 'provider_refunded' && !window.confirm(copy.value.confirmRefunded)) return
  disposingId.value = refund.refundId
  actionMessage.value = ''
  errorMessage.value = ''
  try {
    const result = await disposeAdminGroupBuyFailedRefund(refund.refundId, {
      outcome,
      providerReference,
      note,
    })
    delete providerReferences.value[refund.refundId]
    delete dispositionNotes.value[refund.refundId]
    actionMessage.value = result.alertResolved ? copy.value.resolvedResult : copy.value.unresolvedResult
    await load()
    if (failedRefunds.value?.list.length === 0 && refundPage.value > 1) {
      refundPage.value -= 1
      await load()
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.dispositionError
  } finally {
    disposingId.value = null
  }
}

async function reconcile(team: AdminGroupBuyTeam) {
  if (!canWrite.value || reconcilingId.value !== null) return
  reconcilingId.value = team.id
  actionMessage.value = ''
  errorMessage.value = ''
  try {
    const result = await reconcileAdminGroupBuyTeam(team.id)
    actionMessage.value = copy.value.result(
      result.vouchersIssued,
      result.expiredOrdersProcessed,
      result.failures,
    )
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.actionError
  } finally {
    reconcilingId.value = null
  }
}

function formatDate(value: string) {
  if (!value) return '--'
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleString(state.region === 'EU' ? 'en-GB' : 'zh-CN')
}

watch([statusFilter, problemOnly], () => {
  page.value = 1
  void load()
})
watch(() => state.region, () => {
  page.value = 1
  refundPage.value = 1
  void load()
})
onMounted(load)
</script>

<template>
  <section class="page-stack">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ copy.eyebrow }}</p>
        <h1>{{ copy.heading }}</h1>
        <p>{{ copy.description }}</p>
      </div>
      <button type="button" class="secondary-button" :disabled="loading" @click="load">
        {{ loading ? copy.loading : copy.refresh }}
      </button>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="actionMessage" class="feedback is-success" role="status">{{ actionMessage }}</p>
    <p v-if="!canWrite" class="feedback">{{ copy.readOnly }}</p>

    <div class="stat-grid groupbuy-summary">
      <article class="stat-card"><span>{{ copy.metrics.total }}</span><strong>{{ summary?.totalTeams ?? '--' }}</strong></article>
      <article class="stat-card"><span>{{ copy.metrics.active }}</span><strong>{{ summary?.activeTeams ?? '--' }}</strong></article>
      <article class="stat-card"><span>{{ copy.metrics.formed }}</span><strong>{{ summary?.formedTeams ?? '--' }}</strong></article>
      <article class="stat-card"><span>{{ copy.metrics.expired }}</span><strong>{{ summary?.expiredTeams ?? '--' }}</strong></article>
      <article class="stat-card"><span>{{ copy.metrics.conversion }}</span><strong>{{ paymentConversion }}</strong></article>
      <article class="stat-card"><span>{{ copy.metrics.problems }}</span><strong>{{ problemCount }}</strong></article>
    </div>

    <article class="panel">
      <div class="section-heading"><h2>{{ copy.alertHeading }}</h2></div>
      <p v-if="!summary?.alerts.length" class="empty-state">{{ copy.healthy }}</p>
      <ul v-else class="alert-list">
        <li v-for="alert in summary.alerts" :key="alert.code" :class="`is-${alert.severity}`">
          <strong>{{ alert.count }}</strong><span>{{ alert.message }}</span>
        </li>
      </ul>
    </article>

    <article class="panel">
      <div class="section-heading"><div><h2>{{ copy.refundHeading }}</h2><p>{{ copy.refundDescription }}</p></div></div>
      <p v-if="!failedRefunds?.list.length" class="empty-state">{{ copy.noFailedRefunds }}</p>
      <div v-else class="table-scroll">
        <table class="data-table terminal-refund-table">
          <thead><tr>
            <th>{{ copy.refundHeaders.order }}</th><th>{{ copy.refundHeaders.provider }}</th>
            <th>{{ copy.refundHeaders.failure }}</th><th>{{ copy.refundHeaders.review }}</th>
            <th>{{ copy.refundHeaders.actions }}</th>
          </tr></thead>
          <tbody><tr v-for="refund in failedRefunds.list" :key="refund.refundId">
            <td>
              <strong>{{ refund.orderNo }}</strong>
              <small>#{{ refund.orderId }} · team #{{ refund.teamId }} · {{ refund.campaignTitle }} / {{ refund.shopName }}</small>
              <small>{{ refund.amount }} {{ refund.currency }}</small>
            </td>
            <td><strong>{{ refund.channel }}</strong><small>{{ refund.channelRefundTxn || '--' }} · {{ refund.channelStatus }}</small></td>
            <td>{{ refund.channelFailureReason || '--' }}</td>
            <td><span>{{ refund.auditReason || '--' }}</span><small>{{ formatDate(refund.auditedAt || '') }}</small></td>
            <td>
              <div class="disposition-form">
                <input
                  v-model="providerReferences[refund.refundId]"
                  :data-testid="`refund-reference-${refund.refundId}`"
                  :placeholder="copy.providerReference"
                  :disabled="!canWrite || disposingId !== null"
                >
                <textarea
                  v-model="dispositionNotes[refund.refundId]"
                  :data-testid="`refund-note-${refund.refundId}`"
                  :placeholder="copy.dispositionNote"
                  :disabled="!canWrite || disposingId !== null"
                  rows="2"
                />
                <div class="disposition-actions">
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`refund-not-refunded-${refund.refundId}`"
                    :disabled="!canWrite || disposingId !== null"
                    @click="disposeRefund(refund, 'provider_not_refunded')"
                  >{{ disposingId === refund.refundId ? copy.disposing : copy.markNotRefunded }}</button>
                  <button
                    type="button"
                    class="table-action is-danger"
                    :data-testid="`refund-refunded-${refund.refundId}`"
                    :disabled="!canWrite || disposingId !== null"
                    @click="disposeRefund(refund, 'provider_refunded')"
                  >{{ disposingId === refund.refundId ? copy.disposing : copy.markRefunded }}</button>
                </div>
              </div>
            </td>
          </tr></tbody>
        </table>
      </div>
      <div v-if="failedRefunds?.total" class="pagination-row">
        <button type="button" :disabled="refundPage <= 1 || loading" @click="refundPage--; load()">{{ copy.previous }}</button>
        <span>{{ copy.page(refundPage) }}</span>
        <button type="button" :disabled="!failedRefunds.hasMore || loading" @click="refundPage++; load()">{{ copy.next }}</button>
      </div>
    </article>

    <article class="panel">
      <div class="section-heading groupbuy-toolbar">
        <h2>{{ copy.listHeading }}</h2>
        <div class="filter-row">
          <select v-model="statusFilter" aria-label="status filter">
            <option value="">{{ copy.allStatuses }}</option>
            <option value="1">{{ copy.open }}</option>
            <option value="2">{{ copy.formed }}</option>
            <option value="3">{{ copy.expired }}</option>
          </select>
          <label><input v-model="problemOnly" type="checkbox"> {{ copy.problemOnly }}</label>
        </div>
      </div>

      <div class="table-scroll">
        <table class="data-table">
          <thead><tr>
            <th>{{ copy.headers.team }}</th><th>{{ copy.headers.campaign }}</th><th>{{ copy.headers.progress }}</th>
            <th>{{ copy.headers.status }}</th><th>{{ copy.headers.refunds }}</th><th>{{ copy.headers.vouchers }}</th>
            <th>{{ copy.headers.inventory }}</th><th>{{ copy.headers.expireAt }}</th><th>{{ copy.headers.actions }}</th>
          </tr></thead>
          <tbody>
            <tr v-if="loading && !teams"><td colspan="9">{{ copy.loading }}</td></tr>
            <tr v-else-if="!teams?.list.length"><td colspan="9">{{ copy.empty }}</td></tr>
            <tr v-for="team in teams?.list" :key="team.id">
              <td>#{{ team.id }}</td>
              <td><strong>{{ team.campaignTitle }}</strong><small>{{ team.shopName }}</small></td>
              <td>{{ team.memberCount }}/{{ team.groupSize }} · {{ team.paidCount }}/{{ team.groupSize }}</td>
              <td><span class="status-pill" :class="team.problem ? 'status-warning' : 'status-up'">{{ team.statusText }}</span></td>
              <td>{{ copy.pending }} {{ team.pendingRefunds }} · {{ copy.failed }} {{ team.failedRefunds }}</td>
              <td>{{ team.missingCouponOrders ? `${copy.missing} ${team.missingCouponOrders}` : copy.normal }}</td>
              <td>{{ team.unreleasedInventoryOrders ? `${copy.unreleased} ${team.unreleasedInventoryOrders}` : copy.normal }}</td>
              <td>{{ formatDate(team.expireAt) }}</td>
              <td>
                <button type="button" class="table-action" :disabled="!canWrite || reconcilingId !== null" @click="reconcile(team)">
                  {{ reconcilingId === team.id ? copy.reconciling : copy.reconcile }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination-row">
        <button type="button" :disabled="page <= 1 || loading" @click="page--; load()">{{ copy.previous }}</button>
        <span>{{ copy.page(page) }}</span>
        <button type="button" :disabled="!teams?.hasMore || loading" @click="page++; load()">{{ copy.next }}</button>
      </div>
    </article>
  </section>
</template>

<style scoped>
.groupbuy-summary { grid-template-columns: repeat(6, minmax(0, 1fr)); }
.alert-list { display: grid; gap: .65rem; margin: 0; padding: 0; list-style: none; }
.alert-list li { display: flex; gap: .75rem; align-items: center; padding: .75rem 1rem; border-radius: .75rem; background: #fff7ed; }
.alert-list li.is-critical { background: #fef2f2; color: #991b1b; }
.groupbuy-toolbar { align-items: center; }
.filter-row { display: flex; gap: 1rem; align-items: center; }
.filter-row select { min-width: 10rem; }
td small { display: block; margin-top: .25rem; color: var(--muted-text); }
.status-warning { background: #fff7ed; color: #9a3412; }
.status-up { background: #ecfdf5; color: #047857; }
.pagination-row { display: flex; justify-content: flex-end; align-items: center; gap: .75rem; margin-top: 1rem; }
.terminal-refund-table { min-width: 1100px; }
.disposition-form { display: grid; gap: .5rem; min-width: 20rem; }
.disposition-form input, .disposition-form textarea { width: 100%; }
.disposition-actions { display: flex; flex-wrap: wrap; gap: .5rem; }
.table-action.is-danger { color: #991b1b; }
@media (max-width: 1100px) { .groupbuy-summary { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
@media (max-width: 700px) { .groupbuy-summary { grid-template-columns: repeat(2, minmax(0, 1fr)); } .groupbuy-toolbar { align-items: flex-start; } }
</style>
