<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { fetchUserFollowers, fetchUserFollowing } from '@/services/auth'
import type { SocialUserSummary } from '@/types/auth'

const props = defineProps<{ userId: number; mode: 'followers' | 'following' }>()
const { state } = useAppContext()
const copy = computed(() => userStringsForRegion(state.region))
const users = ref<SocialUserSummary[]>([])
const total = ref(0)
const errorMessage = ref('')

async function load() {
  errorMessage.value = ''
  users.value = []
  try {
    const page = props.mode === 'followers'
      ? await fetchUserFollowers(props.userId, { page: 1, pageSize: 50 })
      : await fetchUserFollowing(props.userId, { page: 1, pageSize: 50 })
    users.value = page.list
    total.value = page.total
  } catch (error) {
    errorMessage.value = localizeWebUserError(copy.value, error, copy.value.relationships.loadFailed)
  }
}

watch([() => props.userId, () => props.mode, () => state.region], () => void load(), { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.relationships.eyebrow }}</p>
        <h1>{{ mode === 'followers' ? copy.relationships.followers(total) : copy.relationships.following(total) }}</h1>
        <p>{{ copy.relationships.summary }}</p>
      </div>
    </div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="users.length === 0" class="feedback">
      {{ mode === 'followers' ? copy.relationships.emptyFollowers : copy.relationships.emptyFollowing }}
    </p>
    <div v-else class="review-list">
      <RouterLink v-for="user in users" :key="user.id" :to="`/users/${user.id}`" class="content-card review-card">
        <strong>{{ user.nickname }}</strong>
        <p>{{ user.signature || `Lv.${user.level} · ${copy.relationships.followerCount(user.followerCount)}` }}</p>
        <span>{{ copy.relationships.followedAt }} {{ formatWebDateTime(user.followedAt, copy.tag) }}</span>
      </RouterLink>
    </div>
  </section>
</template>
