<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { campaignStringsForRegion, localizeWebCampaignError } from '@/core/web_campaign_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { fetchActivities } from '@/services/activity'
import type { ActivitySummary } from '@/types/activity'

const { state } = useAppContext()
const activities = ref<ActivitySummary[]>([])
const loading = ref(false)
const errorMessage = ref('')
const activeChannel = ref<number | undefined>()

const copy = computed(() => campaignStringsForRegion(state.region))
const channels = computed(() => [1, 2, 3, 4, 5].map((id) => ({
  id,
  name: copy.value.activity.channelLabel(id),
})))

async function loadActivities() {
  loading.value = true
  errorMessage.value = ''
  try {
    activities.value = await fetchActivities({
      cityId: state.cityId,
      channel: activeChannel.value,
      limit: 20,
    })
  } catch (error) {
    errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.activity.listLoadFailed)
  } finally {
    loading.value = false
  }
}

function selectChannel(channel?: number) {
  activeChannel.value = channel
  void loadActivities()
}

watch(() => [state.region, state.cityId], loadActivities, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.activity.eyebrow }}</p>
        <h1>{{ copy.activity.title }}</h1>
        <p>{{ copy.activity.summary(state.region) }}</p>
      </div>
    </div>

    <div class="filters-panel__actions rank-type-tabs">
      <button
        type="button"
        :class="activeChannel == null ? 'primary-button' : 'secondary-button'"
        @click="selectChannel()"
      >
        {{ copy.activity.allChannels }}
      </button>
      <button
        v-for="item in channels"
        :key="item.id"
        type="button"
        :class="activeChannel === item.id ? 'primary-button' : 'secondary-button'"
        @click="selectChannel(item.id)"
      >
        {{ item.name }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.activity.loading }}</p>
    <p v-else-if="activities.length === 0" class="feedback">{{ copy.activity.empty }}</p>

    <div class="activity-grid">
      <RouterLink
        v-for="activity in activities"
        :key="activity.id"
        :to="`/activities/${activity.id}`"
        class="activity-card"
      >
        <img :src="activity.cover" :alt="activity.name" />
        <div class="activity-card__body">
          <div class="shop-card__heading">
            <h2>{{ activity.name }}</h2>
            <span class="status-pill is-deal">{{ copy.activity.typeLabel(activity.type, activity.typeText) }}</span>
          </div>
          <p>{{ activity.cityName }} · {{ copy.activity.channelLabel(activity.channel, activity.channelText) }} · {{ copy.activity.resourceCount(activity.itemCount) }}</p>
          <span v-if="activity.startAt || activity.endAt">
            {{ activity.startAt ? formatWebDateTime(activity.startAt, copy.tag) : copy.activity.noStart }} — {{ activity.endAt ? formatWebDateTime(activity.endAt, copy.tag) : copy.activity.noEnd }}
          </span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>
