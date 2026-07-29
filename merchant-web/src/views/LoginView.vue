<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { fetchSettlementStatus, loginMerchant } from '@/services/merchant'

const route = useRoute()
const router = useRouter()
const { state, setSession } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const account = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  loading.value = true
  error.value = ''
  try {
    setSession(await loginMerchant({ account: account.value, password: password.value }))
    const settlement = await fetchSettlementStatus()
    await router.replace(settlement.status === 1 ? String(route.query.redirect || '/dashboard') : '/settlement')
  } catch (errorCause) {
    error.value = errorCause instanceof Error ? errorCause.message : strings.value.auth.loginError
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="auth-page">
    <form class="card auth-card" @submit.prevent="submit">
      <p class="eyebrow">{{ strings.shell.workbenchEyebrow }}</p>
      <h1>{{ strings.auth.loginHeading }}</h1>
      <label>
        {{ strings.auth.accountLabel }}
        <input v-model="account" required autocomplete="username" />
      </label>
      <label>
        {{ strings.auth.passwordLabel }}
        <input v-model="password" required type="password" autocomplete="current-password" />
      </label>
      <p v-if="error" class="error">{{ error }}</p>
      <button :disabled="loading">
        {{ loading ? strings.auth.loginSubmitting : strings.auth.loginButton }}
      </button>
      <p class="auth-switch">
        {{ strings.auth.loginSwitchLabel }}
        <RouterLink to="/register">{{ strings.auth.loginSwitchAction }}</RouterLink>
      </p>
    </form>
  </main>
</template>
