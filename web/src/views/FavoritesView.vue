<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { fetchFavorites, removeFavorite } from '@/services/favorite'
import type { FavoriteItem } from '@/types/favorite'
import { formatMoney } from '@/lib/currency'

const { state } = useAppContext()
const items = ref<FavoriteItem[]>([])
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const filter = ref<'all' | 'shop' | 'post'>('all')

const emptyText = computed(() => {
  if (filter.value === 'post') return '当前区域还没有收藏帖子。可在 APP 收藏后回来查看。'
  if (filter.value === 'shop') return '当前区域还没有收藏门店。'
  return '当前区域还没有收藏内容。'
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
  return item.targetType === 2 ? '查看帖子' : '查看门店'
}

function itemMeta(item: FavoriteItem) {
  if (item.targetType === 2) {
    return item.targetTypeText || '帖子'
  }
  const parts = [
    item.target.cityName,
    item.target.areaName,
    item.target.pricePerCapita != null
      ? `人均 ${formatMoney(item.target.pricePerCapita, item.target.currency)}`
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
    errorMessage.value = error instanceof Error ? error.message : '收藏加载失败'
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
    successMessage.value = item.targetType === 2 ? '已取消帖子收藏' : '已取消门店收藏'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '取消收藏失败'
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
        <p class="eyebrow">我的收藏</p>
        <h1>真喜欢的店和帖子都留在这儿。</h1>
        <p>收藏按当前区域隔离；门店可在 PC 收藏，帖子可在 APP 收藏后回这里查看。</p>
      </div>
    </div>

    <div class="filters-panel__actions rank-type-tabs" role="tablist" aria-label="收藏类型">
      <button
        type="button"
        class="secondary-button"
        :class="{ active: filter === 'all' }"
        data-testid="favorite-filter-all"
        @click="filter = 'all'"
      >
        全部
      </button>
      <button
        type="button"
        class="secondary-button"
        :class="{ active: filter === 'shop' }"
        data-testid="favorite-filter-shop"
        @click="filter = 'shop'"
      >
        门店
      </button>
      <button
        type="button"
        class="secondary-button"
        :class="{ active: filter === 'post' }"
        data-testid="favorite-filter-post"
        @click="filter = 'post'"
      >
        帖子
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-else-if="loading" class="feedback">收藏加载中...</p>
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
                {{ item.target.merchantCertification.label }}
              </span>
            </RouterLink>
            <span v-if="item.targetType === 1" class="shop-card__score">
              {{ Number(item.target.score || 0).toFixed(1) }}
            </span>
            <span v-else class="status-pill is-deal">{{ item.targetTypeText || '帖子' }}</span>
          </div>
          <p>{{ itemMeta(item) }}</p>
          <p v-if="item.target.address">{{ item.target.address }}</p>
          <p class="muted">收藏于 {{ item.createdAt }}</p>
          <div class="hero-actions">
            <RouterLink :to="itemLink(item)" class="primary-link">{{ itemActionLabel(item) }}</RouterLink>
            <button type="button" class="secondary-button" :disabled="acting" @click="remove(item)">
              取消收藏
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
