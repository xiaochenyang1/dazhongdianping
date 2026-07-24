<script setup lang="ts">
import { ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { fetchActivities } from '@/services/activity'
import type { ActivitySummary } from '@/types/activity'

const { state } = useAppContext()
const activities = ref<ActivitySummary[]>([])
const loading = ref(false)
const errorMessage = ref('')
const activeChannel = ref<number | undefined>()

const channels = [
  { id: 1, name: '首页' },
  { id: 2, name: '搜索' },
  { id: 3, name: '频道' },
  { id: 4, name: '活动页' },
  { id: 5, name: '社区' },
]

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
    errorMessage.value = error instanceof Error ? error.message : '活动列表加载失败'
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
        <p class="eyebrow">运营活动</p>
        <h1>管理端配好的专题，终于能直接在 C 端被点开。</h1>
        <p>
          当前区域 {{ state.region }} · 只展示状态为“上线中”且在有效期内的活动。
        </p>
      </div>
    </div>

    <div class="filters-panel__actions rank-type-tabs">
      <button
        type="button"
        :class="activeChannel == null ? 'primary-button' : 'secondary-button'"
        @click="selectChannel()"
      >
        全部频道
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
    <p v-else-if="loading" class="feedback">活动加载中...</p>
    <p v-else-if="activities.length === 0" class="feedback">当前城市暂时没有上线活动。</p>

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
            <span class="status-pill is-deal">{{ activity.typeText }}</span>
          </div>
          <p>{{ activity.cityName }} · {{ activity.channelText }} · {{ activity.itemCount }} 个资源</p>
          <span v-if="activity.startAt || activity.endAt">
            {{ activity.startAt || '不限开始' }} — {{ activity.endAt || '不限结束' }}
          </span>
        </div>
      </RouterLink>
    </div>
  </section>
</template>
