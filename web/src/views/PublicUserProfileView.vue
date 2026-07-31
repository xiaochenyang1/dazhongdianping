<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { fetchPublicUserProfile } from '@/services/auth'
import type { PublicUserProfile } from '@/types/auth'

const props = defineProps<{
  userId: number
}>()

const { state: appState } = useAppContext()
const { state: sessionState } = useUserSession()
const copy = computed(() => userStringsForRegion(appState.region))
const certificationCopy = computed(() => discoveryStringsForRegion(appState.region).shopCard)

const loading = ref(false)
const errorMessage = ref('')
const profile = ref<PublicUserProfile | null>(null)

const userInitial = computed(() => profile.value?.nickname?.slice(0, 1)?.toUpperCase() || 'TA')
const isSelf = computed(() => profile.value?.id === sessionState.currentUser?.id)

async function loadProfile() {
  if (Number.isNaN(props.userId)) {
    errorMessage.value = copy.value.publicProfile.invalidId
    profile.value = null
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    profile.value = await fetchPublicUserProfile(props.userId)
  } catch (error) {
    profile.value = null
    errorMessage.value = localizeWebUserError(copy.value, error, copy.value.publicProfile.loadFailed)
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
    <p v-else-if="loading" class="feedback">{{ copy.publicProfile.loading }}</p>

    <template v-else-if="profile">
      <section class="hero-panel hero-panel--single">
        <div class="hero-panel__content">
          <p class="eyebrow">{{ copy.publicProfile.eyebrow }}</p>
          <div class="profile-identity">
            <img v-if="profile.avatar" :src="profile.avatar" :alt="profile.nickname" class="profile-avatar" />
            <div v-else class="profile-avatar profile-avatar--placeholder">{{ userInitial }}</div>
            <div>
              <h1 class="name-with-badge">
                <span>{{ profile.nickname }}</span>
                <span v-if="profile.expertCertification" class="verified-badge">
                  {{ certificationCopy.certificationLabel(profile.expertCertification.code, profile.expertCertification.label) }}
                </span>
              </h1>
              <p class="hero-panel__summary">
                {{ profile.preferredRegion }} · Lv.{{ profile.level }} · {{ copy.publicProfile.reviewCount(profile.reviewCount) }}
              </p>
            </div>
          </div>
          <p class="support-copy">
            {{ profile.signature || copy.publicProfile.noSignature }}
          </p>
          <div v-if="isSelf" class="hero-actions">
            <RouterLink to="/user/profile" class="primary-link">{{ copy.publicProfile.myProfile }}</RouterLink>
            <RouterLink to="/user/reviews" class="secondary-button">{{ copy.publicProfile.myReviews }}</RouterLink>
          </div>
        </div>
      </section>

      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.publicProfile.basics }}</p>
            <h2>{{ copy.publicProfile.basicsTitle }}</h2>
          </div>
        </div>

        <div class="profile-grid">
          <div class="hero-metric">
            <span>{{ copy.publicProfile.level }}</span>
            <strong>Lv.{{ profile.level }}</strong>
          </div>
          <div class="hero-metric">
            <span>{{ copy.publicProfile.pointsAndGrowth }}</span>
            <strong>{{ profile.points }} / {{ profile.growthValue }}</strong>
          </div>
          <div class="hero-metric">
            <span>{{ copy.publicProfile.publicReviews }}</span>
            <strong>{{ copy.publicProfile.reviewCount(profile.reviewCount) }}</strong>
          </div>
          <RouterLink :to="`/users/${profile.id}/followers`" class="hero-metric social-metric-link">
            <span>{{ copy.publicProfile.publicRelations }}</span>
            <strong>{{ copy.publicProfile.followers(profile.followerCount) }}</strong>
          </RouterLink>
          <RouterLink :to="`/users/${profile.id}/following`" class="hero-metric social-metric-link">
            <span>{{ copy.publicProfile.publicRelations }}</span>
            <strong>{{ copy.publicProfile.following(profile.followingCount) }}</strong>
          </RouterLink>
        </div>

        <p v-if="profile.reviewCount === 0" class="feedback">
          {{ copy.publicProfile.noReviews }}
        </p>
      </section>
    </template>
  </div>
</template>
