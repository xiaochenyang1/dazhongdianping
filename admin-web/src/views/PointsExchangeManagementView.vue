<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  cancelAdminPointsExchange,
  fulfillAdminPointsExchange,
  listAdminPointsExchanges,
} from '@/services/admin'
import type { AdminPointsExchange, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:points:write'))

const loading = ref(false)
const acting = ref(false)
const error = ref('')
const success = ref('')
const pageState = ref<PageResult<AdminPointsExchange> | null>(null)
const selectedId = ref<number | null>(null)
const redeemCode = ref('')
const remark = ref('')

const filters = reactive({
  status: '0',
  keyword: '',
  page: 1,
  pageSize: 10,
})

const selected = computed(() => {
  if (!pageState.value) return null
  return pageState.value.list.find((item) => item.id === selectedId.value) ?? pageState.value.list[0] ?? null
})

function statusText(item: AdminPointsExchange) {
  return strings.value.pointsExchanges.statusText(item.status, item.statusText)
}

function textOrFallback(value: string) {
  return value || strings.value.pointsExchanges.fallbackText
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    pageState.value = await listAdminPointsExchanges({
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((item) => item.id === selectedId.value)) {
      selectedId.value = pageState.value.list[0]?.id ?? null
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.pointsExchanges.loadError
  } finally {
    loading.value = false
  }
}

function select(item: AdminPointsExchange) {
  selectedId.value = item.id
  redeemCode.value = ''
  remark.value = ''
  success.value = ''
  error.value = ''
}

function applyFilters() {
  filters.page = 1
  void load()
}

function goPage(page: number) {
  if (page < 1) return
  filters.page = page
  void load()
}

async function fulfill() {
  const current = selected.value
  if (!current || !canWrite.value || current.status !== 0 || acting.value) return

  acting.value = true
  error.value = ''
  success.value = ''
  const code = redeemCode.value.trim()
  try {
    const updated = await fulfillAdminPointsExchange(current.id, {
      redeemCode: code || undefined,
      remark: remark.value.trim() || undefined,
    })
    success.value = strings.value.pointsExchanges.fulfilledMessage(current.id, updated.redeemCode || code)
    redeemCode.value = ''
    remark.value = ''
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.pointsExchanges.actionError
  } finally {
    acting.value = false
  }
}

async function cancel() {
  const current = selected.value
  if (!current || !canWrite.value || current.status !== 0 || acting.value) return
  if (!window.confirm(strings.value.pointsExchanges.cancelConfirm(current.id, current.pointsCost))) return

  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await cancelAdminPointsExchange(current.id, { remark: remark.value.trim() || undefined })
    success.value = strings.value.pointsExchanges.cancelledMessage(current.id, current.pointsCost)
    redeemCode.value = ''
    remark.value = ''
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.pointsExchanges.actionError
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
        <p class="eyebrow">{{ strings.pointsExchanges.eyebrow }}</p>
        <h1>{{ strings.pointsExchanges.heading }}</h1>
        <p>{{ strings.pointsExchanges.description(state.region) }}</p>
      </div>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <section class="content-card">
      <div class="toolbar">
        <label>
          <span class="muted">{{ strings.pointsExchanges.filters.status }}</span>
          <select v-model="filters.status" data-testid="exchange-status-filter" @change="applyFilters">
            <option value="">{{ strings.pointsExchanges.statusOptions.all }}</option>
            <option value="0">{{ strings.pointsExchanges.statusOptions.pending }}</option>
            <option value="1">{{ strings.pointsExchanges.statusOptions.fulfilled }}</option>
            <option value="2">{{ strings.pointsExchanges.statusOptions.cancelled }}</option>
          </select>
        </label>
        <label>
          <span class="muted">{{ strings.pointsExchanges.filters.keyword }}</span>
          <input
            v-model="filters.keyword"
            data-testid="exchange-keyword-filter"
            type="search"
            :placeholder="strings.pointsExchanges.keywordPlaceholder"
            @keyup.enter="applyFilters"
          />
        </label>
        <button type="button" class="secondary-button" @click="applyFilters">
          {{ strings.pointsExchanges.query }}
        </button>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.pointsExchanges.tableHeaders.id }}</th>
              <th>{{ strings.pointsExchanges.tableHeaders.user }}</th>
              <th>{{ strings.pointsExchanges.tableHeaders.product }}</th>
              <th>{{ strings.pointsExchanges.tableHeaders.points }}</th>
              <th>{{ strings.pointsExchanges.tableHeaders.status }}</th>
              <th>{{ strings.pointsExchanges.tableHeaders.redeemCode }}</th>
              <th>{{ strings.pointsExchanges.tableHeaders.time }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7" class="table-empty">{{ strings.pointsExchanges.loading }}</td>
            </tr>
            <tr v-else-if="!pageState?.list.length">
              <td colspan="7" class="table-empty">{{ strings.pointsExchanges.empty }}</td>
            </tr>
            <tr
              v-for="item in pageState?.list || []"
              :key="item.id"
              :class="{ 'is-selected': selected?.id === item.id }"
              :data-testid="`exchange-row-${item.id}`"
              @click="select(item)"
            >
              <td><strong>#{{ item.id }}</strong></td>
              <td>{{ item.userNickname || item.userId }}</td>
              <td>{{ item.productName }}</td>
              <td>{{ item.pointsCost }}</td>
              <td><span class="status-pill">{{ statusText(item) }}</span></td>
              <td>{{ textOrFallback(item.redeemCode) }}</td>
              <td>{{ item.createdAt }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button
          type="button"
          class="ghost-button system-pager-button"
          data-testid="exchange-prev"
          :disabled="filters.page <= 1"
          @click="goPage(filters.page - 1)"
        >
          {{ strings.pointsExchanges.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.pointsExchanges.page(filters.page) }}</span>
        <button
          type="button"
          class="ghost-button system-pager-button"
          data-testid="exchange-next"
          :disabled="!pageState?.hasMore"
          @click="goPage(filters.page + 1)"
        >
          {{ strings.pointsExchanges.nextPage }}
        </button>
      </div>
    </section>

    <section v-if="selected" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.pointsExchanges.eyebrow }}</p>
          <h2>#{{ selected.id }} {{ selected.productName }}</h2>
        </div>
        <span class="status-pill">{{ statusText(selected) }}</span>
      </div>
      <div class="detail-grid">
        <p>
          <strong>{{ strings.pointsExchanges.tableHeaders.user }}</strong>
          : {{ selected.userNickname || selected.userId }}
        </p>
        <p>
          <strong>{{ strings.pointsExchanges.tableHeaders.points }}</strong>
          : {{ selected.pointsCost }} × {{ selected.quantity }}
        </p>
        <p>
          <strong>{{ strings.pointsExchanges.tableHeaders.redeemCode }}</strong>
          : {{ textOrFallback(selected.redeemCode) }}
        </p>
        <p>
          <strong>{{ strings.pointsExchanges.tableHeaders.remark }}</strong>
          : {{ textOrFallback(selected.remark) }}
        </p>
        <p>
          <strong>{{ strings.pointsExchanges.tableHeaders.time }}</strong>
          : {{ selected.createdAt }}
        </p>
        <p>
          <strong>{{ strings.pointsExchanges.statusOptions.fulfilled }}</strong>
          : {{ textOrFallback(selected.fulfilledAt) }}
        </p>
      </div>

      <div
        v-if="canWrite && selected.status === 0"
        class="form-actions"
        style="margin-top: 16px; gap: 12px; display: flex; flex-wrap: wrap"
      >
        <input
          v-model="redeemCode"
          data-testid="exchange-redeem-code"
          type="text"
          maxlength="32"
          :placeholder="strings.pointsExchanges.redeemCodePlaceholder"
          style="min-width: 240px; flex: 1"
        />
        <input
          v-model="remark"
          data-testid="exchange-remark"
          type="text"
          maxlength="255"
          :placeholder="strings.pointsExchanges.remarkPlaceholder"
          style="min-width: 240px; flex: 1"
        />
        <button
          type="button"
          class="secondary-button"
          data-testid="exchange-cancel"
          :disabled="acting"
          @click="cancel"
        >
          {{ strings.pointsExchanges.cancelAction }}
        </button>
        <button
          type="button"
          class="primary-button"
          data-testid="exchange-fulfill"
          :disabled="acting"
          @click="fulfill"
        >
          {{ strings.pointsExchanges.fulfillAction }}
        </button>
      </div>
      <p v-else-if="!canWrite" class="muted">{{ strings.pointsExchanges.readOnly }}</p>
      <p v-else class="muted">{{ strings.pointsExchanges.handled }}</p>
    </section>
  </section>
</template>
