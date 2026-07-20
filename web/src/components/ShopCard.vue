<script setup lang="ts">
import { formatMoney } from '@/lib/currency'
import type { ShopListItem } from '@/types/browse'

defineProps<{
  shop: ShopListItem
}>()

function formatDistance(distanceMeters: number) {
  if (distanceMeters < 1000) {
    return `${Math.round(distanceMeters)} m`
  }
  return `${(distanceMeters / 1000).toFixed(distanceMeters < 10000 ? 1 : 0)} km`
}
</script>

<template>
  <article class="shop-card">
    <img :src="shop.coverUrl" :alt="shop.name" class="shop-card__cover" />
    <div class="shop-card__body">
      <div class="shop-card__heading">
        <h3>{{ shop.name }}</h3>
        <span class="shop-card__score">{{ shop.score.toFixed(1) }}</span>
      </div>
      <p class="shop-card__meta">
        {{ shop.cityName }} · {{ shop.areaName }} · 人均 {{ formatMoney(shop.pricePerCapita, shop.currency) }}
      </p>
      <p class="shop-card__address">{{ shop.address }}</p>
      <div class="shop-card__tags">
        <span v-for="tag in shop.tags" :key="tag">{{ tag }}</span>
      </div>
      <div class="shop-card__foot">
        <span :class="shop.openNow ? 'status-pill is-open' : 'status-pill is-closed'">
          {{ shop.openNow ? '营业中' : '休息中' }}
        </span>
        <span v-if="shop.hasDeal" class="status-pill is-deal">有团购</span>
        <span v-if="shop.distanceMeters != null" class="status-pill">
          距你 {{ formatDistance(shop.distanceMeters) }}
        </span>
      </div>
    </div>
  </article>
</template>
