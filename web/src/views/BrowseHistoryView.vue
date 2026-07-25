<script setup lang="ts">
import { ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { clearBrowseHistory, fetchBrowseHistory, removeBrowseHistoryItem } from '@/services/browse-history'
import type { ShopBrowseHistoryItem } from '@/types/browse-history'
import { formatMoney } from '@/lib/currency'

const { state } = useAppContext()
const items = ref<ShopBrowseHistoryItem[]>([])
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    items.value = (await fetchBrowseHistory(1, 50)).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '足迹加载失败'
  } finally {
    loading.value = false
  }
}

async function remove(item: ShopBrowseHistoryItem) {
  if (acting.value) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await removeBrowseHistoryItem(item.shopId)
    items.value = items.value.filter((current) => current.id !== item.id)
    successMessage.value = '已移除该足迹'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '删除失败'
  } finally {
    acting.value = false
  }
}

async function clearAll() {
  if (acting.value || items.value.length === 0) return
  const confirmed = window.confirm('确认清空当前区域的浏览足迹？')
  if (!confirmed) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await clearBrowseHistory()
    items.value = []
    successMessage.value = '足迹已清空'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '清空失败'
  } finally {
    acting.value = false
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">我的足迹</p>
        <h1>最近看过的店记在这儿，方便回访。</h1>
        <p>仅登录用户访问门店详情时记录；按当前区域隔离，游客访问不写足迹。</p>
      </div>
      <button
        v-if="items.length"
        type="button"
        class="secondary-button"
        :disabled="acting"
        data-testid="clear-browse-history"
        @click="clearAll"
      >
        清空足迹
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-else-if="loading" class="feedback">足迹加载中...</p>
    <p v-else-if="items.length === 0" class="feedback">当前区域还没有浏览足迹。</p>

    <div class="shop-grid">
      <article v-for="item in items" :key="item.id" class="shop-card">
        <img :src="item.coverUrl" :alt="item.shopName" class="shop-card__cover" />
        <div class="shop-card__body">
          <div class="shop-card__heading">
            <RouterLink :to="`/shops/${item.shopId}`" class="name-with-badge">
              <h3>{{ item.shopName }}</h3>
              <span v-if="item.merchantCertification" class="verified-badge verified-badge--compact">
                {{ item.merchantCertification.label }}
              </span>
            </RouterLink>
            <span class="shop-card__score">{{ Number(item.score || 0).toFixed(1) }}</span>
          </div>
          <p>{{ item.cityName }} · {{ item.areaName }} · 人均 {{ formatMoney(item.pricePerCapita, item.currency) }}</p>
          <p>{{ item.address }}</p>
          <p class="muted">看过 {{ item.viewCount }} 次 · 最近 {{ item.lastViewedAt }}</p>
          <div class="hero-actions">
            <RouterLink :to="`/shops/${item.shopId}`" class="primary-link">再去看看</RouterLink>
            <button type="button" class="secondary-button" :disabled="acting" @click="remove(item)">移除</button>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>
