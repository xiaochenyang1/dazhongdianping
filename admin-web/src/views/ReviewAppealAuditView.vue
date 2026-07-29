<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const loading = ref(false)
const acting = ref(false)
const error = ref('')
const success = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedId = ref<number | null>(null)
const passRemark = ref('')
const rejectReason = ref('')
const filters = reactive({ status: '0', keyword: '', page: 1, pageSize: 10 })

const selected = computed(
  () => pageState.value?.list.find((item) => item.id === selectedId.value) ?? pageState.value?.list[0] ?? null,
)
const canWrite = computed(() => state.permissions.includes('audit:review_appeal:write'))
const canHandleSelected = computed(() => canWrite.value && selected.value?.status === 0)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function taskStatusText(task: AdminAuditTask) {
  return strings.value.reviewAppealAudit.statusText(task.status, task.statusText)
}

function actionLabel(taskId: number) {
  return selectedId.value === taskId
    ? strings.value.reviewAppealAudit.selected
    : strings.value.reviewAppealAudit.view
}

function selectTask(taskId: number) {
  selectedId.value = taskId
  passRemark.value = ''
  rejectReason.value = ''
  error.value = ''
  success.value = ''
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 6,
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((item) => item.id === selectedId.value)) {
      selectedId.value = pageState.value.list[0]?.id ?? null
    }
  } catch (cause) {
    error.value = messageOf(cause, strings.value.reviewAppealAudit.loadError)
  } finally {
    loading.value = false
  }
}

async function pass() {
  const task = selected.value
  if (!canHandleSelected.value || !task) return

  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await passAuditTask(task.id, { remark: passRemark.value.trim() || undefined })
    success.value = strings.value.reviewAppealAudit.passed(task.id)
    passRemark.value = ''
    rejectReason.value = ''
    await load()
  } catch (cause) {
    error.value = messageOf(cause, strings.value.reviewAppealAudit.actionError)
  } finally {
    acting.value = false
  }
}

async function reject() {
  const task = selected.value
  if (!canHandleSelected.value || !task) return

  const reason = rejectReason.value.trim()
  if (!reason) {
    error.value = strings.value.reviewAppealAudit.rejectReasonRequired
    return
  }

  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await rejectAuditTask(task.id, { reason })
    success.value = strings.value.reviewAppealAudit.rejected(task.id)
    passRemark.value = ''
    rejectReason.value = ''
    await load()
  } catch (cause) {
    error.value = messageOf(cause, strings.value.reviewAppealAudit.actionError)
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedId.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.reviewAppealAudit.eyebrow }}</p>
        <h1>{{ strings.reviewAppealAudit.heading }}</h1>
        <p>{{ strings.reviewAppealAudit.description(state.region) }}</p>
      </div>
      <button class="secondary-button" @click="load">{{ strings.reviewAppealAudit.refresh }}</button>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.reviewAppealAudit.filters.status }}</span>
            <select v-model="filters.status" @change="filters.page = 1; load()">
              <option value="">{{ strings.reviewAppealAudit.statusOptions.all }}</option>
              <option value="0">{{ strings.reviewAppealAudit.statusOptions.pending }}</option>
              <option value="1">{{ strings.reviewAppealAudit.statusOptions.approved }}</option>
              <option value="2">{{ strings.reviewAppealAudit.statusOptions.rejected }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.reviewAppealAudit.filters.keyword }}</span>
            <input
              v-model="filters.keyword"
              name="review-appeal-keyword-filter"
              data-testid="review-appeal-keyword-filter"
              :placeholder="strings.reviewAppealAudit.keywordPlaceholder"
              @keyup.enter="filters.page = 1; load()"
            />
          </label>
          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="filters.page = 1; load()">
              {{ strings.reviewAppealAudit.applyFilters }}
            </button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.reviewAppealAudit.tableHeaders.task }}</th>
                <th>{{ strings.reviewAppealAudit.tableHeaders.shop }}</th>
                <th>{{ strings.reviewAppealAudit.tableHeaders.summary }}</th>
                <th>{{ strings.reviewAppealAudit.tableHeaders.status }}</th>
                <th>{{ strings.reviewAppealAudit.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="5" class="table-empty">{{ strings.reviewAppealAudit.loading }}</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="5" class="table-empty">{{ strings.reviewAppealAudit.empty }}</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  #{{ task.id }}
                  <p>{{ strings.reviewAppealAudit.taskLabel(task.bizId) }}</p>
                </td>
                <td>{{ task.shopName || strings.reviewAppealAudit.shopFallback }}</td>
                <td>{{ task.summary || strings.reviewAppealAudit.summaryFallback }}</td>
                <td>{{ taskStatusText(task) }}</td>
                <td>
                  <button class="table-action" @click="selectTask(task.id)">{{ actionLabel(task.id) }}</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button class="ghost-button" :disabled="filters.page <= 1" @click="filters.page--; load()">
            {{ strings.reviewAppealAudit.previousPage }}
          </button>
          <span>{{ strings.reviewAppealAudit.pageSummary(filters.page, pageState?.total ?? 0) }}</span>
          <button class="ghost-button" :disabled="!pageState?.hasMore" @click="filters.page++; load()">
            {{ strings.reviewAppealAudit.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <template v-if="selected">
          <div class="editor-header">
            <div>
              <p class="eyebrow">{{ strings.reviewAppealAudit.editorEyebrow }}</p>
              <h2>{{ strings.reviewAppealAudit.editorHeading(selected.id) }}</h2>
            </div>
            <span class="inline-note">{{ taskStatusText(selected) }}</span>
          </div>

          <div class="hint-card">
            <strong>{{ strings.reviewAppealAudit.editorSummaryLabel }}</strong>
            <p>{{ selected.summary || strings.reviewAppealAudit.summaryFallback }}</p>
          </div>

          <template v-if="canHandleSelected">
            <label class="field field--full">
              <span>{{ strings.reviewAppealAudit.passRemarkLabel }}</span>
              <textarea v-model="passRemark" name="review-appeal-pass-remark" rows="4" />
            </label>
            <label class="field field--full">
              <span>{{ strings.reviewAppealAudit.rejectReasonLabel }}</span>
              <textarea v-model="rejectReason" name="review-appeal-reject-reason" rows="4" />
            </label>
            <div class="form-actions">
              <button
                type="button"
                class="primary-button"
                data-testid="review-appeal-pass"
                :disabled="acting"
                @click="pass"
              >
                {{ strings.reviewAppealAudit.pass }}
              </button>
              <button
                type="button"
                class="secondary-button"
                data-testid="review-appeal-reject"
                :disabled="acting"
                @click="reject"
              >
                {{ strings.reviewAppealAudit.reject }}
              </button>
            </div>
          </template>
          <p v-else-if="!canWrite" class="inline-note">{{ strings.reviewAppealAudit.readOnly }}</p>
          <p v-else class="inline-note">{{ strings.reviewAppealAudit.handled }}</p>
        </template>

        <div v-else class="empty-state">{{ strings.reviewAppealAudit.emptyState }}</div>
      </section>
    </div>
  </section>
</template>
