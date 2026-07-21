<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { fetchPublicUserProfile } from '@/services/auth'
import type { PublicUserProfile } from '@/types/auth'

const props = defineProps<{
  userId: number
}>()

const { state: appState } = useAppContext()
const { state: sessionState } = useUserSession()

const loading = ref(false)
const errorMessage = ref('')
const profile = ref<PublicUserProfile | null>(null)

const userInitial = computed(() => profile.value?.nickname?.slice(0, 1)?.toUpperCase() || 'TA')
const isSelf = computed(() => profile.value?.id === sessionState.currentUser?.id)

async function loadProfile() {
  if (Number.isNaN(props.userId)) {
    errorMessage.value = '用户 ID 不合法'
    profile.value = null
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    profile.value = await fetchPublicUserProfile(props.userId)
  } catch (error) {
    profile.value = null
    errorMessage.value = error instanceof Error ? error.message : '用户主页加载失败'
  } finally {
    loading.value = false
  }
}

watch(
  [() => props.userId, () => appState.region],
  () => {
    void loadProfile()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">用户主页加载中...</p>

    <template v-else-if="profile">
      <section class="hero-panel hero-panel--single">
        <div class="hero-panel__content">
          <p class="eyebrow">公开主页</p>
          <div class="profile-identity">
            <img v-if="profile.avatar" :src="profile.avatar" :alt="profile.nickname" class="profile-avatar" />
            <div v-else class="profile-avatar profile-avatar--placeholder">{{ userInitial }}</div>
            <div>
              <h1 class="name-with-badge">
                <span>{{ profile.nickname }}</span>
                <span v-if="profile.expertCertification" class="verified-badge">
                  {{ profile.expertCertification.label }}
                </span>
              </h1>
              <p class="hero-panel__summary">
                {{ profile.preferredRegion }} · Lv.{{ profile.level }} · 公开点评 {{ profile.reviewCount }} 条
              </p>
            </div>
          </div>
          <p class="support-copy">
            {{ profile.signature || '这个人暂时没留下签名，先看基础信息。' }}
          </p>
          <div v-if="isSelf" class="hero-actions">
            <RouterLink to="/user/profile" class="primary-link">去我的资料页</RouterLink>
            <RouterLink to="/user/reviews" class="secondary-button">看我的点评</RouterLink>
          </div>
        </div>
      </section>

      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">基础数据</p>
            <h2>先把公开能看的信息给够，别把隐私字段乱甩出来。</h2>
          </div>
        </div>

        <div class="profile-grid">
          <div class="hero-metric">
            <span>等级</span>
            <strong>Lv.{{ profile.level }}</strong>
          </div>
          <div class="hero-metric">
            <span>积分 / 成长值</span>
            <strong>{{ profile.points }} / {{ profile.growthValue }}</strong>
          </div>
          <div class="hero-metric">
            <span>公开点评</span>
            <strong>{{ profile.reviewCount }} 条</strong>
          </div>
          <RouterLink :to="`/users/${profile.id}/followers`" class="hero-metric social-metric-link">
            <span>公开关系</span>
            <strong>粉丝 {{ profile.followerCount }}</strong>
          </RouterLink>
          <RouterLink :to="`/users/${profile.id}/following`" class="hero-metric social-metric-link">
            <span>公开关系</span>
            <strong>关注 {{ profile.followingCount }}</strong>
          </RouterLink>
        </div>

        <p v-if="profile.reviewCount === 0" class="feedback">
          这个用户现在还没有公开可见的点评，至少说明待审和驳回内容没被拿出来乱透。
        </p>
      </section>
    </template>
  </div>
</template>
