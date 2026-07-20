<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { listImportBatches, listShops } from '@/services/admin'
import type { AdminImportBatch, AdminShopSummary } from '@/types/admin'

const { state } = useAdminSession()

const loading = ref(false)
const errorMessage = ref('')
const recentShops = ref<AdminShopSummary[]>([])
const recentBatches = ref<AdminImportBatch[]>([])
const totalShops = ref(0)
const totalBatches = ref(0)
const latestSuccessCount = ref(0)
let snapshotRequestId = 0

const canReadShops = computed(() => state.permissions.includes('data:shop:read'))
const canReadImportBatches = computed(() => state.permissions.includes('data:import_batch:read'))
const canImportShops = computed(() => state.permissions.includes('data:shop:import'))
const metrics = computed(() => {
  const items = [] as Array<{ label: string; value: number; note: string }>
  if (canReadShops.value) {
    items.push({
      label: '当前区域门店数',
      value: totalShops.value,
      note: `区域 ${state.region} 下的最小可管理存量`,
    })
  }
  if (canReadImportBatches.value) {
    items.push(
      {
        label: '导入批次数',
        value: totalBatches.value,
        note: '看得见批次，才谈得上运营回灌',
      },
      {
        label: '最近批次成功数',
        value: latestSuccessCount.value,
        note: '用来盯导入动作是不是在真干活',
      },
    )
  }
  return items
})

async function loadSnapshot() {
  const requestId = ++snapshotRequestId
  const loadShops = canReadShops.value
  const loadBatches = canReadImportBatches.value
  const region = state.region
  if (!loadShops && !loadBatches) {
    if (requestId === snapshotRequestId) {
      recentShops.value = []
      recentBatches.value = []
      totalShops.value = 0
      totalBatches.value = 0
      latestSuccessCount.value = 0
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
    const [shopsPage, batchesPage] = await Promise.all([
      loadShops ? listShops({
        region,
        page: 1,
        pageSize: 5,
      }) : Promise.resolve(undefined),
      loadBatches ? listImportBatches({
        region,
        page: 1,
        pageSize: 5,
      }) : Promise.resolve(undefined),
    ])

    if (requestId === snapshotRequestId) {
      recentShops.value = shopsPage?.list ?? []
      recentBatches.value = batchesPage?.list ?? []
      totalShops.value = shopsPage?.total ?? 0
      totalBatches.value = batchesPage?.total ?? 0
      latestSuccessCount.value = batchesPage?.list[0]?.success ?? 0
    }
  } catch (error) {
    if (requestId === snapshotRequestId) {
      errorMessage.value = error instanceof Error ? error.message : '控制台数据加载失败'
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
        <p class="eyebrow">控制台概览</p>
        <h1>当前区域 {{ state.region }} 的基础数据状态，一眼看明白。</h1>
        <p>这页不装神弄鬼，就盯门店、批次和最近动作，先保证运营能用。</p>
      </div>

      <div class="header-actions">
        <RouterLink v-if="canReadShops" to="/data/shops" class="primary-link">去管门店</RouterLink>
        <RouterLink v-if="canImportShops" to="/data/import" class="secondary-link">去做导入</RouterLink>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">控制台数据刷新中...</p>

    <p v-if="metrics.length === 0" class="feedback">当前账号暂无可查看的控制台数据。</p>

    <div v-if="metrics.length > 0" class="stat-grid">
      <article v-for="metric in metrics" :key="metric.label" class="stat-card">
        <p>{{ metric.label }}</p>
        <strong>{{ metric.value }}</strong>
        <span>{{ metric.note }}</span>
      </article>
    </div>

    <div class="two-column-layout">
      <section v-if="canReadShops" class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">最近门店</p>
            <h2>谁刚被录进来，别装看不见。</h2>
          </div>
          <RouterLink to="/data/shops" class="text-link">查看全部</RouterLink>
        </div>

        <div v-if="recentShops.length === 0" class="empty-state">当前区域还没有门店，先去导一批数据。</div>

        <div v-else class="stack-list">
          <article v-for="shop in recentShops" :key="shop.id" class="stack-list__item">
            <div>
              <strong>{{ shop.name }}</strong>
              <p>{{ shop.cityName }} · {{ shop.areaName }} · {{ shop.categoryName }}</p>
            </div>
            <div class="stack-list__meta">
              <span class="status-pill" :class="shop.openNow ? 'status-pill--good' : 'status-pill--muted'">
                {{ shop.openNow ? '营业中' : '休息中' }}
              </span>
              <span>{{ shop.createdAt }}</span>
            </div>
          </article>
        </div>
      </section>

      <section v-if="canReadImportBatches" class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">最近批次</p>
            <h2>批次结果得明明白白，不然导入失败都没人知道。</h2>
          </div>
          <RouterLink v-if="canImportShops" to="/data/import" class="text-link">查看批次</RouterLink>
        </div>

        <div v-if="recentBatches.length === 0" class="empty-state">当前区域还没有导入批次，去导一包种子商户试试。</div>

        <div v-else class="stack-list">
          <article v-for="batch in recentBatches" :key="batch.id" class="stack-list__item">
            <div>
              <strong>{{ batch.fileName }}</strong>
              <p>成功 {{ batch.success }} / 失败 {{ batch.failed }} / 共 {{ batch.total }}</p>
            </div>
            <div class="stack-list__meta">
              <span
                class="status-pill"
                :class="batch.failed === 0 ? 'status-pill--good' : batch.success > 0 ? 'status-pill--warn' : 'status-pill--muted'"
              >
                {{ batch.statusText }}
              </span>
              <span>{{ batch.createdAt }}</span>
            </div>
          </article>
        </div>
      </section>
    </div>
  </section>
</template>
