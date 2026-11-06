<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { saveDownload } from '@/lib/save-download'
import { useUserSession } from '@/composables/useUserSession'
import { useAppContext } from '@/composables/useAppContext'
import { invoiceStringsForRegion } from '@/core/web_invoice_localizations'
import { confirmInvoiceReceipt, downloadInvoice, createInvoiceTitle, fetchInvoiceTitles, fetchInvoices, requestInvoice } from '@/services/invoice'
import type { InvoiceRequest, InvoiceTitle } from '@/types/invoice'

const route = useRoute()
const { state } = useAppContext()
const { state: user } = useUserSession()
const copy = computed(() => invoiceStringsForRegion(state.region))
const titles = ref<InvoiceTitle[]>([])
const invoices = ref<InvoiceRequest[]>([])
const errorMessage = ref('')
const loading = ref(false)
const titleType = ref(1)
const name = ref('')
const taxNo = ref('')
const email = ref('')
const orderId = ref(route.query.orderId ? String(route.query.orderId) : '')
const titleId = ref('')
const page = ref(1)
const hasMore = ref(false)
const acting = ref(false)
const successMessage = ref('')
const busy = computed(() => loading.value || acting.value)
let generation = 0
onBeforeUnmount(() => { generation++ })

async function load(target = page.value) {
  if (loading.value) return
  const current = generation
  loading.value = true
  errorMessage.value = ''
  try {
    const [newTitles, result] = await Promise.all([fetchInvoiceTitles(), fetchInvoices(target)])
    if (current !== generation) return
    titles.value = newTitles
    invoices.value = result.list
    page.value = result.page
    hasMore.value = result.hasMore
    if (!titleId.value && titles.value[0]) titleId.value = String(titles.value[0].id)
  } catch (error) {
    if (current === generation) errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally { if (current === generation) loading.value = false }
}

async function act(work: () => Promise<void>) {
  if (busy.value) return
  const current = generation
  acting.value = true
  errorMessage.value = ''; successMessage.value = ''
  try { await work() } catch (error) {
    if (current === generation) errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally { if (current === generation) acting.value = false }
}

function saveTitle() {
  const current = generation
  return act(async () => {
    const title = await createInvoiceTitle({ titleType: titleType.value, name: name.value.trim(),
      taxNo: taxNo.value.trim(), email: email.value.trim(), isDefault: titles.value.length === 0 })
    if (current !== generation) return
    titles.value = [title, ...titles.value]
    titleId.value = String(title.id)
    name.value = ''; taxNo.value = ''; email.value = ''
  })
}

function submitRequest() {
  const current = generation
  return act(async () => {
    await requestInvoice({ orderId: Number(orderId.value), titleId: Number(titleId.value) })
    if (current === generation) await load(1)
  })
}

function download(item: InvoiceRequest) {
  const current = generation
  return act(async () => {
    const blob = await downloadInvoice(item.id)
    if (current !== generation) return
    saveDownload(blob, `invoice-${item.id}.pdf`)
    successMessage.value = copy.value.downloadStarted
  })
}

function confirmReceipt(item: InvoiceRequest) {
  if (!item.documentSha256 || item.receivedAt) return
  const current = generation
  return act(async () => {
    const result = await confirmInvoiceReceipt(item.id, item.documentSha256!)
    if (current !== generation) return
    Object.assign(item, result)
    successMessage.value = copy.value.received
  })
}

watch(() => [state.region, user.currentUser?.id], () => {
  generation++
  titles.value = []; invoices.value = []; titleId.value = ''; name.value = ''; taxNo.value = ''; email.value = ''
  page.value = 1; hasMore.value = false; loading.value = false; acting.value = false; successMessage.value = ''; errorMessage.value = ''
  void load()
}, { immediate: true, flush: 'sync' })
</script>

<template>
  <section class="invoice-page">
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>
    <button class="secondary-button" type="button" :disabled="busy" @click="load()">{{ copy.refresh }}</button>
    <form class="invoice-title-form" @submit.prevent="saveTitle">
      <label class="field">
        <span>{{ copy.titleType }}</span>
        <select v-model.number="titleType">
          <option :value="1">{{ copy.personal }}</option>
          <option :value="2">{{ copy.company }}</option>
        </select>
      </label>
      <label class="field"><span>{{ copy.name }}</span><input v-model="name" required maxlength="128" /></label>
      <label class="field"><span>{{ copy.taxNo }}</span><input v-model="taxNo" :required="titleType === 2" /></label>
      <label class="field"><span>{{ copy.email }}</span><input v-model="email" type="email" /></label>
      <button class="secondary-button" type="submit" :disabled="busy">{{ copy.saveTitle }}</button>
    </form>
    <form @submit.prevent="submitRequest">
      <label class="field"><span>{{ copy.orderId }}</span><input v-model="orderId" type="number" min="1" required data-testid="invoice-order" /></label>
      <label class="field">
        <span>{{ copy.titleId }}</span>
        <select v-model="titleId" required data-testid="invoice-title">
          <option v-for="title in titles" :key="title.id" :value="String(title.id)">{{ title.name }}</option>
        </select>
      </label>
      <button class="primary-button" type="submit" :disabled="busy" data-testid="invoice-request">{{ copy.request }}</button>
    </form>
    <p v-if="successMessage" role="status" class="feedback">{{ successMessage }}</p>
    <p v-if="errorMessage" role="alert" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="invoices.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-if="invoices.length" class="invoice-history">
      <li v-for="item in invoices" :key="item.id" :data-testid="`invoice-${item.id}`">
        #{{ item.orderId }} · {{ item.status === 2 ? copy.issued : item.status === 3 ? copy.rejected : copy.pending }} · {{ copy.amount }} {{ item.amount }} · {{ copy.tax }} {{ item.taxAmount }}
        <span v-if="item.invoiceNo"> · {{ item.invoiceNo }}</span>
        <span v-if="item.rejectReason"> · {{ item.rejectReason }}</span>
        <template v-if="item.documentAvailable">
          <button class="secondary-button" type="button" :disabled="busy" :data-testid="`invoice-download-${item.id}`" @click="download(item)">{{ copy.download }}</button>
          <p v-if="item.receivedAt">{{ copy.received }} · {{ item.receivedAt.replace('T', ' ').slice(0, 19) }}</p>
          <template v-else>
            <p>{{ copy.receiptHelp }}</p>
            <button class="secondary-button" type="button" :disabled="busy" :data-testid="`invoice-receipt-${item.id}`" @click="confirmReceipt(item)">{{ copy.confirmReceipt }}</button>
          </template>
        </template>
        <p v-else-if="item.status === 2">{{ copy.awaiting }}</p>
      </li>
    </ul>
    <nav><button class="ghost-button" :disabled="busy || page <= 1" @click="load(page - 1)">{{ copy.previous }}</button> {{ page }} <button class="ghost-button" :disabled="busy || !hasMore" @click="load(page + 1)">{{ copy.next }}</button></nav>
  </section>
</template>

<style scoped>
.invoice-page { display: grid; gap: 1rem; }
.invoice-page > form, .invoice-history > li { padding: 1.25rem; border: 1px solid var(--border); border-radius: 1.25rem; background: var(--panel); }
.invoice-page > form { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; align-items: end; }
.invoice-page > button { justify-self: start; }
.invoice-page nav { display: flex; gap: 1rem; align-items: center; }
.invoice-history { display: grid; gap: 1rem; padding: 0; margin: 0; list-style: none; }
.invoice-history button { margin: .5rem; }
@media (max-width: 640px) { .invoice-page > form { grid-template-columns: 1fr; } }
</style>
