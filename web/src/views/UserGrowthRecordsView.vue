<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { fetchCurrentUser, fetchUserGrowthRecords } from '@/services/auth'
import type { PageResult } from '@/types/browse'
import type { AuthCurrentUser, UserGrowthRecord } from '@/types/auth'

const { state, setCurrentUser } = useUserSession()
const { state: appState } = useAppContext()
const copy = computed(() => userStringsForRegion(appState.region))

const loading = ref(false)
const errorMessage = ref('')
const profile = ref<AuthCurrentUser | null>(state.currentUser ?? null)
const pageState = ref<PageResult<UserGrowthRecord> | null>(null)
const filters = reactive({
  page: 1,
  pageSize: 10,
})

let loadRequestId = 0

const latestRecord = computed(() => pageState.value?.list[0] ?? null)

function amountText(value: number) {
  return `${value >= 0 ? '+' : ''}${value}`
}

function typeClass(type: number) {
  if (type === 1) {
    return 'status-pill status-pill--good'
  }
  if (type === 2) {
    return 'status-pill status-pill--warn'
  }
  return 'status-pill status-pill--muted'
}

async function loadRecords() {
  const requestId = ++loadRequestId
  loading.value = true
  errorMessage.value = ''

  const [profileResult, recordsResult] = await Promise.allSettled([
    fetchCurrentUser(),
    fetchUserGrowthRecords({
      page: filters.page,
      pageSize: filters.pageSize,
    }),
  ])

  if (requestId !== loadRequestId) {
    return
  }

  try {
    if (profileResult.status === 'fulfilled') {
      profile.value = profileResult.value
      setCurrentUser(profileResult.value)
    }

    if (recordsResult.status === 'fulfilled') {
      pageState.value = recordsResult.value
      return
    }

    pageState.value = null
    errorMessage.value = localizeWebUserError(copy.value, recordsResult.reason, copy.value.growth.loadFailed)
  } finally {
    if (requestId === loadRequestId) {
      loading.value = false
    }
  }
}

function applyPageSize() {
  filters.page = 1
  void loadRecords()
}

function goPrevPage() {
  if (!pageState.value || pageState.value.page <= 1) {
    return
  }
  filters.page -= 1
  void loadRecords()
}

function goNextPage() {
  if (!pageState.value?.hasMore) {
    return
  }
  filters.page += 1
  void loadRecords()
}

watch(
  () => appState.region,
  () => {
    filters.page = 1
    void loadRecords()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--compact">
      <div class="hero-panel__content">
        <p class="eyebrow">{{ copy.growth.eyebrow }}</p>
        <h1>{{ copy.growth.title }}</h1>
        <p class="hero-panel__summary">
          {{ copy.growth.summary }}
        </p>
        <div class="hero-actions">
          <RouterLink to="/user/profile" class="ghost-button">{{ copy.growth.backProfile }}</RouterLink>
          <RouterLink to="/user/reviews" class="secondary-button">{{ copy.growth.myReviews }}</RouterLink>
        </div>
      </div>

      <div class="hero-panel__side">
        <div class="hero-metric">
          <span>{{ copy.growth.currentLevel }}</span>
          <strong>Lv.{{ profile?.level ?? 1 }}</strong>
        </div>
        <div class="hero-metric">
          <span>{{ copy.growth.pointsAndGrowth }}</span>
          <strong>{{ profile?.points ?? 0 }} / {{ profile?.growthValue ?? 0 }}</strong>
        </div>
        <div class="hero-metric">
          <span>{{ copy.growth.latest }}</span>
          <strong>
            {{ latestRecord ? `${copy.growth.type(latestRecord.type, latestRecord.typeText)} ${amountText(latestRecord.changeAmount)}` : copy.growth.noRecords }}
          </strong>
        </div>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.growth.listEyebrow }}</p>
          <h2>{{ copy.growth.listTitle }}</h2>
        </div>
      </div>

      <div class="field-row field-row--two">
        <label class="field">
          <span>{{ copy.growth.pageSize }}</span>
          <select v-model.number="filters.pageSize" @change="applyPageSize">
            <option :value="10">{{ copy.growth.rows(10) }}</option>
            <option :value="20">{{ copy.growth.rows(20) }}</option>
            <option :value="50">{{ copy.growth.rows(50) }}</option>
          </select>
        </label>

        <div class="hero-actions hero-actions--align-end">
          <button type="button" class="secondary-button" @click="loadRecords">{{ copy.growth.refresh }}</button>
        </div>
      </div>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
      <p v-if="loading" class="feedback">{{ copy.growth.loading }}</p>
      <p v-else-if="!pageState || pageState.list.length === 0" class="feedback">
        {{ copy.growth.empty }}
      </p>

      <div class="stack-list">
        <article v-for="item in pageState?.list" :key="item.id" class="manage-card">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow">{{ copy.growth.type(item.type, item.typeText) }}</p>
              <h3>{{ copy.growth.actionLabel(item.action, item.actionText) }}</h3>
            </div>
            <span :class="typeClass(item.type)">{{ copy.growth.type(item.type, item.typeText) }} {{ amountText(item.changeAmount) }}</span>
          </div>

          <p class="manage-card__copy">
            {{ item.remark ? copy.growth.remarkLabel(item.action, item.remark) : copy.growth.defaultRemark }}
          </p>

          <div class="profile-grid">
            <div class="hero-metric">
              <span>{{ copy.growth.change }}</span>
              <strong>{{ amountText(item.changeAmount) }}</strong>
            </div>
            <div class="hero-metric">
              <span>{{ copy.growth.balance }}</span>
              <strong>{{ item.balanceAfter }}</strong>
            </div>
            <div class="hero-metric">
              <span>{{ copy.growth.creditedAt }}</span>
              <strong>{{ formatWebDateTime(item.createdAt, copy.tag) }}</strong>
            </div>
          </div>

          <div class="manage-card__footer">
            <span>
              {{ copy.growth.action }} {{ item.action }}
              <template v-if="item.bizId"> · {{ copy.growth.business(item.bizId) }}</template>
            </span>
            <div class="hero-actions">
              <RouterLink v-if="item.action === 'review_create' && item.bizId" :to="`/user/reviews/${item.bizId}`" class="ghost-button">
                {{ copy.growth.viewReview }}
              </RouterLink>
            </div>
          </div>
        </article>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
          {{ copy.common.previous }}
        </button>
        <span>{{ copy.growth.pagination(pageState?.page ?? 1, pageState?.total ?? 0) }}</span>
        <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
          {{ copy.common.next }}
        </button>
      </div>
    </section>
  </div>
</template>
