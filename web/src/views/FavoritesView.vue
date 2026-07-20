<script setup lang="ts">
import { ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { fetchFavorites, removeFavorite } from '@/services/favorite'
import type { FavoriteItem } from '@/types/favorite'
import { formatMoney } from '@/lib/currency'

const { state } = useAppContext()
const items = ref<FavoriteItem[]>([])
const loading = ref(false)
const errorMessage = ref('')

async function load() {
  loading.value = true
  try { items.value = (await fetchFavorites(1, 1, 50)).list }
  catch (error) { errorMessage.value = error instanceof Error ? error.message : '收藏加载失败' }
  finally { loading.value = false }
}

async function remove(item: FavoriteItem) {
  await removeFavorite(item.targetType, item.targetId)
  items.value = items.value.filter((current) => current.id !== item.id)
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header"><div><p class="eyebrow">我的收藏</p><h1>真喜欢的店留在这儿，别靠浏览器历史碰运气。</h1><p>收藏按当前区域隔离，切区不会把另一边的店硬塞进来。</p></div></div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">收藏加载中...</p>
    <p v-else-if="items.length === 0" class="feedback">当前区域还没有收藏门店。</p>
    <div class="shop-grid">
      <article v-for="item in items" :key="item.id" class="shop-card">
        <img :src="item.target.coverUrl" :alt="item.target.name" class="shop-card__cover" />
        <div class="shop-card__body">
          <div class="shop-card__heading"><RouterLink :to="`/shops/${item.targetId}`"><h3>{{ item.target.name }}</h3></RouterLink><span class="shop-card__score">{{ item.target.score.toFixed(1) }}</span></div>
          <p>{{ item.target.cityName }} · {{ item.target.areaName }} · 人均 {{ formatMoney(item.target.pricePerCapita, item.target.currency) }}</p>
          <p>{{ item.target.address }}</p>
          <div class="hero-actions"><RouterLink :to="`/shops/${item.targetId}`" class="primary-link">查看门店</RouterLink><button type="button" class="secondary-button" @click="remove(item)">取消收藏</button></div>
        </div>
      </article>
    </div>
  </section>
</template>
