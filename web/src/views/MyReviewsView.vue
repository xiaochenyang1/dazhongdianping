<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebReviewError, reviewStringsForRegion } from '@/core/web_review_localizations'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { deleteReview, listUserReviews } from '@/services/review'
import type { PageResult } from '@/types/browse'
import type { UserReviewSummary } from '@/types/review'

const { state: appState } = useAppContext()
const copy = computed(() => userStringsForRegion(appState.region))
const reviewCopy = computed(() => reviewStringsForRegion(appState.region))

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
    errorMessage.value = localizeWebReviewError(reviewCopy.value, error, copy.value.reviews.loadFailed)
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
  if (!window.confirm(copy.value.reviews.deleteConfirm)) {
    return
  }

  deletingId.value = reviewId
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await deleteReview(reviewId)
    successMessage.value = copy.value.reviews.deleted(reviewId)
    await loadReviews()
  } catch (error) {
    errorMessage.value = localizeWebUserError(copy.value, error, copy.value.reviews.deleteFailed)
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
        <p class="eyebrow">{{ copy.reviews.eyebrow }}</p>
        <h1>{{ copy.reviews.title }}</h1>
        <p class="hero-panel__summary">{{ copy.reviews.summary(appState.region) }}</p>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.reviews.filters }}</p>
          <h2>{{ copy.reviews.filtersTitle }}</h2>
        </div>
      </div>

      <div class="field-row field-row--two">
        <label class="field">
          <span>{{ copy.reviews.auditStatus }}</span>
          <select v-model="filters.auditStatus">
            <option value="">{{ copy.reviews.allStatuses }}</option>
            <option value="0">{{ copy.reviews.status(0) }}</option>
            <option value="1">{{ copy.reviews.status(1) }}</option>
            <option value="2">{{ copy.reviews.status(2) }}</option>
          </select>
        </label>

        <div class="hero-actions hero-actions--align-end">
          <button type="button" class="primary-button" @click="applyFilters">{{ copy.reviews.apply }}</button>
          <button type="button" class="secondary-button" @click="loadReviews">{{ copy.common.refresh }}</button>
        </div>
      </div>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
      <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
      <p v-if="loading" class="feedback">{{ copy.reviews.loading }}</p>
      <p v-else-if="!pageState || pageState.list.length === 0" class="feedback">
        {{ copy.reviews.empty }}
      </p>

      <div class="stack-list">
        <article v-for="item in pageState?.list" :key="item.id" class="manage-card">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow">{{ copy.reviews.review(item.id) }}</p>
              <h3>{{ item.shopName }}</h3>
            </div>
            <span :class="statusClass(item.auditStatus)">{{ reviewCopy.detail.auditStatusLabel(item.auditStatus, item.auditStatusText) }}</span>
          </div>

          <p class="manage-card__copy">{{ item.content }}</p>

          <div class="tag-row">
            <span v-for="tag in item.tags" :key="tag">{{ tag }}</span>
          </div>

          <p v-if="item.auditRemark" class="feedback is-error">{{ copy.reviews.rejectReason }}: {{ item.auditRemark }}</p>

          <div class="manage-card__footer">
            <span>{{ copy.reviews.ratingAndDate(item.scoreOverall.toFixed(1), formatWebDateTime(item.createdAt, copy.tag)) }}</span>
            <div class="hero-actions">
              <RouterLink :to="`/user/reviews/${item.id}`" class="ghost-button">{{ copy.reviews.viewDetails }}</RouterLink>
              <RouterLink :to="`/reviews/${item.id}/edit`" class="secondary-button">{{ copy.reviews.edit }}</RouterLink>
              <RouterLink v-if="item.auditStatus === 1" :to="`/reviews/${item.id}`" class="ghost-button">{{ copy.reviews.publicPage }}</RouterLink>
              <button
                type="button"
                class="ghost-button danger-button"
                :disabled="deletingId === item.id"
                @click="handleDelete(item.id)"
              >
                {{ deletingId === item.id ? copy.reviews.deleting : copy.reviews.delete }}
              </button>
            </div>
          </div>
        </article>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
          {{ copy.common.previous }}
        </button>
        <span>{{ copy.reviews.page(pageState?.page ?? 1) }}</span>
        <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
          {{ copy.common.next }}
        </button>
      </div>
    </section>
  </div>
</template>
