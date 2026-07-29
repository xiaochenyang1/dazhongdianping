<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('audit:post:write'))
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedTaskId = ref<number | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')
const filters = reactive({ status: '0', keyword: '', page: 1, pageSize: 10 })

const selectedTask = computed(
  () => pageState.value?.list.find((task) => task.id === selectedTaskId.value) ?? pageState.value?.list[0] ?? null,
)
const canHandleSelected = computed(() => canWrite.value && selectedTask.value?.status === 0)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function taskStatusText(task: AdminAuditTask) {
  return strings.value.postAudit.statusText(task.status, task.statusText)
}

function actionLabel(taskId: number) {
  return selectedTaskId.value === taskId
    ? strings.value.postAudit.selected
    : strings.value.postAudit.view
}

async function loadTasks() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 4,
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((task) => task.id === selectedTaskId.value)) {
      selectedTaskId.value = pageState.value.list[0]?.id ?? null
    }
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.postAudit.loadError)
  } finally {
    loading.value = false
  }
}

function selectTask(taskId: number) {
  selectedTaskId.value = taskId
  approveRemark.value = ''
  rejectReason.value = ''
  errorMessage.value = ''
  successMessage.value = ''
}

async function handlePass() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await passAuditTask(task.id, { remark: approveRemark.value.trim() || undefined })
    successMessage.value = strings.value.postAudit.passed(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.postAudit.passError)
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  const reason = rejectReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.postAudit.rejectReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await rejectAuditTask(task.id, { reason })
    successMessage.value = strings.value.postAudit.rejected(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.postAudit.rejectError)
  } finally {
    acting.value = false
  }
}

function applyFilters() {
  filters.page = 1
  void loadTasks()
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedTaskId.value = null
    void loadTasks()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.postAudit.eyebrow }}</p>
        <h1>{{ strings.postAudit.heading }}</h1>
        <p>{{ strings.postAudit.description(state.region) }}</p>
      </div>
      <button type="button" class="secondary-button" @click="loadTasks">{{ strings.postAudit.refresh }}</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.postAudit.listEyebrow }}</p>
            <h2>{{ strings.postAudit.listHeading }}</h2>
          </div>
          <span class="inline-note">{{ strings.postAudit.listSummary(pageState?.total ?? 0) }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.postAudit.filters.status }}</span>
            <select v-model="filters.status">
              <option value="">{{ strings.postAudit.statusOptions.all }}</option>
              <option value="0">{{ strings.postAudit.statusOptions.pending }}</option>
              <option value="1">{{ strings.postAudit.statusOptions.approved }}</option>
              <option value="2">{{ strings.postAudit.statusOptions.rejected }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.postAudit.filters.keyword }}</span>
            <input
              v-model="filters.keyword"
              name="post-keyword-filter"
              data-testid="post-keyword-filter"
              :placeholder="strings.postAudit.keywordPlaceholder"
            />
          </label>
          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyFilters">{{ strings.postAudit.applyFilters }}</button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.postAudit.tableHeaders.task }}</th>
                <th>{{ strings.postAudit.tableHeaders.author }}</th>
                <th>{{ strings.postAudit.tableHeaders.summary }}</th>
                <th>{{ strings.postAudit.tableHeaders.status }}</th>
                <th>{{ strings.postAudit.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="5" class="table-empty">{{ strings.postAudit.loading }}</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="5" class="table-empty">{{ strings.postAudit.empty }}</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  <strong>#{{ task.id }}</strong>
                  <p>{{ strings.postAudit.taskLabel(task.bizId) }}</p>
                </td>
                <td>{{ task.submittedBy || strings.postAudit.authorFallback }}</td>
                <td>{{ task.summary || strings.postAudit.summaryFallback }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="task.status === 0 ? 'status-pill--warn' : task.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                  >
                    {{ taskStatusText(task) }}
                  </span>
                </td>
                <td><button type="button" class="table-action" @click="selectTask(task.id)">{{ actionLabel(task.id) }}</button></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button type="button" class="ghost-button" :disabled="filters.page <= 1" @click="filters.page--; loadTasks()">
            {{ strings.postAudit.previousPage }}
          </button>
          <span>{{ strings.postAudit.page(filters.page) }}</span>
          <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="filters.page++; loadTasks()">
            {{ strings.postAudit.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <template v-if="selectedTask">
          <div class="editor-header">
            <div>
              <p class="eyebrow">{{ strings.postAudit.editorEyebrow }}</p>
              <h2>{{ strings.postAudit.editorHeading(selectedTask.id) }}</h2>
            </div>
            <span class="inline-note">{{ taskStatusText(selectedTask) }}</span>
          </div>
          <div class="meta-grid">
            <div>
              <span>{{ strings.postAudit.metaLabels.post }}</span>
              <strong>#{{ selectedTask.bizId }}</strong>
            </div>
            <div>
              <span>{{ strings.postAudit.metaLabels.author }}</span>
              <strong>{{ selectedTask.submittedBy || strings.postAudit.authorFallback }}</strong>
            </div>
            <div>
              <span>{{ strings.postAudit.metaLabels.region }}</span>
              <strong>{{ selectedTask.region }}</strong>
            </div>
            <div>
              <span>{{ strings.postAudit.metaLabels.submittedAt }}</span>
              <strong>{{ selectedTask.createdAt }}</strong>
            </div>
          </div>
          <div class="hint-card">
            <strong>{{ strings.postAudit.detailLabel }}</strong>
            <p>{{ selectedTask.summary || strings.postAudit.summaryFallback }}</p>
          </div>
          <template v-if="canHandleSelected">
            <label class="field field--full">
              <span>{{ strings.postAudit.approveRemarkLabel }}</span>
              <textarea
                v-model="approveRemark"
                name="approve-remark"
                rows="4"
                :placeholder="strings.postAudit.approveRemarkPlaceholder"
              />
            </label>
            <label class="field field--full">
              <span>{{ strings.postAudit.rejectReasonLabel }}</span>
              <textarea
                v-model="rejectReason"
                name="reject-reason"
                rows="4"
                :placeholder="strings.postAudit.rejectReasonPlaceholder"
              />
            </label>
            <div class="form-actions">
              <button type="button" class="primary-button" :disabled="acting" @click="handlePass">{{ strings.postAudit.approve }}</button>
              <button type="button" class="secondary-button" :disabled="acting" @click="handleReject">{{ strings.postAudit.reject }}</button>
            </div>
          </template>
          <p v-else-if="!canWrite" class="inline-note">{{ strings.postAudit.readOnly }}</p>
          <p v-else class="inline-note">{{ strings.postAudit.handled }}</p>
        </template>
        <div v-else class="empty-state">{{ strings.postAudit.emptyState }}</div>
      </section>
    </div>
  </section>
</template>
