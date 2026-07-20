<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchUserFollowers, fetchUserFollowing } from '@/services/auth'
import type { SocialUserSummary } from '@/types/auth'

const props = defineProps<{ userId: number; mode: 'followers' | 'following' }>()
const users = ref<SocialUserSummary[]>([])
const total = ref(0)
const errorMessage = ref('')

onMounted(async () => {
  try {
    const page = props.mode === 'followers'
      ? await fetchUserFollowers(props.userId, { page: 1, pageSize: 50 })
      : await fetchUserFollowing(props.userId, { page: 1, pageSize: 50 })
    users.value = page.list
    total.value = page.total
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '关系列表加载失败'
  }
})
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">公开关系 · 只读</p>
        <h1>{{ mode === 'followers' ? `粉丝 ${total} 人` : `关注 ${total} 人` }}</h1>
        <p>PC 端只展示公开关系，不提供关注或取关操作。</p>
      </div>
    </div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <div v-else class="review-list">
      <RouterLink v-for="user in users" :key="user.id" :to="`/users/${user.id}`" class="content-card review-card">
        <strong>{{ user.nickname }}</strong>
        <p>{{ user.signature || `Lv.${user.level} · 粉丝 ${user.followerCount}` }}</p>
        <span>建立关系于 {{ user.followedAt }}</span>
      </RouterLink>
    </div>
  </section>
</template>
