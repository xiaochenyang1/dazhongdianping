<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchActivityDetail } from '@/services/activity'
import type { ActivityDetail, ActivityItem } from '@/types/activity'

const props = defineProps<{ activityId: number }>()
const activity = ref<ActivityDetail | null>(null)
const loading = ref(true)
const errorMessage = ref('')

async function loadDetail() {
  loading.value = true
  errorMessage.value = ''
  activity.value = null
  try {
    activity.value = await fetchActivityDetail(props.activityId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '活动详情加载失败'
  } finally {
    loading.value = false
  }
}

function itemBadge(item: ActivityItem) {
  const badge = item.extra?.badge
  return typeof badge === 'string' && badge.trim() ? badge.trim() : item.targetTypeText
}

function isExternal(item: ActivityItem) {
  return item.targetType === 6 || item.linkUrl.startsWith('http://') || item.linkUrl.startsWith('https://')
}

onMounted(() => {
  void loadDetail()
})

watch(
  () => props.activityId,
  () => {
    void loadDetail()
  },
)
</script>

<template>
  <section class="page-section">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">活动详情加载中...</p>
    <template v-else-if="activity">
      <div class="page-header activity-detail-header">
        <div>
          <p class="eyebrow">{{ activity.typeText }} · {{ activity.channelText }}</p>
          <h1>{{ activity.name }}</h1>
          <p>
            {{ activity.cityName }} · {{ activity.startAt || '不限开始' }} —
            {{ activity.endAt || '不限结束' }}
          </p>
        </div>
        <RouterLink to="/activities" class="secondary-button">返回活动列表</RouterLink>
      </div>

      <article class="content-card activity-hero-card">
        <img :src="activity.cover" :alt="activity.name" class="activity-hero-card__image" />
        <div class="activity-hero-card__body">
          <p>活动编码：{{ activity.code }}</p>
          <p>当前共 {{ activity.items.length }} 个可用资源项。</p>
          <p v-if="activity.landingUrl">落地配置：{{ activity.landingUrl }}</p>
        </div>
      </article>

      <div v-if="activity.items.length === 0" class="feedback">这个活动还没有启用中的资源项。</div>
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
              打开外链
            </a>
            <RouterLink v-else-if="item.linkUrl" class="text-link" :to="item.linkUrl">
              查看{{ item.targetTypeText }}
            </RouterLink>
            <span v-else class="text-muted">暂无可用跳转</span>
          </div>
        </article>
      </div>
    </template>
  </section>
</template>
