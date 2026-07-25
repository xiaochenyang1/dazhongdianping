<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { fetchReservations } from '@/services/reservation'
import type { Reservation } from '@/types/reservation'

const route = useRoute()
const router = useRouter()

const list = ref<Reservation[]>([])
const loading = ref(false)
const errorMessage = ref('')

const statusTabs = [
  { value: undefined as number | undefined, label: '全部' },
  { value: 0, label: '待确认' },
  { value: 1, label: '已确认' },
  { value: 2, label: '已到店' },
  { value: 3, label: '用户取消' },
  { value: 4, label: '商户拒绝' },
  { value: 5, label: '爽约' },
]

const activeStatus = computed<number | undefined>(() => {
  const raw = route.query.status
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

function statusLabel(status?: number) {
  if (status === 0) return '待确认'
  if (status === 1) return '已确认'
  if (status === 2) return '已到店'
  if (status === 3) return '用户取消'
  if (status === 4) return '商户拒绝'
  if (status === 5) return '爽约'
  return '全部'
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchReservations(activeStatus.value, 1, 50)
    list.value = result.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '预订加载失败'
  } finally {
    loading.value = false
  }
}

async function switchStatus(status?: number) {
  const query: Record<string, string> = {}
  if (status != null) query.status = String(status)
  await router.replace({ path: '/user/reservations', query })
}

onMounted(() => {
  void load()
})

watch(
  () => route.query.status,
  () => {
    void load()
  },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">我的预订</p>
        <h1>待确认、已确认、取消和改期都在一条时间线上。</h1>
        <p>当前筛选：{{ statusLabel(activeStatus) }}</p>
      </div>
    </div>

    <div class="hero-actions" style="margin-bottom: 16px">
      <button
        v-for="tab in statusTabs"
        :key="String(tab.value ?? 'all')"
        type="button"
        class="secondary-button"
        :class="{ 'is-active': activeStatus === tab.value }"
        :data-testid="`reservation-tab-${tab.value ?? 'all'}`"
        @click="switchStatus(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="loading" class="feedback">预订加载中...</p>
    <p v-else-if="list.length === 0" class="feedback">当前筛选下暂无预订。</p>

    <div v-else class="rank-list">
      <RouterLink
        v-for="item in list"
        :key="item.id"
        :to="`/user/reservations/${item.id}`"
        class="content-card rank-item"
        :data-testid="`reservation-card-${item.id}`"
      >
        <img :src="item.shop.coverImage" :alt="item.shop.name" />
        <div class="rank-item__body">
          <h2>{{ item.shop.name }}</h2>
          <p>{{ item.reserveTime }} · {{ item.peopleCount }} 人</p>
          <p class="muted">预订号 {{ item.reservationNo }}</p>
          <span class="status-pill">{{ item.statusText }}</span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>

<style scoped>
.secondary-button.is-active {
  background: var(--color-primary, #ff6633);
  color: #fff;
  border-color: transparent;
}
.muted {
  color: var(--muted, #6b7280);
  font-size: 13px;
}
</style>
