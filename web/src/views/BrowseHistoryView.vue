<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { collectionStringsForRegion, localizeWebCollectionError } from '@/core/web_collection_localizations'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { clearBrowseHistory, fetchBrowseHistory, removeBrowseHistoryItem } from '@/services/browse-history'
import type { ShopBrowseHistoryItem } from '@/types/browse-history'
import { formatMoney } from '@/lib/currency'

const { state } = useAppContext()
const copy = computed(() => collectionStringsForRegion(state.region))
const certificationCopy = computed(() => discoveryStringsForRegion(state.region).shopCard)
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
    errorMessage.value = localizeWebCollectionError(copy.value, error, copy.value.history.loadFailed)
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
    successMessage.value = copy.value.history.removed
  } catch (error) {
    errorMessage.value = localizeWebCollectionError(copy.value, error, copy.value.history.removeFailed)
  } finally {
    acting.value = false
  }
}

async function clearAll() {
  if (acting.value || items.value.length === 0) return
  const confirmed = window.confirm(copy.value.history.clearConfirm)
  if (!confirmed) return
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await clearBrowseHistory()
    items.value = []
    successMessage.value = copy.value.history.cleared
  } catch (error) {
    errorMessage.value = localizeWebCollectionError(copy.value, error, copy.value.history.clearFailed)
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
        <p class="eyebrow">{{ copy.history.eyebrow }}</p>
        <h1>{{ copy.history.title }}</h1>
        <p>{{ copy.history.summary }}</p>
      </div>
      <button
        v-if="items.length"
        type="button"
        class="secondary-button"
        :disabled="acting"
        data-testid="clear-browse-history"
        @click="clearAll"
      >
        {{ copy.history.clear }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.history.loading }}</p>
    <p v-else-if="items.length === 0" class="feedback">{{ copy.history.empty }}</p>

    <div class="shop-grid">
      <article v-for="item in items" :key="item.id" class="shop-card">
        <img :src="item.coverUrl" :alt="item.shopName" class="shop-card__cover" />
        <div class="shop-card__body">
          <div class="shop-card__heading">
            <RouterLink :to="`/shops/${item.shopId}`" class="name-with-badge">
              <h3>{{ item.shopName }}</h3>
              <span v-if="item.merchantCertification" class="verified-badge verified-badge--compact">
                {{ certificationCopy.certificationLabel(item.merchantCertification.code, item.merchantCertification.label) }}
              </span>
            </RouterLink>
            <span class="shop-card__score">{{ Number(item.score || 0).toFixed(1) }}</span>
          </div>
          <p>{{ item.cityName }} · {{ item.areaName }} · {{ copy.history.averageSpend }} {{ formatMoney(item.pricePerCapita, item.currency) }}</p>
          <p>{{ item.address }}</p>
          <p class="muted">
            {{ copy.history.viewed(item.viewCount) }} · {{ copy.history.latest }}
            {{ formatWebDateTime(item.lastViewedAt, copy.tag) }}
          </p>
          <div class="hero-actions">
            <RouterLink :to="`/shops/${item.shopId}`" class="primary-link">{{ copy.history.revisit }}</RouterLink>
            <button type="button" class="secondary-button" :disabled="acting" @click="remove(item)">{{ copy.history.remove }}</button>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>
