<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAdminPrivacyTasks } from '@/services/admin'
import type { AdminPrivacyTask, PageResult } from '@/types/admin'

const pageSize = 20
const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const loading = ref(false)
const errorMessage = ref('')
const pageState = ref<PageResult<AdminPrivacyTask> | null>(null)
const filters = reactive({
  userId: '',
  taskType: '',
  status: '',
  keyword: '',
  page: 1,
})

const statusOptions = computed(() => {
  if (filters.taskType === '2') {
    return [
      { value: '', label: strings.value.privacyTasks.statusOptions.all },
      { value: '0', label: strings.value.privacyTasks.statusOptions.deletePendingConfirm },
      { value: '1', label: strings.value.privacyTasks.statusOptions.deleteCoolingOff },
      { value: '2', label: strings.value.privacyTasks.statusOptions.deleteProcessing },
      { value: '3', label: strings.value.privacyTasks.statusOptions.deleteCompleted },
      { value: '4', label: strings.value.privacyTasks.statusOptions.deleteCancelled },
      { value: '5', label: strings.value.privacyTasks.statusOptions.deleteRejected },
    ]
  }
  if (filters.taskType === '1') {
    return [
      { value: '', label: strings.value.privacyTasks.statusOptions.all },
      { value: '0', label: strings.value.privacyTasks.statusOptions.exportPending },
      { value: '1', label: strings.value.privacyTasks.statusOptions.exportProcessing },
      { value: '2', label: strings.value.privacyTasks.statusOptions.exportReady },
      { value: '3', label: strings.value.privacyTasks.statusOptions.exportExpired },
      { value: '4', label: strings.value.privacyTasks.statusOptions.exportFailed },
      { value: '5', label: strings.value.privacyTasks.statusOptions.exportCancelled },
    ]
  }
  return [
    { value: '', label: strings.value.privacyTasks.statusOptions.all },
    { value: '0', label: strings.value.privacyTasks.statusOptions.mixed0 },
    { value: '1', label: strings.value.privacyTasks.statusOptions.mixed1 },
    { value: '2', label: strings.value.privacyTasks.statusOptions.mixed2 },
    { value: '3', label: strings.value.privacyTasks.statusOptions.mixed3 },
    { value: '4', label: strings.value.privacyTasks.statusOptions.mixed4 },
    { value: '5', label: strings.value.privacyTasks.statusOptions.mixed5 },
  ]
})

function normalizeNumber(value: string) {
  const normalized = value.trim()
  if (!normalized) {
    return undefined
  }
  const parsed = Number(normalized)
  return Number.isFinite(parsed) ? parsed : undefined
}

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized ? normalized : undefined
}

function taskSummary(task: AdminPrivacyTask) {
  if (task.taskType === 1) {
    const modules = task.modules.join(' / ')
    return modules || strings.value.privacyTasks.allModules
  }
  return task.reason || strings.value.privacyTasks.noReason
}

function taskDeadline(task: AdminPrivacyTask) {
  if (task.taskType === 1) {
    return task.expireAt || strings.value.privacyTasks.deadlineFallback
  }
  return task.coolingOffExpireAt
    || task.completedAt
    || task.cancelledAt
    || strings.value.privacyTasks.deadlineFallback
}

function taskTypeText(task: AdminPrivacyTask) {
  return strings.value.privacyTasks.taskTypeText(task.taskType, task.taskTypeText)
}

function taskStatusText(task: AdminPrivacyTask) {
  return strings.value.privacyTasks.taskStatusText(task.taskType, task.status, task.statusText)
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminPrivacyTasks({
      userId: normalizeNumber(filters.userId),
      taskType: normalizeNumber(filters.taskType),
      status: normalizeNumber(filters.status),
      keyword: normalizeText(filters.keyword),
      page: filters.page,
      pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.privacyTasks.loadError
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

function handleTaskTypeChange() {
  filters.status = ''
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.privacyTasks.eyebrow }}</p>
        <h1>{{ strings.privacyTasks.heading }}</h1>
        <p>{{ strings.privacyTasks.description }}</p>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? strings.privacyTasks.metaLoading : strings.privacyTasks.metaSummary(pageState?.total ?? 0) }}</span>
        <span>{{ strings.privacyTasks.metaDescription }}</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.privacyTasks.labels.userId }}</span>
          <input
            name="privacy-task-user-id"
            v-model="filters.userId"
            inputmode="numeric"
            :placeholder="strings.privacyTasks.placeholders.userId"
          />
        </label>
        <label class="field">
          <span>{{ strings.privacyTasks.labels.taskType }}</span>
          <select name="privacy-task-type" v-model="filters.taskType" @change="handleTaskTypeChange">
            <option value="">{{ strings.privacyTasks.taskTypeOptions.all }}</option>
            <option value="1">{{ strings.privacyTasks.taskTypeOptions.export }}</option>
            <option value="2">{{ strings.privacyTasks.taskTypeOptions.delete }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.privacyTasks.labels.status }}</span>
          <select name="privacy-task-status" v-model="filters.status">
            <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.privacyTasks.labels.keyword }}</span>
          <input
            name="privacy-task-keyword"
            v-model="filters.keyword"
            :placeholder="strings.privacyTasks.placeholders.keyword"
          />
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">{{ strings.privacyTasks.applyFilters }}</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.privacyTasks.tableHeaders.time }}</th>
              <th>{{ strings.privacyTasks.tableHeaders.task }}</th>
              <th>{{ strings.privacyTasks.tableHeaders.user }}</th>
              <th>{{ strings.privacyTasks.tableHeaders.status }}</th>
              <th>{{ strings.privacyTasks.tableHeaders.keyInfo }}</th>
              <th>{{ strings.privacyTasks.tableHeaders.deadline }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="table-empty">{{ strings.privacyTasks.loadingRow }}</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="6" class="table-empty">{{ strings.privacyTasks.empty }}</td>
            </tr>
            <tr v-for="task in pageState?.list" :key="`${task.taskType}-${task.id}`">
              <td class="numeric-cell">{{ task.createdAt }}</td>
              <td>
                <strong>{{ taskTypeText(task) }}</strong>
                <p class="code-box">#{{ task.id }}</p>
              </td>
              <td>
                <strong>{{ task.userNickname || '--' }}</strong>
                <p class="code-box">{{ task.account || `user:${task.userId}` }}</p>
              </td>
              <td>
                <span class="status-pill" :class="task.status === 2 && task.taskType === 1 ? 'status-pill--good' : task.status >= 4 ? 'status-pill--muted' : 'status-pill--warn'">
                  {{ taskStatusText(task) }}
                </span>
              </td>
              <td>
                <p>{{ taskSummary(task) }}</p>
                <p class="inline-note" v-if="task.taskType === 1">
                  {{ task.fileName || strings.privacyTasks.exportFilePending }}
                  <span v-if="task.failReason"> · {{ task.failReason }}</span>
                </p>
                <p class="inline-note" v-else>
                  {{ strings.privacyTasks.verificationMethod(task.verifyType || strings.privacyTasks.deadlineFallback) }}
                </p>
              </td>
              <td class="numeric-cell">{{ taskDeadline(task) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="filters.page <= 1" @click="goPage(filters.page - 1)">
          {{ strings.privacyTasks.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.privacyTasks.page(filters.page) }}</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!pageState?.hasMore" @click="goPage(filters.page + 1)">
          {{ strings.privacyTasks.nextPage }}
        </button>
      </div>
    </article>
  </section>
</template>
