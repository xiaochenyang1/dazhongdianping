<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { formatMoney } from '@/lib/currency'
import { fetchRankDetail } from '@/services/rank'
import type { RankDetail } from '@/types/rank'

const props = defineProps<{ rankId: number }>()
const rank = ref<RankDetail | null>(null)
const loading = ref(true)
const errorMessage = ref('')

onMounted(async () => {
  try {
    rank.value = await fetchRankDetail(props.rankId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '榜单详情加载失败'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section class="page-section">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">榜单详情加载中...</p>
    <template v-else-if="rank">
      <div class="page-header">
        <div>
          <p class="eyebrow">{{ rank.typeText }} · {{ rank.period }}</p>
          <h1>{{ rank.name }}</h1>
          <p>{{ rank.cityName }} · {{ rank.categoryName }} · {{ rank.updatedAt }} 更新</p>
        </div>
        <RouterLink to="/ranks" class="secondary-button">返回榜单</RouterLink>
      </div>

      <div class="rank-list">
        <article v-for="item in rank.items" :key="item.shop.id" class="content-card rank-item">
          <div class="rank-position">{{ item.position }}</div>
          <img :src="item.shop.coverUrl" :alt="item.shop.name" />
          <div class="rank-item__body">
            <div class="shop-card__heading">
              <RouterLink :to="`/shops/${item.shop.id}`"><h2>{{ item.shop.name }}</h2></RouterLink>
              <span class="shop-card__score">{{ item.shop.score.toFixed(1) }}</span>
            </div>
            <p>{{ item.shop.cityName }} · {{ item.shop.areaName }} · 人均 {{ formatMoney(item.shop.pricePerCapita, item.shop.currency) }}</p>
            <p>{{ item.reason }}</p>
            <div class="shop-card__tags"><span v-for="tag in item.shop.tags" :key="tag">{{ tag }}</span></div>
          </div>
          <strong class="rank-score">{{ item.rankScore.toFixed(2) }}</strong>
        </article>
      </div>
    </template>
  </section>
</template>
