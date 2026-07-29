<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAdminReports, resolveAdminReport } from '@/services/admin'
import type { AdminReport, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('audit:report:write'))

const loading = ref(false)
const acting = ref(false)
const error = ref('')
const success = ref('')
const pageState = ref<PageResult<AdminReport> | null>(null)
const selectedId = ref<number | null>(null)
const selectedType = ref<string>('')
const remark = ref('')

const filters = reactive({
  reportType: '',
  status: '0',
  keyword: '',
  page: 1,
  pageSize: 10,
})

const selected = computed(() => {
  if (!pageState.value) return null
  return (
    pageState.value.list.find(
      (item) => item.id === selectedId.value && item.reportType === selectedType.value,
    ) ??
    pageState.value.list[0] ??
    null
  )
})

function reportTypeText(report: AdminReport) {
  return strings.value.reportManagement.reportTypeText(report.reportType, report.reportTypeText)
}

function reportStatusText(report: AdminReport) {
  return strings.value.reportManagement.statusText(report.status, report.statusText)
}

function reportTargetTypeText(report: AdminReport) {
  return strings.value.reportManagement.targetTypeText(
    report.reportType,
    report.targetType,
    report.targetTypeText,
  )
}

function reportTargetStatusText(report: AdminReport) {
  return (
    strings.value.reportManagement.targetStatusText(
      report.reportType,
      report.targetAuditStatus,
      report.targetStatusText,
    ) || strings.value.reportManagement.targetStatusFallback
  )
}

function reportSummary(report: AdminReport) {
  return report.targetSummary || strings.value.reportManagement.summaryFallback
}

function reportAuthor(report: AdminReport) {
  return report.targetAuthorName || strings.value.reportManagement.authorFallback
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    pageState.value = await listAdminReports({
      reportType: filters.reportType || undefined,
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    const first = pageState.value.list[0]
    if (
      !pageState.value.list.some(
        (item) => item.id === selectedId.value && item.reportType === selectedType.value,
      )
    ) {
      selectedId.value = first?.id ?? null
      selectedType.value = first?.reportType ?? ''
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.reportManagement.loadError
  } finally {
    loading.value = false
  }
}

function select(item: AdminReport) {
  selectedId.value = item.id
  selectedType.value = item.reportType
  remark.value = ''
  success.value = ''
  error.value = ''
}

function applyFilters() {
  filters.page = 1
  void load()
}

async function resolve(action: 'dismiss' | 'hide') {
  const current = selected.value
  if (!current || !canWrite.value || current.status !== 0) return

  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await resolveAdminReport(current.reportType, current.id, {
      action,
      remark: remark.value.trim() || undefined,
    })
    success.value =
      action === 'hide'
        ? strings.value.reportManagement.upheldMessage(current.id, current.reportType !== 'message')
        : strings.value.reportManagement.dismissedMessage(current.id)
    remark.value = ''
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.reportManagement.actionError
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedId.value = null
    selectedType.value = ''
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.reportManagement.eyebrow }}</p>
        <h1>{{ strings.reportManagement.heading }}</h1>
        <p>{{ strings.reportManagement.description(state.region) }}</p>
      </div>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <section class="content-card">
      <div class="toolbar">
        <label>
          <span class="muted">{{ strings.reportManagement.filters.reportType }}</span>
          <select
            v-model="filters.reportType"
            data-testid="report-type-filter"
            @change="applyFilters"
          >
            <option value="">{{ strings.reportManagement.reportTypeOptions.all }}</option>
            <option value="review">{{ strings.reportManagement.reportTypeOptions.review }}</option>
            <option value="post">{{ strings.reportManagement.reportTypeOptions.post }}</option>
            <option value="message">{{ strings.reportManagement.reportTypeOptions.message }}</option>
          </select>
        </label>
        <label>
          <span class="muted">{{ strings.reportManagement.filters.status }}</span>
          <select
            v-model="filters.status"
            data-testid="report-status-filter"
            @change="applyFilters"
          >
            <option value="">{{ strings.reportManagement.statusOptions.all }}</option>
            <option value="0">{{ strings.reportManagement.statusOptions.pending }}</option>
            <option value="1">{{ strings.reportManagement.statusOptions.upheld }}</option>
            <option value="2">{{ strings.reportManagement.statusOptions.dismissed }}</option>
          </select>
        </label>
        <label>
          <span class="muted">{{ strings.reportManagement.filters.keyword }}</span>
          <input
            v-model="filters.keyword"
            data-testid="report-keyword-filter"
            type="search"
            :placeholder="strings.reportManagement.keywordPlaceholder"
            @keyup.enter="applyFilters"
          />
        </label>
        <button type="button" class="secondary-button" @click="applyFilters">
          {{ strings.reportManagement.query }}
        </button>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.reportManagement.tableHeaders.type }}</th>
              <th>{{ strings.reportManagement.tableHeaders.summary }}</th>
              <th>{{ strings.reportManagement.tableHeaders.reporter }}</th>
              <th>{{ strings.reportManagement.tableHeaders.reason }}</th>
              <th>{{ strings.reportManagement.tableHeaders.status }}</th>
              <th>{{ strings.reportManagement.tableHeaders.time }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="table-empty">{{ strings.reportManagement.loading }}</td>
            </tr>
            <tr v-else-if="!pageState?.list.length">
              <td colspan="6" class="table-empty">{{ strings.reportManagement.empty }}</td>
            </tr>
            <tr
              v-for="item in pageState?.list || []"
              :key="`${item.reportType}-${item.id}`"
              :class="{ 'is-selected': selected?.id === item.id && selected?.reportType === item.reportType }"
              :data-testid="`report-row-${item.reportType}-${item.id}`"
              @click="select(item)"
            >
              <td>{{ reportTypeText(item) }}</td>
              <td>
                <strong>#{{ item.targetId }}</strong>
                <div class="muted">{{ reportSummary(item) }}</div>
              </td>
              <td>{{ item.reporterUserName || item.reporterUserId }}</td>
              <td>{{ item.reason }}</td>
              <td>
                <span class="status-pill">{{ reportStatusText(item) }}</span>
              </td>
              <td>{{ item.createdAt }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="selected" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.reportManagement.detailEyebrow }}</p>
          <h2>{{ strings.reportManagement.detailHeading(reportTypeText(selected), selected.id) }}</h2>
        </div>
        <span class="status-pill">{{ reportStatusText(selected) }}</span>
      </div>
      <div class="detail-grid">
        <p>
          <strong>{{ strings.reportManagement.detailLabels.target }}</strong>
          : #{{ selected.targetId }} {{ reportTargetTypeText(selected) }}
        </p>
        <p>
          <strong>{{ strings.reportManagement.detailLabels.author }}</strong>
          : {{ reportAuthor(selected) }}
        </p>
        <p>
          <strong>{{ strings.reportManagement.detailLabels.targetStatus }}</strong>
          : {{ reportTargetStatusText(selected) }}
        </p>
        <p>
          <strong>{{ strings.reportManagement.detailLabels.reporter }}</strong>
          : {{ selected.reporterUserName || selected.reporterUserId }}
        </p>
        <p>
          <strong>{{ strings.reportManagement.detailLabels.reason }}</strong>
          : {{ selected.reason }}
        </p>
        <p>
          <strong>{{ strings.reportManagement.detailLabels.summary }}</strong>
          : {{ reportSummary(selected) }}
        </p>
        <p>
          <strong>{{ strings.reportManagement.detailLabels.time }}</strong>
          : {{ selected.createdAt }}
        </p>
      </div>

      <div
        v-if="canWrite && selected.status === 0"
        class="form-actions"
        style="margin-top: 16px; gap: 12px; display: flex; flex-wrap: wrap"
      >
        <input
          v-model="remark"
          data-testid="report-resolve-remark"
          type="text"
          maxlength="255"
          :placeholder="strings.reportManagement.remarkPlaceholder"
          style="min-width: 240px; flex: 1"
        />
        <button
          type="button"
          class="secondary-button"
          data-testid="report-dismiss"
          :disabled="acting"
          @click="resolve('dismiss')"
        >
          {{ strings.reportManagement.dismissAction }}
        </button>
        <button
          type="button"
          class="primary-button"
          data-testid="report-hide"
          :disabled="acting"
          @click="resolve('hide')"
        >
          {{ strings.reportManagement.upholdAction }}
        </button>
      </div>
      <p v-else-if="!canWrite" class="muted">{{ strings.reportManagement.readOnly }}</p>
      <p v-else class="muted">{{ strings.reportManagement.handled }}</p>
    </section>
  </section>
</template>
