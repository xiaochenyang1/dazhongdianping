<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { registerMerchant } from '@/services/merchant'
import { useMerchantSession, type MerchantRegion } from '@/composables/useMerchantSession'

const router = useRouter()
const { setSession } = useMerchantSession()
const loading = ref(false)
const error = ref('')
const form = reactive({
  account: '',
  password: '',
  companyName: '',
  contactName: '',
  contactPhone: '',
  region: 'EU' as MerchantRegion,
})
const strings = computed(() => merchantStringsForRegion(form.region))

async function submit() {
  loading.value = true
  error.value = ''
  try {
    const result = await registerMerchant({ ...form })
    setSession(result)
    await router.replace('/settlement')
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.auth.registerError
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="auth-page identity-auth-page">
    <section class="identity-intro">
      <p class="eyebrow">{{ strings.auth.onboardingEyebrow }}</p>
      <h1>{{ strings.auth.registerHeroTitle }}</h1>
      <p>{{ strings.auth.registerHeroDescription }}</p>
      <ol>
        <li><strong>01</strong><span>{{ strings.auth.registerSteps[0] }}</span></li>
        <li><strong>02</strong><span>{{ strings.auth.registerSteps[1] }}</span></li>
        <li><strong>03</strong><span>{{ strings.auth.registerSteps[2] }}</span></li>
      </ol>
    </section>

    <form class="card auth-card identity-form" @submit.prevent="submit">
      <div>
        <p class="eyebrow">{{ strings.auth.registerHeadingEyebrow }}</p>
        <h2>{{ strings.auth.registerHeading }}</h2>
        <p class="muted">{{ strings.auth.registerDescription }}</p>
      </div>

      <label>
        {{ strings.auth.regionLabel }}
        <select v-model="form.region" name="region">
          <option value="EU">{{ strings.auth.euRegionOption }}</option>
          <option value="CN">{{ strings.auth.cnRegionOption }}</option>
        </select>
      </label>
      <label>
        {{ strings.auth.accountLabel }}
        <input v-model.trim="form.account" name="account" required autocomplete="username" />
      </label>
      <label>
        {{ strings.auth.passwordLabel }}
        <input v-model="form.password" name="password" required minlength="8" type="password" autocomplete="new-password" />
      </label>
      <label>
        {{ strings.auth.companyLabel }}
        <input v-model.trim="form.companyName" name="companyName" required />
      </label>
      <div class="form-grid">
        <label>
          {{ strings.auth.contactNameLabel }}
          <input v-model.trim="form.contactName" name="contactName" required autocomplete="name" />
        </label>
        <label>
          {{ strings.auth.contactPhoneLabel }}
          <input v-model.trim="form.contactPhone" name="contactPhone" required autocomplete="tel" />
        </label>
      </div>

      <p v-if="error" class="error" role="alert">{{ error }}</p>
      <button class="primary-action" :disabled="loading">
        {{ loading ? strings.auth.registerSubmitting : strings.auth.registerButton }}
      </button>
      <p class="auth-switch">
        {{ strings.auth.registerSwitchLabel }}
        <RouterLink to="/login">{{ strings.auth.registerSwitchAction }}</RouterLink>
      </p>
    </form>
  </main>
</template>
