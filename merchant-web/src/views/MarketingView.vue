<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { fetchShops, type MerchantShopOption } from '@/services/merchant'
import {
  createMerchantCoupon,
  createMerchantGroupBuy,
  createMerchantSeckill,
  fetchMerchantCoupons,
  fetchMerchantGroupBuy,
  fetchMerchantSeckill,
  type MerchantCoupon,
  type MerchantGroupBuy,
  type MerchantSeckill,
} from '@/services/ops'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), { permissions: () => [] })
const { state } = useMerchantSession()
const zh = computed(() => state.region !== 'EU')
const canManage = computed(() => props.permissions.includes('marketing:manage'))
const shops = ref<MerchantShopOption[]>([])
const shopId = ref<number | ''>('')
const coupons = ref<MerchantCoupon[]>([])
const seckills = ref<MerchantSeckill[]>([])
const groups = ref<MerchantGroupBuy[]>([])
const errorMessage = ref('')
const coupon = reactive({
  name: '', type: 1, thresholdAmount: 0, discountAmount: 1, totalQuantity: 100, perUserLimit: 1, validDays: 7,
})
const seckill = reactive({ dealId: 0, title: '', seckillPrice: 1, stock: 10, startAt: '', endAt: '' })
const group = reactive({ dealId: 0, title: '', groupPrice: 1, groupSize: 2, startAt: '', endAt: '' })

function auditText(status: number) {
  if (zh.value) return status === 2 ? '已通过' : status === 3 ? '已驳回' : '待审核'
  return status === 2 ? 'Approved' : status === 3 ? 'Rejected' : 'Pending'
}

async function load() {
  errorMessage.value = ''
  try {
    shops.value = (await fetchShops({ page: 1, pageSize: 50 })).list
    if (shopId.value === '' && shops.value[0]) shopId.value = shops.value[0].id
    coupons.value = await fetchMerchantCoupons()
    if (shopId.value !== '') {
      seckills.value = await fetchMerchantSeckill(Number(shopId.value))
      groups.value = await fetchMerchantGroupBuy(Number(shopId.value))
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Load failed'
  }
}

async function saveCoupon() {
  await createMerchantCoupon({ ...coupon, shopId: Number(shopId.value) })
  await load()
}

function iso(value: string) {
  return value.length === 16 ? `${value}:00` : value
}

async function saveSeckill() {
  await createMerchantSeckill({
    ...seckill,
    shopId: Number(shopId.value),
    startAt: iso(seckill.startAt),
    endAt: iso(seckill.endAt),
  })
  await load()
}

async function saveGroup() {
  await createMerchantGroupBuy({
    ...group,
    shopId: Number(shopId.value),
    startAt: iso(group.startAt),
    endAt: iso(group.endAt),
  })
  await load()
}

load()
</script>

<template>
  <section>
    <p class="muted">{{ zh ? '创建后待平台审核，通过前不会出现在领券中心或活动列表。' : 'New campaigns stay hidden until approved.' }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <label>
      {{ zh ? '门店' : 'Shop' }}
      <select v-model="shopId" @change="load">
        <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
      </select>
    </label>
    <h2>{{ zh ? '优惠券' : 'Coupons' }}</h2>
    <ul>
      <li v-for="item in coupons" :key="item.id">{{ item.name }} · {{ auditText(item.auditStatus) }} {{ item.rejectReason }}</li>
    </ul>
    <form v-if="canManage" @submit.prevent="saveCoupon">
      <input v-model="coupon.name" required placeholder="name" />
      <select v-model.number="coupon.type"><option :value="1">1</option><option :value="2">2</option></select>
      <input v-model.number="coupon.thresholdAmount" type="number" min="0" step="0.01" />
      <input v-model.number="coupon.discountAmount" type="number" min="0.01" step="0.01" required />
      <input v-model.number="coupon.totalQuantity" type="number" min="0" />
      <input v-model.number="coupon.perUserLimit" type="number" min="1" max="50" />
      <input v-model.number="coupon.validDays" type="number" min="1" max="365" />
      <button type="submit">{{ zh ? '建券' : 'Create' }}</button>
    </form>
    <h2>{{ zh ? '秒杀' : 'Flash sale' }}</h2>
    <ul>
      <li v-for="item in seckills" :key="item.id">{{ item.title }} · {{ auditText(item.auditStatus) }}</li>
    </ul>
    <form v-if="canManage" @submit.prevent="saveSeckill">
      <input v-model.number="seckill.dealId" type="number" min="1" required placeholder="deal" />
      <input v-model="seckill.title" required />
      <input v-model.number="seckill.seckillPrice" type="number" min="0.01" step="0.01" required />
      <input v-model.number="seckill.stock" type="number" min="1" required />
      <input v-model="seckill.startAt" type="datetime-local" required />
      <input v-model="seckill.endAt" type="datetime-local" required />
      <button type="submit">{{ zh ? '创建秒杀' : 'Create' }}</button>
    </form>
    <h2>{{ zh ? '拼团' : 'Group buy' }}</h2>
    <ul>
      <li v-for="item in groups" :key="item.id">{{ item.title }} · {{ auditText(item.auditStatus) }}</li>
    </ul>
    <form v-if="canManage" @submit.prevent="saveGroup">
      <input v-model.number="group.dealId" type="number" min="1" required placeholder="deal" />
      <input v-model="group.title" required />
      <input v-model.number="group.groupPrice" type="number" min="0.01" step="0.01" required />
      <input v-model.number="group.groupSize" type="number" min="2" max="10" required />
      <input v-model="group.startAt" type="datetime-local" required />
      <input v-model="group.endAt" type="datetime-local" required />
      <button type="submit">{{ zh ? '创建拼团' : 'Create' }}</button>
    </form>
  </section>
</template>
