<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { collectionStringsForRegion, localizeWebCollectionError } from '@/core/web_collection_localizations'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { fetchFavorites, removeFavorite } from '@/services/favorite'
import type { FavoriteItem } from '@/types/favorite'
import { formatMoney } from '@/lib/currency'

const { state } = useAppContext()
const copy = computed(() => collectionStringsForRegion(state.region))
const certificationCopy = computed(() => discoveryStringsForRegion(state.region).shopCard)
const items = ref<FavoriteItem[]>([])
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const filter = ref<'all' | 'shop' | 'post'>('all')

const emptyText = computed(() => {
  if (filter.value === 'post') return copy.value.favorites.emptyPost
  if (filter.value === 'shop') return copy.value.favorites.emptyShop
  return copy.value.favorites.emptyAll
})

function targetTypeParam() {
  if (filter.value === 'shop') return 1
  if (filter.value === 'post') return 2
  return undefined
}

function itemLink(item: FavoriteItem) {
  return item.targetType === 2 ? `/community/posts/${item.targetId}` : `/shops/${item.targetId}`
}

function itemActionLabel(item: FavoriteItem) {
  return item.targetType === 2 ? copy.value.favorites.viewPost : copy.value.favorites.viewShop
}

function itemMeta(item: FavoriteItem) {
  if (item.targetType === 2) {
    return copy.value.favorites.post
  }
  const parts = [
    item.target.cityName,
    item.target.areaName,
    item.target.pricePerCapita != null
      ? `${copy.value.favorites.averageSpend} ${formatMoney(item.target.pricePerCapita, item.target.currency)}`
      : '',
  ].filter(Boolean)
  return parts.join(' · ')
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    items.value = (await fetchFavorites(targetTypeParam(), 1, 50)).list
  } catch (error) {
    errorMessage.value = localizeWebCollectionError(copy.value, error, copy.value.favorites.loadFailed)
  } finally {
    loading.value = false
  }
}

async function remove(item: FavoriteItem) {
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await removeFavorite(item.targetType, item.targetId)
    items.value = items.value.filter((current) => current.id !== item.id)
    successMessage.value = item.targetType === 2 ? copy.value.favorites.postRemoved : copy.value.favorites.shopRemoved
  } catch (error) {
    errorMessage.value = localizeWebCollectionError(copy.value, error, copy.value.favorites.removeFailed)
  } finally {
    acting.value = false
  }
}

watch([() => state.region, filter], load, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.favorites.eyebrow }}</p>
        <h1>{{ copy.favorites.title }}</h1>
        <p>{{ copy.favorites.summary }}</p>
      </div>
    </div>

    <div class="filters-panel__actions rank-type-tabs" role="tablist" :aria-label="copy.favorites.filterAria">
      <button
        type="button"
        class="secondary-button"
        :class="{ active: filter === 'all' }"
        data-testid="favorite-filter-all"
        @click="filter = 'all'"
      >
        {{ copy.favorites.all }}
      </button>
      <button
        type="button"
        class="secondary-button"
        :class="{ active: filter === 'shop' }"
        data-testid="favorite-filter-shop"
        @click="filter = 'shop'"
      >
        {{ copy.favorites.shops }}
      </button>
      <button
        type="button"
        class="secondary-button"
        :class="{ active: filter === 'post' }"
        data-testid="favorite-filter-post"
        @click="filter = 'post'"
      >
        {{ copy.favorites.posts }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.favorites.loading }}</p>
    <p v-else-if="items.length === 0" class="feedback">{{ emptyText }}</p>

    <div v-else class="shop-grid">
      <article v-for="item in items" :key="item.id" class="shop-card" :data-testid="`favorite-item-${item.id}`">
        <img
          v-if="item.target.coverUrl"
          :src="item.target.coverUrl"
          :alt="item.target.name"
          class="shop-card__cover"
        />
        <div v-else class="shop-card__cover shop-card__cover--empty" aria-hidden="true" />
        <div class="shop-card__body">
          <div class="shop-card__heading">
            <RouterLink :to="itemLink(item)" class="name-with-badge">
              <h3>{{ item.target.name }}</h3>
              <span v-if="item.target.merchantCertification" class="verified-badge verified-badge--compact">
                {{ certificationCopy.certificationLabel(item.target.merchantCertification.code, item.target.merchantCertification.label) }}
              </span>
            </RouterLink>
            <span v-if="item.targetType === 1" class="shop-card__score">
              {{ Number(item.target.score || 0).toFixed(1) }}
            </span>
            <span v-else class="status-pill is-deal">{{ copy.favorites.post }}</span>
          </div>
          <p>{{ itemMeta(item) }}</p>
          <p v-if="item.target.address">{{ item.target.address }}</p>
          <p class="muted">{{ copy.favorites.savedAt }} {{ formatWebDateTime(item.createdAt, copy.tag) }}</p>
          <div class="hero-actions">
            <RouterLink :to="itemLink(item)" class="primary-link">{{ itemActionLabel(item) }}</RouterLink>
            <button type="button" class="secondary-button" :disabled="acting" @click="remove(item)">
              {{ copy.favorites.remove }}
            </button>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.rank-type-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 18px;
}

.rank-type-tabs .secondary-button.active {
  border-color: #f97316;
  color: #c2410c;
  background: rgba(249, 115, 22, 0.08);
}

.shop-card__cover--empty {
  min-height: 140px;
  background: linear-gradient(135deg, #f8fafc, #e2e8f0);
}
</style>
