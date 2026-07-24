<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchAccount, fetchDashboard, type MerchantAccount } from '@/services/merchant'

const loading = ref(true)
const error = ref('')
const account = ref<MerchantAccount | null>(null)
const dashboard = ref<Record<string, unknown>>({})

const permissions = computed(() => account.value?.permissions ?? [])
const canViewDashboard = computed(() => permissions.value.includes('dashboard:view'))
const canViewReservations = computed(() => permissions.value.includes('reservation:view'))
const canViewOrders = computed(() => permissions.value.includes('order:view'))
const canVerifyCoupons = computed(() => permissions.value.includes('coupon:verify'))
const canEditDeals = computed(() => permissions.value.includes('deal:edit'))
const canEditShops = computed(() => permissions.value.includes('shop:edit'))
const canManageStaffs = computed(() => permissions.value.includes('staff:manage'))

function number(key: string) {
  const value = dashboard.value[key]
  return typeof value === 'number' ? value : 0
}

function nestedNumber(parent: string, key: string) {
  const parentValue = dashboard.value[parent]
  if (!parentValue || typeof parentValue !== 'object') return 0
  const value = (parentValue as Record<string, unknown>)[key]
  return typeof value === 'number' ? value : 0
}

const metrics = computed(() => [
  { label: '浏览量', value: number('views') || number('viewCount'), note: '统计周期内门店浏览' },
  { label: '支付订单', value: number('paidOrders') || number('paidOrderCount'), note: '已支付订单数' },
  { label: '支付金额', value: number('paidAmount'), note: '已支付订单金额' },
  { label: '核销券', value: number('verifiedCoupons') || number('verifiedCouponCount'), note: '到店核销成功券数' },
  { label: '评分', value: nestedNumber('rating', 'score') || number('score'), note: '门店平均评分' },
  { label: '点评数', value: nestedNumber('rating', 'reviewCount') || number('reviewCount'), note: '累计公开点评' },
])

const todos = computed(() => [
  {
    key: 'pendingReservations',
    label: '待确认预订',
    value: nestedNumber('reservations', 'pending'),
    to: '/reservations',
    show: canViewReservations.value,
  },
  {
    key: 'confirmedReservations',
    label: '已确认预订',
    value: nestedNumber('reservations', 'confirmed'),
    to: '/reservations',
    show: canViewReservations.value,
  },
  {
    key: 'pendingRefunds',
    label: '待处理退款',
    value: number('pendingRefunds'),
    to: '/orders',
    show: canViewOrders.value,
  },
])

const quickLinks = computed(() => {
  const items = [] as Array<{ to: string; label: string; note: string }>
  if (canViewReservations.value) {
    items.push({ to: '/reservations', label: '预订处理', note: '确认、拒绝、到店、爽约' })
  }
  if (canViewOrders.value) {
    items.push({ to: '/orders', label: '订单退款', note: '处理用户退款申请' })
  }
  if (canVerifyCoupons.value) {
    items.push({ to: '/coupons', label: '券码核销', note: '到店录码核销' })
  }
  if (canEditDeals.value) {
    items.push({ to: '/deals', label: '团购管理', note: '创建/编辑并提交审核' })
  }
  if (canEditShops.value) {
    items.push({ to: '/shops', label: '门店草稿', note: '新建/修改门店资料' })
  }
  if (canManageStaffs.value) {
    items.push({ to: '/staffs', label: '员工管理', note: '角色与门店范围' })
  }
  return items
})

onMounted(async () => {
  loading.value = true
  error.value = ''
  try {
    const [accountData, dashboardData] = await Promise.all([fetchAccount(), fetchDashboard()])
    account.value = accountData
    dashboard.value = dashboardData
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '加载失败'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">Merchant dashboard</p>
        <strong>
          {{ account?.merchant.companyName ?? '商户' }}
          <template v-if="account?.operator.name"> · {{ account.operator.name }}</template>
        </strong>
        <p class="muted">
          统计区间：{{ String(dashboard.dateFrom || '-') }} ~ {{ String(dashboard.dateTo || '-') }}
        </p>
      </div>
    </div>

    <p v-if="loading" class="muted">加载中...</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>

    <template v-if="!loading && !error">
      <p v-if="!canViewDashboard" class="error" role="alert">当前账号缺少 `dashboard:view` 权限。</p>

      <div class="grid">
        <div v-for="metric in metrics" :key="metric.label" class="card">
          <p class="muted">{{ metric.label }}</p>
          <div class="stat">{{ metric.value }}</div>
          <p class="muted">{{ metric.note }}</p>
        </div>
      </div>

      <article class="card" style="margin-top: 18px">
        <div class="toolbar">
          <strong>待办与状态</strong>
        </div>
        <div class="grid">
          <div
            v-for="item in todos.filter((todo) => todo.show)"
            :key="item.key"
            class="card"
            data-testid="merchant-todo-card"
          >
            <p class="muted">{{ item.label }}</p>
            <div class="stat">{{ item.value }}</div>
            <RouterLink :to="item.to" class="primary-link">去处理</RouterLink>
          </div>
        </div>
      </article>

      <article v-if="quickLinks.length" class="card" style="margin-top: 18px">
        <div class="toolbar">
          <strong>快捷入口</strong>
        </div>
        <div class="grid">
          <RouterLink
            v-for="link in quickLinks"
            :key="link.to"
            :to="link.to"
            class="card"
            data-testid="merchant-quick-link"
          >
            <p class="muted">{{ link.label }}</p>
            <div class="stat" style="font-size: 20px">进入</div>
            <p class="muted">{{ link.note }}</p>
          </RouterLink>
        </div>
      </article>
    </template>
  </section>
</template>
