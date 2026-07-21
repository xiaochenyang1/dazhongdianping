<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import ShopCard from '@/components/ShopCard.vue'
import { useAppContext } from '@/composables/useAppContext'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { formatMoney } from '@/lib/currency'
import { fetchShopDetail, fetchSimilarShops, fetchShopReviews } from '@/services/browse'
import { addFavorite, fetchFavorites, removeFavorite } from '@/services/favorite'
import { fetchShopDeals } from '@/services/trade'
import type { DealSummary } from '@/types/trade'
import { useUserSession } from '@/composables/useUserSession'
import type { ReviewPreview, ShopDetail, ShopListItem } from '@/types/browse'

const route = useRoute()
const { state } = useAppContext()
const { state: sessionState, openAuthDialog } = useUserSession()

const loading = ref(false)
const errorMessage = ref('')
const shop = ref<ShopDetail | null>(null)
const reviews = ref<ReviewPreview[]>([])
const favorited = ref(false)
const favoriteLoading = ref(false)
const deals = ref<DealSummary[]>([])
const shareMessage = ref('')
const similarShops = ref<ShopListItem[]>([])
let detailRequestId = 0

const shopId = computed(() => Number(route.params.id))

useSeoMeta(() => {
  const canonicalPath = `/shops/${shopId.value}`
  const currentShop = shop.value
  if (!currentShop) {
    return {
      title: '门店详情',
      description: '查看门店地址、营业时间、评分、优惠、点评与附近推荐。',
      canonical: canonicalPath,
      robots: 'noindex,nofollow',
    }
  }

  return {
    title: `${currentShop.name} - ${currentShop.cityName}${currentShop.categoryName}`,
    description: toSeoDescription(`${currentShop.summary} 地址：${currentShop.address}。`),
    canonical: canonicalPath,
    image: currentShop.coverUrl,
    type: 'restaurant' as const,
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'Restaurant',
      url: absoluteSeoUrl(canonicalPath),
      name: currentShop.name,
      description: currentShop.summary,
      image: currentShop.coverUrl,
      telephone: currentShop.phone,
      servesCuisine: currentShop.categoryName,
      openingHours: currentShop.businessHours,
      currenciesAccepted: currentShop.currency,
      priceRange: `${currentShop.currency} ${currentShop.pricePerCapita}`,
      address: {
        '@type': 'PostalAddress',
        streetAddress: currentShop.address,
        addressLocality: currentShop.cityName,
        addressRegion: currentShop.areaName,
      },
    },
  }
})

async function loadShopDetail() {
  const requestId = ++detailRequestId
  const targetShopId = shopId.value
  shop.value = null
  reviews.value = []
  deals.value = []
  similarShops.value = []
  favorited.value = false
  shareMessage.value = ''
  errorMessage.value = ''
  if (Number.isNaN(targetShopId)) {
    errorMessage.value = '商户 ID 不合法'
    loading.value = false
    return
  }

  loading.value = true

  try {
    const [shopDetail, reviewPage, dealList, similarList] = await Promise.all([
      fetchShopDetail(targetShopId),
      fetchShopReviews(targetShopId, 1, 3),
      fetchShopDeals(targetShopId),
      fetchSimilarShops(targetShopId, 6).catch(() => []),
    ])
    if (requestId !== detailRequestId) return
    shop.value = shopDetail
    reviews.value = reviewPage.list
    deals.value = dealList
    similarShops.value = similarList
    if (sessionState.accessToken) {
      const favorites = await fetchFavorites(1, 1, 50)
      if (requestId !== detailRequestId) return
      favorited.value = favorites.list.some((item) => item.targetId === targetShopId)
    } else {
      favorited.value = false
    }
  } catch (error) {
    if (requestId === detailRequestId) {
      errorMessage.value = error instanceof Error ? error.message : '商户详情加载失败'
    }
  } finally {
    if (requestId === detailRequestId) loading.value = false
  }
}

async function toggleFavorite() {
  if (!sessionState.accessToken) {
    openAuthDialog({ mode: 'password', redirectTo: route.fullPath })
    return
  }
  favoriteLoading.value = true
  try {
    if (favorited.value) await removeFavorite(1, shopId.value)
    else await addFavorite(1, shopId.value)
    favorited.value = !favorited.value
  } finally { favoriteLoading.value = false }
}

async function shareShop() {
  if (!shop.value) return
  shareMessage.value = ''
  const payload = {
    title: shop.value.name,
    text: `${shop.value.name} · ${shop.value.cityName} · ${shop.value.score.toFixed(1)} 分`,
    url: window.location.href,
  }
  try {
    if (typeof navigator.share === 'function') {
      await navigator.share(payload)
    } else if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(payload.url)
    } else {
      const textarea = document.createElement('textarea')
      textarea.value = payload.url
      textarea.setAttribute('readonly', '')
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      textarea.remove()
    }
    shareMessage.value = '分享链接已准备好'
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') return
    shareMessage.value = error instanceof Error ? error.message : '分享失败，请稍后重试'
  }
}


watch(
  [shopId, () => state.region],
  () => {
    void loadShopDetail()
  },
  { immediate: true },
)
</script>

<template>
  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
  <p v-else-if="loading" class="feedback">详情加载中...</p>

  <template v-else-if="shop">
    <section class="detail-hero">
      <img :src="shop.coverUrl" :alt="shop.name" class="detail-hero__image" />
      <div class="detail-hero__body">
        <p class="eyebrow">{{ shop.cityName }} · {{ shop.areaName }} · {{ shop.categoryName }}</p>
        <h1>{{ shop.name }}</h1>
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
            <span>营业状态</span>
            <strong>{{ shop.openNow ? '营业中' : '休息中' }}</strong>
          </div>
        </div>
        <div class="tag-row">
          <span v-for="tag in shop.tags" :key="tag">{{ tag }}</span>
        </div>
        <div class="hero-actions">
          <RouterLink :to="`/shops/${shop.id}/reviews/new`" class="primary-link">写点评</RouterLink>
          <RouterLink :to="`/shops/${shop.id}/reviews`" class="secondary-button">全部点评</RouterLink>
          <RouterLink to="/user/reviews" class="secondary-button">我的点评</RouterLink>
          <button type="button" class="secondary-button" :disabled="favoriteLoading" @click="toggleFavorite">{{ favorited ? '取消收藏' : '收藏门店' }}</button>
          <button type="button" class="secondary-button" data-testid="share-shop" @click="shareShop">分享</button>
          <RouterLink :to="`/shops/${shop.id}/reserve`" class="secondary-button">在线预订</RouterLink>
        </div>
        <p v-if="shareMessage" class="feedback" role="status">{{ shareMessage }}</p>
      </div>
    </section>

    <section class="detail-grid">
      <article class="detail-card">
        <div class="section-header">
          <div>
            <p class="eyebrow">基础信息</p>
            <h2>先把最值钱的内容呈现出来。</h2>
          </div>
        </div>
        <dl class="detail-list">
          <div>
            <dt>地址</dt>
            <dd>{{ shop.address }}</dd>
          </div>
          <div>
            <dt>电话</dt>
            <dd>{{ shop.phone }}</dd>
          </div>
          <div>
            <dt>营业时间</dt>
            <dd>{{ shop.businessHours }}</dd>
          </div>
          <div>
            <dt>口味 / 环境 / 服务</dt>
            <dd>{{ shop.tasteScore }} / {{ shop.envScore }} / {{ shop.serviceScore }}</dd>
          </div>
          <div>
            <dt>优惠状态</dt>
            <dd>{{ shop.hasDeal ? '当前有团购/优惠' : '暂无优惠' }}</dd>
          </div>
        </dl>
      </article>

      <article class="detail-card">
        <div class="section-header">
          <div>
            <p class="eyebrow">推荐菜</p>
            <h2>数据先走后端，后面再扩成完整菜单。</h2>
          </div>
        </div>
        <div v-if="shop.recommendedDishes.length > 0" class="dish-list">
          <div v-for="dish in shop.recommendedDishes" :key="dish.id" class="dish-card">
            <div>
              <h3>{{ dish.name }}</h3>
              <p>{{ dish.recommendReason }}</p>
            </div>
            <strong>{{ formatMoney(dish.price, shop.currency) }}</strong>
          </div>
        </div>
        <p v-else class="feedback">这家店暂时还没补推荐菜，先看基础信息和公开点评也够用。</p>
      </article>
    </section>

    <section class="content-section">
      <div class="section-header"><div><p class="eyebrow">团购优惠</p><h2>套餐内容、有效期和规则都从交易域读取。</h2></div></div>
      <div v-if="deals.length" class="rank-grid"><RouterLink v-for="deal in deals" :key="deal.id" :to="`/deals/${deal.id}`" class="rank-card"><img :src="deal.coverImage" :alt="deal.title"><div class="rank-card__body"><h3>{{deal.title}}</h3><strong>{{formatMoney(deal.price,deal.currency)}}</strong><span>原价 {{formatMoney(deal.originalPrice,deal.currency)}} · 已售 {{deal.soldCount}}</span></div></RouterLink></div>
      <p v-else class="feedback">当前门店暂无上架团购。</p>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">门店相册</p>
          <h2>这块已经和后端详情接口打通。</h2>
        </div>
      </div>
      <div v-if="shop.photos.length > 0" class="photo-grid">
        <img v-for="photo in shop.photos" :key="photo.id" :src="photo.imageUrl" :alt="shop.name" />
      </div>
      <p v-else class="feedback">门店相册还没补齐，先靠点评和基础信息判断也不至于两眼一抹黑。</p>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">点评预览</p>
          <h2>公开点评已经接上了，前台现在能顺手跳去看详情。</h2>
        </div>
        <RouterLink :to="`/shops/${shop.id}/reviews`" class="secondary-button">全部点评</RouterLink>
      </div>
      <div v-if="reviews.length > 0" class="review-list">
        <RouterLink v-for="review in reviews" :key="review.id" :to="`/reviews/${review.id}`" class="review-link-card">
          <article class="review-card">
            <div class="review-card__header">
              <strong class="name-with-badge">
                <span>{{ review.userName }}</span>
                <span v-if="review.authorCertification" class="verified-badge verified-badge--compact">
                  {{ review.authorCertification.label }}
                </span>
              </strong>
              <span>{{ review.createdAt }} · {{ review.score.toFixed(1) }}</span>
            </div>
            <p>{{ review.content }}</p>
            <span class="review-card__foot">点赞 {{ review.likedCount }} · 评论 {{ review.commentCount }} · 查看详情</span>
          </article>
        </RouterLink>
      </div>
      <p v-else class="feedback">这家店还没有公开点评，想补第一条就直接去写点评。</p>
    </section>

    <section v-if="similarShops.length > 0" class="content-section" data-testid="similar-shops">
      <div class="section-header">
        <div>
          <p class="eyebrow">附近推荐</p>
          <h2>附近相似门店</h2>
        </div>
      </div>
      <div class="shop-grid">
        <RouterLink
          v-for="similarShop in similarShops"
          :key="similarShop.id"
          :to="`/shops/${similarShop.id}`"
          class="shop-grid__link"
        >
          <ShopCard :shop="similarShop" />
        </RouterLink>
      </div>
    </section>
  </template>
</template>
