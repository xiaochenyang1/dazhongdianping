<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { campaignStringsForRegion, localizeWebCampaignError } from '@/core/web_campaign_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { fetchRanks } from '@/services/rank'
import type { RankSummary } from '@/types/rank'

const { state } = useAppContext()
const ranks = ref<RankSummary[]>([])
const loading = ref(false)
const errorMessage = ref('')
const activeType = ref<number | undefined>()
const copy = computed(() => campaignStringsForRegion(state.region))
const rankTypes = computed(() => [1, 2, 3].map((id) => ({ id, name: copy.value.rank.typeLabel(id) })))

async function loadRanks() {
  loading.value = true
  errorMessage.value = ''
  try {
    ranks.value = await fetchRanks({ cityId: state.cityId, type: activeType.value })
  } catch (error) {
    errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.rank.listLoadFailed)
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
        <p class="eyebrow">{{ copy.rank.eyebrow }}</p>
        <h1>{{ copy.rank.title }}</h1>
        <p>{{ copy.rank.summary(state.region) }}</p>
      </div>
    </div>

    <div class="filters-panel__actions rank-type-tabs">
      <button type="button" :class="activeType == null ? 'primary-button' : 'secondary-button'" @click="selectType()">{{ copy.rank.all }}</button>
      <button v-for="item in rankTypes" :key="item.id" type="button" :class="activeType === item.id ? 'primary-button' : 'secondary-button'" @click="selectType(item.id)">
        {{ item.name }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.rank.loading }}</p>
    <p v-else-if="ranks.length === 0" class="feedback">{{ copy.rank.empty }}</p>

    <div class="rank-grid">
      <RouterLink v-for="rank in ranks" :key="rank.id" :to="`/ranks/${rank.id}`" class="rank-card">
        <img :src="rank.coverUrl" :alt="rank.name" />
        <div class="rank-card__body">
          <div class="shop-card__heading">
            <h2>{{ rank.name }}</h2>
            <span class="status-pill is-deal">{{ copy.rank.typeLabel(rank.type, rank.typeText) }}</span>
          </div>
          <p>{{ rank.cityName }} · {{ rank.categoryName }} · {{ rank.period }}</p>
          <strong>{{ copy.rank.leader }}: {{ rank.topShopName }}</strong>
          <span>{{ copy.rank.placeCount(rank.itemCount) }} · {{ copy.rank.updated }} {{ formatWebDateTime(rank.updatedAt, copy.tag) }}</span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>
