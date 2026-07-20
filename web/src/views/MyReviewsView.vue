<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { deleteReview, listUserReviews } from '@/services/review'
import type { PageResult } from '@/types/browse'
import type { UserReviewSummary } from '@/types/review'

const { state: appState } = useAppContext()

const loading = ref(false)
const deletingId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<UserReviewSummary> | null>(null)

const filters = reactive({
  auditStatus: '',
  page: 1,
  pageSize: 10,
})

async function loadReviews() {
  loading.value = true
  errorMessage.value = ''

  try {
    pageState.value = await listUserReviews({
      auditStatus: filters.auditStatus ? Number(filters.auditStatus) : undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '我的点评加载失败'
  } finally {
    loading.value = false
  }
}

function applyFilters() {
  filters.page = 1
  void loadReviews()
}

function statusClass(auditStatus: number) {
  if (auditStatus === 1) {
    return 'status-pill status-pill--good'
  }
  if (auditStatus === 2) {
    return 'status-pill status-pill--muted'
  }
  return 'status-pill status-pill--warn'
}

async function handleDelete(reviewId: number) {
  if (!window.confirm('确认删除这条点评？删了可不会自己长回来。')) {
    return
  }

  deletingId.value = reviewId
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await deleteReview(reviewId)
    successMessage.value = `点评 #${reviewId} 已删除。`
    await loadReviews()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '点评删除失败'
  } finally {
    deletingId.value = null
  }
}

function goPrevPage() {
  if (!pageState.value || pageState.value.page <= 1) {
    return
  }
  filters.page -= 1
  void loadReviews()
}

function goNextPage() {
  if (!pageState.value?.hasMore) {
    return
  }
  filters.page += 1
  void loadReviews()
}

watch(
  () => appState.region,
  () => {
    filters.page = 1
    void loadReviews()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--single">
      <div class="hero-panel__content">
        <p class="eyebrow">我的点评</p>
        <h1>写过的、待审的、被驳回的，都得在这儿看得明明白白。</h1>
        <p class="hero-panel__summary">当前区域 {{ appState.region }}，前台现在已经接上后端点评闭环，不用再靠数据库猜状态。</p>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">筛选</p>
          <h2>先把审核状态捋顺，再看具体内容。</h2>
        </div>
      </div>

      <div class="field-row field-row--two">
        <label class="field">
          <span>审核状态</span>
          <select v-model="filters.auditStatus">
            <option value="">全部状态</option>
            <option value="0">待审</option>
            <option value="1">通过</option>
            <option value="2">驳回</option>
          </select>
        </label>

        <div class="hero-actions hero-actions--align-end">
          <button type="button" class="primary-button" @click="applyFilters">应用筛选</button>
          <button type="button" class="secondary-button" @click="loadReviews">刷新</button>
        </div>
      </div>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
      <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
      <p v-if="loading" class="feedback">我的点评加载中...</p>
      <p v-else-if="!pageState || pageState.list.length === 0" class="feedback">
        当前还没有点评记录，先去门店详情页写一条。
      </p>

      <div class="stack-list">
        <article v-for="item in pageState?.list" :key="item.id" class="manage-card">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow">点评 #{{ item.id }}</p>
              <h3>{{ item.shopName }}</h3>
            </div>
            <span :class="statusClass(item.auditStatus)">{{ item.auditStatusText }}</span>
          </div>

          <p class="manage-card__copy">{{ item.content }}</p>

          <div class="tag-row">
            <span v-for="tag in item.tags" :key="tag">{{ tag }}</span>
          </div>

          <p v-if="item.auditRemark" class="feedback is-error">驳回原因：{{ item.auditRemark }}</p>

          <div class="manage-card__footer">
            <span>评分 {{ item.scoreOverall.toFixed(1) }} · 创建于 {{ item.createdAt }}</span>
            <div class="hero-actions">
              <RouterLink :to="`/user/reviews/${item.id}`" class="ghost-button">查看详情</RouterLink>
              <RouterLink :to="`/reviews/${item.id}/edit`" class="secondary-button">编辑</RouterLink>
              <RouterLink v-if="item.auditStatus === 1" :to="`/reviews/${item.id}`" class="ghost-button">公开页</RouterLink>
              <button
                type="button"
                class="ghost-button danger-button"
                :disabled="deletingId === item.id"
                @click="handleDelete(item.id)"
              >
                {{ deletingId === item.id ? '删除中...' : '删除' }}
              </button>
            </div>
          </div>
        </article>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
          上一页
        </button>
        <span>第 {{ pageState?.page ?? 1 }} 页</span>
        <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
          下一页
        </button>
      </div>
    </section>
  </div>
</template>
