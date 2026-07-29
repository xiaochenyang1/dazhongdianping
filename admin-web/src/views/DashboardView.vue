<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { getAdminDashboardOverview, listImportBatches, listShops } from '@/services/admin'
import type { AdminDashboardOverview, AdminImportBatch, AdminShopSummary } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))

const loading = ref(false)
const errorMessage = ref('')
const recentShops = ref<AdminShopSummary[]>([])
const recentBatches = ref<AdminImportBatch[]>([])
const overview = ref<AdminDashboardOverview | null>(null)
let snapshotRequestId = 0

const canReadDashboard = computed(() => state.permissions.includes('dashboard:read'))
const canReadShops = computed(() => state.permissions.includes('data:shop:read'))
const canReadImportBatches = computed(() => state.permissions.includes('data:import_batch:read'))
const canImportShops = computed(() => state.permissions.includes('data:shop:import'))
const canReadOrders = computed(() => state.permissions.includes('data:order:read'))
const canReadUsers = computed(() => state.permissions.includes('system:user:read'))
const canReadDeals = computed(() => state.permissions.includes('audit:deal:read'))
const canReadShopChanges = computed(() => state.permissions.includes('audit:shop_change:read'))
const canReadReviews = computed(() => state.permissions.includes('audit:review:read'))
const canReadPosts = computed(() => state.permissions.includes('audit:post:read'))

function pendingCountFor(bizType: number) {
  return overview.value?.pendingAuditBreakdown.find((item) => item.bizType === bizType)?.count
}

function auditBreakdownLabel(bizType: number, fallback?: string) {
  const labels = strings.value.dashboard.pendingAudit.bizTypeLabels
  if (bizType === 2) return labels.deals
  if (bizType === 3) return labels.reviews
  if (bizType === 4) return labels.posts
  if (bizType === 5) return labels.shopChanges
  if (bizType === 6) return labels.reviewAppeals
  if (bizType === 7) return labels.expertCertifications
  if (bizType === 8) return labels.userAppeals
  if (bizType === 9) return labels.verifiedMerchants
  return fallback || strings.value.dashboard.pendingAudit.fallbackLabel(bizType)
}

function shopOpenStatus(openNow: boolean) {
  return openNow ? strings.value.dashboard.recentShops.openNow : strings.value.dashboard.recentShops.closed
}

function importBatchStatusText(status: number, fallback?: string) {
  return strings.value.dashboard.recentBatches.statusText(status, fallback)
}

const metrics = computed(() => {
  const items = [] as Array<{ label: string; value: number; note: string }>
  if (!overview.value) {
    return items
  }
  if (canReadShops.value) {
    items.push({
      label: strings.value.dashboard.metrics.shopCount.label,
      value: overview.value.shopCount,
      note: strings.value.dashboard.metrics.shopCount.note(state.region),
    })
  }
  if (canReadImportBatches.value) {
    items.push({
      label: strings.value.dashboard.metrics.importBatchCount.label,
      value: overview.value.importBatchCount,
      note: strings.value.dashboard.metrics.importBatchCount.note,
    })
  }
  if (canReadOrders.value) {
    items.push(
      {
        label: strings.value.dashboard.metrics.paidOrderCount.label,
        value: overview.value.paidOrderCount,
        note: strings.value.dashboard.metrics.paidOrderCount.note,
      },
      {
        label: strings.value.dashboard.metrics.pendingRefundCount.label,
        value: overview.value.pendingRefundCount,
        note: strings.value.dashboard.metrics.pendingRefundCount.note,
      },
    )
  }
  if (canReadDashboard.value) {
    items.push({
      label: strings.value.dashboard.metrics.pendingAuditTaskCount.label,
      value: overview.value.pendingAuditTaskCount,
      note: strings.value.dashboard.metrics.pendingAuditTaskCount.note,
    })
  }
  if (canReadUsers.value) {
    items.push({
      label: strings.value.dashboard.metrics.userCount.label,
      value: overview.value.userCount,
      note: strings.value.dashboard.metrics.userCount.note,
    })
  }
  return items
})

const auditRouteByBizType: Record<number, string> = {
  2: '/audit/deals',
  3: '/audit/reviews',
  4: '/audit/posts',
  5: '/audit/shop-changes',
  6: '/audit/review-appeals',
  7: '/audit/expert-certifications',
  8: '/audit/user-appeals',
  9: '/audit/verified-merchants',
}

const quickLinks = computed(() => {
  const items = [] as Array<{ to: string; label: string; note: string; value?: number }>
  if (canReadDeals.value) {
    const count = pendingCountFor(2)
    items.push({
      to: '/audit/deals',
      label: strings.value.dashboard.quickLinks.pendingDeals.label,
      note: strings.value.dashboard.quickLinks.pendingDeals.note,
      value: count,
    })
  }
  if (canReadShopChanges.value) {
    const count = pendingCountFor(5)
    items.push({
      to: '/audit/shop-changes',
      label: strings.value.dashboard.quickLinks.pendingShopChanges.label,
      note: strings.value.dashboard.quickLinks.pendingShopChanges.note,
      value: count,
    })
  }
  if (canReadReviews.value) {
    const count = pendingCountFor(3)
    items.push({
      to: '/audit/reviews',
      label: strings.value.dashboard.quickLinks.pendingReviews.label,
      note: strings.value.dashboard.quickLinks.pendingReviews.note,
      value: count,
    })
  }
  if (canReadPosts.value) {
    const count = pendingCountFor(4)
    items.push({
      to: '/audit/posts',
      label: strings.value.dashboard.quickLinks.pendingPosts.label,
      note: strings.value.dashboard.quickLinks.pendingPosts.note,
      value: count,
    })
  }
  if (canReadOrders.value) {
    items.push({
      to: '/data/orders',
      label: strings.value.dashboard.quickLinks.pendingRefunds.label,
      note: strings.value.dashboard.quickLinks.pendingRefunds.note,
      value: overview.value?.pendingRefundCount,
    })
  }
  return items
})

const clickableAuditBreakdown = computed(() => {
  if (!overview.value) return []
  return overview.value.pendingAuditBreakdown
    .map((item) => ({
      ...item,
      label: auditBreakdownLabel(item.bizType, item.label),
      to: auditRouteByBizType[item.bizType],
    }))
    .filter((item) => Boolean(item.to))
})

async function loadSnapshot() {
  const requestId = ++snapshotRequestId
  const loadShops = canReadShops.value
  const loadBatches = canReadImportBatches.value
  const loadOverview = canReadDashboard.value
  const region = state.region
  if (!loadShops && !loadBatches && !loadOverview) {
    if (requestId === snapshotRequestId) {
      recentShops.value = []
      recentBatches.value = []
      overview.value = null
      errorMessage.value = ''
      loading.value = false
    }
    return
  }

  if (requestId === snapshotRequestId) {
    loading.value = true
    errorMessage.value = ''
  }

  try {
    const [shopsPage, batchesPage, overviewData] = await Promise.all([
      loadShops
        ? listShops({
            region,
            page: 1,
            pageSize: 5,
          })
        : Promise.resolve(undefined),
      loadBatches
        ? listImportBatches({
            region,
            page: 1,
            pageSize: 5,
          })
        : Promise.resolve(undefined),
      loadOverview ? getAdminDashboardOverview() : Promise.resolve(undefined),
    ])

    if (requestId === snapshotRequestId) {
      recentShops.value = shopsPage?.list ?? []
      recentBatches.value = batchesPage?.list ?? []
      overview.value = overviewData ?? null
    }
  } catch (error) {
    if (requestId === snapshotRequestId) {
      errorMessage.value = error instanceof Error ? error.message : strings.value.dashboard.loadError
    }
  } finally {
    if (requestId === snapshotRequestId) {
      loading.value = false
    }
  }
}

watch(
  () => [state.region, state.permissions.join('|')],
  () => {
    void loadSnapshot()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.dashboard.eyebrow }}</p>
        <h1>{{ strings.dashboard.heading(state.region) }}</h1>
        <p>{{ strings.dashboard.description }}</p>
      </div>

      <div class="header-actions">
        <RouterLink v-if="canReadShops" to="/data/shops" class="primary-link">{{ strings.dashboard.headerActions.manageShops }}</RouterLink>
        <RouterLink v-if="canImportShops" to="/data/import" class="secondary-link">{{ strings.dashboard.headerActions.importShops }}</RouterLink>
        <RouterLink v-if="canReadOrders" to="/data/orders" class="secondary-link">{{ strings.dashboard.headerActions.viewOrders }}</RouterLink>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ strings.dashboard.loading }}</p>

    <p v-if="metrics.length === 0" class="feedback">{{ strings.dashboard.noData }}</p>

    <div v-if="metrics.length > 0" class="stat-grid">
      <article v-for="metric in metrics" :key="metric.label" class="stat-card">
        <p>{{ metric.label }}</p>
        <strong>{{ metric.value }}</strong>
        <span>{{ metric.note }}</span>
      </article>
    </div>

    <section v-if="quickLinks.length" class="content-card" style="margin-top: 18px">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.dashboard.quickLinks.eyebrow }}</p>
          <h2>{{ strings.dashboard.quickLinks.heading }}</h2>
        </div>
      </div>
      <div class="stat-grid">
        <RouterLink
          v-for="link in quickLinks"
          :key="link.to"
          :to="link.to"
          class="stat-card"
          data-testid="dashboard-quick-link"
        >
          <p>{{ link.label }}</p>
          <strong>{{ link.value ?? 0 }}</strong>
          <span>{{ link.note }}</span>
        </RouterLink>
      </div>
    </section>

    <div class="two-column-layout">
      <section v-if="canReadShops" class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.dashboard.recentShops.eyebrow }}</p>
            <h2>{{ strings.dashboard.recentShops.heading }}</h2>
          </div>
          <RouterLink to="/data/shops" class="text-link">{{ strings.dashboard.recentShops.viewAll }}</RouterLink>
        </div>

        <div v-if="recentShops.length === 0" class="empty-state">{{ strings.dashboard.recentShops.empty }}</div>

        <div v-else class="stack-list">
          <article v-for="shop in recentShops" :key="shop.id" class="stack-list__item">
            <div>
              <strong>{{ shop.name }}</strong>
              <p>{{ shop.cityName }} · {{ shop.areaName }} · {{ shop.categoryName }}</p>
            </div>
            <div class="stack-list__meta">
              <span class="status-pill" :class="shop.openNow ? 'status-pill--good' : 'status-pill--muted'">
                {{ shopOpenStatus(shop.openNow) }}
              </span>
              <span>{{ shop.createdAt }}</span>
            </div>
          </article>
        </div>
      </section>

      <section v-if="canReadImportBatches" class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.dashboard.recentBatches.eyebrow }}</p>
            <h2>{{ strings.dashboard.recentBatches.heading }}</h2>
          </div>
          <RouterLink v-if="canImportShops" to="/data/import" class="text-link">{{ strings.dashboard.recentBatches.viewAll }}</RouterLink>
        </div>

        <div v-if="recentBatches.length === 0" class="empty-state">{{ strings.dashboard.recentBatches.empty }}</div>

        <div v-else class="stack-list">
          <article v-for="batch in recentBatches" :key="batch.id" class="stack-list__item">
            <div>
              <strong>{{ batch.fileName }}</strong>
              <p>{{ strings.dashboard.recentBatches.batchSummary(batch.success, batch.failed, batch.total) }}</p>
            </div>
            <div class="stack-list__meta">
              <span
                class="status-pill"
                :class="batch.failed === 0 ? 'status-pill--good' : batch.success > 0 ? 'status-pill--warn' : 'status-pill--muted'"
              >
                {{ importBatchStatusText(batch.status, batch.statusText) }}
              </span>
              <span>{{ batch.createdAt }}</span>
            </div>
          </article>
        </div>
      </section>

      <section v-if="canReadDashboard && overview" class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.dashboard.pendingAudit.eyebrow }}</p>
            <h2>{{ strings.dashboard.pendingAudit.heading }}</h2>
          </div>
        </div>
        <div v-if="!clickableAuditBreakdown.length" class="empty-state">{{ strings.dashboard.pendingAudit.empty }}</div>
        <div v-else class="stack-list">
          <RouterLink
            v-for="item in clickableAuditBreakdown"
            :key="item.bizType"
            :to="item.to"
            class="stack-list__item"
            data-testid="dashboard-audit-breakdown-link"
          >
            <div>
              <strong>{{ item.label }}</strong>
              <p>{{ strings.dashboard.pendingAudit.detailsNote(item.bizType) }}</p>
            </div>
            <div class="stack-list__meta">
              <span class="status-pill" :class="item.count > 0 ? 'status-pill--warn' : 'status-pill--good'">
                {{ strings.dashboard.pendingAudit.countSummary(item.count) }}
              </span>
            </div>
          </RouterLink>
        </div>
      </section>
    </div>
  </section>
</template>
