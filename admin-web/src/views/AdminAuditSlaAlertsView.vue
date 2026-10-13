<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAdminAuditSlaAlerts } from '@/services/admin'
import type { AdminAuditSlaAlert, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const pageSize = 20
const statusFilter = ref<number | ''>(0)
const pageNumber = ref(1)
const pageState = ref<PageResult<AdminAuditSlaAlert> | null>(null)
const loading = ref(false)
const errorMessage = ref('')
let requestSequence = 0

async function loadAlerts() {
  const requestId = ++requestSequence
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await listAdminAuditSlaAlerts({
      status: statusFilter.value === '' ? undefined : statusFilter.value,
      page: pageNumber.value,
      pageSize,
    })
    if (requestId === requestSequence) pageState.value = result
  } catch (error) {
    if (requestId === requestSequence) {
      errorMessage.value = error instanceof Error ? error.message : strings.value.auditSlaAlerts.loadError
    }
  } finally {
    if (requestId === requestSequence) loading.value = false
  }
}

watch([statusFilter, () => state.region], () => {
  pageNumber.value = 1
  void loadAlerts()
})

onMounted(() => {
  void loadAlerts()
  refreshTimer = window.setInterval(() => {
    if (!loading.value) void loadAlerts()
  }, 60_000)
})

let refreshTimer: number | undefined
onUnmounted(() => {
  if (refreshTimer !== undefined) window.clearInterval(refreshTimer)
})

async function goToPage(nextPage: number) {
  pageNumber.value = Math.max(1, nextPage)
  await loadAlerts()
}
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.auditSlaAlerts.eyebrow }}</p>
        <h1>{{ strings.auditSlaAlerts.heading }}</h1>
      </div>
      <label class="field alert-filter">
        <span>{{ strings.auditSlaAlerts.statusFilter }}</span>
        <select v-model.number="statusFilter">
          <option :value="0">{{ strings.auditSlaAlerts.statuses.active }}</option>
          <option :value="1">{{ strings.auditSlaAlerts.statuses.resolved }}</option>
          <option value="">{{ strings.auditSlaAlerts.statuses.all }}</option>
        </select>
      </label>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <h2>{{ loading ? strings.auditSlaAlerts.loading : strings.auditSlaAlerts.listSummary(pageState?.total ?? 0) }}</h2>
        <button type="button" class="secondary-button" :disabled="loading" @click="loadAlerts">{{ strings.auditSlaAlerts.refresh }}</button>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.auditSlaAlerts.tableHeaders.region }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.bizType }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.status }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.pendingCount }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.overdueCount }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.oldestPendingAt }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.firstOverdueAt }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.lastDetectedAt }}</th>
              <th>{{ strings.auditSlaAlerts.tableHeaders.resolvedAt }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading"><td colspan="9" class="table-empty">{{ strings.auditSlaAlerts.loading }}</td></tr>
            <tr v-else-if="!pageState?.list.length"><td colspan="9" class="table-empty">{{ strings.auditSlaAlerts.empty }}</td></tr>
            <tr v-for="alert in pageState?.list" :key="alert.id">
              <td>{{ strings.auditSlaAlerts.regionLabel(alert.region) }}</td>
              <td>{{ strings.auditSlaAlerts.bizTypeLabel(alert.bizType, alert.bizTypeText) }}</td>
              <td><span :class="alert.status === 0 ? 'alert-status--active' : 'alert-status--resolved'">{{ strings.auditSlaAlerts.statusText(alert.status, alert.statusText) }}</span></td>
              <td>{{ alert.pendingCount }}</td>
              <td>{{ alert.overdueCount }}</td>
              <td>{{ alert.oldestPendingAt || '—' }}</td>
              <td>{{ alert.firstOverdueAt }}</td>
              <td>{{ alert.lastDetectedAt }}</td>
              <td>{{ alert.resolvedAt || '—' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pager">
        <button type="button" class="ghost-button" :disabled="pageNumber <= 1 || loading" @click="goToPage(pageNumber - 1)">{{ strings.auditSlaAlerts.previousPage }}</button>
        <span>{{ strings.auditSlaAlerts.page(pageNumber) }}</span>
        <button type="button" class="ghost-button" :disabled="!pageState?.hasMore || loading" @click="goToPage(pageNumber + 1)">{{ strings.auditSlaAlerts.nextPage }}</button>
      </div>
    </section>
  </section>
</template>

<style scoped>
.alert-filter {
  min-width: 180px;
}

.alert-status--active {
  color: #b42318;
  font-weight: 700;
}

.alert-status--resolved {
  color: #067647;
  font-weight: 700;
}
</style>
