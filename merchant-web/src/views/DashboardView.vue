<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { fetchAccount, fetchDashboard, type MerchantAccount } from '@/services/merchant'

const { state } = useMerchantSession()
const loading = ref(true)
const error = ref('')
const account = ref<MerchantAccount | null>(null)
const dashboard = ref<Record<string, unknown>>({})
const region = computed(() => account.value?.merchant.region ?? state.region)
const strings = computed(() => merchantStringsForRegion(region.value))

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
  {
    label: strings.value.dashboard.metrics.views.label,
    value: number('views') || number('viewCount'),
    note: strings.value.dashboard.metrics.views.note,
  },
  {
    label: strings.value.dashboard.metrics.paidOrders.label,
    value: number('paidOrders') || number('paidOrderCount'),
    note: strings.value.dashboard.metrics.paidOrders.note,
  },
  {
    label: strings.value.dashboard.metrics.paidAmount.label,
    value: number('paidAmount'),
    note: strings.value.dashboard.metrics.paidAmount.note,
  },
  {
    label: strings.value.dashboard.metrics.verifiedCoupons.label,
    value: number('verifiedCoupons') || number('verifiedCouponCount'),
    note: strings.value.dashboard.metrics.verifiedCoupons.note,
  },
  {
    label: strings.value.dashboard.metrics.rating.label,
    value: nestedNumber('rating', 'score') || number('score'),
    note: strings.value.dashboard.metrics.rating.note,
  },
  {
    label: strings.value.dashboard.metrics.reviewCount.label,
    value: nestedNumber('rating', 'reviewCount') || number('reviewCount'),
    note: strings.value.dashboard.metrics.reviewCount.note,
  },
])

const todos = computed(() => [
  {
    key: 'pendingReservations',
    label: strings.value.dashboard.todoLabels.pendingReservations,
    value: nestedNumber('reservations', 'pending'),
    to: '/reservations',
    show: canViewReservations.value,
  },
  {
    key: 'confirmedReservations',
    label: strings.value.dashboard.todoLabels.confirmedReservations,
    value: nestedNumber('reservations', 'confirmed'),
    to: '/reservations',
    show: canViewReservations.value,
  },
  {
    key: 'pendingRefunds',
    label: strings.value.dashboard.todoLabels.pendingRefunds,
    value: number('pendingRefunds'),
    to: '/orders',
    show: canViewOrders.value,
  },
  {
    key: 'pendingDeals',
    label: strings.value.dashboard.todoLabels.pendingDeals,
    value: number('pendingDeals'),
    to: '/deals',
    show: canEditDeals.value,
  },
  {
    key: 'rejectedDeals',
    label: strings.value.dashboard.todoLabels.rejectedDeals,
    value: number('rejectedDeals'),
    to: '/deals',
    show: canEditDeals.value,
  },
  {
    key: 'pendingShopChanges',
    label: strings.value.dashboard.todoLabels.pendingShopChanges,
    value: number('pendingShopChanges'),
    to: '/shops',
    show: canEditShops.value,
  },
  {
    key: 'rejectedShopChanges',
    label: strings.value.dashboard.todoLabels.rejectedShopChanges,
    value: number('rejectedShopChanges'),
    to: '/shops',
    show: canEditShops.value,
  },
])

const quickLinks = computed(() => {
  const items = [] as Array<{ to: string; label: string; note: string }>
  if (canViewReservations.value) {
    items.push({
      to: '/reservations',
      label: strings.value.routeTitles.reservations,
      note: strings.value.dashboard.quickLinkNotes.reservations,
    })
  }
  if (canViewOrders.value) {
    items.push({
      to: '/orders',
      label: strings.value.routeTitles.orders,
      note: strings.value.dashboard.quickLinkNotes.orders,
    })
  }
  if (canVerifyCoupons.value) {
    items.push({
      to: '/coupons',
      label: strings.value.routeTitles.coupons,
      note: strings.value.dashboard.quickLinkNotes.coupons,
    })
  }
  if (canEditDeals.value) {
    items.push({
      to: '/deals',
      label: strings.value.routeTitles.deals,
      note: strings.value.dashboard.quickLinkNotes.deals,
    })
  }
  if (canEditShops.value) {
    items.push({
      to: '/shops',
      label: strings.value.routeTitles.shops,
      note: strings.value.dashboard.quickLinkNotes.shops,
    })
  }
  if (canManageStaffs.value) {
    items.push({
      to: '/staffs',
      label: strings.value.routeTitles.staffs,
      note: strings.value.dashboard.quickLinkNotes.staffs,
    })
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
    error.value = cause instanceof Error ? cause.message : strings.value.dashboard.loadError
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">{{ strings.dashboard.eyebrow }}</p>
        <strong>
          {{ account?.merchant.companyName ?? strings.dashboard.merchantFallbackName }}
          <template v-if="account?.operator.name"> · {{ account.operator.name }}</template>
        </strong>
        <p class="muted">{{ strings.dashboard.dateRange(dashboard.dateFrom, dashboard.dateTo) }}</p>
      </div>
    </div>

    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>

    <template v-if="!loading && !error">
      <p v-if="!canViewDashboard" class="error" role="alert">
        {{ strings.dashboard.missingPermission('dashboard:view') }}
      </p>

      <div class="grid">
        <div v-for="metric in metrics" :key="metric.label" class="card">
          <p class="muted">{{ metric.label }}</p>
          <div class="stat">{{ metric.value }}</div>
          <p class="muted">{{ metric.note }}</p>
        </div>
      </div>

      <article class="card" style="margin-top: 18px">
        <div class="toolbar">
          <strong>{{ strings.dashboard.todosHeading }}</strong>
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
            <RouterLink :to="item.to" class="primary-link">{{ strings.dashboard.todoAction }}</RouterLink>
          </div>
        </div>
      </article>

      <article v-if="quickLinks.length" class="card" style="margin-top: 18px">
        <div class="toolbar">
          <strong>{{ strings.dashboard.quickLinksHeading }}</strong>
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
            <div class="stat" style="font-size: 20px">{{ strings.dashboard.quickLinkEnter }}</div>
            <p class="muted">{{ link.note }}</p>
          </RouterLink>
        </div>
      </article>
    </template>
  </section>
</template>
