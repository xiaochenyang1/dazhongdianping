<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { fetchShops, fetchDeals, type MerchantShopOption, type MerchantDeal } from '@/services/merchant'
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
const savingSeckill = ref(false)
const deals = ref<MerchantDeal[]>([])
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
      if (props.permissions.includes('deal:edit')) {
        deals.value = (await fetchDeals({ shopId: Number(shopId.value), status: 1, auditStatus: 1, pageSize: 100 })).list
        if (!deals.value.some(deal => deal.id === seckill.dealId)) seckill.dealId = deals.value[0]?.id ?? 0
      }
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
  if (savingSeckill.value) return
  savingSeckill.value = true
  errorMessage.value = ''
  try {
    await createMerchantSeckill({
      ...seckill,
      shopId: Number(shopId.value),
      startAt: iso(seckill.startAt),
      endAt: iso(seckill.endAt),
    })
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : (zh.value ? '秒杀创建失败' : 'Could not create flash sale')
  } finally {
    savingSeckill.value = false
  }
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
      <select v-model="shopId" data-testid="marketing-shop" @change="load">
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
    <p class="muted">{{ zh ? '每人每场限购一件；待支付最多占用 15 分钟，同时占用套餐库存。取消、超时或退款成功后释放库存。' : 'One purchase per person. Unpaid orders reserve the event and offer stock for up to 15 minutes. Cancellation, expiry and successful refunds release stock.' }}</p>
    <ul>
      <li v-for="item in seckills" :key="item.id">
        {{ item.title }} · {{ auditText(item.auditStatus) }} · {{ item.seckillPrice }} {{ item.currency }}
        · {{ zh ? '已售及待支付/总名额' : 'Sold and reserved / allocation' }} {{ item.sold }}/{{ item.stock }}
      </li>
    </ul>
    <form v-if="canManage" class="seckill-form" data-testid="seckill-create" @submit.prevent="saveSeckill">
      <label>{{ zh ? '套餐' : 'Offer' }}
        <select v-if="deals.length" v-model.number="seckill.dealId" required data-testid="seckill-deal">
          <option v-for="deal in deals" :key="deal.id" :value="deal.id">{{ deal.title }} · {{ deal.price }} {{ deal.currency }}</option>
        </select>
        <input v-else v-model.number="seckill.dealId" type="number" min="1" required data-testid="seckill-deal" />
      </label>
      <label>{{ zh ? '活动名称' : 'Sale title' }}<input v-model="seckill.title" maxlength="128" required data-testid="seckill-title" /></label>
      <label>{{ zh ? '秒杀价' : 'Sale price' }}<input v-model.number="seckill.seckillPrice" type="number" min="0.01" step="0.01" required data-testid="seckill-price" /></label>
      <label>{{ zh ? '活动名额' : 'Allocation' }}<input v-model.number="seckill.stock" type="number" min="1" required data-testid="seckill-stock" /></label>
      <label>{{ zh ? '开始时间' : 'Starts at' }}<input v-model="seckill.startAt" type="datetime-local" required data-testid="seckill-start" /></label>
      <label>{{ zh ? '结束时间' : 'Ends at' }}<input v-model="seckill.endAt" type="datetime-local" required data-testid="seckill-end" /></label>
      <button type="submit" :disabled="savingSeckill">{{ savingSeckill ? (zh ? '提交中…' : 'Submitting…') : (zh ? '创建秒杀' : 'Create flash sale') }}</button>
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

<style scoped>
.seckill-form { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }
.seckill-form label { display: grid; gap: 6px; }
.seckill-form button { align-self: end; }
</style>
