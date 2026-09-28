<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { fetchCouponTemplates, createCouponTemplate, updateCouponTemplate } from '@/services/admin'
import { auditCouponTemplate } from '@/services/ops'
import type { CouponTemplate, CouponTemplatePayload } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const copy = computed(() => strings.value.marketingCoupons)
const canWrite = computed(() => state.permissions.includes('operations:marketing:write'))

const templates = ref<CouponTemplate[]>([])
const errorMessage = ref('')
const successMessage = ref('')
const saving = ref(false)
const editingId = ref<number | null>(null)
const formOpen = ref(false)

const defaultCurrency = computed(() => (state.region === 'EU' ? 'EUR' : 'CNY'))

const form = reactive<CouponTemplatePayload>({
  name: '',
  type: 1,
  thresholdAmount: 0,
  discountAmount: 0,
  currency: 'CNY',
  shopId: 0,
  totalQuantity: 0,
  perUserLimit: 1,
  validDays: 7,
  status: 1,
})

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

async function load() {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const page = await fetchCouponTemplates({ page: 1, pageSize: 50 })
    templates.value = page.list
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

function resetForm() {
  form.name = ''
  form.type = 1
  form.thresholdAmount = 0
  form.discountAmount = 0
  form.currency = defaultCurrency.value
  form.shopId = 0
  form.totalQuantity = 0
  form.perUserLimit = 1
  form.validDays = 7
  form.status = 1
}

function openCreate() {
  if (!canWrite.value) return
  editingId.value = null
  resetForm()
  successMessage.value = ''
  errorMessage.value = ''
  formOpen.value = true
}

function openEdit(t: CouponTemplate) {
  if (!canWrite.value) return
  editingId.value = t.id
  form.name = t.name
  form.type = t.type
  form.thresholdAmount = t.thresholdAmount
  form.discountAmount = t.discountAmount
  form.currency = t.currency
  form.shopId = t.shopId
  form.totalQuantity = t.totalQuantity
  form.perUserLimit = t.perUserLimit
  form.validDays = t.validDays
  form.status = t.status
  successMessage.value = ''
  errorMessage.value = ''
  formOpen.value = true
}

function closeForm() {
  formOpen.value = false
  editingId.value = null
}

async function submit() {
  if (!canWrite.value) return
  errorMessage.value = ''
  successMessage.value = ''
  saving.value = true
  const payload: CouponTemplatePayload = {
    name: form.name,
    type: form.type,
    thresholdAmount: form.type === 2 ? 0 : form.thresholdAmount,
    discountAmount: form.discountAmount,
    currency: form.currency,
    shopId: form.shopId,
    totalQuantity: form.totalQuantity,
    perUserLimit: form.perUserLimit,
    validDays: form.validDays,
    status: form.status,
  }
  const targetId = editingId.value
  const created = targetId == null
  try {
    if (targetId == null) {
      await createCouponTemplate(payload)
    } else {
      await updateCouponTemplate(targetId, payload)
    }
    closeForm()
    await load()
    successMessage.value = created ? copy.value.created : copy.value.saved
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.saveError)
  } finally {
    saving.value = false
  }
}

function typeText(type: number) {
  return type === 2 ? copy.value.typeNewcomer : copy.value.typeThreshold
}

function scopeText(shopId: number) {
  return shopId === 0 ? copy.value.scopePlatform : copy.value.scopeShop(shopId)
}

function quotaText(t: CouponTemplate) {
  return t.totalQuantity === 0 ? copy.value.quotaUnlimited : copy.value.quotaText(t.claimedQuantity, t.totalQuantity)
}

async function audit(id: number, approve: boolean) {
  if (!canWrite.value) return
  errorMessage.value = ''
  try {
    await auditCouponTemplate(id, approve, approve ? '' : '不符合规则')
    successMessage.value = approve ? '已通过' : '已驳回'
    await load()
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

watch(() => state.region, () => { closeForm(); resetForm(); load() }, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>{{ copy.title }}</h1>
      <p class="page-desc">{{ copy.description }}</p>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="toolbar">
      <button v-if="canWrite" type="button" @click="openCreate">{{ copy.create }}</button>
      <p v-else class="feedback">{{ copy.readOnly }}</p>
    </div>

    <table class="data-table">
      <thead>
        <tr>
          <th>{{ copy.colName }}</th>
          <th>{{ copy.colType }}</th>
          <th>{{ copy.colDiscount }}</th>
          <th>{{ copy.colThreshold }}</th>
          <th>{{ copy.colScope }}</th>
          <th>{{ copy.colQuota }}</th>
          <th>{{ copy.colPerUser }}</th>
          <th>{{ copy.colValidDays }}</th>
          <th>{{ copy.colStatus }}</th>
          <th>{{ copy.colActions }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="t in templates" :key="t.id" :data-id="t.id">
          <td>{{ t.name }}</td>
          <td>{{ typeText(t.type) }}</td>
          <td>{{ t.discountAmount }} {{ t.currency }}</td>
          <td>{{ t.type === 2 ? '-' : t.thresholdAmount }}</td>
          <td>{{ scopeText(t.shopId) }}</td>
          <td>{{ quotaText(t) }}</td>
          <td>{{ t.perUserLimit }}</td>
          <td>{{ t.validDays }}</td>
          <td>{{ t.status === 1 ? copy.statusOn : copy.statusOff }}</td>
          <td>
            <button v-if="canWrite" type="button" class="link" @click="openEdit(t)">{{ copy.edit }}</button>
            <button v-if="canWrite" type="button" class="link" @click="audit(t.id, true)">通过</button>
            <button v-if="canWrite" type="button" class="link" @click="audit(t.id, false)">驳回</button>
          </td>
        </tr>
        <tr v-if="templates.length === 0">
          <td colspan="10" class="empty">{{ copy.empty }}</td>
        </tr>
      </tbody>
    </table>

    <form v-if="formOpen" class="coupon-form" @submit.prevent="submit">
      <label>
        <span>{{ copy.fieldName }}</span>
        <input v-model="form.name" type="text" maxlength="128" required />
      </label>
      <label>
        <span>{{ copy.fieldType }}</span>
        <select v-model.number="form.type">
          <option :value="1">{{ copy.typeThreshold }}</option>
          <option :value="2">{{ copy.typeNewcomer }}</option>
        </select>
      </label>
      <label v-if="form.type !== 2">
        <span>{{ copy.fieldThreshold }}</span>
        <input v-model.number="form.thresholdAmount" type="number" min="0" step="0.01" />
      </label>
      <label>
        <span>{{ copy.fieldDiscount }}</span>
        <input v-model.number="form.discountAmount" type="number" min="0.01" step="0.01" required />
      </label>
      <label>
        <span>{{ copy.fieldCurrency }}</span>
        <input v-model="form.currency" type="text" maxlength="3" required />
      </label>
      <label>
        <span>{{ copy.fieldShopId }}</span>
        <input v-model.number="form.shopId" type="number" min="0" />
      </label>
      <label>
        <span>{{ copy.fieldTotalQuantity }}</span>
        <input v-model.number="form.totalQuantity" type="number" min="0" />
      </label>
      <label>
        <span>{{ copy.fieldPerUserLimit }}</span>
        <input v-model.number="form.perUserLimit" type="number" min="1" max="50" />
      </label>
      <label>
        <span>{{ copy.fieldValidDays }}</span>
        <input v-model.number="form.validDays" type="number" min="1" max="365" />
      </label>
      <label>
        <span>{{ copy.fieldStatus }}</span>
        <select v-model.number="form.status">
          <option :value="1">{{ copy.statusOn }}</option>
          <option :value="0">{{ copy.statusOff }}</option>
        </select>
      </label>
      <div class="form-actions">
        <button type="submit" :disabled="saving">{{ copy.save }}</button>
        <button type="button" class="secondary" @click="closeForm">{{ copy.cancel }}</button>
      </div>
    </form>
  </section>
</template>
