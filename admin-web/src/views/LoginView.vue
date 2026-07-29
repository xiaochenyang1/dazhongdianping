<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { loginAdmin } from '@/services/admin'
import type { Region } from '@/types/admin'

const route = useRoute()
const router = useRouter()
const { state, setSession, setRegion } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))

const form = reactive({
  account: 'admin',
  password: 'admin123456',
})

const loading = ref(false)
const errorMessage = ref('')

const redirectTarget = computed(() =>
  typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard',
)

function regionOptionLabel(region: Region) {
  return `${region} · ${strings.value.common.regionLabel(region)}`
}

const spotlightCards = computed(() => [
  {
    label: strings.value.auth.spotlightCredentialsLabel,
    value: strings.value.auth.spotlightCredentialsValue,
    detail: strings.value.auth.spotlightCredentialsDetail,
  },
  {
    label: strings.value.auth.spotlightRegionScopeLabel,
    value: strings.value.auth.spotlightRegionScopeValue(state.region),
    detail: strings.value.auth.spotlightRegionScopeDetail,
  },
  {
    label: strings.value.auth.spotlightAuthModelLabel,
    value: strings.value.auth.spotlightAuthModelValue,
    detail: strings.value.auth.spotlightAuthModelDetail,
  },
])

const entryFacts = computed(() => [
  {
    label: strings.value.auth.entryTargetRouteLabel,
    value: redirectTarget.value,
  },
  {
    label: strings.value.auth.entrySessionModeLabel,
    value: strings.value.auth.entrySessionModeValue,
  },
  {
    label: strings.value.auth.entryRegionPerspectiveLabel,
    value: regionOptionLabel(state.region),
  },
])

const consoleNotes = computed(() => [
  {
    title: strings.value.auth.noteRegionScopeTitle,
    detail: strings.value.auth.noteRegionScopeDetail,
  },
  {
    title: strings.value.auth.noteLivePermissionsTitle,
    detail: strings.value.auth.noteLivePermissionsDetail,
  },
  {
    title: strings.value.auth.noteAdminRbacTitle,
    detail: strings.value.auth.noteAdminRbacDetail,
  },
])

async function handleSubmit() {
  loading.value = true
  errorMessage.value = ''

  try {
    const result = await loginAdmin({
      account: form.account.trim(),
      password: form.password,
    })

    setSession(result.accessToken, result.profile, result.permissions, result.regions)

    await router.replace(redirectTarget.value)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.auth.loginError
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <section class="auth-page auth-page--admin">
    <div class="auth-panel auth-panel--admin">
      <div class="auth-copy auth-copy--admin">
        <div class="auth-copy__brand">
          <span class="auth-copy__mark">DP</span>
          <div class="auth-copy__brand-text">
            <p class="eyebrow">{{ strings.auth.brandEyebrow }}</p>
            <strong>{{ strings.auth.brandHeading }}</strong>
          </div>
        </div>

        <div class="auth-copy__headline">
          <h1>{{ strings.auth.heroTitle }}</h1>
          <p>{{ strings.auth.heroDescription }}</p>
        </div>

        <div class="auth-copy__ribbon">
          <span>{{ strings.auth.ribbonRegion(state.region) }}</span>
          <span>{{ strings.auth.ribbonDatabaseRbac }}</span>
          <span>{{ strings.auth.ribbonLivePermissions }}</span>
        </div>

        <div class="tip-stack tip-stack--admin">
          <article v-for="card in spotlightCards" :key="card.label" class="tip-card tip-card--admin">
            <span>{{ card.label }}</span>
            <strong>{{ card.value }}</strong>
            <p>{{ card.detail }}</p>
          </article>
        </div>

        <div class="admin-brief">
          <article v-for="item in consoleNotes" :key="item.title" class="admin-brief__item">
            <strong>{{ item.title }}</strong>
            <p>{{ item.detail }}</p>
          </article>
        </div>
      </div>

      <form class="auth-card auth-card--admin" @submit.prevent="handleSubmit">
        <div class="auth-card__topline">
          <div>
            <p class="eyebrow">{{ strings.auth.formEyebrow }}</p>
            <h2>{{ strings.auth.formHeading }}</h2>
          </div>
          <span class="auth-card__badge">{{ strings.auth.formBadge }}</span>
        </div>

        <p class="auth-card__summary">{{ strings.auth.formSummary(redirectTarget) }}</p>

        <div class="auth-card__facts">
          <article v-for="fact in entryFacts" :key="fact.label" class="auth-card__fact">
            <span>{{ fact.label }}</span>
            <strong>{{ fact.value }}</strong>
          </article>
        </div>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

        <label class="field">
          <span>{{ strings.auth.regionFieldLabel }}</span>
          <select :value="state.region" @change="setRegion(($event.target as HTMLSelectElement).value as Region)">
            <option value="CN">{{ strings.auth.regionOptionCn }}</option>
            <option value="EU">{{ strings.auth.regionOptionEu }}</option>
          </select>
        </label>

        <label class="field">
          <span>{{ strings.auth.accountLabel }}</span>
          <input
            v-model="form.account"
            type="text"
            :placeholder="strings.auth.accountPlaceholder"
            autocomplete="username"
          />
        </label>

        <label class="field">
          <span>{{ strings.auth.passwordLabel }}</span>
          <input
            v-model="form.password"
            type="password"
            :placeholder="strings.auth.passwordPlaceholder"
            autocomplete="current-password"
          />
        </label>

        <button type="submit" class="primary-button primary-button--block" :disabled="loading">
          {{ loading ? strings.auth.loginSubmitting : strings.auth.loginButton }}
        </button>

        <div class="auth-card__footer">
          <span>{{ strings.auth.footerText }}</span>
          <div class="auth-card__chips">
            <span v-for="chip in strings.auth.footerChips" :key="chip">{{ chip }}</span>
          </div>
        </div>
      </form>
    </div>
  </section>
</template>
