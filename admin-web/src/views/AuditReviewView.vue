<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, PageResult } from '@/types/admin'

interface AuditFilters {
  status: string
  keyword: string
  page: number
  pageSize: number
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('audit:review:write'))

const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedTaskId = ref<number | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')

const filters = reactive<AuditFilters>({
  status: '0',
  keyword: '',
  page: 1,
  pageSize: 10,
})

const selectedTask = computed(() => {
  if (!pageState.value?.list.length) {
    return null
  }
  return pageState.value.list.find((item) => item.id === selectedTaskId.value) ?? pageState.value.list[0]
})

const canHandleSelected = computed(() => canWrite.value && selectedTask.value?.status === 0)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function taskStatusText(task: AdminAuditTask) {
  return strings.value.reviewAudit.statusText(task.status, task.statusText)
}

function taskActionLabel(taskId: number) {
  return selectedTaskId.value === taskId
    ? strings.value.reviewAudit.selected
    : strings.value.reviewAudit.view
}

async function loadTasks() {
  loading.value = true
  errorMessage.value = ''

  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 3,
      status: filters.status ? Number(filters.status) : undefined,
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })

    const exists = pageState.value.list.some((item) => item.id === selectedTaskId.value)
    selectedTaskId.value = exists ? selectedTaskId.value : (pageState.value.list[0]?.id ?? null)
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.reviewAudit.loadError)
  } finally {
    loading.value = false
  }
}

function selectTask(taskId: number) {
  selectedTaskId.value = taskId
  approveRemark.value = ''
  rejectReason.value = ''
  successMessage.value = ''
  errorMessage.value = ''
}

async function handlePass() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await passAuditTask(task.id, {
      remark: approveRemark.value.trim() || undefined,
    })
    successMessage.value = strings.value.reviewAudit.passed(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.reviewAudit.passError)
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  const reason = rejectReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.reviewAudit.rejectReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await rejectAuditTask(task.id, { reason })
    successMessage.value = strings.value.reviewAudit.rejected(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.reviewAudit.rejectError)
  } finally {
    acting.value = false
  }
}

function applyFilters() {
  filters.page = 1
  void loadTasks()
}

function goPrevPage() {
  if (!pageState.value || pageState.value.page <= 1) return
  filters.page -= 1
  void loadTasks()
}

function goNextPage() {
  if (!pageState.value?.hasMore) return
  filters.page += 1
  void loadTasks()
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedTaskId.value = null
    approveRemark.value = ''
    rejectReason.value = ''
    successMessage.value = ''
    errorMessage.value = ''
    void loadTasks()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.reviewAudit.eyebrow }}</p>
        <h1>{{ strings.reviewAudit.heading }}</h1>
        <p>{{ strings.reviewAudit.description(state.region) }}</p>
      </div>

      <div class="header-actions">
        <button type="button" class="secondary-button" @click="loadTasks">{{ strings.reviewAudit.refresh }}</button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.reviewAudit.listEyebrow }}</p>
            <h2>{{ strings.reviewAudit.listHeading }}</h2>
          </div>
          <span class="inline-note">{{ strings.reviewAudit.listSummary(pageState?.total ?? 0) }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.reviewAudit.filters.status }}</span>
            <select v-model="filters.status">
              <option value="">{{ strings.reviewAudit.statusOptions.all }}</option>
              <option value="0">{{ strings.reviewAudit.statusOptions.pending }}</option>
              <option value="1">{{ strings.reviewAudit.statusOptions.approved }}</option>
              <option value="2">{{ strings.reviewAudit.statusOptions.rejected }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.reviewAudit.filters.keyword }}</span>
            <input
              v-model="filters.keyword"
              name="review-keyword-filter"
              data-testid="review-keyword-filter"
              :placeholder="strings.reviewAudit.keywordPlaceholder"
            />
          </label>

          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyFilters">{{ strings.reviewAudit.applyFilters }}</button>
            <button type="button" class="ghost-button" @click="loadTasks">{{ strings.reviewAudit.resetRefresh }}</button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.reviewAudit.tableHeaders.task }}</th>
                <th>{{ strings.reviewAudit.tableHeaders.shop }}</th>
                <th>{{ strings.reviewAudit.tableHeaders.submitter }}</th>
                <th>{{ strings.reviewAudit.tableHeaders.status }}</th>
                <th>{{ strings.reviewAudit.tableHeaders.submittedAt }}</th>
                <th>{{ strings.reviewAudit.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="6" class="table-empty">{{ strings.reviewAudit.loading }}</td>
              </tr>
              <tr v-else-if="!pageState || pageState.list.length === 0">
                <td colspan="6" class="table-empty">{{ strings.reviewAudit.empty }}</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  <strong>#{{ task.id }}</strong>
                  <p>{{ strings.reviewAudit.taskLabel(task.bizId) }}</p>
                </td>
                <td>
                  <strong>{{ task.shopName || strings.reviewAudit.shopFallback }}</strong>
                  <p>{{ task.region }} · {{ strings.reviewAudit.taskTypeLabel }}</p>
                </td>
                <td>{{ task.submittedBy || strings.reviewAudit.submitterFallback }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="task.status === 0 ? 'status-pill--warn' : task.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                  >
                    {{ taskStatusText(task) }}
                  </span>
                </td>
                <td>{{ task.createdAt }}</td>
                <td class="table-actions">
                  <button type="button" class="table-action" @click="selectTask(task.id)">{{ taskActionLabel(task.id) }}</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
            {{ strings.reviewAudit.previousPage }}
          </button>
          <span>{{ strings.reviewAudit.page(pageState?.page ?? 1) }}</span>
          <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
            {{ strings.reviewAudit.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <div class="editor-header">
          <div>
            <p class="eyebrow">{{ strings.reviewAudit.editorEyebrow }}</p>
            <h2>{{ strings.reviewAudit.editorHeading(selectedTask?.id ?? null) }}</h2>
          </div>
          <span class="inline-note">{{ selectedTask ? taskStatusText(selectedTask) : strings.reviewAudit.editorStatusFallback }}</span>
        </div>

        <template v-if="selectedTask">
          <div class="meta-grid">
            <div>
              <span>{{ strings.reviewAudit.metaLabels.shop }}</span>
              <strong>{{ selectedTask.shopName || strings.reviewAudit.shopFallback }}</strong>
            </div>
            <div>
              <span>{{ strings.reviewAudit.metaLabels.submitter }}</span>
              <strong>{{ selectedTask.submittedBy || strings.reviewAudit.submitterFallback }}</strong>
            </div>
            <div>
              <span>{{ strings.reviewAudit.metaLabels.submittedAt }}</span>
              <strong>{{ selectedTask.createdAt }}</strong>
            </div>
            <div>
              <span>{{ strings.reviewAudit.metaLabels.updatedAt }}</span>
              <strong>{{ selectedTask.updatedAt || strings.reviewAudit.updatedAtFallback }}</strong>
            </div>
          </div>

          <div class="hint-card">
            <strong>{{ strings.reviewAudit.summaryLabel }}</strong>
            <p>{{ selectedTask.summary || strings.reviewAudit.summaryFallback }}</p>
          </div>

          <template v-if="canHandleSelected">
            <label class="field field--full">
              <span>{{ strings.reviewAudit.approveRemarkLabel }}</span>
              <textarea
                v-model="approveRemark"
                name="approve-remark"
                rows="4"
                spellcheck="false"
                :placeholder="strings.reviewAudit.approveRemarkPlaceholder"
              />
            </label>

            <label class="field field--full">
              <span>{{ strings.reviewAudit.rejectReasonLabel }}</span>
              <textarea
                v-model="rejectReason"
                name="reject-reason"
                rows="4"
                spellcheck="false"
                :placeholder="strings.reviewAudit.rejectReasonPlaceholder"
              />
            </label>

            <div class="form-actions">
              <button type="button" class="primary-button" :disabled="acting" @click="handlePass">
                {{ acting ? strings.reviewAudit.acting : strings.reviewAudit.approve }}
              </button>
              <button type="button" class="secondary-button" :disabled="acting" @click="handleReject">
                {{ acting ? strings.reviewAudit.acting : strings.reviewAudit.reject }}
              </button>
            </div>
          </template>
          <p v-else-if="!canWrite" class="inline-note">{{ strings.reviewAudit.readOnly }}</p>
          <p v-else class="inline-note">{{ strings.reviewAudit.handled }}</p>
        </template>

        <div v-else class="empty-state">{{ strings.reviewAudit.emptyState }}</div>
      </section>
    </div>
  </section>
</template>
