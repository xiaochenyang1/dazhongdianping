<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useRoute } from 'vue-router'
import ShopCard from '@/components/ShopCard.vue'
import { useAppContext } from '@/composables/useAppContext'
import { fetchAreas, fetchCategories, fetchCities, fetchShops } from '@/services/browse'
import type { Area, CategoryNode, City, ShopListItem } from '@/types/browse'

const { state, setCityId } = useAppContext()
const route = useRoute()

const loading = ref(false)
const errorMessage = ref('')
const categories = ref<CategoryNode[]>([])
const cities = ref<City[]>([])
const areas = ref<Area[]>([])
const shops = ref<ShopListItem[]>([])
const shopTotal = ref(0)
const shopHasMore = ref(false)
const userLocation = ref<{ lat: number; lng: number } | null>(null)

const filters = reactive({
  keyword: routeKeyword(),
  categoryId: undefined as number | undefined,
  cityId: state.cityId as number | undefined,
  areaId: undefined as number | undefined,
  sort: 'smart',
})

const sortLabelMap = {
  smart: '智能排序',
  score: '评分优先',
  popular: '热门优先',
  distance: '距离优先',
} as const

const activeCityName = computed(() => cities.value.find((item) => item.id === filters.cityId)?.name ?? '未选城市')
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
  const tags = [`区域 ${state.region}`, activeCityName.value]

  if (filters.keyword.trim()) {
    tags.push(`关键词 ${filters.keyword.trim()}`)
  }

  if (activeCategoryName.value) {
    tags.push(activeCategoryName.value)
  }

  if (activeAreaName.value) {
    tags.push(activeAreaName.value)
  }

  if (filters.sort !== 'smart') {
    tags.push(sortLabelMap[filters.sort as keyof typeof sortLabelMap])
  }

  return tags
})

const resultFacts = computed(() => [
  {
    label: '当前命中',
    value: loading.value ? '加载中' : String(shopTotal.value),
    detail:
      shopTotal.value > shops.value.length
        ? `当前只先摊开 ${shops.value.length} 家，别一口气把列表灌满。`
        : `这轮返回的 ${shops.value.length} 家门店已经全部展示完。`,
  },
  {
    label: '当前城市',
    value: activeCityName.value,
    detail: activeAreaName.value ? `当前已经收进 ${activeAreaName.value} 商圈。` : '当前先按整座城市控制搜索范围。',
  },
  {
    label: '筛选状态',
    value: filters.sort === 'smart' && activeFilterTags.value.length <= 2 ? '默认浏览' : `${activeFilterTags.value.length} 条上下文`,
    detail: shopHasMore.value ? '后端还有更多结果，继续细筛会更利索。' : '当前结果已经收口，再换条件看更直接。',
  },
])

function routeKeyword() {
  return typeof route.query.keyword === 'string' ? route.query.keyword.trim() : ''
}

async function bootstrapPage() {
  loading.value = true
  errorMessage.value = ''
  filters.keyword = routeKeyword()

  try {
    const [nextCategories, nextCities] = await Promise.all([fetchCategories(), fetchCities()])
    categories.value = nextCategories
    cities.value = nextCities

    const resolvedCityId =
      filters.cityId && nextCities.some((item) => item.id === filters.cityId)
        ? filters.cityId
        : nextCities[0]?.id

    filters.cityId = resolvedCityId
    setCityId(resolvedCityId)

    await loadAreas()
    await loadShops()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '商户列表加载失败'
  } finally {
    loading.value = false
  }
}

async function loadAreas() {
  if (!filters.cityId) {
    areas.value = []
    return
  }
  areas.value = await fetchAreas(filters.cityId)
}

async function loadShops() {
  loading.value = true
  errorMessage.value = ''
  try {
    if (filters.sort === 'distance' && !userLocation.value) {
      userLocation.value = await resolveUserLocation()
    }
    const page = await fetchShops({
      keyword: filters.keyword || undefined,
      categoryId: filters.categoryId,
      cityId: filters.cityId,
      areaId: filters.areaId,
      sort: filters.sort,
      lat: filters.sort === 'distance' ? userLocation.value?.lat : undefined,
      lng: filters.sort === 'distance' ? userLocation.value?.lng : undefined,
      page: 1,
      pageSize: 12,
    })
    shops.value = page.list
    shopTotal.value = page.total
    shopHasMore.value = page.hasMore
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '商户列表加载失败'
  } finally {
    loading.value = false
  }
}

function resolveUserLocation() {
  return new Promise<{ lat: number; lng: number }>((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('当前浏览器不支持定位，无法按距离排序。'))
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => resolve({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      }),
      () => reject(new Error('定位未授权或获取失败，无法按距离排序。')),
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 },
    )
  })
}

function onCityChange(value: string) {
  filters.cityId = Number(value)
  filters.areaId = undefined
  setCityId(filters.cityId)
  void loadAreas().then(() => loadShops())
}

function resetFilters() {
  filters.keyword = ''
  filters.categoryId = undefined
  filters.areaId = undefined
  filters.sort = 'smart'
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
          <p class="eyebrow">筛选区</p>
          <h2>先把最小可用的列表过滤闭环跑通。</h2>
        </div>
      </div>

      <p class="support-copy">
        当前会话会带着 <strong>{{ state.region }}</strong> 区域和
        <strong>{{ activeCityName }}</strong> 城市一起筛，先把串区这种低级错误堵死。
      </p>

      <div class="tag-row">
        <span v-for="tag in activeFilterTags" :key="tag">{{ tag }}</span>
      </div>

      <label class="field">
        <span>关键词</span>
        <input v-model="filters.keyword" type="text" placeholder="店名、标签、地址" />
      </label>

      <label class="field">
        <span>城市</span>
        <select :value="filters.cityId" @change="onCityChange(($event.target as HTMLSelectElement).value)">
          <option v-for="city in cities" :key="city.id" :value="city.id">
            {{ city.name }}
          </option>
        </select>
      </label>

      <label class="field">
        <span>商圈</span>
        <select v-model="filters.areaId">
          <option :value="undefined">全部商圈</option>
          <option v-for="area in areas" :key="area.id" :value="area.id">
            {{ area.name }}
          </option>
        </select>
      </label>

      <label class="field">
        <span>一级分类</span>
        <select v-model="filters.categoryId">
          <option :value="undefined">全部分类</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>
      </label>

      <label class="field">
        <span>排序</span>
        <select v-model="filters.sort">
          <option value="smart">智能排序</option>
          <option value="score">评分优先</option>
          <option value="popular">热门优先</option>
          <option value="distance">距离优先</option>
        </select>
      </label>

      <div class="filters-panel__actions">
        <button type="button" class="primary-button" @click="loadShops">应用筛选</button>
        <button type="button" class="secondary-button" @click="resetFilters">重置</button>
      </div>
    </aside>

    <div class="list-results">
      <div class="section-header">
        <div>
          <p class="eyebrow">商户列表</p>
          <h2>当前区域 {{ state.region }}，先把可浏览链路做扎实。</h2>
          <p class="support-copy">
            头部搜索、列表筛选和区域切换现在共用同一套查询上下文，不再让结果一会儿东一会儿西。
          </p>
        </div>
        <RouterLink to="/" class="text-link">返回首页</RouterLink>
      </div>

      <div class="detail-hero__stats">
        <div v-for="fact in resultFacts" :key="fact.label">
          <span>{{ fact.label }}</span>
          <strong>{{ fact.value }}</strong>
          <p class="support-copy">{{ fact.detail }}</p>
        </div>
      </div>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
      <p v-else-if="loading" class="feedback">正在拉取商户列表...</p>
      <p v-else-if="shops.length === 0" class="feedback">当前筛选下没有数据，先别怀疑人生，改个条件试试。</p>

      <div class="shop-grid">
        <RouterLink v-for="shop in shops" :key="shop.id" :to="`/shops/${shop.id}`" class="shop-grid__link">
          <ShopCard :shop="shop" />
        </RouterLink>
      </div>
    </div>
  </section>
</template>
