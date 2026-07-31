<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useRoute } from 'vue-router'
import ShopCard from '@/components/ShopCard.vue'
import { useAppContext } from '@/composables/useAppContext'
import {
  discoveryStringsForRegion,
  localizeWebDiscoveryError,
} from '@/core/web_discovery_localizations'
import { fetchAreas, fetchCategories, fetchCities, fetchShops } from '@/services/browse'
import type { Area, CategoryNode, City, ShopListItem } from '@/types/browse'

const { state, setCityId } = useAppContext()
const route = useRoute()

const loading = ref(false)
const loadingMore = ref(false)
const errorMessage = ref('')
const loadMoreErrorMessage = ref('')
const categories = ref<CategoryNode[]>([])
const cities = ref<City[]>([])
const areas = ref<Area[]>([])
const shops = ref<ShopListItem[]>([])
const shopTotal = ref(0)
const shopHasMore = ref(false)
const shopPage = ref(1)
const userLocation = ref<{ lat: number; lng: number } | null>(null)
let bootstrapRequestId = 0
let areaRequestId = 0
let shopRequestId = 0
let cityChangeRequestId = 0
const copy = computed(() => discoveryStringsForRegion(state.region))

const filters = reactive({
  keyword: routeKeyword(),
  categoryId: undefined as number | undefined,
  cityId: state.cityId as number | undefined,
  areaId: undefined as number | undefined,
  sort: 'smart',
  minPrice: '',
  maxPrice: '',
  minScore: '',
  hasDeal: '',
  openNow: '',
})

const activeCityName = computed(() => cities.value.find((item) => item.id === filters.cityId)?.name ?? copy.value.shopList.unselectedCity)
const activeAreaName = computed(() => areas.value.find((item) => item.id === filters.areaId)?.name ?? '')
const activeCategoryName = computed(() => {
  if (!filters.categoryId) {
    return ''
  }

  for (const group of categories.value) {
    if (group.id === filters.categoryId) {
      return group.name
    }

    const child = group.children.find((item) => item.id === filters.categoryId)
    if (child) {
      return `${group.name} / ${child.name}`
    }
  }

  return ''
})

const activeFilterTags = computed(() => {
  const strings = copy.value.shopList
  const tags = [strings.regionTag(state.region), activeCityName.value]

  if (filters.keyword.trim()) {
    tags.push(strings.keywordTag(filters.keyword.trim()))
  }

  if (activeCategoryName.value) {
    tags.push(activeCategoryName.value)
  }

  if (activeAreaName.value) {
    tags.push(activeAreaName.value)
  }

  if (filters.sort !== 'smart') {
    tags.push(strings.sorts[filters.sort as keyof typeof strings.sorts])
  }

  if (filters.minPrice || filters.maxPrice) {
    tags.push(strings.priceTag(filters.minPrice || strings.any, filters.maxPrice || strings.any))
  }
  if (filters.minScore) tags.push(strings.scoreTag(filters.minScore))
  if (filters.hasDeal === 'true') tags.push(strings.hasDealTag)
  if (filters.hasDeal === 'false') tags.push(strings.noDealTag)
  if (filters.openNow === 'true') tags.push(strings.openTag)
  if (filters.openNow === 'false') tags.push(strings.closedTag)

  return tags
})

const resultFacts = computed(() => [
  {
    label: copy.value.shopList.factMatches,
    value: loading.value ? copy.value.shopList.loading : String(shopTotal.value),
    detail:
      shopTotal.value > shops.value.length
        ? copy.value.shopList.partialResults(shops.value.length)
        : copy.value.shopList.allResults(shops.value.length),
  },
  {
    label: copy.value.shopList.factCity,
    value: activeCityName.value,
    detail: activeAreaName.value ? copy.value.shopList.areaScope(activeAreaName.value) : copy.value.shopList.cityScope,
  },
  {
    label: copy.value.shopList.factFilters,
    value: filters.sort === 'smart' && activeFilterTags.value.length <= 2
      ? copy.value.shopList.defaultBrowse
      : copy.value.shopList.contextCount(activeFilterTags.value.length),
    detail: shopHasMore.value ? copy.value.shopList.moreResults : copy.value.shopList.resultsComplete,
  },
])

function routeKeyword() {
  return typeof route.query.keyword === 'string' ? route.query.keyword.trim() : ''
}

async function bootstrapPage() {
  const requestId = ++bootstrapRequestId
  ++areaRequestId
  ++shopRequestId
  ++cityChangeRequestId
  loading.value = true
  loadingMore.value = false
  errorMessage.value = ''
  loadMoreErrorMessage.value = ''
  categories.value = []
  cities.value = []
  areas.value = []
  shops.value = []
  shopTotal.value = 0
  shopHasMore.value = false
  shopPage.value = 1
  filters.keyword = routeKeyword()

  try {
    const [nextCategories, nextCities] = await Promise.all([fetchCategories(), fetchCities()])
    if (requestId !== bootstrapRequestId) return
    categories.value = nextCategories
    cities.value = nextCities

    const resolvedCityId =
      filters.cityId && nextCities.some((item) => item.id === filters.cityId)
        ? filters.cityId
        : nextCities[0]?.id

    filters.cityId = resolvedCityId
    setCityId(resolvedCityId)

    const areasLoaded = await loadAreas()
    if (requestId !== bootstrapRequestId || !areasLoaded) return
    await loadShops()
  } catch (error) {
    if (requestId === bootstrapRequestId) {
      errorMessage.value = localizeWebDiscoveryError(copy.value, error, copy.value.shopList.loadFailed)
    }
  } finally {
    if (requestId === bootstrapRequestId) loading.value = false
  }
}

async function loadAreas() {
  const requestId = ++areaRequestId
  const cityId = filters.cityId
  areas.value = []
  if (!cityId) return true

  try {
    const nextAreas = await fetchAreas(cityId)
    if (requestId !== areaRequestId || filters.cityId !== cityId) return false
    areas.value = nextAreas
    return true
  } catch (error) {
    if (requestId !== areaRequestId) return false
    throw error
  }
}

async function loadShops(append = false) {
  if (append && (!shopHasMore.value || loadingMore.value)) return
  const requestId = ++shopRequestId
  const targetPage = append ? shopPage.value + 1 : 1
  const requestFilters = { ...filters }
  if (append) {
    loadingMore.value = true
    loadMoreErrorMessage.value = ''
  } else {
    loading.value = true
    loadingMore.value = false
    errorMessage.value = ''
    loadMoreErrorMessage.value = ''
    shops.value = []
    shopTotal.value = 0
    shopHasMore.value = false
    shopPage.value = 1
  }
  try {
    let location = userLocation.value
    if (requestFilters.sort === 'distance' && !location) {
      location = await resolveUserLocation()
      if (requestId !== shopRequestId) return
      userLocation.value = location
    }
    const page = await fetchShops({
      keyword: requestFilters.keyword || undefined,
      categoryId: requestFilters.categoryId,
      cityId: requestFilters.cityId,
      areaId: requestFilters.areaId,
      sort: requestFilters.sort,
      lat: requestFilters.sort === 'distance' ? location?.lat : undefined,
      lng: requestFilters.sort === 'distance' ? location?.lng : undefined,
      minPrice: optionalNumber(requestFilters.minPrice),
      maxPrice: optionalNumber(requestFilters.maxPrice),
      minScore: optionalNumber(requestFilters.minScore),
      hasDeal: optionalBoolean(requestFilters.hasDeal),
      openNow: optionalBoolean(requestFilters.openNow),
      page: targetPage,
      pageSize: 12,
    })
    if (requestId !== shopRequestId) return
    shops.value = append ? [...shops.value, ...page.list] : page.list
    shopTotal.value = page.total
    shopPage.value = page.page
    shopHasMore.value = page.hasMore
  } catch (error) {
    if (requestId !== shopRequestId) return
    const message = localizeWebDiscoveryError(copy.value, error, copy.value.shopList.loadFailed)
    if (append) loadMoreErrorMessage.value = message
    else errorMessage.value = message
  } finally {
    if (requestId === shopRequestId) {
      if (append) loadingMore.value = false
      else loading.value = false
    }
  }
}

function optionalNumber(value: string | number) {
  if (value === '' || value === null || value === undefined) return undefined
  const parsed = typeof value === 'number' ? value : Number(value.trim())
  return Number.isFinite(parsed) ? parsed : undefined
}

function optionalBoolean(value: string) {
  if (value === 'true') return true
  if (value === 'false') return false
  return undefined
}

function resolveUserLocation() {
  return new Promise<{ lat: number; lng: number }>((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error(copy.value.shopList.geolocationUnsupported))
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => resolve({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      }),
      () => reject(new Error(copy.value.shopList.geolocationFailed)),
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 },
    )
  })
}

async function onCityChange(value: string) {
  const requestId = ++cityChangeRequestId
  filters.cityId = Number(value)
  filters.areaId = undefined
  setCityId(filters.cityId)
  ++shopRequestId
  loading.value = true
  loadingMore.value = false
  errorMessage.value = ''
  loadMoreErrorMessage.value = ''
  shops.value = []
  shopTotal.value = 0
  shopHasMore.value = false
  shopPage.value = 1
  try {
    if (await loadAreas()) await loadShops()
  } catch (error) {
    if (requestId === cityChangeRequestId) {
      errorMessage.value = localizeWebDiscoveryError(copy.value, error, copy.value.shopList.areasLoadFailed)
    }
  } finally {
    if (requestId === cityChangeRequestId) loading.value = false
  }
}

function resetFilters() {
  filters.keyword = ''
  filters.categoryId = undefined
  filters.areaId = undefined
  filters.sort = 'smart'
  filters.minPrice = ''
  filters.maxPrice = ''
  filters.minScore = ''
  filters.hasDeal = ''
  filters.openNow = ''
  void loadShops()
}

watch(
  () => state.region,
  () => {
    filters.cityId = undefined
    filters.areaId = undefined
    void bootstrapPage()
  },
  { immediate: true },
)

watch(
  () => route.query.keyword,
  () => {
    const nextKeyword = routeKeyword()
    if (filters.keyword === nextKeyword) {
      return
    }
    filters.keyword = nextKeyword
    void loadShops()
  },
)
</script>

<template>
  <section class="list-page">
    <aside class="filters-panel">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.shopList.filtersEyebrow }}</p>
          <h2>{{ copy.shopList.filtersTitle }}</h2>
        </div>
      </div>

      <p class="support-copy">{{ copy.shopList.filtersSupport(state.region, activeCityName) }}</p>

      <div class="tag-row">
        <span v-for="tag in activeFilterTags" :key="tag">{{ tag }}</span>
      </div>

      <label class="field">
        <span>{{ copy.shopList.keywordLabel }}</span>
        <input v-model="filters.keyword" type="text" :placeholder="copy.shopList.keywordPlaceholder" />
      </label>

      <label class="field">
        <span>{{ copy.shopList.cityLabel }}</span>
        <select :value="filters.cityId" @change="void onCityChange(($event.target as HTMLSelectElement).value)">
          <option v-for="city in cities" :key="city.id" :value="city.id">
            {{ city.name }}
          </option>
        </select>
      </label>

      <label class="field">
        <span>{{ copy.shopList.areaLabel }}</span>
        <select v-model="filters.areaId">
          <option :value="undefined">{{ copy.shopList.allAreas }}</option>
          <option v-for="area in areas" :key="area.id" :value="area.id">
            {{ area.name }}
          </option>
        </select>
      </label>

      <label class="field">
        <span>{{ copy.shopList.categoryLabel }}</span>
        <select v-model="filters.categoryId">
          <option :value="undefined">{{ copy.shopList.allCategories }}</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>
      </label>

      <label class="field">
        <span>{{ copy.shopList.sortLabel }}</span>
        <select v-model="filters.sort">
          <option v-for="(label, value) in copy.shopList.sorts" :key="value" :value="value">{{ label }}</option>
        </select>
      </label>

      <div class="filter-inline-grid">
        <label class="field">
          <span>{{ copy.shopList.minPriceLabel }}</span>
          <input v-model="filters.minPrice" data-testid="filter-min-price" type="number" min="0" step="1" :placeholder="copy.shopList.any" />
        </label>
        <label class="field">
          <span>{{ copy.shopList.maxPriceLabel }}</span>
          <input v-model="filters.maxPrice" data-testid="filter-max-price" type="number" min="0" step="1" :placeholder="copy.shopList.any" />
        </label>
      </div>

      <label class="field">
        <span>{{ copy.shopList.minScoreLabel }}</span>
        <input v-model="filters.minScore" data-testid="filter-min-score" type="number" min="0" max="5" step="0.1" :placeholder="copy.shopList.any" />
      </label>

      <label class="field">
        <span>{{ copy.shopList.dealLabel }}</span>
        <select v-model="filters.hasDeal" data-testid="filter-has-deal">
          <option value="">{{ copy.shopList.any }}</option>
          <option value="true">{{ copy.shopList.hasDeal }}</option>
          <option value="false">{{ copy.shopList.noDeal }}</option>
        </select>
      </label>

      <label class="field">
        <span>{{ copy.shopList.openStatusLabel }}</span>
        <select v-model="filters.openNow" data-testid="filter-open-now">
          <option value="">{{ copy.shopList.any }}</option>
          <option value="true">{{ copy.shopList.openNow }}</option>
          <option value="false">{{ copy.shopList.closed }}</option>
        </select>
      </label>

      <div class="filters-panel__actions">
        <button type="button" class="primary-button" @click="loadShops()">{{ copy.shopList.applyFilters }}</button>
        <button type="button" class="secondary-button" @click="resetFilters">{{ copy.shopList.reset }}</button>
      </div>
    </aside>

    <div class="list-results">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.shopList.resultsEyebrow }}</p>
          <h2>{{ copy.shopList.resultsTitle(state.region) }}</h2>
          <p class="support-copy">{{ copy.shopList.resultsSupport }}</p>
        </div>
        <RouterLink to="/" class="text-link">{{ copy.shopList.backHome }}</RouterLink>
      </div>

      <div class="detail-hero__stats">
        <div v-for="fact in resultFacts" :key="fact.label">
          <span>{{ fact.label }}</span>
          <strong>{{ fact.value }}</strong>
          <p class="support-copy">{{ fact.detail }}</p>
        </div>
      </div>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
      <p v-else-if="loading" class="feedback">{{ copy.shopList.loadingResults }}</p>
      <p v-else-if="shops.length === 0" class="feedback">{{ copy.shopList.emptyResults }}</p>

      <div class="shop-grid">
        <RouterLink v-for="shop in shops" :key="shop.id" :to="`/shops/${shop.id}`" class="shop-grid__link">
          <ShopCard :shop="shop" />
        </RouterLink>
      </div>
      <p v-if="loadMoreErrorMessage" class="feedback is-error">{{ loadMoreErrorMessage }}</p>
      <button
        v-if="shopHasMore"
        type="button"
        class="secondary-button list-load-more"
        data-testid="load-more-shops"
        :disabled="loadingMore"
        @click="loadShops(true)"
      >
        {{ loadingMore ? copy.shopList.loadingMore : copy.shopList.loadMore }}
      </button>
    </div>
  </section>
</template>
