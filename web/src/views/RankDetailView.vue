<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { formatMoney } from '@/lib/currency'
import { useAppContext } from '@/composables/useAppContext'
import { campaignStringsForRegion, localizeWebCampaignError } from '@/core/web_campaign_localizations'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { fetchRankDetail } from '@/services/rank'
import type { RankDetail } from '@/types/rank'

const props = defineProps<{ rankId: number }>()
const rank = ref<RankDetail | null>(null)
const loading = ref(true)
const errorMessage = ref('')
const { state } = useAppContext()
const copy = computed(() => campaignStringsForRegion(state.region))
const certificationCopy = computed(() => discoveryStringsForRegion(state.region).shopCard)
let requestSequence = 0

async function loadDetail() {
  const request = ++requestSequence
  loading.value = true
  errorMessage.value = ''
  rank.value = null
  try {
    const result = await fetchRankDetail(props.rankId)
    if (request === requestSequence) rank.value = result
  } catch (error) {
    if (request === requestSequence) {
      errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.rank.detailLoadFailed)
    }
  } finally {
    if (request === requestSequence) loading.value = false
  }
}

watch([() => props.rankId, () => state.region], () => void loadDetail(), { immediate: true })
</script>

<template>
  <section class="page-section">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.rank.detailLoading }}</p>
    <template v-else-if="rank">
      <div class="page-header">
        <div>
          <p class="eyebrow">{{ copy.rank.typeLabel(rank.type, rank.typeText) }} · {{ rank.period }}</p>
          <h1>{{ rank.name }}</h1>
          <p>{{ rank.cityName }} · {{ rank.categoryName }} · {{ copy.rank.updated }} {{ formatWebDateTime(rank.updatedAt, copy.tag) }}</p>
        </div>
        <RouterLink to="/ranks" class="secondary-button">{{ copy.rank.back }}</RouterLink>
      </div>

      <div class="rank-list">
        <article v-for="item in rank.items" :key="item.shop.id" class="content-card rank-item">
          <div class="rank-position">{{ item.position }}</div>
          <img :src="item.shop.coverUrl" :alt="item.shop.name" />
          <div class="rank-item__body">
            <div class="shop-card__heading">
              <RouterLink :to="`/shops/${item.shop.id}`" class="name-with-badge">
                <h2>{{ item.shop.name }}</h2>
                <span v-if="item.shop.merchantCertification" class="verified-badge verified-badge--compact">
                  {{ certificationCopy.certificationLabel(item.shop.merchantCertification.code, item.shop.merchantCertification.label) }}
                </span>
              </RouterLink>
              <span class="shop-card__score">{{ item.shop.score.toFixed(1) }}</span>
            </div>
            <p>{{ item.shop.cityName }} · {{ item.shop.areaName }} · {{ copy.rank.averageSpend }} {{ formatMoney(item.shop.pricePerCapita, item.shop.currency) }}</p>
            <p>{{ item.reason }}</p>
            <div class="shop-card__tags"><span v-for="tag in item.shop.tags" :key="tag">{{ tag }}</span></div>
          </div>
          <strong class="rank-score">{{ item.rankScore.toFixed(2) }}</strong>
        </article>
      </div>
    </template>
  </section>
</template>
