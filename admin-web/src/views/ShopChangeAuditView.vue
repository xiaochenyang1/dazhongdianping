<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { getAdminShopChangeDetail, listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, AdminShopChangeDetail, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const loading = ref(false)
const detailLoading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedTaskId = ref<number | null>(null)
const shopChangeDetail = ref<AdminShopChangeDetail | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')
const filters = reactive({ status: '0', keyword: '', page: 1, pageSize: 10 })

const selectedTask = computed(
  () =>
    pageState.value?.list.find((task) => task.id === selectedTaskId.value) ??
    pageState.value?.list[0] ??
    null,
)
const canWrite = computed(() => state.permissions.includes('audit:shop_change:write'))
const canHandleSelected = computed(() => canWrite.value && selectedTask.value?.status === 0)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function taskStatusText(task: AdminAuditTask) {
  return strings.value.shopChangeAudit.statusText(task.status, task.statusText)
}

function merchantLabel(task: AdminAuditTask) {
  return task.submittedBy || strings.value.shopChangeAudit.merchantFallback
}

function candidateShopLabel(task: AdminAuditTask) {
  return task.shopName || strings.value.shopChangeAudit.candidateShopFallback
}

function targetShopLabel(shopId: number | null) {
  return strings.value.shopChangeAudit.targetShopLabel(shopId)
}

function summaryLabel(task: AdminAuditTask) {
  return task.summary || strings.value.shopChangeAudit.summaryFallback
}

function actionLabel(taskId: number) {
  return selectedTaskId.value === taskId
    ? strings.value.shopChangeAudit.selected
    : strings.value.shopChangeAudit.view
}

async function loadShopChangeDetail(changeId: number) {
  detailLoading.value = true
  shopChangeDetail.value = null
  try {
    shopChangeDetail.value = await getAdminShopChangeDetail(changeId)
  } catch (cause) {
    shopChangeDetail.value = null
    errorMessage.value = messageOf(cause, strings.value.shopChangeAudit.detailLoadError)
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
      bizType: 5,
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
        await loadShopChangeDetail(selected.bizId)
      }
    } else {
      shopChangeDetail.value = null
    }
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.shopChangeAudit.loadError)
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
    await loadShopChangeDetail(selected.bizId)
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
    successMessage.value = strings.value.shopChangeAudit.passed(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.shopChangeAudit.passError)
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  const task = selectedTask.value
  if (!canHandleSelected.value || !task) return

  const reason = rejectReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.shopChangeAudit.rejectReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await rejectAuditTask(task.id, { reason })
    successMessage.value = strings.value.shopChangeAudit.rejected(task.id)
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.shopChangeAudit.rejectError)
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
    shopChangeDetail.value = null
    void loadTasks()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.shopChangeAudit.eyebrow }}</p>
        <h1>{{ strings.shopChangeAudit.heading }}</h1>
        <p>{{ strings.shopChangeAudit.description(state.region) }}</p>
      </div>
      <button type="button" class="secondary-button" @click="loadTasks">{{ strings.shopChangeAudit.refresh }}</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.shopChangeAudit.listEyebrow }}</p>
            <h2>{{ strings.shopChangeAudit.listHeading }}</h2>
          </div>
          <span class="inline-note">{{ strings.shopChangeAudit.listSummary(pageState?.total ?? 0) }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.shopChangeAudit.filters.status }}</span>
            <select v-model="filters.status" name="shop-change-status-filter">
              <option value="">{{ strings.shopChangeAudit.statusOptions.all }}</option>
              <option value="0">{{ strings.shopChangeAudit.statusOptions.pending }}</option>
              <option value="1">{{ strings.shopChangeAudit.statusOptions.approved }}</option>
              <option value="2">{{ strings.shopChangeAudit.statusOptions.rejected }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.shopChangeAudit.filters.keyword }}</span>
            <input
              v-model="filters.keyword"
              name="shop-change-keyword-filter"
              data-testid="shop-change-keyword-filter"
              :placeholder="strings.shopChangeAudit.keywordPlaceholder"
            />
          </label>
          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyFilters">{{ strings.shopChangeAudit.applyFilters }}</button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.shopChangeAudit.tableHeaders.task }}</th>
                <th>{{ strings.shopChangeAudit.tableHeaders.merchant }}</th>
                <th>{{ strings.shopChangeAudit.tableHeaders.candidateShop }}</th>
                <th>{{ strings.shopChangeAudit.tableHeaders.summary }}</th>
                <th>{{ strings.shopChangeAudit.tableHeaders.status }}</th>
                <th>{{ strings.shopChangeAudit.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="6" class="table-empty">{{ strings.shopChangeAudit.loading }}</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="6" class="table-empty">{{ strings.shopChangeAudit.empty }}</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  <strong>#{{ task.id }}</strong>
                  <p>{{ strings.shopChangeAudit.taskLabel(task.bizId) }}</p>
                </td>
                <td>{{ merchantLabel(task) }}</td>
                <td>
                  <strong>{{ candidateShopLabel(task) }}</strong>
                  <p>{{ targetShopLabel(task.shopId) }}</p>
                </td>
                <td>{{ summaryLabel(task) }}</td>
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
                    {{ actionLabel(task.id) }}
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
            {{ strings.shopChangeAudit.previousPage }}
          </button>
          <span>{{ strings.shopChangeAudit.page(filters.page) }}</span>
          <button
            type="button"
            class="ghost-button"
            :disabled="!pageState?.hasMore"
            @click="filters.page++; loadTasks()"
          >
            {{ strings.shopChangeAudit.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <template v-if="selectedTask">
          <div class="editor-header">
            <div>
              <p class="eyebrow">{{ strings.shopChangeAudit.editorEyebrow }}</p>
              <h2>{{ strings.shopChangeAudit.editorHeading(selectedTask.id) }}</h2>
            </div>
            <span class="inline-note">{{ taskStatusText(selectedTask) }}</span>
          </div>
          <div class="meta-grid">
            <div>
              <span>{{ strings.shopChangeAudit.metaLabels.draft }}</span>
              <strong>#{{ selectedTask.bizId }}</strong>
            </div>
            <div>
              <span>{{ strings.shopChangeAudit.metaLabels.merchant }}</span>
              <strong>{{ merchantLabel(selectedTask) }}</strong>
            </div>
            <div>
              <span>{{ strings.shopChangeAudit.metaLabels.candidateShop }}</span>
              <strong>{{ candidateShopLabel(selectedTask) }}</strong>
            </div>
            <div>
              <span>{{ strings.shopChangeAudit.metaLabels.targetShop }}</span>
              <strong>{{ targetShopLabel(selectedTask.shopId) }}</strong>
            </div>
            <div>
              <span>{{ strings.shopChangeAudit.metaLabels.region }}</span>
              <strong>{{ selectedTask.region }}</strong>
            </div>
            <div>
              <span>{{ strings.shopChangeAudit.metaLabels.submittedAt }}</span>
              <strong>{{ selectedTask.createdAt }}</strong>
            </div>
          </div>
          <div class="hint-card">
            <strong>{{ strings.shopChangeAudit.detailSummaryLabel }}</strong>
            <p>{{ summaryLabel(selectedTask) }}</p>
          </div>

          <div v-if="detailLoading" class="inline-note">{{ strings.shopChangeAudit.detailLoading }}</div>
          <template v-else-if="shopChangeDetail">
            <div class="meta-grid">
              <div>
                <span>{{ strings.shopChangeAudit.detailLabels.changeType }}</span>
                <strong>{{ strings.shopChangeAudit.changeTypeText(shopChangeDetail.changeType) }}</strong>
              </div>
              <div>
                <span>{{ strings.shopChangeAudit.detailLabels.phone }}</span>
                <strong>{{ shopChangeDetail.phone || strings.shopChangeAudit.emptyValue }}</strong>
              </div>
              <div>
                <span>{{ strings.shopChangeAudit.detailLabels.pricePerCapita }}</span>
                <strong>{{ shopChangeDetail.pricePerCapita }} {{ shopChangeDetail.currency }}</strong>
              </div>
              <div>
                <span>{{ strings.shopChangeAudit.detailLabels.businessHours }}</span>
                <strong>{{ shopChangeDetail.businessHours || strings.shopChangeAudit.emptyValue }}</strong>
              </div>
              <div>
                <span>{{ strings.shopChangeAudit.detailLabels.address }}</span>
                <strong>{{ shopChangeDetail.address || strings.shopChangeAudit.emptyValue }}</strong>
              </div>
              <div>
                <span>{{ strings.shopChangeAudit.detailLabels.tags }}</span>
                <strong>{{ (shopChangeDetail.tags || []).join(', ') || strings.shopChangeAudit.emptyValue }}</strong>
              </div>
            </div>
            <div class="hint-card">
              <strong>{{ strings.shopChangeAudit.detailLabels.gallery }}</strong>
              <div class="application-photos">
                <a
                  v-for="(photo, index) in shopChangeDetail.photos || []"
                  :key="`${photo.imageUrl}-${index}`"
                  :href="photo.imageUrl"
                  target="_blank"
                  rel="noreferrer"
                >
                  <img :src="photo.imageUrl" :alt="strings.shopChangeAudit.photoAlt(index)" />
                </a>
                <p v-if="!(shopChangeDetail.photos && shopChangeDetail.photos.length)" class="inline-note">
                  {{ strings.shopChangeAudit.emptyGallery }}
                </p>
              </div>
            </div>
            <div class="hint-card">
              <strong>{{ strings.shopChangeAudit.detailLabels.menu }}</strong>
              <div class="table-shell">
                <table class="data-table">
                  <thead>
                    <tr>
                      <th>{{ strings.shopChangeAudit.dishHeaders.name }}</th>
                      <th>{{ strings.shopChangeAudit.dishHeaders.price }}</th>
                      <th>{{ strings.shopChangeAudit.dishHeaders.recommendReason }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(dish, index) in shopChangeDetail.dishes || []" :key="`${dish.name}-${index}`">
                      <td>{{ dish.name }}</td>
                      <td>{{ dish.price }}</td>
                      <td>{{ dish.recommendReason || strings.shopChangeAudit.dishRecommendFallback }}</td>
                    </tr>
                    <tr v-if="!(shopChangeDetail.dishes && shopChangeDetail.dishes.length)">
                      <td colspan="3" class="table-empty">{{ strings.shopChangeAudit.dishEmpty }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </template>

          <template v-if="canHandleSelected">
            <label class="field field--full">
              <span>{{ strings.shopChangeAudit.approveRemarkLabel }}</span>
              <textarea
                v-model="approveRemark"
                name="approve-remark"
                rows="4"
                :placeholder="strings.shopChangeAudit.approveRemarkPlaceholder"
              />
            </label>
            <label class="field field--full">
              <span>{{ strings.shopChangeAudit.rejectReasonLabel }}</span>
              <textarea
                v-model="rejectReason"
                name="reject-reason"
                rows="4"
                :placeholder="strings.shopChangeAudit.rejectReasonPlaceholder"
              />
            </label>
            <div class="form-actions">
              <button type="button" class="primary-button" :disabled="acting" @click="handlePass">
                {{ strings.shopChangeAudit.approve }}
              </button>
              <button type="button" class="secondary-button" :disabled="acting" @click="handleReject">
                {{ strings.shopChangeAudit.reject }}
              </button>
            </div>
          </template>
          <p v-else-if="!canWrite" class="inline-note">{{ strings.shopChangeAudit.readOnly }}</p>
          <p v-else class="inline-note">{{ strings.shopChangeAudit.handled }}</p>
        </template>
        <div v-else class="empty-state">{{ strings.shopChangeAudit.emptyState }}</div>
      </section>
    </div>
  </section>
</template>
