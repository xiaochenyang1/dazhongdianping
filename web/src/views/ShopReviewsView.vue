<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { formatMoney } from '@/lib/currency'
import { fetchShopDetail, fetchShopReviews } from '@/services/browse'
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

const REVIEW_PAGE_SIZE = 20

const reviewFacts = computed(() => {
  if (!shop.value) {
    return []
  }

  const remaining = Math.max(reviewTotal.value - reviews.value.length, 0)

  return [
    {
      label: '已加载',
      value: `${reviews.value.length} / ${reviewTotal.value}`,
      detail: reviewHasMore.value ? `还有 ${remaining} 条公开点评可继续往下翻。` : '当前这批公开点评已经翻到底了。',
    },
    {
      label: '人均客单',
      value: formatMoney(shop.value.pricePerCapita, shop.value.currency),
      detail: '价格口径和门店详情保持一致，不额外玩花活。',
    },
    {
      label: '浏览视角',
      value: state.region,
      detail: `${shop.value.cityName} · ${shop.value.areaName} · ${shop.value.categoryName}`,
    },
  ]
})

async function loadReviews() {
  if (Number.isNaN(props.shopId)) {
    errorMessage.value = '商户 ID 不合法'
    return
  }

  loading.value = true
  errorMessage.value = ''
  loadMoreErrorMessage.value = ''

  try {
    const [shopDetail, reviewResult] = await Promise.all([
      fetchShopDetail(props.shopId),
      fetchShopReviews(props.shopId, 1, REVIEW_PAGE_SIZE),
    ])
    shop.value = shopDetail
    reviews.value = reviewResult.list
    reviewTotal.value = reviewResult.total
    reviewPage.value = reviewResult.page
    reviewHasMore.value = reviewResult.hasMore
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店点评加载失败'
  } finally {
    loading.value = false
  }
}

async function loadMoreReviews() {
  if (!reviewHasMore.value || loadingMore.value) {
    return
  }

  loadingMore.value = true
  loadMoreErrorMessage.value = ''
  try {
    const nextPage = await fetchShopReviews(props.shopId, reviewPage.value + 1, REVIEW_PAGE_SIZE)
    reviews.value = [...reviews.value, ...nextPage.list]
    reviewTotal.value = nextPage.total
    reviewPage.value = nextPage.page
    reviewHasMore.value = nextPage.hasMore
  } catch (error) {
    loadMoreErrorMessage.value = error instanceof Error ? error.message : '更多点评加载失败'
  } finally {
    loadingMore.value = false
  }
}

watch(
  [() => props.shopId, () => state.region],
  () => {
    void loadReviews()
  },
  { immediate: true },
)
</script>

<template>
  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
  <p v-else-if="loading" class="feedback">点评列表加载中...</p>

  <template v-else-if="shop">
    <section class="detail-hero detail-hero--compact">
      <div class="detail-hero__body">
        <p class="eyebrow">{{ shop.cityName }} · {{ shop.areaName }} · {{ shop.categoryName }}</p>
        <h1>{{ shop.name }}的公开点评</h1>
        <p class="detail-hero__summary">{{ shop.summary }}</p>
        <div class="detail-hero__stats">
          <div>
            <span>综合评分</span>
            <strong>{{ shop.score.toFixed(1) }}</strong>
          </div>
          <div>
            <span>人均</span>
            <strong>{{ formatMoney(shop.pricePerCapita, shop.currency) }}</strong>
          </div>
          <div>
            <span>公开点评</span>
            <strong>{{ reviewTotal }}</strong>
          </div>
        </div>
        <div class="hero-actions">
          <RouterLink :to="`/shops/${shop.id}`" class="secondary-button">回到门店</RouterLink>
          <RouterLink :to="`/shops/${shop.id}/reviews/new`" class="primary-link">写点评</RouterLink>
        </div>
        <p class="support-copy">当前按公开可见点评集中展示，想看互动细节就直接点进具体点评页。</p>
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
          <p class="eyebrow">点评列表</p>
          <h2>审核通过的公开点评集中放这儿，别都挤在详情页预览里。</h2>
        </div>
      </div>

      <div v-if="reviews.length > 0" class="review-list">
        <RouterLink v-for="review in reviews" :key="review.id" :to="`/reviews/${review.id}`" class="review-link-card">
          <article class="review-card">
            <div class="review-card__header">
              <strong>{{ review.userName }}</strong>
              <span>{{ review.createdAt }} · {{ review.score.toFixed(1) }}</span>
            </div>
            <p>{{ review.content }}</p>
            <span class="review-card__foot">点赞 {{ review.likedCount }} · 评论 {{ review.commentCount }} · 查看详情</span>
          </article>
        </RouterLink>
      </div>
      <p v-else class="feedback">这家店暂时没有公开点评。</p>
      <p v-if="loadMoreErrorMessage" class="feedback is-error">{{ loadMoreErrorMessage }}</p>
      <button
        v-if="reviewHasMore"
        type="button"
        class="secondary-button"
        :disabled="loadingMore"
        @click="loadMoreReviews"
      >
        {{ loadingMore ? '加载中...' : '加载更多点评' }}
      </button>
    </section>
  </template>
</template>
