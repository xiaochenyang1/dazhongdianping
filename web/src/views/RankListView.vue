<script setup lang="ts">
import { ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { fetchRanks } from '@/services/rank'
import type { RankSummary } from '@/types/rank'

const { state } = useAppContext()
const ranks = ref<RankSummary[]>([])
const loading = ref(false)
const errorMessage = ref('')
const activeType = ref<number | undefined>()

async function loadRanks() {
  loading.value = true
  errorMessage.value = ''
  try {
    ranks.value = await fetchRanks({ cityId: state.cityId, type: activeType.value })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '榜单加载失败'
  } finally {
    loading.value = false
  }
}

function selectType(type?: number) {
  activeType.value = type
  void loadRanks()
}

watch(() => [state.region, state.cityId], loadRanks, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">城市榜单</p>
        <h1>榜单看的是发布快照，不拿实时 SQL 临场发挥。</h1>
        <p>当前区域 {{ state.region }}，每一份排名都能追到规则版本和榜单周期。</p>
      </div>
    </div>

    <div class="filters-panel__actions rank-type-tabs">
      <button type="button" :class="activeType == null ? 'primary-button' : 'secondary-button'" @click="selectType()">全部</button>
      <button v-for="item in [{ id: 1, name: '必吃榜' }, { id: 2, name: '好评榜' }, { id: 3, name: '热门榜' }]" :key="item.id" type="button" :class="activeType === item.id ? 'primary-button' : 'secondary-button'" @click="selectType(item.id)">
        {{ item.name }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">榜单快照加载中...</p>
    <p v-else-if="ranks.length === 0" class="feedback">当前城市还没有已发布榜单。</p>

    <div class="rank-grid">
      <RouterLink v-for="rank in ranks" :key="rank.id" :to="`/ranks/${rank.id}`" class="rank-card">
        <img :src="rank.coverUrl" :alt="rank.name" />
        <div class="rank-card__body">
          <div class="shop-card__heading">
            <h2>{{ rank.name }}</h2>
            <span class="status-pill is-deal">{{ rank.typeText }}</span>
          </div>
          <p>{{ rank.cityName }} · {{ rank.categoryName }} · {{ rank.period }}</p>
          <strong>榜首：{{ rank.topShopName }}</strong>
          <span>共 {{ rank.itemCount }} 家 · {{ rank.updatedAt }} 更新</span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>
