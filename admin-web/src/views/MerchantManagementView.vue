<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { getAdminMerchant, listAdminMerchants, updateAdminMerchantStatus } from '@/services/admin'
import type { AdminMerchant, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const pageSize = 20
const loading = ref(false)
const detailLoading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminMerchant> | null>(null)
const detail = ref<AdminMerchant | null>(null)
const disableTarget = ref<AdminMerchant | null>(null)
const disableReason = ref('')
const filters = reactive({
  keyword: '',
  merchantId: '',
  auditStatus: '',
  status: '',
  page: 1,
})

const canWrite = computed(() => state.permissions.includes('system:merchant:write'))

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized || undefined
}

function normalizePositiveNumber(value: string) {
  const parsed = Number(value.trim())
  return value.trim() && Number.isInteger(parsed) && parsed > 0 ? parsed : undefined
}

function normalizeNonNegativeNumber(value: string) {
  const parsed = Number(value.trim())
  return value.trim() && Number.isInteger(parsed) && parsed >= 0 ? parsed : undefined
}

function merchantLabel(merchant: AdminMerchant) {
  return merchant.companyName || strings.value.merchantManagement.merchantFallback(merchant.id)
}

function auditStatusText(merchant: AdminMerchant) {
  if (merchant.auditStatus === 1) return strings.value.merchantManagement.filters.approved
  if (merchant.auditStatus === 2) return strings.value.merchantManagement.filters.rejected
  return strings.value.merchantManagement.filters.pending
}

function accountStatusText(merchant: AdminMerchant) {
  return merchant.status === 1
    ? strings.value.merchantManagement.filters.active
    : strings.value.merchantManagement.filters.disabled
}

function auditPillClass(merchant: AdminMerchant) {
  if (merchant.auditStatus === 1) return 'status-pill--good'
  if (merchant.auditStatus === 2) return 'status-pill--warn'
  return 'status-pill--muted'
}

function accountPillClass(merchant: AdminMerchant) {
  return merchant.status === 1 ? 'status-pill--good' : 'status-pill--warn'
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminMerchants({
      keyword: normalizeText(filters.keyword),
      merchantId: normalizePositiveNumber(filters.merchantId),
      auditStatus: normalizeNonNegativeNumber(filters.auditStatus),
      status: normalizePositiveNumber(filters.status),
      page: filters.page,
      pageSize,
    })
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.loadError
  } finally {
    loading.value = false
  }
}

async function applyFilters() {
  filters.page = 1
  await load()
}

async function goPage(page: number) {
  filters.page = Math.max(1, page)
  await load()
}

async function openDetail(merchant: AdminMerchant) {
  detailLoading.value = true
  detail.value = null
  errorMessage.value = ''
  try {
    detail.value = await getAdminMerchant(merchant.id)
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.detailLoadError
  } finally {
    detailLoading.value = false
  }
}

function openDisable(merchant: AdminMerchant) {
  disableTarget.value = merchant
  disableReason.value = ''
  errorMessage.value = ''
  successMessage.value = ''
}

async function confirmDisable() {
  const target = disableTarget.value
  if (!target) return
  const reason = disableReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.merchantManagement.disableReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminMerchantStatus(target.id, { action: 'disable', reason })
    successMessage.value = strings.value.merchantManagement.disabledMessage(merchantLabel(target))
    disableTarget.value = null
    disableReason.value = ''
    if (detail.value?.id === target.id) detail.value = null
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.disableError
  } finally {
    acting.value = false
  }
}

async function enable(merchant: AdminMerchant) {
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminMerchantStatus(merchant.id, { action: 'enable', reason: '' })
    successMessage.value = strings.value.merchantManagement.enabledMessage(merchantLabel(merchant))
    if (detail.value?.id === merchant.id) detail.value = null
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.enableError
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    detail.value = null
    disableTarget.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.merchantManagement.eyebrow }}</p>
        <h1>{{ strings.merchantManagement.heading }}</h1>
        <p>{{ strings.merchantManagement.description(state.region) }}</p>
      </div>
      <button class="secondary-button" type="button" @click="load">
        {{ strings.merchantManagement.refresh }}
      </button>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? strings.merchantManagement.metaLoading : strings.merchantManagement.metaSummary(pageState?.total ?? 0) }}</span>
        <span>{{ strings.merchantManagement.metaDescription }}</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.merchantManagement.filters.keyword }}</span>
          <input v-model="filters.keyword" name="merchant-keyword" :placeholder="strings.merchantManagement.filters.keywordPlaceholder" />
        </label>
        <label class="field">
          <span>{{ strings.merchantManagement.filters.merchantId }}</span>
          <input v-model="filters.merchantId" name="merchant-id" inputmode="numeric" :placeholder="strings.merchantManagement.filters.merchantIdPlaceholder" />
        </label>
        <label class="field">
          <span>{{ strings.merchantManagement.filters.auditStatus }}</span>
          <select v-model="filters.auditStatus" name="merchant-audit-status">
            <option value="">{{ strings.merchantManagement.filters.all }}</option>
            <option value="0">{{ strings.merchantManagement.filters.pending }}</option>
            <option value="1">{{ strings.merchantManagement.filters.approved }}</option>
            <option value="2">{{ strings.merchantManagement.filters.rejected }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.merchantManagement.filters.status }}</span>
          <select v-model="filters.status" name="merchant-status">
            <option value="">{{ strings.merchantManagement.filters.all }}</option>
            <option value="1">{{ strings.merchantManagement.filters.active }}</option>
            <option value="2">{{ strings.merchantManagement.filters.disabled }}</option>
          </select>
        </label>
        <div class="toolbar-actions">
          <button class="primary-button" type="button" @click="applyFilters">{{ strings.merchantManagement.filters.apply }}</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.merchantManagement.tableHeaders.merchant }}</th>
              <th>{{ strings.merchantManagement.tableHeaders.contact }}</th>
              <th>{{ strings.merchantManagement.tableHeaders.auditStatus }}</th>
              <th>{{ strings.merchantManagement.tableHeaders.accountStatus }}</th>
              <th>{{ strings.merchantManagement.tableHeaders.resources }}</th>
              <th>{{ strings.merchantManagement.tableHeaders.updatedAt }}</th>
              <th>{{ strings.merchantManagement.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading"><td colspan="7" class="table-empty">{{ strings.merchantManagement.loading }}</td></tr>
            <tr v-else-if="!pageState?.list.length"><td colspan="7" class="table-empty">{{ strings.merchantManagement.empty }}</td></tr>
            <tr v-for="merchant in pageState?.list" :key="merchant.id">
              <td>
                <strong>{{ merchantLabel(merchant) }}</strong>
                <p class="inline-note">{{ strings.merchantManagement.merchantIdLabel(merchant.id) }}</p>
                <p class="code-box">{{ merchant.account }}</p>
              </td>
              <td>
                <strong>{{ merchant.contactName || strings.merchantManagement.contactFallback }}</strong>
                <p class="inline-note">{{ merchant.contactPhone || strings.merchantManagement.contactFallback }}</p>
              </td>
              <td><span class="status-pill" :class="auditPillClass(merchant)">{{ auditStatusText(merchant) }}</span></td>
              <td><span class="status-pill" :class="accountPillClass(merchant)">{{ accountStatusText(merchant) }}</span></td>
              <td>{{ strings.merchantManagement.resourceSummary(merchant.shopCount, merchant.activeOperatorCount, merchant.operatorCount) }}</td>
              <td class="numeric-cell">{{ merchant.updatedAt || '--' }}</td>
              <td>
                <div class="table-actions">
                  <button class="table-action" type="button" @click="openDetail(merchant)">{{ strings.merchantManagement.detailAction }}</button>
                  <button v-if="canWrite && merchant.status === 1" class="table-action table-action--danger" type="button" :disabled="acting" @click="openDisable(merchant)">{{ strings.merchantManagement.disableAction }}</button>
                  <button v-if="canWrite && merchant.status === 2" class="table-action" type="button" :disabled="acting" @click="enable(merchant)">{{ strings.merchantManagement.enableAction }}</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button class="ghost-button system-pager-button" type="button" :disabled="filters.page <= 1" @click="goPage(filters.page - 1)">{{ strings.merchantManagement.previousPage }}</button>
        <span class="numeric-cell">{{ strings.merchantManagement.page(filters.page) }}</span>
        <button class="ghost-button system-pager-button" type="button" :disabled="!pageState?.hasMore" @click="goPage(filters.page + 1)">{{ strings.merchantManagement.nextPage }}</button>
      </div>
    </article>

    <div v-if="detailLoading" class="audit-drawer"><p class="inline-note">{{ strings.merchantManagement.detailLoading }}</p></div>
    <div v-else-if="detail" class="audit-drawer">
      <div>
        <p class="eyebrow">{{ strings.merchantManagement.detailEyebrow }}</p>
        <h2>{{ merchantLabel(detail) }}</h2>
        <p>{{ strings.merchantManagement.detailSummary(detail.account, detail.region) }}</p>
      </div>
      <dl class="detail-grid">
        <div><dt>{{ strings.merchantManagement.detailFields.auditStatus }}</dt><dd>{{ auditStatusText(detail) }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.accountStatus }}</dt><dd>{{ accountStatusText(detail) }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.shops }}</dt><dd>{{ detail.shopCount }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.operators }}</dt><dd>{{ detail.operatorCount }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.activeOperators }}</dt><dd>{{ detail.activeOperatorCount }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.disableReason }}</dt><dd>{{ detail.disableReason || '--' }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.createdAt }}</dt><dd>{{ detail.createdAt || '--' }}</dd></div>
        <div><dt>{{ strings.merchantManagement.detailFields.updatedAt }}</dt><dd>{{ detail.updatedAt || '--' }}</dd></div>
      </dl>
      <div class="form-actions"><button class="ghost-button" type="button" @click="detail = null">{{ strings.merchantManagement.close }}</button></div>
    </div>

    <div v-if="disableTarget" class="audit-drawer">
      <div>
        <p class="eyebrow">{{ strings.merchantManagement.disableEyebrow }}</p>
        <h2>{{ merchantLabel(disableTarget) }}</h2>
        <p>{{ strings.merchantManagement.disableDescription }}</p>
      </div>
      <label class="field field--full">
        <span>{{ strings.merchantManagement.disableReasonField }}</span>
        <textarea v-model="disableReason" name="disableReason" rows="4" :placeholder="strings.merchantManagement.disablePlaceholder" />
      </label>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="disableTarget = null">{{ strings.common.cancel }}</button>
        <button class="secondary-button" type="button" :disabled="acting" @click="confirmDisable">{{ strings.merchantManagement.confirmDisable }}</button>
      </div>
    </div>
  </section>
</template>
