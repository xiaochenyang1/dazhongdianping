<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import ShopCard from '@/components/ShopCard.vue'
import { useAppContext } from '@/composables/useAppContext'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebShopError, shopStringsForRegion } from '@/core/web_shop_localizations'
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
const copy = computed(() => shopStringsForRegion(state.region))
const certificationCopy = computed(() => discoveryStringsForRegion(state.region).shopCard)

useSeoMeta(() => {
  const canonicalPath = `/shops/${shopId.value}`
  const currentShop = shop.value
  if (!currentShop) {
    return {
      title: copy.value.detail.seoTitle,
      description: copy.value.detail.seoDescription,
      canonical: canonicalPath,
      robots: 'noindex,nofollow',
    }
  }

  return {
    title: `${currentShop.name} - ${currentShop.cityName}${currentShop.categoryName}`,
    description: toSeoDescription(copy.value.detail.seoDescriptionFor(currentShop.summary, currentShop.address)),
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
    errorMessage.value = copy.value.detail.invalidId
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
      errorMessage.value = localizeWebShopError(copy.value, error, copy.value.detail.loadFailed)
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
    text: copy.value.detail.shareText(shop.value.name, shop.value.cityName, shop.value.score.toFixed(1)),
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
    shareMessage.value = copy.value.detail.shareReady
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') return
    shareMessage.value = localizeWebShopError(copy.value, error, copy.value.detail.shareFailed)
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
  <p v-else-if="loading" class="feedback">{{ copy.detail.loading }}</p>

  <template v-else-if="shop">
    <section class="detail-hero">
      <img :src="shop.coverUrl" :alt="shop.name" class="detail-hero__image" />
      <div class="detail-hero__body">
        <p class="eyebrow">{{ shop.cityName }} · {{ shop.areaName }} · {{ shop.categoryName }}</p>
        <h1 class="name-with-badge">
          {{ shop.name }}
          <span v-if="shop.merchantCertification" class="verified-badge">
            {{ certificationCopy.certificationLabel(shop.merchantCertification.code, shop.merchantCertification.label) }}
          </span>
        </h1>
        <p class="detail-hero__summary">{{ shop.summary }}</p>
        <div class="detail-hero__stats">
          <div>
            <span>{{ copy.detail.score }}</span>
            <strong>{{ shop.score.toFixed(1) }}</strong>
          </div>
          <div>
            <span>{{ copy.detail.averageSpend }}</span>
            <strong>{{ formatMoney(shop.pricePerCapita, shop.currency) }}</strong>
          </div>
          <div>
            <span>{{ copy.detail.openingStatus }}</span>
            <strong>{{ shop.openNow ? copy.detail.openNow : copy.detail.closed }}</strong>
          </div>
        </div>
        <div class="tag-row">
          <span v-for="tag in shop.tags" :key="tag">{{ tag }}</span>
        </div>
        <div class="hero-actions">
          <RouterLink :to="`/shops/${shop.id}/reviews/new`" class="primary-link">{{ copy.detail.writeReview }}</RouterLink>
          <RouterLink :to="`/shops/${shop.id}/reviews`" class="secondary-button">{{ copy.detail.allReviews }}</RouterLink>
          <RouterLink to="/user/reviews" class="secondary-button">{{ copy.detail.myReviews }}</RouterLink>
          <button type="button" class="secondary-button" :disabled="favoriteLoading" @click="toggleFavorite">
            {{ favorited ? copy.detail.removeFavorite : copy.detail.saveFavorite }}
          </button>
          <button type="button" class="secondary-button" data-testid="share-shop" @click="shareShop">{{ copy.detail.share }}</button>
          <RouterLink :to="`/shops/${shop.id}/reserve`" class="secondary-button">{{ copy.detail.booking }}</RouterLink>
        </div>
        <p v-if="shareMessage" class="feedback" role="status">{{ shareMessage }}</p>
      </div>
    </section>

    <section class="detail-grid">
      <article class="detail-card">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.detail.basicEyebrow }}</p>
            <h2>{{ copy.detail.basicTitle }}</h2>
          </div>
        </div>
        <dl class="detail-list">
          <div>
            <dt>{{ copy.detail.address }}</dt>
            <dd>{{ shop.address }}</dd>
          </div>
          <div>
            <dt>{{ copy.detail.phone }}</dt>
            <dd>{{ shop.phone }}</dd>
          </div>
          <div>
            <dt>{{ copy.detail.hours }}</dt>
            <dd>{{ shop.businessHours }}</dd>
          </div>
          <div>
            <dt>{{ copy.detail.tasteEnvService }}</dt>
            <dd>{{ shop.tasteScore }} / {{ shop.envScore }} / {{ shop.serviceScore }}</dd>
          </div>
          <div>
            <dt>{{ copy.detail.offerStatus }}</dt>
            <dd>{{ shop.hasDeal ? copy.detail.currentOffer : copy.detail.noOffer }}</dd>
          </div>
        </dl>
      </article>

      <article class="detail-card">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.detail.dishesEyebrow }}</p>
            <h2>{{ copy.detail.dishesTitle }}</h2>
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
        <p v-else class="feedback">{{ copy.detail.noDishes }}</p>
      </article>
    </section>

    <section class="content-section">
      <div class="section-header"><div><p class="eyebrow">{{ copy.detail.dealsEyebrow }}</p><h2>{{ copy.detail.dealsTitle }}</h2></div></div>
      <div v-if="deals.length" class="rank-grid"><RouterLink v-for="deal in deals" :key="deal.id" :to="`/deals/${deal.id}`" class="rank-card"><img :src="deal.coverImage" :alt="deal.title"><div class="rank-card__body"><h3>{{deal.title}}</h3><strong>{{formatMoney(deal.price,deal.currency)}}</strong><span>{{ copy.detail.originalPrice }} {{formatMoney(deal.originalPrice,deal.currency)}} · {{ copy.detail.sold }} {{deal.soldCount}}</span></div></RouterLink></div>
      <p v-else class="feedback">{{ copy.detail.noDeals }}</p>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.detail.galleryEyebrow }}</p>
          <h2>{{ copy.detail.galleryTitle }}</h2>
        </div>
      </div>
      <div v-if="shop.photos.length > 0" class="photo-grid">
        <img v-for="photo in shop.photos" :key="photo.id" :src="photo.imageUrl" :alt="shop.name" />
      </div>
      <p v-else class="feedback">{{ copy.detail.galleryMissing }}</p>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.detail.previewEyebrow }}</p>
          <h2>{{ copy.detail.previewTitle }}</h2>
        </div>
        <RouterLink :to="`/shops/${shop.id}/reviews`" class="secondary-button">{{ copy.detail.previewViewAll }}</RouterLink>
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
            <span class="review-card__foot">{{ copy.detail.likes(review.likedCount) }} · {{ copy.detail.comments(review.commentCount) }} · {{ copy.detail.viewDetails }}</span>
          </article>
        </RouterLink>
      </div>
      <p v-else class="feedback">{{ copy.detail.noReviews }}</p>
    </section>

    <section v-if="similarShops.length > 0" class="content-section" data-testid="similar-shops">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.detail.nearbyEyebrow }}</p>
          <h2>{{ copy.detail.nearbyTitle }}</h2>
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
