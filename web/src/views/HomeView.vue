<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import {
  discoveryStringsForRegion,
  localizeWebDiscoveryError,
} from '@/core/web_discovery_localizations'
import { fetchActivities } from '@/services/activity'
import { fetchCategories, fetchCities, fetchHomeBanners, fetchHomeFeed } from '@/services/browse'
import type { ActivitySummary } from '@/types/activity'
import type { Banner, CategoryNode, City, HomeFeedItem } from '@/types/browse'

const { state, setCityId } = useAppContext()

const loading = ref(false)
const errorMessage = ref('')
const categories = ref<CategoryNode[]>([])
const cities = ref<City[]>([])
const banners = ref<Banner[]>([])
const feed = ref<HomeFeedItem[]>([])
const activities = ref<ActivitySummary[]>([])

const copy = computed(() => discoveryStringsForRegion(state.region))
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
    errorMessage.value = localizeWebDiscoveryError(copy.value, error, copy.value.home.loadFailed)
  } finally {
    loading.value = false
  }
}

async function loadHomeContent() {
  if (!state.cityId) {
    return
  }
  try {
    ;[banners.value, feed.value, activities.value] = await Promise.all([
      fetchHomeBanners(state.cityId),
      fetchHomeFeed(state.cityId, 6),
      fetchActivities({ cityId: state.cityId, limit: 4 }),
    ])
  } catch (error) {
    errorMessage.value = localizeWebDiscoveryError(copy.value, error, copy.value.home.contentLoadFailed)
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
      <p class="eyebrow">{{ copy.home.heroEyebrow }}</p>
      <h1>{{ copy.home.heroTitle }}</h1>
      <p class="hero-panel__summary">
        {{ copy.home.currentRegion }}:
        <strong>{{ state.region }}</strong>
        <span v-if="activeCity"> · {{ copy.home.currentCity }}: {{ activeCity.name }}</span>
      </p>
      <div class="hero-panel__actions">
        <RouterLink to="/shops" class="primary-link">{{ copy.home.browsePlaces }}</RouterLink>
        <label class="city-picker">
          <span>{{ copy.home.switchCity }}</span>
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
        <span>{{ copy.home.regionHeader }}</span>
        <strong>X-Region = {{ state.region }}</strong>
      </div>
      <div class="hero-metric">
        <span>{{ copy.home.pageStatus }}</span>
        <strong>{{ loading ? copy.home.loading : copy.home.browsable }}</strong>
      </div>
    </div>
  </section>

  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

  <section class="content-section">
    <div class="section-header">
      <div>
        <p class="eyebrow">{{ copy.home.bannersEyebrow }}</p>
        <h2>{{ copy.home.bannersTitle }}</h2>
      </div>
    </div>
    <div class="banner-grid">
      <article v-for="item in banners" :key="item.id" class="banner-card">
        <img :src="item.imageUrl" :alt="item.title" class="banner-card__image" />
        <div class="banner-card__body">
          <h3>{{ item.title }}</h3>
          <p>{{ item.subtitle }}</p>
          <RouterLink class="banner-card__link" :to="item.linkUrl">{{ copy.home.viewDestination }}</RouterLink>
        </div>
      </article>
    </div>
  </section>

  <section v-if="activities.length > 0" class="content-section">
    <div class="section-header">
      <div>
        <p class="eyebrow">{{ copy.home.activitiesEyebrow }}</p>
        <h2>{{ copy.home.activitiesTitle }}</h2>
      </div>
      <RouterLink to="/activities" class="text-link">{{ copy.home.viewAllActivities }}</RouterLink>
    </div>
    <div class="activity-grid">
      <RouterLink
        v-for="item in activities"
        :key="item.id"
        :to="`/activities/${item.id}`"
        class="activity-card"
      >
        <img :src="item.cover" :alt="item.name" />
        <div class="activity-card__body">
          <div class="shop-card__heading">
            <h3>{{ item.name }}</h3>
            <span class="status-pill is-deal">{{ copy.home.activityType(item.type, item.typeText) }}</span>
          </div>
          <p>{{ item.cityName }} · {{ copy.home.activityChannel(item.channel, item.channelText) }} · {{ copy.home.resourceCount(item.itemCount) }}</p>
        </div>
      </RouterLink>
    </div>
  </section>

  <section class="content-section">
    <div class="section-header">
      <div>
        <p class="eyebrow">{{ copy.home.categoriesEyebrow }}</p>
        <h2>{{ copy.home.categoriesTitle }}</h2>
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
        <p class="eyebrow">{{ copy.home.feedEyebrow }}</p>
        <h2>{{ copy.home.feedTitle }}</h2>
      </div>
      <RouterLink to="/shops" class="text-link">{{ copy.home.viewMorePlaces }}</RouterLink>
    </div>
    <div class="feed-grid">
      <article v-for="item in feed" :key="item.id" class="feed-card">
        <img :src="item.coverUrl" :alt="item.title" class="feed-card__image" />
        <div class="feed-card__body">
          <p class="feed-card__type">{{ item.type }}</p>
          <h3>{{ item.title }}</h3>
          <p>{{ item.subtitle }}</p>
          <RouterLink v-if="item.shopId" :to="`/shops/${item.shopId}`" class="text-link">{{ copy.home.viewDetails }}</RouterLink>
        </div>
      </article>
    </div>
  </section>
</template>
