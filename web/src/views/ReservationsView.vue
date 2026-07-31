<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { fetchReservations } from '@/services/reservation'
import type { Reservation } from '@/types/reservation'

const route = useRoute()
const router = useRouter()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))

const list = ref<Reservation[]>([])
const loading = ref(false)
const errorMessage = ref('')

const statusTabs = computed(() => [
  { value: undefined as number | undefined, label: copy.value.statuses.all },
  ...[0, 1, 2, 3, 4, 5].map((value) => ({ value, label: copy.value.statuses.reservation(value) })),
])

const activeStatus = computed<number | undefined>(() => {
  const raw = route.query.status
  if (raw == null || raw === '') return undefined
  const parsed = Number(Array.isArray(raw) ? raw[0] : raw)
  return Number.isFinite(parsed) ? parsed : undefined
})

function statusLabel(status?: number) {
  return status == null ? copy.value.statuses.all : copy.value.statuses.reservation(status)
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchReservations(activeStatus.value, 1, 50)
    list.value = result.list
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservations.loadFailed)
  } finally {
    loading.value = false
  }
}

async function switchStatus(status?: number) {
  const query: Record<string, string> = {}
  if (status != null) query.status = String(status)
  await router.replace({ path: '/user/reservations', query })
}

watch(
  [() => route.query.status, () => state.region],
  () => {
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.reservations.eyebrow }}</p>
        <h1>{{ copy.reservations.title }}</h1>
        <p>{{ copy.reservations.currentFilter(statusLabel(activeStatus)) }}</p>
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
    <p v-if="loading" class="feedback">{{ copy.reservations.loading }}</p>
    <p v-else-if="list.length === 0" class="feedback">{{ copy.reservations.empty }}</p>

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
          <p>{{ formatWebDateTime(item.reserveTime, copy.tag) }} · {{ copy.common.people(item.peopleCount) }}</p>
          <p class="muted">{{ copy.reservations.reservationNo(item.reservationNo) }}</p>
          <span class="status-pill">{{ copy.statuses.reservation(item.status, item.statusText) }}</span>
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
