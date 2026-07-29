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
const canWrite = computed(() => state.permissions.includes('audit:user_appeal:write'))
const canHandleSelected = computed(() => canWrite.value && selected.value?.status === 0)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function taskStatusText(task: AdminAuditTask) {
  return strings.value.userAppealAudit.statusText(task.status, task.statusText)
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
      bizType: 8,
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((item) => item.id === selectedId.value)) {
      selectedId.value = pageState.value.list[0]?.id ?? null
    }
  } catch (cause) {
    error.value = messageOf(cause, strings.value.userAppealAudit.loadError)
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
    success.value = strings.value.userAppealAudit.passed(task.id)
    passRemark.value = ''
    rejectReason.value = ''
    await load()
  } catch (cause) {
    error.value = messageOf(cause, strings.value.userAppealAudit.actionError)
  } finally {
    acting.value = false
  }
}

async function reject() {
  const task = selected.value
  if (!canHandleSelected.value || !task) return

  const reason = rejectReason.value.trim()
  if (!reason) {
    error.value = strings.value.userAppealAudit.rejectReasonRequired
    return
  }

  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await rejectAuditTask(task.id, { reason })
    success.value = strings.value.userAppealAudit.rejected(task.id)
    passRemark.value = ''
    rejectReason.value = ''
    await load()
  } catch (cause) {
    error.value = messageOf(cause, strings.value.userAppealAudit.actionError)
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
        <p class="eyebrow">{{ strings.userAppealAudit.eyebrow }}</p>
        <h1>{{ strings.userAppealAudit.heading }}</h1>
        <p>{{ strings.userAppealAudit.description(state.region) }}</p>
      </div>
      <button class="secondary-button" @click="load">{{ strings.userAppealAudit.refresh }}</button>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.userAppealAudit.filters.status }}</span>
            <select v-model="filters.status" @change="filters.page = 1; load()">
              <option value="">{{ strings.userAppealAudit.statusOptions.all }}</option>
              <option value="0">{{ strings.userAppealAudit.statusOptions.pending }}</option>
              <option value="1">{{ strings.userAppealAudit.statusOptions.approved }}</option>
              <option value="2">{{ strings.userAppealAudit.statusOptions.rejected }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.userAppealAudit.filters.keyword }}</span>
            <input
              v-model="filters.keyword"
              name="user-appeal-keyword-filter"
              data-testid="user-appeal-keyword-filter"
              :placeholder="strings.userAppealAudit.keywordPlaceholder"
              @keyup.enter="filters.page = 1; load()"
            />
          </label>
          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="filters.page = 1; load()">
              {{ strings.userAppealAudit.applyFilters }}
            </button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.userAppealAudit.tableHeaders.task }}</th>
                <th>{{ strings.userAppealAudit.tableHeaders.user }}</th>
                <th>{{ strings.userAppealAudit.tableHeaders.reason }}</th>
                <th>{{ strings.userAppealAudit.tableHeaders.status }}</th>
                <th>{{ strings.userAppealAudit.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="5" class="table-empty">{{ strings.userAppealAudit.loading }}</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="5" class="table-empty">{{ strings.userAppealAudit.empty }}</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  #{{ task.id }}
                  <p>{{ strings.userAppealAudit.taskLabel(task.bizId) }}</p>
                </td>
                <td>{{ task.submittedBy || strings.userAppealAudit.userFallback }}</td>
                <td>{{ task.summary || strings.userAppealAudit.reasonFallback }}</td>
                <td>{{ taskStatusText(task) }}</td>
                <td><button class="table-action" @click="selectTask(task.id)">{{ strings.userAppealAudit.view }}</button></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button class="ghost-button" :disabled="filters.page <= 1" @click="filters.page--; load()">
            {{ strings.userAppealAudit.previousPage }}
          </button>
          <span>{{ strings.userAppealAudit.pageSummary(filters.page, pageState?.total ?? 0) }}</span>
          <button class="ghost-button" :disabled="!pageState?.hasMore" @click="filters.page++; load()">
            {{ strings.userAppealAudit.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <template v-if="selected">
          <div class="editor-header">
            <div>
              <p class="eyebrow">{{ strings.userAppealAudit.editorEyebrow }}</p>
              <h2>{{ strings.userAppealAudit.editorHeading(selected.id) }}</h2>
            </div>
            <span class="inline-note">{{ taskStatusText(selected) }}</span>
          </div>

          <div class="hint-card">
            <strong>{{ strings.userAppealAudit.detailLabels.user }}</strong>
            <p>{{ selected.submittedBy || strings.userAppealAudit.userFallback }}</p>
            <strong>{{ strings.userAppealAudit.detailLabels.reason }}</strong>
            <p>{{ selected.summary || strings.userAppealAudit.reasonFallback }}</p>
          </div>

          <template v-if="canHandleSelected">
            <label class="field field--full">
              <span>{{ strings.userAppealAudit.passRemarkLabel }}</span>
              <textarea v-model="passRemark" name="pass-remark" rows="4" />
            </label>
            <label class="field field--full">
              <span>{{ strings.userAppealAudit.rejectReasonLabel }}</span>
              <textarea v-model="rejectReason" name="reject-reason" rows="4" />
            </label>
            <div class="form-actions">
              <button class="primary-button" :disabled="acting" @click="pass">{{ strings.userAppealAudit.pass }}</button>
              <button class="secondary-button" :disabled="acting" @click="reject">{{ strings.userAppealAudit.reject }}</button>
            </div>
          </template>
          <p v-else-if="!canWrite" class="inline-note">{{ strings.userAppealAudit.readOnly }}</p>
          <p v-else class="inline-note">{{ strings.userAppealAudit.handled }}</p>
        </template>

        <div v-else class="empty-state">{{ strings.userAppealAudit.emptyState }}</div>
      </section>
    </div>
  </section>
</template>
