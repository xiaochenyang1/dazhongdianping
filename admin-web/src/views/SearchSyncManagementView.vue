<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  getAdminSearchSyncOverview,
  listAdminSearchSyncTasks,
  rebuildAdminSearchIndex,
  retryAdminSearchSyncTask,
  retryFailedAdminSearchSyncTasks,
} from '@/services/admin'
import type {
  AdminSearchSyncOverview,
  AdminSearchSyncState,
  AdminSearchSyncTask,
  PageResult,
} from '@/types/admin'

const PAGE_SIZE = 20

const zhCopy = {
  eyebrow: '搜索基础设施',
  heading: '搜索索引同步',
  description: '查看 MySQL 到 Elasticsearch 的待处理任务、失败原因和恢复状态。',
  refresh: '刷新',
  retryFailed: '重试异常任务',
  rebuild: '全量重建索引',
  provider: '当前搜索提供方',
  index: '索引名称',
  enabled: '增量同步运行中',
  disabled: '增量同步已暂停',
  disabledNote: '当前 APP_SEARCH_PROVIDER 不是 elasticsearch，任务不会被投递。',
  metrics: {
    total: '任务总数',
    pending: '待处理',
    processing: '处理中',
    retrying: '有失败记录',
    stale: '处理超时',
    ready: '可立即投递',
  },
  listEyebrow: '任务队列',
  listHeading: '按异常优先级查看同步积压',
  listSummary: (total: number) => `当前范围共 ${total} 条任务`,
  keyword: '门店',
  keywordPlaceholder: '门店名称或门店 ID',
  state: '状态',
  states: {
    all: '全部状态',
    pending: '待处理',
    processing: '处理中',
    retrying: '等待重试',
    stale: '处理超时',
  },
  query: '查询',
  headers: {
    shop: '门店',
    state: '状态',
    progress: '版本 / 尝试',
    schedule: '调度时间',
    error: '最近错误',
    updated: '更新时间',
    actions: '操作',
  },
  loading: '同步任务加载中...',
  empty: '当前筛选条件下没有同步任务。',
  shopFallback: '未知门店',
  cityFallback: '未知城市',
  version: (version: number) => `版本 ${version}`,
  attempts: (attempts: number) => `尝试 ${attempts} 次`,
  nextRetry: '下次投递',
  lockedAt: '认领时间',
  noSchedule: '--',
  noError: '尚无错误',
  retry: '立即重试',
  previous: '上一页',
  next: '下一页',
  page: (page: number) => `第 ${page} 页`,
  retryConfirm: (shopName: string) => `确认把「${shopName}」的同步任务立即重新排队？`,
  retryFailedConfirm: '确认立即重新排队当前区域内所有失败或超时的同步任务？',
  rebuildConfirm: '全量重建会覆盖当前 Elasticsearch 门店索引，确认继续？',
  retrySuccess: '任务已重新排队。',
  retryFailedSuccess: (count: number) => `已重新排队 ${count} 条异常任务。`,
  rebuildSuccess: (count: number) => `全量索引重建完成，共写入 ${count} 家门店。`,
  requestFailed: '搜索同步操作失败。',
  readOnly: '当前账号只有查看权限。',
}

const enCopy = {
  eyebrow: 'Search infrastructure',
  heading: 'Search Index Sync',
  description: 'Inspect MySQL-to-Elasticsearch tasks, failure reasons, and recovery state.',
  refresh: 'Refresh',
  retryFailed: 'Retry failed tasks',
  rebuild: 'Rebuild full index',
  provider: 'Search provider',
  index: 'Index name',
  enabled: 'Incremental sync running',
  disabled: 'Incremental sync paused',
  disabledNote: 'APP_SEARCH_PROVIDER is not elasticsearch, so queued tasks will not be dispatched.',
  metrics: {
    total: 'Total tasks',
    pending: 'Pending',
    processing: 'Processing',
    retrying: 'Previously failed',
    stale: 'Timed out',
    ready: 'Ready now',
  },
  listEyebrow: 'Task queue',
  listHeading: 'Inspect the queue with unhealthy tasks first',
  listSummary: (total: number) => `${total} tasks in the current scope`,
  keyword: 'Shop',
  keywordPlaceholder: 'Shop name or ID',
  state: 'State',
  states: {
    all: 'All states',
    pending: 'Pending',
    processing: 'Processing',
    retrying: 'Waiting to retry',
    stale: 'Timed out',
  },
  query: 'Search',
  headers: {
    shop: 'Shop',
    state: 'State',
    progress: 'Version / attempts',
    schedule: 'Schedule',
    error: 'Latest error',
    updated: 'Updated',
    actions: 'Actions',
  },
  loading: 'Loading sync tasks...',
  empty: 'No sync tasks match the current filters.',
  shopFallback: 'Unknown shop',
  cityFallback: 'Unknown city',
  version: (version: number) => `Version ${version}`,
  attempts: (attempts: number) => `${attempts} attempts`,
  nextRetry: 'Next dispatch',
  lockedAt: 'Claimed at',
  noSchedule: '--',
  noError: 'No error recorded',
  retry: 'Retry now',
  previous: 'Previous',
  next: 'Next',
  page: (page: number) => `Page ${page}`,
  retryConfirm: (shopName: string) => `Queue the sync task for "${shopName}" immediately?`,
  retryFailedConfirm: 'Queue every failed or timed-out task in the current region immediately?',
  rebuildConfirm: 'A full rebuild replaces the current Elasticsearch shop index. Continue?',
  retrySuccess: 'The task has been queued again.',
  retryFailedSuccess: (count: number) => `${count} unhealthy tasks were queued again.`,
  rebuildSuccess: (count: number) => `Full index rebuild completed with ${count} shops.`,
  requestFailed: 'Search sync operation failed.',
  readOnly: 'This account has read-only access.',
}

const { state } = useAdminSession()
const copy = computed(() => state.region === 'EU' ? enCopy : zhCopy)
const canWrite = computed(() => state.permissions.includes('data:search_index:write'))

const overview = ref<AdminSearchSyncOverview | null>(null)
const tasksPage = ref<PageResult<AdminSearchSyncTask> | null>(null)
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let requestId = 0

const filters = reactive<{
  keyword: string
  state: '' | AdminSearchSyncState
  page: number
}>({
  keyword: '',
  state: '',
  page: 1,
})

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : copy.value.requestFailed
}

function formatDate(value: string | null | undefined) {
  return value ? value.replace('T', ' ') : copy.value.noSchedule
}

function stateLabel(task: AdminSearchSyncTask) {
  return copy.value.states[task.state]
}

function stateClass(task: AdminSearchSyncTask) {
  if (task.state === 'stale') return 'status-pill--warn'
  if (task.state === 'retrying') return 'status-pill--warn'
  if (task.state === 'processing') return 'status-pill--good'
  return 'status-pill--muted'
}

async function load() {
  const currentRequestId = ++requestId
  loading.value = true
  errorMessage.value = ''
  try {
    const [nextOverview, nextTasks] = await Promise.all([
      getAdminSearchSyncOverview(),
      listAdminSearchSyncTasks({
        keyword: filters.keyword.trim() || undefined,
        state: filters.state || undefined,
        page: filters.page,
        pageSize: PAGE_SIZE,
      }),
    ])
    if (currentRequestId !== requestId) return
    overview.value = nextOverview
    tasksPage.value = nextTasks
  } catch (error) {
    if (currentRequestId === requestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

function applyFilters() {
  filters.page = 1
  void load()
}

function goPage(page: number) {
  filters.page = Math.max(1, page)
  void load()
}

async function retryTask(task: AdminSearchSyncTask) {
  if (!canWrite.value || !overview.value?.enabled || acting.value) return
  if (!window.confirm(copy.value.retryConfirm(task.shopName || `#${task.shopId}`))) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await retryAdminSearchSyncTask(task.shopId)
    successMessage.value = copy.value.retrySuccess
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    acting.value = false
  }
}

async function retryFailedTasks() {
  if (!canWrite.value || !overview.value?.enabled || acting.value) return
  if (!window.confirm(copy.value.retryFailedConfirm)) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const result = await retryFailedAdminSearchSyncTasks()
    successMessage.value = copy.value.retryFailedSuccess(result.retried)
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    acting.value = false
  }
}

async function rebuildIndex() {
  if (!canWrite.value || !overview.value?.enabled || acting.value) return
  if (!window.confirm(copy.value.rebuildConfirm)) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const result = await rebuildAdminSearchIndex()
    successMessage.value = copy.value.rebuildSuccess(result.indexed)
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.keyword = ''
    filters.state = ''
    filters.page = 1
    successMessage.value = ''
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ copy.eyebrow }}</p>
        <h1>{{ copy.heading }}</h1>
        <p>{{ copy.description }}</p>
      </div>
      <div class="header-actions">
        <button type="button" class="ghost-button" :disabled="loading || acting" @click="load">
          {{ copy.refresh }}
        </button>
        <button
          v-if="canWrite"
          type="button"
          class="secondary-button"
          :disabled="acting || !overview?.enabled || !(overview.retrying || overview.stale)"
          @click="retryFailedTasks"
        >
          {{ copy.retryFailed }}
        </button>
        <button
          v-if="canWrite"
          type="button"
          class="primary-button"
          :disabled="acting || !overview?.enabled"
          @click="rebuildIndex"
        >
          {{ copy.rebuild }}
        </button>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="!canWrite" class="feedback">{{ copy.readOnly }}</p>
    <p v-if="overview && !overview.enabled" class="feedback is-error">{{ copy.disabledNote }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ copy.provider }}</p>
          <h2>{{ overview?.provider ?? '--' }}</h2>
        </div>
        <div class="sync-provider-meta">
          <span>{{ copy.index }}: <strong>{{ overview?.indexName ?? '--' }}</strong></span>
          <span class="status-pill" :class="overview?.enabled ? 'status-pill--good' : 'status-pill--warn'">
            {{ overview?.enabled ? copy.enabled : copy.disabled }}
          </span>
        </div>
      </div>

      <div class="stat-grid">
        <article class="stat-card"><p>{{ copy.metrics.total }}</p><strong>{{ overview?.total ?? 0 }}</strong></article>
        <article class="stat-card"><p>{{ copy.metrics.pending }}</p><strong>{{ overview?.pending ?? 0 }}</strong></article>
        <article class="stat-card"><p>{{ copy.metrics.processing }}</p><strong>{{ overview?.processing ?? 0 }}</strong></article>
        <article class="stat-card"><p>{{ copy.metrics.retrying }}</p><strong>{{ overview?.retrying ?? 0 }}</strong></article>
        <article class="stat-card"><p>{{ copy.metrics.stale }}</p><strong>{{ overview?.stale ?? 0 }}</strong></article>
        <article class="stat-card"><p>{{ copy.metrics.ready }}</p><strong>{{ overview?.ready ?? 0 }}</strong></article>
      </div>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ copy.listEyebrow }}</p>
          <h2>{{ copy.listHeading }}</h2>
        </div>
        <span class="inline-note">{{ copy.listSummary(tasksPage?.total ?? 0) }}</span>
      </div>

      <form class="toolbar-grid toolbar-grid--filters" @submit.prevent="applyFilters">
        <label class="field">
          <span>{{ copy.keyword }}</span>
          <input
            v-model="filters.keyword"
            name="search-sync-keyword"
            type="search"
            maxlength="100"
            :placeholder="copy.keywordPlaceholder"
          />
        </label>
        <label class="field">
          <span>{{ copy.state }}</span>
          <select v-model="filters.state" name="search-sync-state">
            <option value="">{{ copy.states.all }}</option>
            <option value="pending">{{ copy.states.pending }}</option>
            <option value="processing">{{ copy.states.processing }}</option>
            <option value="retrying">{{ copy.states.retrying }}</option>
            <option value="stale">{{ copy.states.stale }}</option>
          </select>
        </label>
        <div class="toolbar-actions">
          <button type="submit" class="primary-button" :disabled="loading">{{ copy.query }}</button>
        </div>
      </form>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ copy.headers.shop }}</th>
              <th>{{ copy.headers.state }}</th>
              <th>{{ copy.headers.progress }}</th>
              <th>{{ copy.headers.schedule }}</th>
              <th>{{ copy.headers.error }}</th>
              <th>{{ copy.headers.updated }}</th>
              <th v-if="canWrite">{{ copy.headers.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 7 : 6" class="table-empty">{{ copy.loading }}</td>
            </tr>
            <tr v-else-if="!tasksPage?.list.length">
              <td :colspan="canWrite ? 7 : 6" class="table-empty">{{ copy.empty }}</td>
            </tr>
            <tr v-for="task in tasksPage?.list" :key="`${task.shopId}-${task.version}`">
              <td>
                <strong>{{ task.shopName || copy.shopFallback }}</strong>
                <p>#{{ task.shopId }} · {{ task.cityName || copy.cityFallback }}</p>
              </td>
              <td><span class="status-pill" :class="stateClass(task)">{{ stateLabel(task) }}</span></td>
              <td>
                <strong>{{ copy.version(task.version) }}</strong>
                <p>{{ copy.attempts(task.attemptCount) }}</p>
              </td>
              <td>
                <span>{{ copy.nextRetry }}: {{ formatDate(task.nextRetryAt) }}</span>
                <p>{{ copy.lockedAt }}: {{ formatDate(task.lockedAt) }}</p>
              </td>
              <td class="sync-error-cell">
                <code class="code-box">{{ task.lastError || copy.noError }}</code>
              </td>
              <td>{{ formatDate(task.updatedAt) }}</td>
              <td v-if="canWrite">
                <button
                  type="button"
                  class="table-action"
                  :disabled="acting || !overview?.enabled"
                  @click="retryTask(task)"
                >
                  {{ copy.retry }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button" :disabled="filters.page <= 1 || loading" @click="goPage(filters.page - 1)">
          {{ copy.previous }}
        </button>
        <span>{{ copy.page(filters.page) }}</span>
        <button type="button" class="ghost-button" :disabled="!tasksPage?.hasMore || loading" @click="goPage(filters.page + 1)">
          {{ copy.next }}
        </button>
      </div>
    </section>
  </section>
</template>
