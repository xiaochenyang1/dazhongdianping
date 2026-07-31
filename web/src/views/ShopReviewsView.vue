<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebShopError, shopStringsForRegion } from '@/core/web_shop_localizations'
import { formatMoney } from '@/lib/currency'
import { fetchShopDetail, fetchShopReviews, type ShopReviewQuery } from '@/services/browse'
import type { ReviewPreview, ShopDetail } from '@/types/browse'

const props = defineProps<{
  shopId: number
}>()

const { state } = useAppContext()

const loading = ref(false)
const loadingMore = ref(false)
const errorMessage = ref('')
const loadMoreErrorMessage = ref('')
const shop = ref<ShopDetail | null>(null)
const reviews = ref<ReviewPreview[]>([])
const reviewTotal = ref(0)
const reviewPage = ref(1)
const reviewHasMore = ref(false)
const reviewSort = ref<ShopReviewQuery['sort']>('latest')
const reviewMinScore = ref('')
const reviewHasImages = ref('')
let reviewsRequestId = 0
let appliedReviewQuery: ShopReviewQuery = {}

const REVIEW_PAGE_SIZE = 20
const copy = computed(() => shopStringsForRegion(state.region))
const certificationCopy = computed(() => discoveryStringsForRegion(state.region).shopCard)

const reviewFacts = computed(() => {
  if (!shop.value) {
    return []
  }

  const remaining = Math.max(reviewTotal.value - reviews.value.length, 0)

  return [
    {
      label: copy.value.reviews.loaded,
      value: `${reviews.value.length} / ${reviewTotal.value}`,
      detail: reviewHasMore.value ? copy.value.reviews.moreAvailable(remaining) : copy.value.reviews.allLoaded,
    },
    {
      label: copy.value.reviews.averageSpend,
      value: formatMoney(shop.value.pricePerCapita, shop.value.currency),
      detail: copy.value.reviews.priceDetail,
    },
    {
      label: copy.value.reviews.perspective,
      value: state.region,
      detail: `${shop.value.cityName} · ${shop.value.areaName} · ${shop.value.categoryName}`,
    },
  ]
})

function currentReviewQuery(): ShopReviewQuery {
  const query: ShopReviewQuery = {}
  if (reviewSort.value && reviewSort.value !== 'latest') query.sort = reviewSort.value
  if (reviewMinScore.value) query.minScore = Number(reviewMinScore.value)
  if (reviewHasImages.value === 'true') query.hasImages = true
  if (reviewHasImages.value === 'false') query.hasImages = false
  return query
}

function loadReviewsPage(shopId: number, page: number, query: ShopReviewQuery) {
  return Object.keys(query).length > 0
    ? fetchShopReviews(shopId, page, REVIEW_PAGE_SIZE, query)
    : fetchShopReviews(shopId, page, REVIEW_PAGE_SIZE)
}

async function loadReviews(clearShop = false) {
  const requestId = ++reviewsRequestId
  const shopId = props.shopId
  const query = currentReviewQuery()
  loadingMore.value = false
  loadMoreErrorMessage.value = ''
  if (clearShop) shop.value = null
  reviews.value = []
  reviewTotal.value = 0
  reviewPage.value = 1
  reviewHasMore.value = false
  if (Number.isNaN(shopId)) {
    errorMessage.value = copy.value.reviews.invalidId
    loading.value = false
    return
  }

  loading.value = clearShop || shop.value == null
  errorMessage.value = ''

  try {
    const [shopDetail, reviewResult] = await Promise.all([
      fetchShopDetail(shopId),
      loadReviewsPage(shopId, 1, query),
    ])
    if (requestId !== reviewsRequestId) return
    shop.value = shopDetail
    reviews.value = reviewResult.list
    reviewTotal.value = reviewResult.total
    reviewPage.value = reviewResult.page
    reviewHasMore.value = reviewResult.hasMore
    appliedReviewQuery = query
  } catch (error) {
    if (requestId === reviewsRequestId) {
      errorMessage.value = localizeWebShopError(copy.value, error, copy.value.reviews.loadFailed)
    }
  } finally {
    if (requestId === reviewsRequestId) loading.value = false
  }
}

async function loadMoreReviews() {
  if (!reviewHasMore.value || loadingMore.value) {
    return
  }

  const requestId = reviewsRequestId
  const shopId = props.shopId
  const targetPage = reviewPage.value + 1
  loadingMore.value = true
  loadMoreErrorMessage.value = ''
  try {
    const nextPage = await loadReviewsPage(shopId, targetPage, appliedReviewQuery)
    if (requestId !== reviewsRequestId || props.shopId !== shopId) return
    reviews.value = [...reviews.value, ...nextPage.list]
    reviewTotal.value = nextPage.total
    reviewPage.value = nextPage.page
    reviewHasMore.value = nextPage.hasMore
  } catch (error) {
    if (requestId === reviewsRequestId) {
      loadMoreErrorMessage.value = localizeWebShopError(copy.value, error, copy.value.reviews.moreLoadFailed)
    }
  } finally {
    if (requestId === reviewsRequestId) loadingMore.value = false
  }
}

watch(
  [() => props.shopId, () => state.region],
  () => {
    void loadReviews(true)
  },
  { immediate: true },
)
</script>

<template>
  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
  <p v-else-if="loading" class="feedback">{{ copy.reviews.loading }}</p>

  <template v-else-if="shop">
    <section class="detail-hero detail-hero--compact">
      <div class="detail-hero__body">
        <p class="eyebrow">{{ shop.cityName }} · {{ shop.areaName }} · {{ shop.categoryName }}</p>
        <h1>{{ copy.reviews.title(shop.name) }}</h1>
        <p class="detail-hero__summary">{{ shop.summary }}</p>
        <div class="detail-hero__stats">
          <div>
            <span>{{ copy.reviews.score }}</span>
            <strong>{{ shop.score.toFixed(1) }}</strong>
          </div>
          <div>
            <span>{{ copy.detail.averageSpend }}</span>
            <strong>{{ formatMoney(shop.pricePerCapita, shop.currency) }}</strong>
          </div>
          <div>
            <span>{{ copy.reviews.publicReviews }}</span>
            <strong>{{ reviewTotal }}</strong>
          </div>
        </div>
        <div class="hero-actions">
          <RouterLink :to="`/shops/${shop.id}`" class="secondary-button">{{ copy.reviews.backToShop }}</RouterLink>
          <RouterLink :to="`/shops/${shop.id}/reviews/new`" class="primary-link">{{ copy.reviews.writeReview }}</RouterLink>
        </div>
        <p class="support-copy">{{ copy.reviews.support }}</p>
      </div>

      <aside class="hero-aside">
        <div v-for="fact in reviewFacts" :key="fact.label" class="hero-metric">
          <span>{{ fact.label }}</span>
          <strong>{{ fact.value }}</strong>
          <p class="support-copy">{{ fact.detail }}</p>
        </div>
      </aside>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.reviews.listEyebrow }}</p>
          <h2>{{ copy.reviews.listTitle }}</h2>
        </div>
        <div class="review-filters" :aria-label="copy.reviews.filterAria">
          <label class="compact-field">
            <span>{{ copy.reviews.sort }}</span>
            <select v-model="reviewSort" data-testid="review-sort">
              <option value="latest">{{ copy.reviews.latest }}</option>
              <option value="popular">{{ copy.reviews.popular }}</option>
              <option value="score">{{ copy.reviews.scoreSort }}</option>
            </select>
          </label>
          <label class="compact-field">
            <span>{{ copy.reviews.minScore }}</span>
            <select v-model="reviewMinScore" data-testid="review-min-score">
              <option value="">{{ copy.reviews.any }}</option>
              <option value="4">{{ copy.reviews.points('4') }}</option>
              <option value="4.5">{{ copy.reviews.points('4.5') }}</option>
              <option value="5">{{ copy.reviews.points('5') }}</option>
            </select>
          </label>
          <label class="compact-field">
            <span>{{ copy.reviews.images }}</span>
            <select v-model="reviewHasImages" data-testid="review-has-images">
              <option value="">{{ copy.reviews.allImages }}</option>
              <option value="true">{{ copy.reviews.withImages }}</option>
              <option value="false">{{ copy.reviews.withoutImages }}</option>
            </select>
          </label>
          <button type="button" class="secondary-button" data-testid="apply-review-filters" @click="loadReviews()">{{ copy.reviews.apply }}</button>
        </div>
      </div>

      <div v-if="reviews.length > 0" class="review-list">
        <RouterLink v-for="review in reviews" :key="review.id" :to="`/reviews/${review.id}`" class="review-link-card">
          <article class="review-card">
            <div class="review-card__header">
              <strong class="name-with-badge">
                <span>{{ review.userName }}</span>
                <span v-if="review.authorCertification" class="verified-badge verified-badge--compact">
                  {{ certificationCopy.certificationLabel(review.authorCertification.code, review.authorCertification.label) }}
                </span>
              </strong>
              <span>{{ formatWebDateTime(review.createdAt, copy.tag) }} · {{ review.score.toFixed(1) }}</span>
            </div>
            <p>{{ review.content }}</p>
            <span class="review-card__foot">{{ copy.reviews.likes(review.likedCount) }} · {{ copy.reviews.comments(review.commentCount) }} · {{ copy.reviews.viewDetails }}</span>
          </article>
        </RouterLink>
      </div>
      <p v-else class="feedback">{{ copy.reviews.noReviews }}</p>
      <p v-if="loadMoreErrorMessage" class="feedback is-error">{{ loadMoreErrorMessage }}</p>
      <button
        v-if="reviewHasMore"
        type="button"
        class="secondary-button"
        :disabled="loadingMore"
        @click="loadMoreReviews"
      >
        {{ loadingMore ? copy.reviews.loadingMore : copy.reviews.loadMore }}
      </button>
    </section>
  </template>
</template>
