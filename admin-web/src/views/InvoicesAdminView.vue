<script setup lang="ts">
import { ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  fetchAdminInvoices,
  fetchAdminTaxRates,
  issueAdminInvoice,
  rejectAdminInvoice,
  updateAdminTaxRate,
  type OpsInvoice,
  type OpsTaxRate,
} from '@/services/ops'

const { state } = useAdminSession()
const invoices = ref<OpsInvoice[]>([])
const rates = ref<OpsTaxRate[]>([])
const drafts = ref<Record<number, string>>({})
const errorMessage = ref('')
const canWrite = () => state.permissions.includes('finance:invoice:write')

async function load() {
  errorMessage.value = ''
  try {
    invoices.value = (await fetchAdminInvoices()).list
    rates.value = await fetchAdminTaxRates()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

async function issue(item: OpsInvoice) {
  await issueAdminInvoice(item.id, (drafts.value[item.id] ?? '').trim())
  await load()
}

async function reject(item: OpsInvoice) {
  await rejectAdminInvoice(item.id, (drafts.value[item.id] ?? '').trim())
  await load()
}

async function saveRate(rate: OpsTaxRate) {
  await updateAdminTaxRate(rate.id, { name: rate.name, rateBp: Number(rate.rateBp), status: Number(rate.status) })
  await load()
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>发票与税率</h1>
      <p class="page-desc">税额按当前区域已启用税率中 id 最大的一条计算。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <table class="data-table">
      <tbody>
        <tr v-for="item in invoices" :key="item.id">
          <td>#{{ item.orderId }} {{ item.amount }} / {{ item.taxAmount }} {{ item.currency }}</td>
          <td>{{ item.statusText }} {{ item.invoiceNo }} {{ item.rejectReason }}</td>
          <td v-if="canWrite() && item.status === 1">
            <input v-model="drafts[item.id]" placeholder="发票号或驳回原因" />
            <button type="button" @click="issue(item)">开票</button>
            <button type="button" @click="reject(item)">驳回</button>
          </td>
        </tr>
      </tbody>
    </table>
    <h2>税率</h2>
    <form v-for="rate in rates" :key="rate.id" @submit.prevent="saveRate(rate)">
      <input v-model="rate.name" :disabled="!canWrite()" />
      <input v-model.number="rate.rateBp" type="number" min="0" :disabled="!canWrite()" />
      <select v-model.number="rate.status" :disabled="!canWrite()">
        <option :value="1">启用</option>
        <option :value="0">停用</option>
      </select>
      <button v-if="canWrite()" type="submit">保存</button>
    </form>
  </section>
</template>
