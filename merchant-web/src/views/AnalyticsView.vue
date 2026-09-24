<script setup lang="ts">
import { computed, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { fetchShops, type MerchantShopOption } from '@/services/merchant'
import { exportTrend, fetchAdReport, fetchTrend, type AdReportCampaign, type TrendPoint } from '@/services/ops'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), { permissions: () => [] })
const { state } = useMerchantSession()
const zh = computed(() => state.region !== 'EU')
const canAnalytics = computed(() => props.permissions.includes('analytics:view'))
const canAds = computed(() => props.permissions.includes('ad:view'))
const shops = ref<MerchantShopOption[]>([])
const shopId = ref<number | ''>('')
const days = ref(7)
const points = ref<TrendPoint[]>([])
const csv = ref('')
const campaigns = ref<AdReportCampaign[]>([])
const errorMessage = ref('')

async function load() {
  errorMessage.value = ''
  csv.value = ''
  try {
    shops.value = (await fetchShops({ page: 1, pageSize: 50 })).list
    if (shopId.value === '' && shops.value[0]) shopId.value = shops.value[0].id
    if (shopId.value === '') return
    if (canAnalytics.value) points.value = (await fetchTrend(Number(shopId.value), days.value)).list
    if (canAds.value) campaigns.value = (await fetchAdReport(Number(shopId.value))).campaigns
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Load failed'
  }
}

async function download() {
  csv.value = await exportTrend(Number(shopId.value), days.value)
}

load()
</script>

<template>
  <section>
    <p class="muted">{{ zh ? '没有数据的日期记 0。导出是 CSV 文本。' : 'Missing days are zero. Export is a CSV string.' }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <label>
      {{ zh ? '门店' : 'Shop' }}
      <select v-model="shopId" @change="load">
        <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
      </select>
    </label>
    <label v-if="canAnalytics">
      {{ zh ? '天数' : 'Days' }}
      <input v-model.number="days" type="number" min="1" max="30" @change="load" />
    </label>
    <table v-if="canAnalytics" class="data-table">
      <thead><tr><th>date</th><th>views</th><th>orders</th><th>amount</th></tr></thead>
      <tbody>
        <tr v-for="point in points" :key="point.date">
          <td>{{ point.date }}</td><td>{{ point.views }}</td><td>{{ point.orders }}</td><td>{{ point.amount }}</td>
        </tr>
      </tbody>
    </table>
    <button v-if="canAnalytics" type="button" @click="download">CSV</button>
    <pre v-if="csv">{{ csv }}</pre>
    <h2 v-if="canAds">{{ zh ? '广告报表' : 'Ad report' }}</h2>
    <ul v-if="canAds">
      <li v-for="item in campaigns" :key="item.id">
        {{ item.name }} · {{ item.clickCount }} · {{ item.clickCost }} · {{ item.totalSpent }}
      </li>
    </ul>
  </section>
</template>
