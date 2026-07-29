<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { getAdminDealDetail, listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, AdminDealDetail, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const loading = ref(false)
const detailLoading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedTaskId = ref<number | null>(null)
const dealDetail = ref<AdminDealDetail | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')
const filters = reactive({ status: '0', keyword: '', page: 1, pageSize: 10 })
const canWrite = computed(() => state.permissions.includes('audit:deal:write'))

const selectedTask = computed(
  () =>
    pageState.value?.list.find((task) => task.id === selectedTaskId.value) ??
    pageState.value?.list[0] ??
    null,
)
const canHandleSelected = computed(() => canWrite.value && selectedTask.value?.status === 0)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function taskStatusText(task: AdminAuditTask) {
  return strings.value.dealAudit.statusText(task.status, task.statusText)
}

function merchantLabel(task: AdminAuditTask) {
  return task.submittedBy || strings.value.dealAudit.merchantFallback
}

function shopLabel(task: AdminAuditTask) {
  return task.shopName || strings.value.dealAudit.shopFallback(task.shopId)
}

function titleLabel(task: AdminAuditTask) {
  return task.summary || strings.value.dealAudit.titleFallback
}

function taskActionLabel(taskId: number) {
  return selectedTaskId.value === taskId
    ? strings.value.dealAudit.selected
    : strings.value.dealAudit.view
}

async function loadDealDetail(dealId: number) {
  detailLoading.value = true
  dealDetail.value = null
  try {
    dealDetail.value = await getAdminDealDetail(dealId)
  } catch (cause) {
    dealDetail.value = null
    errorMessage.value = messageOf(cause, strings.value.dealAudit.detailLoadError)
  } finally {
    detailLoading.value = false
  }
}

async function loadTasks() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 2,
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((task) => task.id === selectedTaskId.value)) {
      selectedTaskId.value = pageState.value.list[0]?.id ?? null
    }
    if (selectedTaskId.value != null) {
      const selected = pageState.value.list.find((task) => task.id === selectedTaskId.value)
      if (selected) {
        await loadDealDetail(selected.bizId)
      }
    } else {
      dealDetail.value = null
    }
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.dealAudit.loadError)
  } finally {
    loading.value = false
  }
}

async function selectTask(taskId: number) {
  selectedTaskId.value = taskId
  approveRemark.value = ''
  rejectReason.value = ''
  errorMessage.value = ''
  successMessage.value = ''
  const selected = pageState.value?.list.find((task) => task.id === taskId)
  if (selected) {
    await loadDealDetail(selected.bizId)
  }
}

async function handlePass() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await passAuditTask(task.id, { remark: approveRemark.value.trim() || undefined })
    successMessage.value = strings.value.dealAudit.passed(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.dealAudit.passError)
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  const reason = rejectReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.dealAudit.rejectReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await rejectAuditTask(task.id, { reason })
    successMessage.value = strings.value.dealAudit.rejected(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.dealAudit.rejectError)
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
    dealDetail.value = null
    void loadTasks()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.dealAudit.eyebrow }}</p>
        <h1>{{ strings.dealAudit.heading }}</h1>
        <p>{{ strings.dealAudit.description(state.region) }}</p>
      </div>
      <button type="button" class="secondary-button" @click="loadTasks">{{ strings.dealAudit.refresh }}</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.dealAudit.listEyebrow }}</p>
            <h2>{{ strings.dealAudit.listHeading }}</h2>
          </div>
          <span class="inline-note">{{ strings.dealAudit.listSummary(pageState?.total ?? 0) }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.dealAudit.filters.status }}</span>
            <select v-model="filters.status" name="deal-status-filter">
              <option value="">{{ strings.dealAudit.statusOptions.all }}</option>
              <option value="0">{{ strings.dealAudit.statusOptions.pending }}</option>
              <option value="1">{{ strings.dealAudit.statusOptions.approved }}</option>
              <option value="2">{{ strings.dealAudit.statusOptions.rejected }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.dealAudit.filters.keyword }}</span>
            <input
              v-model="filters.keyword"
              name="deal-keyword-filter"
              data-testid="deal-keyword-filter"
              :placeholder="strings.dealAudit.keywordPlaceholder"
            />
          </label>
          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyFilters">{{ strings.dealAudit.applyFilters }}</button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.dealAudit.tableHeaders.task }}</th>
                <th>{{ strings.dealAudit.tableHeaders.merchant }}</th>
                <th>{{ strings.dealAudit.tableHeaders.shop }}</th>
                <th>{{ strings.dealAudit.tableHeaders.title }}</th>
                <th>{{ strings.dealAudit.tableHeaders.status }}</th>
                <th>{{ strings.dealAudit.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="6" class="table-empty">{{ strings.dealAudit.loading }}</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="6" class="table-empty">{{ strings.dealAudit.empty }}</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  <strong>#{{ task.id }}</strong>
                  <p>{{ strings.dealAudit.taskLabel(task.bizId) }}</p>
                </td>
                <td>{{ merchantLabel(task) }}</td>
                <td>
                  <strong>{{ shopLabel(task) }}</strong>
                  <p v-if="task.shopId">{{ strings.dealAudit.shopIdLabel(task.shopId) }}</p>
                </td>
                <td>{{ titleLabel(task) }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="task.status === 0 ? 'status-pill--warn' : task.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                  >
                    {{ taskStatusText(task) }}
                  </span>
                </td>
                <td>
                  <button type="button" class="table-action" @click="selectTask(task.id)">
                    {{ taskActionLabel(task.id) }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button
            type="button"
            class="ghost-button"
            :disabled="filters.page <= 1"
            @click="filters.page--; loadTasks()"
          >
            {{ strings.dealAudit.previousPage }}
          </button>
          <span>{{ strings.dealAudit.page(filters.page) }}</span>
          <button
            type="button"
            class="ghost-button"
            :disabled="!pageState?.hasMore"
            @click="filters.page++; loadTasks()"
          >
            {{ strings.dealAudit.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <template v-if="selectedTask">
          <div class="editor-header">
            <div>
              <p class="eyebrow">{{ strings.dealAudit.editorEyebrow }}</p>
              <h2>{{ strings.dealAudit.editorHeading(selectedTask.id) }}</h2>
            </div>
            <span class="inline-note">{{ taskStatusText(selectedTask) }}</span>
          </div>

          <div class="meta-grid">
            <div>
              <span>{{ strings.dealAudit.metaLabels.deal }}</span>
              <strong>#{{ selectedTask.bizId }}</strong>
            </div>
            <div>
              <span>{{ strings.dealAudit.metaLabels.merchant }}</span>
              <strong>{{ merchantLabel(selectedTask) }}</strong>
            </div>
            <div>
              <span>{{ strings.dealAudit.metaLabels.shop }}</span>
              <strong>{{ shopLabel(selectedTask) }}</strong>
            </div>
            <div>
              <span>{{ strings.dealAudit.metaLabels.region }}</span>
              <strong>{{ selectedTask.region }}</strong>
            </div>
            <div>
              <span>{{ strings.dealAudit.metaLabels.submittedAt }}</span>
              <strong>{{ selectedTask.createdAt }}</strong>
            </div>
            <div>
              <span>{{ strings.dealAudit.metaLabels.bizType }}</span>
              <strong>{{ selectedTask.bizTypeText }}</strong>
            </div>
          </div>
          <div class="hint-card">
            <strong>{{ strings.dealAudit.tableHeaders.title }}</strong>
            <p>{{ titleLabel(selectedTask) }}</p>
          </div>

          <div v-if="detailLoading" class="inline-note">{{ strings.dealAudit.detailLoading }}</div>
          <template v-else-if="dealDetail">
            <div class="meta-grid">
              <div>
                <span>{{ strings.dealAudit.detailLabels.price }}</span>
                <strong>{{ dealDetail.price }} {{ dealDetail.currency }}</strong>
              </div>
              <div>
                <span>{{ strings.dealAudit.detailLabels.originalPrice }}</span>
                <strong>{{ dealDetail.originalPrice }} {{ dealDetail.currency }}</strong>
              </div>
              <div>
                <span>{{ strings.dealAudit.detailLabels.stock }}</span>
                <strong>{{ dealDetail.stock }}</strong>
              </div>
              <div>
                <span>{{ strings.dealAudit.detailLabels.validPeriod }}</span>
                <strong>{{ dealDetail.validStart || strings.dealAudit.unlimited }} ~ {{ dealDetail.validEnd || strings.dealAudit.unlimited }}</strong>
              </div>
            </div>
            <div class="hint-card">
              <strong>{{ strings.dealAudit.detailLabels.rules }}</strong>
              <p>{{ dealDetail.rules || strings.dealAudit.noRules }}</p>
            </div>
            <div class="hint-card">
              <strong>{{ strings.dealAudit.detailLabels.items }}</strong>
              <div class="table-shell">
                <table class="data-table">
                  <thead>
                    <tr>
                      <th>{{ strings.dealAudit.itemHeaders.name }}</th>
                      <th>{{ strings.dealAudit.itemHeaders.quantity }}</th>
                      <th>{{ strings.dealAudit.itemHeaders.price }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(item, index) in dealDetail.items || []" :key="`${item.name}-${index}`">
                      <td>{{ item.name }}</td>
                      <td>{{ item.quantity }}</td>
                      <td>{{ item.price }}</td>
                    </tr>
                    <tr v-if="!(dealDetail.items && dealDetail.items.length)">
                      <td colspan="3" class="table-empty">{{ strings.dealAudit.itemEmpty }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div v-if="dealDetail.coverImage" class="application-photos">
              <a :href="dealDetail.coverImage" target="_blank" rel="noreferrer">
                <img :src="dealDetail.coverImage" :alt="strings.dealAudit.detailLabels.coverAlt" />
              </a>
            </div>
          </template>

          <template v-if="canHandleSelected">
            <label class="field field--full">
              <span>{{ strings.dealAudit.approveRemarkLabel }}</span>
              <textarea
                v-model="approveRemark"
                name="approve-remark"
                rows="4"
                :placeholder="strings.dealAudit.approveRemarkPlaceholder"
              />
            </label>
            <label class="field field--full">
              <span>{{ strings.dealAudit.rejectReasonLabel }}</span>
              <textarea
                v-model="rejectReason"
                name="reject-reason"
                rows="4"
                :placeholder="strings.dealAudit.rejectReasonPlaceholder"
              />
            </label>
            <div class="form-actions">
              <button
                type="button"
                class="primary-button"
                data-testid="deal-audit-pass"
                :disabled="acting"
                @click="handlePass"
              >
                {{ strings.dealAudit.approve }}
              </button>
              <button
                type="button"
                class="secondary-button"
                data-testid="deal-audit-reject"
                :disabled="acting"
                @click="handleReject"
              >
                {{ strings.dealAudit.reject }}
              </button>
            </div>
          </template>
          <p v-else-if="!canWrite" class="inline-note">{{ strings.dealAudit.readOnly }}</p>
          <p v-else class="inline-note">{{ strings.dealAudit.handled }}</p>
        </template>
        <div v-else class="empty-state">{{ strings.dealAudit.emptyState }}</div>
      </section>
    </div>
  </section>
</template>
