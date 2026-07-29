<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { listAdminAuditLogs } from '@/services/admin'
import type { AdminAuditLog, PageResult } from '@/types/admin'

const pageSize = 20
const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const loading = ref(false)
const errorMessage = ref('')
const pageState = ref<PageResult<AdminAuditLog> | null>(null)
const filters = reactive({
  adminId: '',
  action: '',
  target: '',
  keyword: '',
  page: 1,
})

function normalizeNumber(value: string) {
  const normalized = value.trim()
  if (!normalized) {
    return undefined
  }
  const parsed = Number(normalized)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined
}

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized ? normalized : undefined
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminAuditLogs({
      adminId: normalizeNumber(filters.adminId),
      action: normalizeText(filters.action),
      target: normalizeText(filters.target),
      keyword: normalizeText(filters.keyword),
      page: filters.page,
      pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.auditLogs.loadError
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

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.auditLogs.eyebrow }}</p>
        <h1>{{ strings.auditLogs.heading }}</h1>
        <p>{{ strings.auditLogs.description }}</p>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? strings.auditLogs.metaLoading : strings.auditLogs.metaSummary(pageState?.total ?? 0) }}</span>
        <span>{{ strings.auditLogs.metaDescription }}</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.auditLogs.labels.adminId }}</span>
          <input
            name="audit-log-admin-id"
            v-model="filters.adminId"
            inputmode="numeric"
            :placeholder="strings.auditLogs.placeholders.adminId"
          />
        </label>
        <label class="field">
          <span>{{ strings.auditLogs.labels.action }}</span>
          <input
            name="audit-log-action"
            v-model="filters.action"
            :placeholder="strings.auditLogs.placeholders.action"
          />
        </label>
        <label class="field">
          <span>{{ strings.auditLogs.labels.target }}</span>
          <input
            name="audit-log-target"
            v-model="filters.target"
            :placeholder="strings.auditLogs.placeholders.target"
          />
        </label>
        <label class="field">
          <span>{{ strings.auditLogs.labels.keyword }}</span>
          <input
            name="audit-log-keyword"
            v-model="filters.keyword"
            :placeholder="strings.auditLogs.placeholders.keyword"
          />
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">{{ strings.auditLogs.applyFilters }}</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.auditLogs.tableHeaders.time }}</th>
              <th>{{ strings.auditLogs.tableHeaders.operator }}</th>
              <th>{{ strings.auditLogs.tableHeaders.action }}</th>
              <th>{{ strings.auditLogs.tableHeaders.target }}</th>
              <th>{{ strings.auditLogs.tableHeaders.detail }}</th>
              <th>{{ strings.auditLogs.tableHeaders.ip }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="table-empty">{{ strings.auditLogs.loadingRow }}</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="6" class="table-empty">{{ strings.auditLogs.empty }}</td>
            </tr>
            <tr v-for="item in pageState?.list" :key="item.id">
              <td class="numeric-cell">{{ item.createdAt }}</td>
              <td>
                <strong>{{ item.adminName || strings.auditLogs.systemFallback }}</strong>
                <p class="code-box">{{ item.adminAccount || `admin:${item.adminId}` }}</p>
              </td>
              <td><p class="code-box">{{ item.action }}</p></td>
              <td><p class="code-box">{{ item.target || '--' }}</p></td>
              <td>{{ item.detail || strings.auditLogs.detailFallback }}</td>
              <td class="numeric-cell">{{ item.ip || '--' }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="filters.page <= 1" @click="goPage(filters.page - 1)">
          {{ strings.auditLogs.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.auditLogs.page(filters.page) }}</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!pageState?.hasMore" @click="goPage(filters.page + 1)">
          {{ strings.auditLogs.nextPage }}
        </button>
      </div>
    </article>
  </section>
</template>
