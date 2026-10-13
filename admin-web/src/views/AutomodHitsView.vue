<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { claimAuditTask, getModerationQueueMetrics, listAuditTasks, passAuditTask, rejectAuditTask, releaseAuditTask } from '@/services/admin'
import { fetchAutomodHits, type OpsAutomodHit } from '@/services/ops'
import type { AdminAuditQueueMetric, AdminAuditTask, PageResult } from '@/types/admin'

const auditPageSize = 20
const { state } = useAdminSession()
const hits = ref<OpsAutomodHit[]>([])
const tasks = ref<PageResult<AdminAuditTask> | null>(null)
const metrics = ref<AdminAuditQueueMetric[]>([])
const mode = ref<'queue' | 'hits'>('queue')
const decision = ref<number | ''>('')
const bizType = ref<number | null>(10)
const assignmentFilter = ref<'all' | 'unclaimed' | 'mine' | 'others'>('all')
const overdueOnly = ref(false)
const pageNumber = ref(1)
const selectedTaskId = ref<number | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')
const errorMessage = ref('')
const successMessage = ref('')
const loading = ref(false)
const acting = ref(false)
const canWrite = computed(() => state.permissions.includes('audit:automod:write'))
const currentAdminId = computed(() => state.profile?.id ?? null)
const overdueMetrics = computed(() => metrics.value.filter((metric) => metric.overdueCount > 0))
const overdueCount = computed(() => overdueMetrics.value.reduce((total, metric) => total + metric.overdueCount, 0))
const selectedTask = computed(
  () => tasks.value?.list.find((task) => task.id === selectedTaskId.value) ?? tasks.value?.list[0] ?? null,
)
const selectedTaskClaimActive = computed(() => selectedTask.value !== null && claimIsActive(selectedTask.value))
const selectedTaskIsClaimOwner = computed(() => selectedTask.value?.claimedByAdminId === currentAdminId.value)
const canDecideSelectedTask = computed(() => canWrite.value && selectedTaskClaimActive.value && selectedTaskIsClaimOwner.value)

function claimIsActive(task: AdminAuditTask) {
  return task.claimedByAdminId !== null
    && task.claimExpiresAt !== null
    && parseServerDateTime(task.claimExpiresAt) > Date.now()
}

async function loadHits() {
  errorMessage.value = ''
  try {
    const page = await fetchAutomodHits({
      decision: decision.value === '' ? undefined : Number(decision.value),
      page: 1,
      pageSize: 20,
    })
    hits.value = page.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

async function loadTasks() {
  if (loading.value) return
  loading.value = true
  errorMessage.value = ''
  try {
    const [taskPage, queueMetrics] = await Promise.all([
      listAuditTasks({
        region: state.region,
        bizType: bizType.value ?? undefined,
        status: 0,
        assignmentFilter: assignmentFilter.value,
        overdueOnly: overdueOnly.value,
        page: pageNumber.value,
        pageSize: auditPageSize,
      }),
      getModerationQueueMetrics(),
    ])
    tasks.value = taskPage
    metrics.value = queueMetrics
    if (!tasks.value.list.some((task) => task.id === selectedTaskId.value)) {
      selectedTaskId.value = tasks.value.list[0]?.id ?? null
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核队列加载失败'
  } finally {
    loading.value = false
  }
}

function selectBizType(value: number) {
  bizType.value = value
  pageNumber.value = 1
  selectedTaskId.value = null
  void loadTasks()
}

function handleOverdueFilterChange() {
  if (!overdueOnly.value && bizType.value === null) bizType.value = 10
  pageNumber.value = 1
  selectedTaskId.value = null
  void loadTasks()
}

function formatDuration(seconds: number | null) {
  if (seconds === null) return '暂无记录'
  const safeSeconds = Math.max(0, Math.floor(seconds))
  const days = Math.floor(safeSeconds / 86400)
  const hours = Math.floor((safeSeconds % 86400) / 3600)
  const minutes = Math.floor((safeSeconds % 3600) / 60)
  if (days > 0) return `${days}天${hours}小时`
  if (hours > 0) return `${hours}小时${minutes}分`
  if (minutes > 0) return `${minutes}分`
  return `${safeSeconds}秒`
}

function formatOldestWait(oldestPendingAt: string | null) {
  if (!oldestPendingAt) return '无待审'
  const timestamp = parseServerDateTime(oldestPendingAt)
  if (Number.isNaN(timestamp)) return oldestPendingAt
  return formatDuration(Math.floor((Date.now() - timestamp) / 1000))
}

function parseServerDateTime(value: string) {
  return Date.parse(`${value.replace(' ', 'T')}+08:00`)
}

function assignmentText(task: AdminAuditTask) {
  if (!task.claimedByAdminId) return '未认领'
  if (!claimIsActive(task)) return `${task.claimedByAdminName || '审核员'} · 已过期`
  if (task.claimedByAdminId === currentAdminId.value) return `我负责 · ${task.claimExpiresAt}`
  return `${task.claimedByAdminName || '其他审核员'} · ${task.claimExpiresAt}`
}

function taskIsOverdue(task: AdminAuditTask) {
  const metric = metrics.value.find((item) => item.bizType === task.bizType)
  return metric !== undefined
    && Date.now() - parseServerDateTime(task.createdAt) >= metric.slaMinutes * 60_000
}

function openOverdueQueue() {
  if (overdueCount.value === 0) return
  bizType.value = null
  overdueOnly.value = true
  pageNumber.value = 1
  selectedTaskId.value = null
  void loadTasks()
}

async function handleClaim() {
  const task = selectedTask.value
  if (!canWrite.value || !task || acting.value) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await claimAuditTask(task.id)
    successMessage.value = `任务 #${task.id} 已认领，租期 15 分钟`
    await loadTasks()
  } catch (error) {
    const message = error instanceof Error ? error.message : '认领失败'
    await loadTasks()
    errorMessage.value = message
  } finally {
    acting.value = false
  }
}

async function handleRelease() {
  const task = selectedTask.value
  if (!canWrite.value || !task || !selectedTaskIsClaimOwner.value || acting.value) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await releaseAuditTask(task.id)
    successMessage.value = `任务 #${task.id} 已释放`
    await loadTasks()
  } catch (error) {
    const message = error instanceof Error ? error.message : '释放失败'
    await loadTasks()
    errorMessage.value = message
  } finally {
    acting.value = false
  }
}

async function handlePass() {
  const task = selectedTask.value
  if (!canWrite.value || !task || acting.value) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await passAuditTask(task.id, { remark: approveRemark.value.trim() || undefined })
    successMessage.value = `任务 #${task.id} 已通过`
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核操作失败'
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  const task = selectedTask.value
  const reason = rejectReason.value.trim()
  if (!canWrite.value || !task || acting.value) return
  if (!reason) {
    errorMessage.value = '请填写驳回原因'
    return
  }
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await rejectAuditTask(task.id, { reason })
    successMessage.value = `任务 #${task.id} 已驳回`
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核操作失败'
  } finally {
    acting.value = false
  }
}

watch(() => state.region, () => {
  pageNumber.value = 1
  selectedTaskId.value = null
  void loadTasks()
  void loadHits()
}, { immediate: true })

let refreshTimer: number | undefined
onMounted(() => {
  refreshTimer = window.setInterval(() => {
    if (mode.value === 'queue') void loadTasks()
  }, 60_000)
})
onUnmounted(() => {
  if (refreshTimer !== undefined) window.clearInterval(refreshTimer)
})
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">内容治理</p>
        <h1>机审与人工复核</h1>
      </div>
      <div class="form-actions">
        <button type="button" :class="mode === 'queue' ? 'primary-button' : 'secondary-button'" @click="mode = 'queue'; loadTasks()">待复审</button>
        <button type="button" :class="mode === 'hits' ? 'primary-button' : 'secondary-button'" @click="mode = 'hits'; loadHits()">命中记录</button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <template v-if="mode === 'queue'">
      <div v-if="overdueCount > 0" class="sla-alert" role="status" aria-live="polite">
        <div><strong>{{ overdueCount }} 条待复审内容已超过 SLA</strong><p>请优先处理已超时队列。</p></div>
        <button type="button" class="secondary-button" @click="openOverdueQueue">查看超时队列</button>
      </div>
      <section class="content-card">
        <div class="section-headline">
          <h2>审核积压与处理时长</h2>
          <button type="button" class="secondary-button" :disabled="loading" @click="loadTasks">刷新</button>
        </div>
        <div class="table-shell">
          <table class="data-table">
            <thead><tr><th>内容类型</th><th>待审数量</th><th>SLA</th><th>超时数量</th><th>最久等待</th><th>历史处理量</th><th>平均处理时长</th></tr></thead>
            <tbody>
              <tr v-for="metric in metrics" :key="metric.bizType">
                <td><button type="button" class="table-action" @click="selectBizType(metric.bizType)">{{ metric.bizTypeText }}</button></td>
                <td>{{ metric.pendingCount }}</td>
                <td>{{ formatDuration(metric.slaMinutes * 60) }}</td>
                <td :class="{ 'sla-overdue-count': metric.overdueCount > 0 }">{{ metric.overdueCount }}</td>
                <td>{{ formatOldestWait(metric.oldestPendingAt) }}</td>
                <td>{{ metric.processedCount }}</td>
                <td>{{ formatDuration(metric.averageProcessingSeconds) }}</td>
              </tr>
              <tr v-if="!metrics.length"><td colspan="7" class="table-empty">当前账号没有可查看的人工复核队列</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <div class="queue-filters">
        <label class="field">
          <span>内容类型</span>
          <select v-model.number="bizType" @change="pageNumber = 1; selectedTaskId = null; loadTasks()">
            <option v-if="overdueOnly" :value="null">全部类型</option>
            <option :value="10">点评评论</option>
            <option :value="11">帖子评论</option>
            <option :value="12">门店提问</option>
            <option :value="13">门店回答</option>
            <option :value="14">私信</option>
          </select>
        </label>
        <label class="field">
          <span>负责人</span>
          <select v-model="assignmentFilter" @change="pageNumber = 1; selectedTaskId = null; loadTasks()">
            <option value="all">全部负责人</option>
            <option value="unclaimed">未认领或已过期</option>
            <option value="mine">我负责的</option>
            <option value="others">他人负责的</option>
          </select>
        </label>
        <label class="field">
          <span>SLA 状态</span>
          <select v-model="overdueOnly" @change="handleOverdueFilterChange">
            <option :value="false">全部状态</option>
            <option :value="true">仅显示已超时</option>
          </select>
        </label>
      </div>

      <div class="two-column-layout">
        <section class="content-card">
          <div class="section-headline">
            <h2>{{ tasks?.total ?? 0 }} 条{{ overdueOnly ? '超时' : '' }}待复审</h2>
            <button type="button" class="secondary-button" :disabled="loading" @click="loadTasks">刷新</button>
          </div>
          <div class="table-shell">
            <table class="data-table">
              <thead><tr><th>任务</th><th>内容类型</th><th>提交人</th><th>内容</th><th>提交时间</th><th>负责人</th><th>SLA 状态</th><th>操作</th></tr></thead>
              <tbody>
                <tr v-if="loading"><td colspan="8" class="table-empty">加载中</td></tr>
                <tr v-else-if="!tasks?.list.length"><td colspan="8" class="table-empty">{{ overdueOnly ? '当前筛选下没有超时任务' : '当前类型没有待复审内容' }}</td></tr>
                <tr v-for="task in tasks?.list" :key="task.id">
                  <td><strong>#{{ task.id }}</strong><p>内容 #{{ task.bizId }}</p></td>
                  <td>{{ task.bizTypeText }}</td>
                  <td>{{ task.submittedBy || '未知用户' }}</td>
                  <td class="automod-summary">{{ task.summary }}</td>
                  <td>{{ task.createdAt }}</td>
                  <td>{{ assignmentText(task) }}</td>
                  <td><span v-if="taskIsOverdue(task)" class="sla-overdue-label">已超时</span><span v-else>处理中</span></td>
                  <td><button type="button" class="table-action" @click="selectedTaskId = task.id">查看</button></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="pager">
            <button type="button" class="ghost-button" :disabled="pageNumber <= 1 || loading" @click="pageNumber--; loadTasks()">上一页</button>
            <span>第 {{ pageNumber }} 页</span>
            <button type="button" class="ghost-button" :disabled="!tasks?.hasMore || loading" @click="pageNumber++; loadTasks()">下一页</button>
          </div>
        </section>

        <section class="content-card editor-card">
          <template v-if="selectedTask">
            <div class="section-headline">
              <div><p class="eyebrow">待复审内容</p><h2>任务 #{{ selectedTask.id }}</h2></div>
              <span class="inline-note">{{ selectedTask.region }} · {{ selectedTask.submittedBy }}</span>
            </div>
            <div class="hint-card"><strong>{{ selectedTask.shopName || selectedTask.bizTypeText }}</strong><p>{{ selectedTask.summary }}</p></div>
            <p class="inline-note">机审原因：{{ selectedTask.remark || '关键词规则要求人工复核' }}</p>
            <div v-if="canWrite" class="claim-toolbar">
              <p v-if="selectedTaskClaimActive && selectedTaskIsClaimOwner" class="inline-note">
                当前由你负责，认领到期 {{ selectedTask.claimExpiresAt }}
              </p>
              <p v-else-if="selectedTaskClaimActive" class="inline-note">
                当前由 {{ selectedTask.claimedByAdminName || '其他审核员' }} 负责，认领到期 {{ selectedTask.claimExpiresAt }}
              </p>
              <p v-else class="inline-note">当前任务尚未被有效认领</p>
              <div class="form-actions">
                <button
                  v-if="!selectedTaskClaimActive || !selectedTaskIsClaimOwner"
                  type="button"
                  class="secondary-button"
                  :disabled="acting || (selectedTaskClaimActive && !selectedTaskIsClaimOwner)"
                  @click="handleClaim"
                >{{ selectedTask.claimedByAdminId ? '接管任务' : '认领任务' }}</button>
                <template v-else>
                  <button type="button" class="secondary-button" :disabled="acting" @click="handleClaim">续期 15 分钟</button>
                  <button type="button" class="secondary-button" :disabled="acting" @click="handleRelease">释放认领</button>
                </template>
              </div>
            </div>
            <template v-if="canDecideSelectedTask">
              <label class="field field--full"><span>通过备注</span><textarea v-model="approveRemark" rows="2" /></label>
              <label class="field field--full"><span>驳回原因</span><textarea v-model="rejectReason" rows="2" /></label>
              <div class="form-actions">
                <button type="button" class="primary-button" :disabled="acting" @click="handlePass">通过并公开</button>
                <button type="button" class="secondary-button" :disabled="acting" @click="handleReject">驳回并保持隐藏</button>
              </div>
            </template>
            <p v-else-if="canWrite && selectedTaskClaimActive" class="inline-note">当前认领有效，租期结束后可接管</p>
            <p v-else-if="canWrite" class="inline-note">认领该任务后即可提交审核结论</p>
            <p v-else class="inline-note">当前账号只有查看权限</p>
          </template>
          <div v-else class="empty-state">选择一条待复审内容</div>
        </section>
      </div>
    </template>

    <section v-else class="content-card">
      <div class="toolbar">
        <select v-model="decision" @change="loadHits">
          <option value="">全部结果</option>
          <option :value="3">拦截</option>
          <option :value="2">待复审</option>
          <option :value="1">通过</option>
        </select>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead><tr><th>业务</th><th>用户</th><th>决定</th><th>原因</th><th>时间</th></tr></thead>
          <tbody>
            <tr v-for="hit in hits" :key="hit.id">
              <td>{{ hit.bizType }} #{{ hit.bizId }}</td><td>{{ hit.userId }}</td><td>{{ hit.decision }}</td><td>{{ hit.reason }}</td><td>{{ hit.createdAt }}</td>
            </tr>
            <tr v-if="!hits.length"><td colspan="5" class="table-empty">没有命中记录</td></tr>
          </tbody>
        </table>
      </div>
    </section>
  </section>
</template>

<style scoped>
.sla-alert {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  border: 1px solid #d97706;
  border-left-width: 4px;
  background: #fff7ed;
  color: #7c2d12;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.sla-alert p {
  margin: 4px 0 0;
}

.sla-overdue-count,
.sla-overdue-label {
  color: #b42318;
  font-weight: 700;
}

.automod-summary {
  max-width: 360px;
  white-space: normal;
  overflow-wrap: anywhere;
}

.queue-filters,
.claim-toolbar {
  display: flex;
  align-items: end;
  gap: 16px;
  flex-wrap: wrap;
}

.queue-filters .field {
  width: min(280px, 100%);
}

.claim-toolbar {
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.claim-toolbar p {
  margin: 0;
}

@media (max-width: 640px) {
  .sla-alert {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
