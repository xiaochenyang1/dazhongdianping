<script setup lang="ts">
import { computed } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatMoney } from '@/lib/currency'
import type { ShopListItem } from '@/types/browse'

defineProps<{
  shop: ShopListItem
}>()

const { state } = useAppContext()
const copy = computed(() => discoveryStringsForRegion(state.region).shopCard)

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
        <h3 class="name-with-badge">
          {{ shop.name }}
          <span v-if="shop.merchantCertification" class="verified-badge verified-badge--compact">
            {{ copy.certificationLabel(shop.merchantCertification.code, shop.merchantCertification.label) }}
          </span>
        </h3>
        <span class="shop-card__score">{{ shop.score.toFixed(1) }}</span>
      </div>
      <p class="shop-card__meta">
        {{ shop.cityName }} · {{ shop.areaName }} · {{ copy.averageSpend }} {{ formatMoney(shop.pricePerCapita, shop.currency) }}
      </p>
      <p class="shop-card__address">{{ shop.address }}</p>
      <div class="shop-card__tags">
        <span v-for="tag in shop.tags" :key="tag">{{ tag }}</span>
      </div>
      <div class="shop-card__foot">
        <span :class="shop.openNow ? 'status-pill is-open' : 'status-pill is-closed'">
          {{ shop.openNow ? copy.openNow : copy.closed }}
        </span>
        <span v-if="shop.hasDeal" class="status-pill is-deal">{{ copy.dealAvailable }}</span>
        <span v-if="shop.distanceMeters != null" class="status-pill">
          {{ copy.distanceFromYou(formatDistance(shop.distanceMeters)) }}
        </span>
      </div>
    </div>
  </article>
</template>
