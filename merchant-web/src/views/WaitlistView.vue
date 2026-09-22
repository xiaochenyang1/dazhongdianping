<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  callWaitlist,
  fetchShops,
  fetchWaitlistQueue,
  passWaitlist,
  seatWaitlist,
  type MerchantShopOption,
  type WaitlistEntry,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const copy = computed(() => strings.value.waitlist)
const canManage = computed(() => props.permissions.includes('waitlist:manage'))

const loading = ref(true)
const error = ref('')
const shops = ref<MerchantShopOption[]>([])
const shopId = ref<number | null>(null)
const entries = ref<WaitlistEntry[]>([])

async function loadShopsThenQueue() {
  loading.value = true
  error.value = ''
  try {
    shops.value = (await fetchShops({ page: 1, pageSize: 100 })).list
    if (shopId.value == null && shops.value.length > 0) shopId.value = shops.value[0].id
    await loadQueue()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    loading.value = false
  }
}

async function loadQueue() {
  if (shopId.value == null) {
    entries.value = []
    return
  }
  error.value = ''
  try {
    entries.value = await fetchWaitlistQueue(shopId.value)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.loadError
  }
}

async function act(entry: WaitlistEntry, action: 'call' | 'seat' | 'pass') {
  if (!canManage.value) return
  error.value = ''
  try {
    if (action === 'call') await callWaitlist(entry.id)
    else if (action === 'seat') await seatWaitlist(entry.id)
    else await passWaitlist(entry.id)
    await loadQueue()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.actionError
  }
}

onMounted(loadShopsThenQueue)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">{{ copy.summary }}</span>
      <label>
        {{ copy.shopLabel }}
        <select v-model.number="shopId" @change="loadQueue">
          <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
        </select>
      </label>
      <button type="button" @click="loadQueue">{{ strings.common.refresh }}</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="!canManage" class="muted">{{ copy.readOnly }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>

    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ copy.headers.queueNo }}</th>
            <th>{{ copy.headers.customer }}</th>
            <th>{{ copy.headers.tableType }}</th>
            <th>{{ copy.headers.partySize }}</th>
            <th>{{ copy.headers.status }}</th>
            <th>{{ copy.headers.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in entries" :key="e.id">
            <td>{{ e.queueNo }}</td>
            <td>{{ e.userNickname }}</td>
            <td>{{ copy.tableTypeText(e.tableType, e.tableTypeText) }}</td>
            <td>{{ e.partySize }}</td>
            <td>{{ copy.statusText(e.status, e.statusText) }}</td>
            <td>
              <template v-if="canManage">
                <button v-if="e.status === 1" type="button" :data-testid="`call-${e.id}`" @click="act(e, 'call')">{{ copy.call }}</button>
                <button v-if="e.status === 1 || e.status === 2" type="button" :data-testid="`seat-${e.id}`" @click="act(e, 'seat')">{{ copy.seat }}</button>
                <button v-if="e.status === 2" type="button" :data-testid="`pass-${e.id}`" @click="act(e, 'pass')">{{ copy.pass }}</button>
              </template>
            </td>
          </tr>
          <tr v-if="entries.length === 0"><td colspan="6" class="feedback">{{ copy.empty }}</td></tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
