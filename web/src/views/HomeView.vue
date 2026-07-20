<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { fetchCategories, fetchCities, fetchHomeBanners, fetchHomeFeed } from '@/services/browse'
import type { Banner, CategoryNode, City, HomeFeedItem } from '@/types/browse'

const { state, setCityId } = useAppContext()

const loading = ref(false)
const errorMessage = ref('')
const categories = ref<CategoryNode[]>([])
const cities = ref<City[]>([])
const banners = ref<Banner[]>([])
const feed = ref<HomeFeedItem[]>([])

const activeCity = computed(() => cities.value.find((item) => item.id === state.cityId))

async function bootstrapHome() {
  loading.value = true
  errorMessage.value = ''

  try {
    const [nextCategories, nextCities] = await Promise.all([fetchCategories(), fetchCities()])
    categories.value = nextCategories
    cities.value = nextCities

    const resolvedCityId =
      state.cityId && nextCities.some((item) => item.id === state.cityId)
        ? state.cityId
        : nextCities[0]?.id

    if (resolvedCityId !== state.cityId) {
      setCityId(resolvedCityId)
      return
    }

    await loadHomeContent()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '首页加载失败'
  } finally {
    loading.value = false
  }
}

async function loadHomeContent() {
  if (!state.cityId) {
    return
  }
  try {
    ;[banners.value, feed.value] = await Promise.all([
      fetchHomeBanners(state.cityId),
      fetchHomeFeed(state.cityId, 6),
    ])
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '首页内容加载失败'
  }
}

watch(
  () => state.region,
  () => {
    void bootstrapHome()
  },
  { immediate: true },
)

watch(
  () => state.cityId,
  (cityId, previousCityId) => {
    if (cityId && cityId !== previousCityId) {
      void loadHomeContent()
    }
  },
)
</script>

<template>
  <section class="hero-panel">
    <div class="hero-panel__content">
      <p class="eyebrow">M1 骨架已接后端公开浏览接口</p>
      <h1>先把首页、列表、详情跑通，别上来就做一锅大乱炖。</h1>
      <p class="hero-panel__summary">
        当前区域：
        <strong>{{ state.region }}</strong>
        <span v-if="activeCity"> · 当前城市：{{ activeCity.name }}</span>
      </p>
      <div class="hero-panel__actions">
        <RouterLink to="/shops" class="primary-link">去看商户列表</RouterLink>
        <label class="city-picker">
          <span>切换城市</span>
          <select :value="state.cityId" @change="setCityId(Number(($event.target as HTMLSelectElement).value))">
            <option v-for="city in cities" :key="city.id" :value="city.id">
              {{ city.name }}
            </option>
          </select>
        </label>
      </div>
    </div>
    <div class="hero-panel__side">
      <div class="hero-metric">
        <span>区域头</span>
        <strong>X-Region = {{ state.region }}</strong>
      </div>
      <div class="hero-metric">
        <span>首页状态</span>
        <strong>{{ loading ? '加载中' : '可浏览' }}</strong>
      </div>
    </div>
  </section>

  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

  <section class="content-section">
    <div class="section-header">
      <div>
        <p class="eyebrow">首页 Banner</p>
        <h2>运营位先接实数据，不搞假按钮糊人。</h2>
      </div>
    </div>
    <div class="banner-grid">
      <article v-for="item in banners" :key="item.id" class="banner-card">
        <img :src="item.imageUrl" :alt="item.title" class="banner-card__image" />
        <div class="banner-card__body">
          <h3>{{ item.title }}</h3>
          <p>{{ item.subtitle }}</p>
          <RouterLink class="banner-card__link" :to="item.linkUrl">查看落点</RouterLink>
        </div>
      </article>
    </div>
  </section>

  <section class="content-section">
    <div class="section-header">
      <div>
        <p class="eyebrow">分类导航</p>
        <h2>分类树已经按区域从后端拿回来了。</h2>
      </div>
    </div>
    <div class="category-board">
      <article v-for="category in categories" :key="category.id" class="category-card">
        <h3>{{ category.name }}</h3>
        <div class="category-card__children">
          <span v-for="child in category.children" :key="child.id">{{ child.name }}</span>
        </div>
      </article>
    </div>
  </section>

  <section class="content-section">
    <div class="section-header">
      <div>
        <p class="eyebrow">推荐 Feed</p>
        <h2>这个列表已经和后端示例数据通了，后面再慢慢换真运营配置。</h2>
      </div>
      <RouterLink to="/shops" class="text-link">去列表页看更多</RouterLink>
    </div>
    <div class="feed-grid">
      <article v-for="item in feed" :key="item.id" class="feed-card">
        <img :src="item.coverUrl" :alt="item.title" class="feed-card__image" />
        <div class="feed-card__body">
          <p class="feed-card__type">{{ item.type }}</p>
          <h3>{{ item.title }}</h3>
          <p>{{ item.subtitle }}</p>
          <RouterLink v-if="item.shopId" :to="`/shops/${item.shopId}`" class="text-link">查看详情</RouterLink>
        </div>
      </article>
    </div>
  </section>
</template>
