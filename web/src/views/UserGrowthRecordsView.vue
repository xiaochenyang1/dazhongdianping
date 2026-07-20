<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useUserSession } from '@/composables/useUserSession'
import { fetchCurrentUser, fetchUserGrowthRecords } from '@/services/auth'
import type { PageResult } from '@/types/browse'
import type { AuthCurrentUser, UserGrowthRecord } from '@/types/auth'

const { state, setCurrentUser } = useUserSession()

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
    errorMessage.value = recordsResult.reason instanceof Error ? recordsResult.reason.message : '成长值流水加载失败'
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

void loadRecords()
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--compact">
      <div class="hero-panel__content">
        <p class="eyebrow">成长值流水</p>
        <h1>每一笔成长值和积分都摊开看，别让等级变化像算命。</h1>
        <p class="hero-panel__summary">
          当前先把发点评奖励这条最小闭环看清楚，后面获赞、订单奖励再继续往里堆，不整玄学。
        </p>
        <div class="hero-actions">
          <RouterLink to="/user/profile" class="ghost-button">回我的资料</RouterLink>
          <RouterLink to="/user/reviews" class="secondary-button">去我的点评</RouterLink>
        </div>
      </div>

      <div class="hero-panel__side">
        <div class="hero-metric">
          <span>当前等级</span>
          <strong>Lv.{{ profile?.level ?? 1 }}</strong>
        </div>
        <div class="hero-metric">
          <span>积分 / 成长值</span>
          <strong>{{ profile?.points ?? 0 }} / {{ profile?.growthValue ?? 0 }}</strong>
        </div>
        <div class="hero-metric">
          <span>最近一笔</span>
          <strong>{{ latestRecord ? `${latestRecord.typeText}${amountText(latestRecord.changeAmount)}` : '暂无流水' }}</strong>
        </div>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">流水列表</p>
          <h2>现在先盯住发点评奖励，账得对得上，后面扩规则才不至于越做越乱。</h2>
        </div>
      </div>

      <div class="field-row field-row--two">
        <label class="field">
          <span>每页条数</span>
          <select v-model.number="filters.pageSize" @change="applyPageSize">
            <option :value="10">10 条</option>
            <option :value="20">20 条</option>
            <option :value="50">50 条</option>
          </select>
        </label>

        <div class="hero-actions hero-actions--align-end">
          <button type="button" class="secondary-button" @click="loadRecords">刷新流水</button>
        </div>
      </div>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
      <p v-if="loading" class="feedback">成长值流水加载中...</p>
      <p v-else-if="!pageState || pageState.list.length === 0" class="feedback">
        现在还没有流水，先去写条点评把第一笔奖励打出来。
      </p>

      <div class="stack-list">
        <article v-for="item in pageState?.list" :key="item.id" class="manage-card">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow">{{ item.typeText }}</p>
              <h3>{{ item.actionText }}</h3>
            </div>
            <span :class="typeClass(item.type)">{{ item.typeText }} {{ amountText(item.changeAmount) }}</span>
          </div>

          <p class="manage-card__copy">{{ item.remark || '系统奖励已入账。' }}</p>

          <div class="profile-grid">
            <div class="hero-metric">
              <span>变动</span>
              <strong>{{ amountText(item.changeAmount) }}</strong>
            </div>
            <div class="hero-metric">
              <span>余额</span>
              <strong>{{ item.balanceAfter }}</strong>
            </div>
            <div class="hero-metric">
              <span>入账时间</span>
              <strong>{{ item.createdAt }}</strong>
            </div>
          </div>

          <div class="manage-card__footer">
            <span>
              动作 {{ item.action }}
              <template v-if="item.bizId"> · 业务 #{{ item.bizId }}</template>
            </span>
            <div class="hero-actions">
              <RouterLink v-if="item.action === 'review_create' && item.bizId" :to="`/user/reviews/${item.bizId}`" class="ghost-button">
                查看点评
              </RouterLink>
            </div>
          </div>
        </article>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
          上一页
        </button>
        <span>第 {{ pageState?.page ?? 1 }} 页，共 {{ pageState?.total ?? 0 }} 条</span>
        <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
          下一页
        </button>
      </div>
    </section>
  </div>
</template>
