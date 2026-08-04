<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  getAdminMerchant,
  getAdminMerchantOperator,
  listAdminMerchantOperators,
  listAdminMerchants,
  updateAdminMerchantOperatorStatus,
  updateAdminMerchantStatus,
} from '@/services/admin'
import type { AdminMerchant, AdminMerchantOperator, PageResult } from '@/types/admin'

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
const staffMerchant = ref<AdminMerchant | null>(null)
const staffPageState = ref<PageResult<AdminMerchantOperator> | null>(null)
const staffLoading = ref(false)
const staffDetail = ref<AdminMerchantOperator | null>(null)
const staffDetailLoading = ref(false)
const staffDisableTarget = ref<AdminMerchantOperator | null>(null)
const staffDisableReason = ref('')
let staffRequestId = 0
let staffDetailRequestId = 0
const filters = reactive({
  keyword: '',
  merchantId: '',
  auditStatus: '',
  status: '',
  page: 1,
})
const staffFilters = reactive({ keyword: '', status: '', page: 1 })

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

function operatorLabel(operator: AdminMerchantOperator) {
  return operator.name || strings.value.merchantManagement.staff.operatorFallback(operator.id)
}

function operatorStatusText(operator: AdminMerchantOperator) {
  return operator.status === 1
    ? strings.value.merchantManagement.staff.filters.active
    : strings.value.merchantManagement.staff.filters.disabled
}

function operatorScopeText(operator: AdminMerchantOperator) {
  return operator.shopScopeType === 1
    ? strings.value.merchantManagement.staff.allShops
    : strings.value.merchantManagement.staff.selectedShops(operator.shopIds)
}

function operatorRolesText(operator: AdminMerchantOperator) {
  return operator.roleNames.join(', ') || strings.value.merchantManagement.staff.rolesFallback
}

function operatorPillClass(operator: AdminMerchantOperator) {
  return operator.status === 1 ? 'status-pill--good' : 'status-pill--warn'
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

async function loadStaff() {
  const merchant = staffMerchant.value
  if (!merchant) return
  const requestId = ++staffRequestId
  staffLoading.value = true
  errorMessage.value = ''
  try {
    const result = await listAdminMerchantOperators(merchant.id, {
      keyword: normalizeText(staffFilters.keyword),
      status: normalizePositiveNumber(staffFilters.status),
      page: staffFilters.page,
      pageSize,
    })
    if (requestId === staffRequestId && staffMerchant.value?.id === merchant.id) {
      staffPageState.value = result
    }
  } catch (cause) {
    if (requestId === staffRequestId && staffMerchant.value?.id === merchant.id) {
      errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.staff.loadError
    }
  } finally {
    if (requestId === staffRequestId) staffLoading.value = false
  }
}

async function openStaff(merchant: AdminMerchant) {
  staffMerchant.value = merchant
  staffFilters.keyword = ''
  staffFilters.status = ''
  staffFilters.page = 1
  staffDetail.value = null
  staffDisableTarget.value = null
  await loadStaff()
}

async function applyStaffFilters() {
  staffFilters.page = 1
  await loadStaff()
}

async function goStaffPage(page: number) {
  staffFilters.page = Math.max(1, page)
  await loadStaff()
}

function closeStaff() {
  staffRequestId += 1
  staffDetailRequestId += 1
  staffMerchant.value = null
  staffPageState.value = null
  staffDetail.value = null
  staffDisableTarget.value = null
}

async function openStaffDetail(operator: AdminMerchantOperator) {
  const merchant = staffMerchant.value
  if (!merchant) return
  const requestId = ++staffDetailRequestId
  staffDetailLoading.value = true
  staffDetail.value = null
  errorMessage.value = ''
  try {
    const result = await getAdminMerchantOperator(merchant.id, operator.id)
    if (requestId === staffDetailRequestId && staffMerchant.value?.id === merchant.id) {
      staffDetail.value = result
    }
  } catch (cause) {
    if (requestId === staffDetailRequestId && staffMerchant.value?.id === merchant.id) {
      errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.staff.detailLoadError
    }
  } finally {
    if (requestId === staffDetailRequestId) staffDetailLoading.value = false
  }
}

function openStaffDisable(operator: AdminMerchantOperator) {
  staffDisableTarget.value = operator
  staffDisableReason.value = ''
  errorMessage.value = ''
  successMessage.value = ''
}

async function confirmStaffDisable() {
  const merchant = staffMerchant.value
  const target = staffDisableTarget.value
  if (!merchant || !target) return
  const reason = staffDisableReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.merchantManagement.staff.disableReasonRequired
    return
  }
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminMerchantOperatorStatus(merchant.id, target.id, { action: 'disable', reason })
    successMessage.value = strings.value.merchantManagement.staff.disabledMessage(operatorLabel(target))
    staffDisableTarget.value = null
    staffDisableReason.value = ''
    if (staffDetail.value?.id === target.id) staffDetail.value = null
    await loadStaff()
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.staff.disableError
  } finally {
    acting.value = false
  }
}

async function enableStaff(operator: AdminMerchantOperator) {
  const merchant = staffMerchant.value
  if (!merchant) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminMerchantOperatorStatus(merchant.id, operator.id, { action: 'enable', reason: '' })
    successMessage.value = strings.value.merchantManagement.staff.enabledMessage(operatorLabel(operator))
    if (staffDetail.value?.id === operator.id) staffDetail.value = null
    await loadStaff()
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.merchantManagement.staff.enableError
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
    closeStaff()
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
                  <button class="table-action" type="button" @click="openStaff(merchant)">{{ strings.merchantManagement.staff.action }}</button>
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

    <article v-if="staffMerchant" class="content-card system-table-card">
      <div class="system-table-card__meta">
        <div>
          <p class="eyebrow">{{ strings.merchantManagement.staff.eyebrow }}</p>
          <strong>{{ strings.merchantManagement.staff.heading(merchantLabel(staffMerchant)) }}</strong>
          <p class="inline-note">{{ strings.merchantManagement.staff.description }}</p>
        </div>
        <button class="ghost-button" type="button" @click="closeStaff">{{ strings.merchantManagement.staff.close }}</button>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.merchantManagement.staff.filters.keyword }}</span>
          <input v-model="staffFilters.keyword" name="merchant-operator-keyword" :placeholder="strings.merchantManagement.staff.filters.keywordPlaceholder" />
        </label>
        <label class="field">
          <span>{{ strings.merchantManagement.staff.filters.status }}</span>
          <select v-model="staffFilters.status" name="merchant-operator-status">
            <option value="">{{ strings.merchantManagement.staff.filters.all }}</option>
            <option value="1">{{ strings.merchantManagement.staff.filters.active }}</option>
            <option value="2">{{ strings.merchantManagement.staff.filters.disabled }}</option>
          </select>
        </label>
        <div class="toolbar-actions">
          <button class="primary-button" type="button" @click="applyStaffFilters">{{ strings.merchantManagement.staff.filters.apply }}</button>
        </div>
      </div>

      <div class="system-table-card__meta">
        <span>{{ staffLoading ? strings.merchantManagement.staff.metaLoading : strings.merchantManagement.staff.metaSummary(staffPageState?.total ?? 0) }}</span>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead><tr>
            <th>{{ strings.merchantManagement.staff.tableHeaders.operator }}</th>
            <th>{{ strings.merchantManagement.staff.tableHeaders.contact }}</th>
            <th>{{ strings.merchantManagement.staff.tableHeaders.roles }}</th>
            <th>{{ strings.merchantManagement.staff.tableHeaders.shopScope }}</th>
            <th>{{ strings.merchantManagement.staff.tableHeaders.status }}</th>
            <th>{{ strings.merchantManagement.staff.tableHeaders.actions }}</th>
          </tr></thead>
          <tbody>
            <tr v-if="staffLoading"><td colspan="6" class="table-empty">{{ strings.merchantManagement.staff.loading }}</td></tr>
            <tr v-else-if="!staffPageState?.list.length"><td colspan="6" class="table-empty">{{ strings.merchantManagement.staff.empty }}</td></tr>
            <tr v-for="operator in staffPageState?.list" :key="operator.id">
              <td><strong>{{ operatorLabel(operator) }}</strong><p class="inline-note">{{ strings.merchantManagement.staff.operatorIdLabel(operator.id) }}</p><p class="code-box">{{ operator.account }}</p></td>
              <td><strong>{{ operator.phone || strings.merchantManagement.staff.contactFallback }}</strong><p class="inline-note">{{ operator.email || strings.merchantManagement.staff.contactFallback }}</p></td>
              <td><span class="tag-list">{{ operatorRolesText(operator) }}</span></td>
              <td><span class="region-list">{{ operatorScopeText(operator) }}</span></td>
              <td><span class="status-pill" :class="operatorPillClass(operator)">{{ operatorStatusText(operator) }}</span></td>
              <td><div class="table-actions">
                <button class="table-action" type="button" @click="openStaffDetail(operator)">{{ strings.merchantManagement.staff.detailAction }}</button>
                <button v-if="canWrite && operator.status === 1" class="table-action table-action--danger" type="button" :disabled="acting" @click="openStaffDisable(operator)">{{ strings.merchantManagement.staff.disableAction }}</button>
                <button v-if="canWrite && operator.status === 2" class="table-action" type="button" :disabled="acting" @click="enableStaff(operator)">{{ strings.merchantManagement.staff.enableAction }}</button>
              </div></td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pager">
        <button class="ghost-button system-pager-button" type="button" :disabled="staffFilters.page <= 1" @click="goStaffPage(staffFilters.page - 1)">{{ strings.merchantManagement.staff.previousPage }}</button>
        <span class="numeric-cell">{{ strings.merchantManagement.staff.page(staffFilters.page) }}</span>
        <button class="ghost-button system-pager-button" type="button" :disabled="!staffPageState?.hasMore" @click="goStaffPage(staffFilters.page + 1)">{{ strings.merchantManagement.staff.nextPage }}</button>
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

    <div v-if="staffDetailLoading" class="audit-drawer"><p class="inline-note">{{ strings.merchantManagement.staff.detailLoading }}</p></div>
    <div v-else-if="staffDetail" class="audit-drawer">
      <div><p class="eyebrow">{{ strings.merchantManagement.staff.detailEyebrow }}</p><h2>{{ operatorLabel(staffDetail) }}</h2><p>{{ strings.merchantManagement.staff.detailSummary(staffDetail.account) }}</p></div>
      <dl class="detail-grid">
        <div><dt>{{ strings.merchantManagement.staff.detailFields.roles }}</dt><dd>{{ operatorRolesText(staffDetail) }}</dd></div>
        <div><dt>{{ strings.merchantManagement.staff.detailFields.shopScope }}</dt><dd>{{ operatorScopeText(staffDetail) }}</dd></div>
        <div><dt>{{ strings.merchantManagement.staff.detailFields.status }}</dt><dd>{{ operatorStatusText(staffDetail) }}</dd></div>
        <div><dt>{{ strings.merchantManagement.staff.detailFields.disableReason }}</dt><dd>{{ staffDetail.disableReason || '--' }}</dd></div>
        <div><dt>{{ strings.merchantManagement.staff.detailFields.createdAt }}</dt><dd>{{ staffDetail.createdAt || '--' }}</dd></div>
        <div><dt>{{ strings.merchantManagement.staff.detailFields.updatedAt }}</dt><dd>{{ staffDetail.updatedAt || '--' }}</dd></div>
      </dl>
      <div class="form-actions"><button class="ghost-button" type="button" @click="staffDetail = null">{{ strings.merchantManagement.staff.close }}</button></div>
    </div>

    <div v-if="staffDisableTarget" class="audit-drawer">
      <div><p class="eyebrow">{{ strings.merchantManagement.staff.disableEyebrow }}</p><h2>{{ operatorLabel(staffDisableTarget) }}</h2><p>{{ strings.merchantManagement.staff.disableDescription }}</p></div>
      <label class="field field--full"><span>{{ strings.merchantManagement.staff.disableReasonField }}</span><textarea v-model="staffDisableReason" name="staffDisableReason" rows="4" :placeholder="strings.merchantManagement.staff.disablePlaceholder" /></label>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="staffDisableTarget = null">{{ strings.common.cancel }}</button>
        <button class="secondary-button" type="button" :disabled="acting" @click="confirmStaffDisable">{{ strings.merchantManagement.staff.confirmDisable }}</button>
      </div>
    </div>
  </section>
</template>
