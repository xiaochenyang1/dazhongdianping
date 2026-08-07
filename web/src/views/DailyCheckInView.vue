<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { checkInCurrentUser, fetchCurrentUser, fetchUserCheckInStatus } from '@/services/auth'
import type { UserCheckInStatus } from '@/types/auth'

const { state: appState } = useAppContext()
const { setCurrentUser } = useUserSession()
const strings = computed(() => userStringsForRegion(appState.region))
const copy = computed(() => strings.value.checkIn)
const locale = computed(() => strings.value.tag)

const status = ref<UserCheckInStatus | null>(null)
const loading = ref(false)
const submitting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let loadRequestId = 0

const statusClass = computed(() => (
  status.value?.checkedInToday
    ? 'status-pill status-pill--good'
    : 'status-pill status-pill--warn'
))

const lastCheckInText = computed(() => {
  const value = status.value?.lastCheckInAt?.trim()
  return value ? formatWebDateTime(value, locale.value) : copy.value.never
})

async function loadStatus() {
  const requestId = ++loadRequestId
  const hadStatus = status.value !== null
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const nextStatus = await fetchUserCheckInStatus()
    if (requestId === loadRequestId) {
      status.value = nextStatus
    }
  } catch (error) {
    if (requestId === loadRequestId) {
      if (!hadStatus) {
        status.value = null
      }
      errorMessage.value = localizeWebUserError(strings.value, error, copy.value.loadFailed)
    }
  } finally {
    if (requestId === loadRequestId) {
      loading.value = false
    }
  }
}

async function submitCheckIn() {
  if (submitting.value || status.value?.checkedInToday) {
    return
  }

  submitting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    status.value = await checkInCurrentUser()
    successMessage.value = copy.value.success

    try {
      setCurrentUser(await fetchCurrentUser())
    } catch {
      // The check-in is already committed; profile refresh can recover on the next page load.
    }
  } catch (error) {
    errorMessage.value = localizeWebUserError(strings.value, error, copy.value.submitFailed)
  } finally {
    submitting.value = false
  }
}

watch(
  () => appState.region,
  () => {
    status.value = null
    void loadStatus()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--compact">
      <div class="hero-panel__content">
        <p class="eyebrow">{{ copy.eyebrow }}</p>
        <h1>{{ copy.title }}</h1>
        <p class="hero-panel__summary">{{ copy.summary }}</p>
        <div class="hero-actions">
          <RouterLink to="/user/profile" class="ghost-button">{{ copy.backProfile }}</RouterLink>
          <RouterLink to="/user/points-mall" class="secondary-button">{{ strings.pointsMall.eyebrow }}</RouterLink>
          <RouterLink to="/user/growth-records" class="secondary-button">{{ copy.growthHistory }}</RouterLink>
        </div>
      </div>

      <div class="hero-panel__side">
        <div class="hero-metric">
          <span>{{ copy.todayStatus }}</span>
          <strong>{{ status ? status.checkedInToday ? copy.checkedIn : copy.notCheckedIn : '—' }}</strong>
        </div>
        <div class="hero-metric">
          <span>{{ copy.streak }}</span>
          <strong>{{ status ? copy.streakValue(status.streakDays) : '—' }}</strong>
        </div>
        <div class="hero-metric">
          <span>{{ copy.total }}</span>
          <strong>{{ status ? copy.totalValue(status.totalCount) : '—' }}</strong>
        </div>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.detailEyebrow }}</p>
          <h2>{{ copy.detailTitle }}</h2>
        </div>
      </div>

      <p v-if="loading && !status" class="feedback">{{ copy.loading }}</p>
      <div v-else-if="!status" class="stack-list">
        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
        <div class="hero-actions">
          <button type="button" class="secondary-button" data-testid="check-in-retry" @click="loadStatus">
            {{ copy.retry }}
          </button>
        </div>
      </div>

      <article v-else class="manage-card">
        <div class="manage-card__header">
          <div>
            <p class="eyebrow">{{ copy.reward }}</p>
            <h3>{{ copy.rewardValue(status.todayGrowthReward, status.todayPointsReward) }}</h3>
          </div>
          <span :class="statusClass" data-testid="check-in-status">
            {{ status.checkedInToday ? copy.checkedIn : copy.notCheckedIn }}
          </span>
        </div>

        <p class="manage-card__copy">
          {{ status.checkedInToday ? copy.checkedHint : copy.availableHint }}
        </p>

        <div class="profile-grid">
          <div class="hero-metric">
            <span>{{ copy.streak }}</span>
            <strong>{{ copy.streakValue(status.streakDays) }}</strong>
          </div>
          <div class="hero-metric">
            <span>{{ copy.total }}</span>
            <strong>{{ copy.totalValue(status.totalCount) }}</strong>
          </div>
          <div class="hero-metric">
            <span>{{ copy.lastCheckIn }}</span>
            <strong>{{ lastCheckInText }}</strong>
          </div>
        </div>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
        <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

        <div class="manage-card__footer">
          <span>{{ status.checkedInToday ? copy.checkedHint : copy.availableHint }}</span>
          <div class="hero-actions">
            <button type="button" class="ghost-button" :disabled="loading" @click="loadStatus">
              {{ loading ? copy.refreshing : copy.refresh }}
            </button>
            <button
              type="button"
              class="primary-button"
              data-testid="check-in-submit"
              :disabled="submitting || status.checkedInToday"
              @click="submitCheckIn"
            >
              {{ submitting ? copy.submitting : status.checkedInToday ? copy.submitted : copy.submit }}
            </button>
          </div>
        </div>
      </article>
    </section>
  </div>
</template>
