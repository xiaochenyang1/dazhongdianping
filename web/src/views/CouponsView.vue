<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { fetchCoupons } from '@/services/trade'
import type { Coupon } from '@/types/trade'

const route = useRoute()
const router = useRouter()

const coupons = ref<Coupon[]>([])
const loading = ref(false)
const errorMessage = ref('')
const highlightCode = ref('')

const statusTabs = [
  { value: undefined as number | undefined, label: '全部' },
  { value: 1, label: '待使用' },
  { value: 2, label: '已使用' },
  { value: 3, label: '已过期' },
  { value: 4, label: '已退款' },
]

const activeStatus = computed<number | undefined>(() => {
  const raw = route.query.status
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

function statusLabel(status?: number) {
  if (status === 1) return '待使用'
  if (status === 2) return '已使用'
  if (status === 3) return '已过期'
  if (status === 4) return '已退款'
  return '全部'
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchCoupons(activeStatus.value, 1, 50)
    coupons.value = result.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '券加载失败'
  } finally {
    loading.value = false
  }
}

async function switchStatus(status?: number) {
  const query: Record<string, string> = {}
  if (status != null) query.status = String(status)
  if (highlightCode.value) query.code = highlightCode.value
  await router.replace({ path: '/user/coupons', query })
}

onMounted(async () => {
  const rawCode = route.query.code
  highlightCode.value = String(Array.isArray(rawCode) ? rawCode[0] || '' : rawCode || '')
  await load()
})

watch(
  () => [route.query.status, route.query.code],
  async () => {
    const rawCode = route.query.code
    highlightCode.value = String(Array.isArray(rawCode) ? rawCode[0] || '' : rawCode || '')
    await load()
  },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">我的券</p>
        <h1>每张券独立核销，退款、过期和到期提醒也各算各的。</h1>
        <p>
          当前筛选：{{ statusLabel(activeStatus) }}
          <template v-if="highlightCode"> · 定位券码 {{ highlightCode }}</template>
        </p>
      </div>
    </div>

    <div class="hero-actions" style="margin-bottom: 16px">
      <button
        v-for="tab in statusTabs"
        :key="String(tab.value ?? 'all')"
        type="button"
        class="secondary-button"
        :class="{ 'is-active': activeStatus === tab.value }"
        :data-testid="`coupon-tab-${tab.value ?? 'all'}`"
        @click="switchStatus(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">券码加载中...</p>
    <p v-else-if="coupons.length === 0" class="feedback">当前筛选下暂无券码。</p>

    <div v-else class="rank-grid">
      <RouterLink
        v-for="coupon in coupons"
        :key="coupon.id"
        class="rank-card"
        :class="{ 'is-highlight': highlightCode && highlightCode === coupon.code }"
        :data-testid="`coupon-card-${coupon.code}`"
        :to="`/user/coupons/${encodeURIComponent(coupon.code)}`"
      >
        <img :src="coupon.coverImage" :alt="coupon.dealTitle" />
        <div class="rank-card__body">
          <h2>{{ coupon.dealTitle }}</h2>
          <strong>{{ coupon.code }}</strong>
          <span>{{ coupon.shopName }} · {{ coupon.statusText }} · 有效期至 {{ coupon.expireAt || '不限期' }}</span>
          <span class="muted">查看二维码与使用规则</span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>

<style scoped>
.rank-card.is-highlight {
  outline: 2px solid var(--color-primary, #ff6633);
  box-shadow: 0 0 0 4px rgba(255, 102, 51, 0.12);
}
.secondary-button.is-active {
  background: var(--color-primary, #ff6633);
  color: #fff;
  border-color: transparent;
}
</style>
