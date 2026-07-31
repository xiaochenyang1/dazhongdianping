<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { campaignStringsForRegion, localizeWebCampaignError } from '@/core/web_campaign_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { fetchActivityDetail } from '@/services/activity'
import type { ActivityDetail, ActivityItem } from '@/types/activity'

const props = defineProps<{ activityId: number }>()
const activity = ref<ActivityDetail | null>(null)
const loading = ref(true)
const errorMessage = ref('')
const { state } = useAppContext()
const copy = computed(() => campaignStringsForRegion(state.region))
let requestSequence = 0

async function loadDetail() {
  const request = ++requestSequence
  loading.value = true
  errorMessage.value = ''
  activity.value = null
  try {
    const result = await fetchActivityDetail(props.activityId)
    if (request === requestSequence) activity.value = result
  } catch (error) {
    if (request === requestSequence) {
      errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.activity.detailLoadFailed)
    }
  } finally {
    if (request === requestSequence) loading.value = false
  }
}

function itemBadge(item: ActivityItem) {
  const badge = item.extra?.badge
  return typeof badge === 'string' && badge.trim()
    ? badge.trim()
    : copy.value.activity.targetLabel(item.targetType, item.targetTypeText)
}

function isExternal(item: ActivityItem) {
  return item.targetType === 6 || item.linkUrl.startsWith('http://') || item.linkUrl.startsWith('https://')
}

watch(
  [() => props.activityId, () => state.region],
  () => void loadDetail(),
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.activity.detailLoading }}</p>
    <template v-else-if="activity">
      <div class="page-header activity-detail-header">
        <div>
          <p class="eyebrow">{{ copy.activity.typeLabel(activity.type, activity.typeText) }} · {{ copy.activity.channelLabel(activity.channel, activity.channelText) }}</p>
          <h1>{{ activity.name }}</h1>
          <p>
            {{ activity.cityName }} · {{ activity.startAt ? formatWebDateTime(activity.startAt, copy.tag) : copy.activity.noStart }} —
            {{ activity.endAt ? formatWebDateTime(activity.endAt, copy.tag) : copy.activity.noEnd }}
          </p>
        </div>
        <RouterLink to="/activities" class="secondary-button">{{ copy.activity.back }}</RouterLink>
      </div>

      <article class="content-card activity-hero-card">
        <img :src="activity.cover" :alt="activity.name" class="activity-hero-card__image" />
        <div class="activity-hero-card__body">
          <p>{{ copy.activity.code }}: {{ activity.code }}</p>
          <p>{{ copy.activity.availableItems(activity.items.length) }}</p>
          <p v-if="activity.landingUrl">{{ copy.activity.landing }}: {{ activity.landingUrl }}</p>
        </div>
      </article>

      <div v-if="activity.items.length === 0" class="feedback">{{ copy.activity.noItems }}</div>
      <div v-else class="activity-item-grid">
        <article v-for="item in activity.items" :key="item.id" class="content-card activity-item-card">
          <img :src="item.image" :alt="item.title" />
          <div class="activity-item-card__body">
            <div class="shop-card__heading">
              <h2>{{ item.title }}</h2>
              <span class="status-pill is-deal">{{ itemBadge(item) }}</span>
            </div>
            <p>{{ item.subtitle || item.targetName || item.targetTypeText }}</p>
            <a
              v-if="isExternal(item) && item.linkUrl"
              class="text-link"
              :href="item.linkUrl"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ copy.activity.openExternal }}
            </a>
            <RouterLink v-else-if="item.linkUrl" class="text-link" :to="item.linkUrl">
              {{ copy.activity.viewTarget(copy.activity.targetLabel(item.targetType, item.targetTypeText)) }}
            </RouterLink>
            <span v-else class="text-muted">{{ copy.activity.noLink }}</span>
          </div>
        </article>
      </div>
    </template>
  </section>
</template>
