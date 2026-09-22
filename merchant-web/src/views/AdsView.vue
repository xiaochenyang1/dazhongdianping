<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  createAd,
  fetchAds,
  fetchShops,
  pauseAd,
  resumeAd,
  updateAd,
  type MerchantAdCampaign,
  type MerchantAdPayload,
  type MerchantShopOption,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const copy = computed(() => strings.value.ads)
const canView = computed(() => props.permissions.includes('ad:view'))
const canManage = computed(() => props.permissions.includes('ad:manage'))

const loading = ref(true)
const error = ref('')
const success = ref('')
const items = ref<MerchantAdCampaign[]>([])
const shops = ref<MerchantShopOption[]>([])
const formOpen = ref(false)
const editingId = ref<number | null>(null)

const form = reactive<MerchantAdPayload>({
  shopId: 0,
  name: '',
  slotType: 1,
  keyword: '',
  bidCpc: 1,
  dailyBudget: 0,
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [ads, shopPage] = await Promise.all([
      fetchAds({ page: 1, pageSize: 50 }),
      fetchShops({ page: 1, pageSize: 100 }),
    ])
    items.value = ads.list
    shops.value = shopPage.list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    loading.value = false
  }
}

function openCreate() {
  if (!canManage.value) return
  editingId.value = null
  form.shopId = shops.value[0]?.id ?? 0
  form.name = ''
  form.slotType = 1
  form.keyword = ''
  form.bidCpc = 1
  form.dailyBudget = 0
  success.value = ''
  error.value = ''
  formOpen.value = true
}

function openEdit(item: MerchantAdCampaign) {
  if (!canManage.value) return
  editingId.value = item.id
  form.shopId = item.shopId
  form.name = item.name
  form.slotType = item.slotType
  form.keyword = item.keyword
  form.bidCpc = item.bidCpc
  form.dailyBudget = item.dailyBudget
  success.value = ''
  error.value = ''
  formOpen.value = true
}

function closeForm() {
  formOpen.value = false
  editingId.value = null
}

async function submit() {
  if (!canManage.value) return
  const targetId = editingId.value
  const payload: MerchantAdPayload = {
    shopId: form.shopId,
    name: form.name,
    slotType: form.slotType,
    keyword: form.keyword,
    bidCpc: form.bidCpc,
    dailyBudget: form.dailyBudget,
  }
  error.value = ''
  success.value = ''
  try {
    if (targetId == null) await createAd(payload)
    else await updateAd(targetId, payload)
    closeForm()
    await load()
    success.value = targetId == null ? copy.value.created : copy.value.saved
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.saveError
  }
}

async function toggle(item: MerchantAdCampaign) {
  if (!canManage.value) return
  error.value = ''
  success.value = ''
  try {
    if (item.status === 1) await pauseAd(item.id)
    else await resumeAd(item.id)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.saveError
  }
}

function slotLabel(slotType: number) {
  return slotType === 2 ? copy.value.slotList : copy.value.slotSearch
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">{{ copy.summary }}</span>
      <button v-if="canManage" type="button" @click="openCreate">{{ copy.create }}</button>
      <span v-else class="muted">{{ copy.readOnly }}</span>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="success" class="muted" role="status">{{ success }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ copy.headers.name }}</th>
            <th>{{ copy.headers.shop }}</th>
            <th>{{ copy.headers.slot }}</th>
            <th>{{ copy.headers.keyword }}</th>
            <th>{{ copy.headers.bid }}</th>
            <th>{{ copy.headers.budget }}</th>
            <th>{{ copy.headers.spentToday }}</th>
            <th>{{ copy.headers.status }}</th>
            <th>{{ copy.headers.audit }}</th>
            <th>{{ copy.headers.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.name }}</td>
            <td>{{ item.shopName }}</td>
            <td>{{ slotLabel(item.slotType) }}</td>
            <td>{{ item.keyword || '—' }}</td>
            <td>{{ item.bidCpc }}</td>
            <td>{{ item.dailyBudget === 0 ? copy.unlimited : item.dailyBudget }}</td>
            <td>{{ item.spentToday }}</td>
            <td>{{ copy.statusText(item.status, item.statusText) }}</td>
            <td>{{ copy.auditText(item.auditStatus, item.auditStatusText) }}</td>
            <td>
              <template v-if="canManage">
                <button type="button" :data-testid="`edit-${item.id}`" @click="openEdit(item)">{{ copy.edit }}</button>
                <button type="button" :data-testid="`toggle-${item.id}`" @click="toggle(item)">
                  {{ item.status === 1 ? copy.pause : copy.resume }}
                </button>
              </template>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="10" class="feedback">{{ copy.empty }}</td></tr>
        </tbody>
      </table>
    </div>

    <form v-if="formOpen" class="card ad-form" @submit.prevent="submit">
      <label>
        {{ copy.fieldShop }}
        <select v-model.number="form.shopId">
          <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
        </select>
      </label>
      <label>
        {{ copy.fieldName }}
        <input v-model="form.name" type="text" maxlength="128" required />
      </label>
      <label>
        {{ copy.fieldSlot }}
        <select v-model.number="form.slotType">
          <option :value="1">{{ copy.slotSearch }}</option>
          <option :value="2">{{ copy.slotList }}</option>
        </select>
      </label>
      <label v-if="form.slotType === 1">
        {{ copy.fieldKeyword }}
        <input v-model="form.keyword" type="text" maxlength="64" :placeholder="copy.keywordHint" />
      </label>
      <label>
        {{ copy.fieldBid }}
        <input v-model.number="form.bidCpc" type="number" min="0.01" step="0.01" required />
      </label>
      <label>
        {{ copy.fieldBudget }}
        <input v-model.number="form.dailyBudget" type="number" min="0" step="0.01" />
      </label>
      <div class="form-actions">
        <button type="submit">{{ copy.save }}</button>
        <button type="button" @click="closeForm">{{ copy.cancel }}</button>
      </div>
    </form>
  </section>
</template>
