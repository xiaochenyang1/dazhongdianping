<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminInvoiceStrings } from '@/core/admin_invoice_localizations'
import { saveDownload } from '@/lib/save-download'
import { fetchAdminInvoices, fetchAdminTaxRates, uploadAdminInvoice, downloadAdminInvoice,
  rejectAdminInvoice, updateAdminTaxRate, type OpsInvoice, type OpsTaxRate } from '@/services/ops'

const { state } = useAdminSession()
const copy = computed(() => adminInvoiceStrings(state.region))
const invoices = ref<OpsInvoice[]>([])
const rates = ref<OpsTaxRate[]>([])
const numbers = ref<Record<number, string>>({})
const reasons = ref<Record<number, string>>({})
const files = ref<Record<number, File>>({})
const errorMessage = ref('')
const successMessage = ref('')
const loading = ref(false)
const acting = ref(false)
const busy = computed(() => loading.value || acting.value)
const canWrite = computed(() => state.permissions.includes('finance:invoice:write'))
const page = ref(1)
const hasMore = ref(false)
let generation = 0
onBeforeUnmount(() => { generation++ })

async function load(target = page.value) {
  if (busy.value) return
  const current = generation
  loading.value = true
  errorMessage.value = ''
  try {
    const [result, taxRates] = await Promise.all([fetchAdminInvoices(target), fetchAdminTaxRates()])
    if (current !== generation) return
    invoices.value = result.list
    rates.value = taxRates
    page.value = result.page
    hasMore.value = result.hasMore
  } catch (error) {
    if (current === generation) errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  } finally {
    if (current === generation) loading.value = false
  }
}

function chooseFile(item: OpsInvoice, event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  delete files.value[item.id]
  if (!file) return
  if (!file.name.toLowerCase().endsWith('.pdf') || file.size === 0 || file.size > 5 * 1024 * 1024) {
    errorMessage.value = copy.value.invalid
    input.value = ''
    return
  }
  errorMessage.value = ''
  files.value[item.id] = file
}

async function act(work: () => Promise<void>) {
  if (busy.value) return
  const current = generation
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try { await work() } catch (error) {
    if (current === generation) errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  } finally { if (current === generation) acting.value = false }
}

function upload(item: OpsInvoice) {
  if (!canWrite.value || item.documentAvailable || ![1, 2].includes(item.status)) return
  const number = item.status === 2 ? item.invoiceNo : (numbers.value[item.id] ?? '').trim()
  const file = files.value[item.id]
  if (!number || !file) { errorMessage.value = copy.value.invalid; return }
  const current = generation
  return act(async () => {
    const result = await uploadAdminInvoice(item.id, number, file)
    if (current !== generation) return
    Object.assign(item, result)
    delete files.value[item.id]
    delete numbers.value[item.id]
    successMessage.value = copy.value.published
  })
}

function reject(item: OpsInvoice) {
  if (!canWrite.value || item.status !== 1) return
  const reason = (reasons.value[item.id] ?? '').trim()
  if (!reason) { errorMessage.value = copy.value.reasonRequired; return }
  const current = generation
  return act(async () => {
    const result = await rejectAdminInvoice(item.id, reason)
    if (current !== generation) return
    Object.assign(item, result)
    delete files.value[item.id]
    delete reasons.value[item.id]
  })
}

function download(item: OpsInvoice) {
  const current = generation
  return act(async () => {
    const blob = await downloadAdminInvoice(item.id)
    if (current === generation) saveDownload(blob, `invoice-${item.id}.pdf`)
  })
}

function saveRate(rate: OpsTaxRate) {
  if (!canWrite.value) return
  const current = generation
  return act(async () => {
    const result = await updateAdminTaxRate(rate.id, { name: rate.name, rateBp: Number(rate.rateBp), status: Number(rate.status) })
    if (current !== generation) return
    Object.assign(rate, result)
    successMessage.value = copy.value.saved
  })
}

watch(() => [state.region, state.profile?.id, state.token], () => {
  generation++
  invoices.value = []; rates.value = []; numbers.value = {}; reasons.value = {}; files.value = {}
  errorMessage.value = ''; successMessage.value = ''; page.value = 1; hasMore.value = false
  loading.value = false; acting.value = false
  void load()
}, { immediate: true, flush: 'sync' })
</script>

<template>
  <section class="page invoice-page">
    <header class="page-header"><h1>{{ copy.title }}</h1><p class="page-desc">{{ copy.summary }}</p></header>
    <button class="secondary-button" type="button" :disabled="busy" @click="load()">{{ copy.refresh }}</button>
    <p v-if="errorMessage" role="alert" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" role="status" class="feedback">{{ successMessage }}</p>
    <p v-if="!loading && !invoices.length">{{ copy.empty }}</p>
    <div v-else class="invoice-table-scroll"><table class="data-table" :aria-busy="busy">
      <thead><tr><th>{{ copy.customer }}</th><th>{{ copy.amount }}</th><th>{{ copy.delivery }}</th><th>{{ copy.actions }}</th></tr></thead>
      <tbody><tr v-for="item in invoices" :key="item.id" :data-testid="`admin-invoice-${item.id}`">
        <td>{{ item.orderNo || item.orderId }}<br />{{ item.titleType === 2 ? copy.company : copy.personal }} · {{ item.titleName }}<br />{{ item.taxNo }}<br />{{ item.email }}</td>
        <td>{{ item.amount }} / {{ item.taxAmount }} {{ item.currency }}</td>
        <td>{{ item.status === 2 ? copy.issued : item.status === 3 ? copy.rejected : copy.pending }} · {{ item.invoiceNo }} {{ item.rejectReason }}
          <p v-if="item.documentAvailable">{{ item.receivedAt ? copy.received : copy.delivered }}<br />{{ (item.receivedAt || item.documentUploadedAt)?.replace('T', ' ').slice(0, 19) }}</p>
          <p v-else-if="item.status !== 3">{{ copy.awaiting }}</p>
        </td>
        <td>
          <button class="secondary-button" v-if="item.documentAvailable" type="button" :disabled="busy" @click="download(item)">{{ copy.download }}</button>
          <form v-if="canWrite && !item.documentAvailable && [1, 2].includes(item.status)" @submit.prevent="upload(item)">
            <label class="field">{{ copy.number }}<input v-if="item.status === 1" v-model="numbers[item.id]" required maxlength="64" :disabled="busy" :data-testid="`invoice-number-${item.id}`" /><input v-else :value="item.invoiceNo" disabled /></label>
            <label class="field">{{ copy.file }}<input type="file" accept="application/pdf,.pdf" :disabled="busy" :data-testid="`invoice-file-${item.id}`" @change="chooseFile(item, $event)" /></label>
            <button class="primary-button" type="submit" :disabled="busy || !files[item.id]" :data-testid="`invoice-upload-${item.id}`">{{ copy.upload }}</button>
          </form>
          <form v-if="canWrite && item.status === 1" @submit.prevent="reject(item)">
            <label class="field">{{ copy.rejectReason }}<input v-model="reasons[item.id]" required maxlength="255" :disabled="busy" /></label>
            <button class="primary-button" type="submit" :disabled="busy">{{ copy.reject }}</button>
          </form>
        </td>
      </tr></tbody>
    </table></div>
    <nav><button class="ghost-button" :disabled="busy || page <= 1" @click="load(page - 1)">{{ copy.previous }}</button> {{ page }} <button class="ghost-button" :disabled="busy || !hasMore" @click="load(page + 1)">{{ copy.next }}</button></nav>
    <h2>{{ copy.rates }}</h2><p>{{ copy.rateHelp }}</p>
    <form class="tax-rate-form" v-for="rate in rates" :key="rate.id" @submit.prevent="saveRate(rate)">
      <label class="field">{{ copy.rateName }}<input v-model="rate.name" required maxlength="64" :disabled="busy || !canWrite" /></label>
      <label class="field">{{ copy.rateBp }}<input v-model.number="rate.rateBp" type="number" required min="0" max="10000" :disabled="busy || !canWrite" /></label>
      <select v-model.number="rate.status" :aria-label="copy.rates" :disabled="busy || !canWrite"><option :value="1">{{ copy.enabled }}</option><option :value="0">{{ copy.disabled }}</option></select>
      <button class="secondary-button" v-if="canWrite" type="submit" :disabled="busy">{{ copy.save }}</button>
    </form>
  </section>
</template>

<style scoped>
.invoice-page { display: grid; gap: 1rem; }
.invoice-page > button { justify-self: start; }
.invoice-table-scroll { overflow-x: auto; border: 1px solid var(--border); border-radius: 1rem; background: var(--panel); }
.invoice-page td { vertical-align: top; min-width: 130px; overflow-wrap: anywhere; }
.invoice-page td:last-child { min-width: 230px; }
.invoice-page form { display: grid; gap: .75rem; padding: .75rem 0; }
.invoice-page nav { display: flex; align-items: center; gap: 1rem; }
.invoice-page .tax-rate-form { grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); align-items: end; padding: 1rem; background: var(--panel); border: 1px solid var(--border); border-radius: 1rem; }
</style>
