<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { invoiceStringsForRegion } from '@/core/web_invoice_localizations'
import { createInvoiceTitle, fetchInvoiceTitles, fetchInvoices, requestInvoice } from '@/services/invoice'
import type { InvoiceRequest, InvoiceTitle } from '@/types/invoice'

const route = useRoute()
const { state } = useAppContext()
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

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    titles.value = await fetchInvoiceTitles()
    invoices.value = (await fetchInvoices()).list
    if (!titleId.value && titles.value[0]) titleId.value = String(titles.value[0].id)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function saveTitle() {
  errorMessage.value = ''
  try {
    await createInvoiceTitle({
      titleType: titleType.value,
      name: name.value.trim(),
      taxNo: taxNo.value.trim(),
      email: email.value.trim(),
      isDefault: titles.value.length === 0,
    })
    name.value = ''
    taxNo.value = ''
    email.value = ''
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

async function submitRequest() {
  errorMessage.value = ''
  try {
    await requestInvoice({ orderId: Number(orderId.value), titleId: Number(titleId.value) })
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section>
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>
    <form class="invoice-title-form" @submit.prevent="saveTitle">
      <label class="field">
        <span>{{ copy.name }}</span>
        <select v-model.number="titleType">
          <option :value="1">{{ copy.personal }}</option>
          <option :value="2">{{ copy.company }}</option>
        </select>
      </label>
      <label class="field"><span>{{ copy.name }}</span><input v-model="name" required maxlength="128" /></label>
      <label class="field"><span>{{ copy.taxNo }}</span><input v-model="taxNo" :required="titleType === 2" /></label>
      <label class="field"><span>{{ copy.email }}</span><input v-model="email" type="email" /></label>
      <button class="secondary-button" type="submit">{{ copy.saveTitle }}</button>
    </form>
    <form @submit.prevent="submitRequest">
      <label class="field"><span>{{ copy.orderId }}</span><input v-model="orderId" type="number" min="1" required data-testid="invoice-order" /></label>
      <label class="field">
        <span>{{ copy.titleId }}</span>
        <select v-model="titleId" required data-testid="invoice-title">
          <option v-for="title in titles" :key="title.id" :value="String(title.id)">{{ title.name }}</option>
        </select>
      </label>
      <button class="primary-button" type="submit" data-testid="invoice-request">{{ copy.request }}</button>
    </form>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="invoices.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-else>
      <li v-for="item in invoices" :key="item.id">
        #{{ item.orderId }} · {{ item.statusText }} · {{ copy.amount }} {{ item.amount }} · {{ copy.tax }} {{ item.taxAmount }}
        <span v-if="item.invoiceNo"> · {{ item.invoiceNo }}</span>
        <span v-if="item.rejectReason"> · {{ item.rejectReason }}</span>
      </li>
    </ul>
  </section>
</template>
