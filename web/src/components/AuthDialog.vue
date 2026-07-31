<script setup lang="ts">
import { Transition, computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { getBrowserDeviceId } from '@/lib/device-id'
import { ApiError } from '@/lib/http'
import {
  fetchCurrentUser,
  loginWithCode,
  loginWithPassword,
  queryBanAppeal,
  registerUser,
  resetPassword,
  sendAuthCode,
  submitBanAppeal,
} from '@/services/auth'
import type { AuthMode, AuthSessionResponse, UserBanAppealStatus } from '@/types/auth'
import {
  authStringsForRegion,
  localizeWebAuthError,
} from '@/core/web_auth_localizations'
import { formatWebDateTime } from '@/core/web_localizations'

const router = useRouter()
const { state: appState } = useAppContext()
const { state, closeAuthDialog, consumePendingAuthAction, setSession, setCurrentUser, clearSession, setAuthMode } =
  useUserSession()

const loading = ref(false)
const sendingCode = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const mockCodeHint = ref('')
const browserDeviceId = getBrowserDeviceId()

const passwordForm = reactive({
  account: '',
  password: '',
})

const codeForm = reactive({
  type: 'email' as 'email' | 'phone',
  account: '',
  code: '',
})

const registerForm = reactive({
  type: 'email' as 'email' | 'phone',
  account: '',
  code: '',
  password: '',
  nickname: '',
})

const resetForm = reactive({
  type: 'email' as 'email' | 'phone',
  account: '',
  code: '',
  newPassword: '',
})

const appealForm = reactive({
  type: 'email' as 'email' | 'phone',
  account: '',
  code: '',
  reason: '',
})

const appealStatus = ref<UserBanAppealStatus | null>(null)
const appealQuerying = ref(false)
const bannedAccount = ref('')
const auth = computed(() => authStringsForRegion(appState.region))
const accountTypeOptions = computed(() => auth.value.accountTypes)
const modeOptions = computed(() => auth.value.modes)

const panelTitle = computed(() => {
  return auth.value.panelTitles[state.authMode]
})

const panelSummary = computed(() => auth.value.panelSummary(Boolean(state.redirectTo)))

const activeModeMeta = computed(() => {
  if (state.authMode === 'appeal') {
    return auth.value.appealMode
  }
  return modeOptions.value.find((item) => item.mode === state.authMode) ?? modeOptions.value[0]
})

const activeModeIndex = computed(() => {
  const index = modeOptions.value.findIndex((item) => item.mode === state.authMode)
  return index >= 0 ? index + 1 : 1
})

const stageHeadline = computed(() => auth.value.stageHeadline(Boolean(state.redirectTo)))
const stageSummary = computed(() => auth.value.stageSummary(state.redirectTo ?? null))
const resumeFacts = computed(() => auth.value.resumeFacts(
  state.redirectTo ?? null,
  appState.region,
  browserDeviceId.slice(0, 8).toUpperCase(),
))
const servicePromises = computed(() => auth.value.servicePromises(Boolean(state.redirectTo), appState.region))
const stageFacts = computed(() => auth.value.stageFacts(
  activeModeMeta.value.label,
  state.redirectTo ?? null,
  appState.region,
))
const secondaryModeLinks = computed(() => modeOptions.value.filter((item) => item.mode !== state.authMode))

watch(
  () => state.authDialogOpen,
  (open) => {
    if (open) {
      errorMessage.value = ''
      successMessage.value = ''
      mockCodeHint.value = ''
      bannedAccount.value = ''
      appealStatus.value = null
    }
  },
)

function formatModeIndex(value: number) {
  return String(value).padStart(2, '0')
}

function switchMode(mode: AuthMode) {
  setAuthMode(mode)
  errorMessage.value = ''
  successMessage.value = ''
  mockCodeHint.value = ''
  if (mode !== 'appeal') {
    bannedAccount.value = ''
    appealStatus.value = null
  }
}

function inferAccountType(account: string): 'email' | 'phone' {
  return account.includes('@') ? 'email' : 'phone'
}

function handleBannedLogin(account: string) {
  bannedAccount.value = account
  appealStatus.value = null
}

function openAppealFromBan() {
  appealForm.account = bannedAccount.value
  appealForm.type = inferAccountType(bannedAccount.value)
  appealForm.code = ''
  appealForm.reason = ''
  switchMode('appeal')
}

function resolveCodePayload(targetMode: 'code' | 'register' | 'reset' | 'appeal') {
  if (targetMode === 'register') {
    return {
      scene: 'register' as const,
      type: registerForm.type,
      account: registerForm.account.trim(),
      deviceId: browserDeviceId,
    }
  }

  if (targetMode === 'reset') {
    return {
      scene: 'reset' as const,
      type: resetForm.type,
      account: resetForm.account.trim(),
      deviceId: browserDeviceId,
    }
  }

  if (targetMode === 'appeal') {
    return {
      scene: 'appeal' as const,
      type: appealForm.type,
      account: appealForm.account.trim(),
      deviceId: browserDeviceId,
    }
  }

  return {
    scene: 'login' as const,
    type: codeForm.type,
    account: codeForm.account.trim(),
    deviceId: browserDeviceId,
  }
}

async function handleSendCode(targetMode: 'code' | 'register' | 'reset' | 'appeal') {
  const payload = resolveCodePayload(targetMode)
  if (!payload.account) {
    errorMessage.value = auth.value.text.codeAccountRequired
    return
  }

  sendingCode.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await sendAuthCode(payload)
    successMessage.value = auth.value.codeSent(response.nextRetrySeconds)
    mockCodeHint.value = response.mockCode ? auth.value.mockCode(response.mockCode) : ''
  } catch (error) {
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.sendCodeFailed)
  } finally {
    sendingCode.value = false
  }
}

async function completeAuth(session: AuthSessionResponse) {
  const redirectTo = state.redirectTo
  const pendingAction = consumePendingAuthAction()
  setSession(session)

  try {
    const currentUser = await fetchCurrentUser()
    setCurrentUser(currentUser)
  } catch (error) {
    clearSession()
    throw error
  }

  closeAuthDialog()
  if (redirectTo) {
    await router.push(redirectTo)
  }
  if (pendingAction) {
    await pendingAction()
  }
}

async function submitPasswordLogin() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const session = await loginWithPassword({
      account: passwordForm.account.trim(),
      password: passwordForm.password,
    })
    await completeAuth(session)
  } catch (error) {
    if (error instanceof ApiError && error.messageKey === 'auth.user_banned') {
      handleBannedLogin(passwordForm.account.trim())
    }
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.passwordLoginFailed)
  } finally {
    loading.value = false
  }
}

async function submitCodeLogin() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const session = await loginWithCode({
      type: codeForm.type,
      account: codeForm.account.trim(),
      code: codeForm.code.trim(),
      preferredRegion: appState.region,
    })
    await completeAuth(session)
  } catch (error) {
    if (error instanceof ApiError && error.messageKey === 'auth.user_banned') {
      handleBannedLogin(codeForm.account.trim())
    }
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.codeLoginFailed)
  } finally {
    loading.value = false
  }
}

async function submitRegister() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const session = await registerUser({
      type: registerForm.type,
      account: registerForm.account.trim(),
      code: registerForm.code.trim(),
      password: registerForm.password,
      nickname: registerForm.nickname.trim() || undefined,
      preferredRegion: appState.region,
    })
    await completeAuth(session)
  } catch (error) {
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.registerFailed)
  } finally {
    loading.value = false
  }
}

async function submitResetPassword() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await resetPassword({
      type: resetForm.type,
      account: resetForm.account.trim(),
      code: resetForm.code.trim(),
      newPassword: resetForm.newPassword,
    })
    passwordForm.account = resetForm.account.trim()
    passwordForm.password = ''
    switchMode('password')
    successMessage.value = auth.value.text.passwordResetSuccess
  } catch (error) {
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.passwordResetFailed)
  } finally {
    loading.value = false
  }
}

async function submitAppeal() {
  const account = appealForm.account.trim()
  const code = appealForm.code.trim()
  const reason = appealForm.reason.trim()
  if (!account || !code) {
    errorMessage.value = auth.value.text.appealCredentialsRequired
    return
  }
  if (reason.length < 10) {
    errorMessage.value = auth.value.text.appealReasonTooShort
    return
  }

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    appealStatus.value = await submitBanAppeal({
      type: appealForm.type,
      account,
      code,
      reason,
    })
    appealForm.code = ''
    appealForm.reason = ''
    successMessage.value = auth.value.appealSubmitted(appealStatus.value.id)
  } catch (error) {
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.appealSubmitFailed)
  } finally {
    loading.value = false
  }
}

async function queryAppealProgress() {
  const account = appealForm.account.trim()
  const code = appealForm.code.trim()
  if (!account || !code) {
    errorMessage.value = auth.value.text.appealQueryCredentialsRequired
    return
  }

  appealQuerying.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    appealStatus.value = await queryBanAppeal({
      type: appealForm.type,
      account,
      code,
    })
    appealForm.code = ''
    successMessage.value = auth.value.appealRefreshed(appealStatus.value.id)
  } catch (error) {
    errorMessage.value = localizeWebAuthError(auth.value, error, auth.value.text.appealQueryFailed)
  } finally {
    appealQuerying.value = false
  }
}

function backToPasswordLogin() {
  passwordForm.account = appealForm.account.trim()
  passwordForm.password = ''
  switchMode('password')
  successMessage.value = auth.value.text.accountUnbanned
}
</script>

<template>
  <Teleport to="body">
    <div v-if="state.authDialogOpen" class="auth-dialog-backdrop" @click.self="closeAuthDialog">
      <section class="auth-dialog">
        <button type="button" class="auth-dialog__close" @click="closeAuthDialog">×</button>

        <div class="auth-dialog__layout">
          <aside class="auth-rail">
            <div class="auth-rail__top">
              <div class="auth-rail__brand">
                <span class="auth-rail__mark">{{ auth.text.brandMark }}</span>
                <div class="auth-rail__copy">
                  <p class="eyebrow">{{ auth.text.brandEyebrow }}</p>
                  <strong>{{ auth.text.brandTitle }}</strong>
                </div>
              </div>
              <span class="auth-rail__signal">{{ auth.text.signal }}</span>
            </div>

            <div class="auth-dialog__hero">
              <p class="eyebrow">{{ auth.text.userCenter }} · {{ appState.region }}</p>
              <h2>{{ panelTitle }}</h2>
              <p>{{ panelSummary }}</p>
            </div>

            <article class="auth-resume-card" :class="{ 'is-redirected': !!state.redirectTo }">
              <div class="auth-resume-card__header">
                <span class="auth-resume-card__tag">{{ state.redirectTo ? auth.text.resumeTagRedirect : auth.text.resumeTagDefault }}</span>
                <strong>{{ state.redirectTo ? auth.text.resumeTitleRedirect : auth.text.resumeTitleDefault }}</strong>
              </div>
              <p>{{ stageSummary }}</p>

              <div class="auth-resume-meta">
                <div v-for="fact in resumeFacts" :key="fact.label" class="auth-resume-meta__item">
                  <span>{{ fact.label }}</span>
                  <strong>{{ fact.value }}</strong>
                </div>
              </div>
            </article>

            <div class="auth-method-rail">
              <button
                v-for="(item, index) in modeOptions"
                :key="item.mode"
                type="button"
                class="auth-method-option"
                :class="{ 'is-active': state.authMode === item.mode }"
                @click="switchMode(item.mode)"
              >
                <span class="auth-method-option__index">{{ formatModeIndex(index + 1) }}</span>
                <div class="auth-method-option__body">
                  <span class="auth-method-option__eyebrow">{{ item.eyebrow }}</span>
                  <strong>{{ item.label }}</strong>
                  <small>{{ item.detail }}</small>
                </div>
                <span class="auth-method-option__arrow" aria-hidden="true">→</span>
              </button>
            </div>

            <div class="auth-service-grid">
              <article v-for="item in servicePromises" :key="item.title" class="auth-service-card">
                <strong>{{ item.title }}</strong>
                <p>{{ item.detail }}</p>
              </article>
            </div>
          </aside>

          <div class="auth-stage">
            <div class="auth-stage__chrome">
              <div class="auth-stage__header">
                <p class="eyebrow">{{ activeModeMeta.eyebrow }}</p>
                <h3>{{ activeModeMeta.label }}</h3>
                <p>{{ activeModeMeta.detail }}</p>
              </div>
              <div class="auth-stage__counter">
                <strong>{{ formatModeIndex(activeModeIndex) }}</strong>
                <span>/ 04</span>
              </div>
            </div>

            <div class="auth-stage__banner">
              <div class="auth-stage__banner-copy">
                <span class="auth-stage__banner-tag">{{ state.redirectTo ? auth.text.bannerTagRedirect : auth.text.bannerTagDefault }}</span>
                <strong>{{ stageHeadline }}</strong>
                <p>{{ activeModeMeta.footer }}</p>
              </div>

              <div class="auth-stage__facts">
                <article v-for="fact in stageFacts" :key="fact.label" class="auth-stage__fact">
                  <span>{{ fact.label }}</span>
                  <strong>{{ fact.value }}</strong>
                </article>
              </div>
            </div>

            <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
            <div v-if="bannedAccount && state.authMode !== 'appeal'" class="auth-ban-appeal-cta">
              <p>{{ auth.bannedDescription(bannedAccount) }}</p>
              <button type="button" class="secondary-button" @click="openAppealFromBan">{{ auth.text.bannedAction }}</button>
            </div>
            <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
            <p v-if="mockCodeHint" class="feedback">{{ mockCodeHint }}</p>

            <div class="auth-stage__body">
              <Transition name="auth-mode" mode="out-in">
                <form
                  v-if="state.authMode === 'password'"
                  key="password"
                  class="auth-grid"
                  @submit.prevent="submitPasswordLogin"
                >
                  <label class="field">
                    <span>{{ auth.text.accountOrPhoneLabel }}</span>
                    <input v-model="passwordForm.account" type="text" :placeholder="auth.text.accountPlaceholder" />
                  </label>
                  <label class="field">
                    <span>{{ auth.text.passwordLabel }}</span>
                    <input v-model="passwordForm.password" type="password" :placeholder="auth.text.passwordPlaceholder" />
                  </label>
                  <p class="support-copy auth-support-copy">
                    {{ auth.text.passwordSupport }}
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? auth.text.signingIn : auth.text.signIn }}
                  </button>
                </form>

                <form
                  v-else-if="state.authMode === 'code'"
                  key="code"
                  class="auth-grid"
                  @submit.prevent="submitCodeLogin"
                >
                  <div class="field">
                    <span>{{ auth.text.accountTypeLabel }}</span>
                    <div class="mode-type-switch" role="group" :aria-label="auth.text.accountTypeLabel">
                      <button
                        v-for="option in accountTypeOptions"
                        :key="`code-${option.value}`"
                        type="button"
                        class="mode-type-switch__button"
                        :class="{ 'is-active': codeForm.type === option.value }"
                        :aria-pressed="codeForm.type === option.value"
                        @click="codeForm.type = option.value"
                      >
                        {{ option.label }}
                      </button>
                    </div>
                  </div>
                  <label class="field">
                    <span>{{ auth.text.accountLabel }}</span>
                    <input v-model="codeForm.account" type="text" :placeholder="auth.text.codeAccountPlaceholder" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>{{ auth.text.verificationCodeLabel }}</span>
                      <input v-model="codeForm.code" type="text" :placeholder="auth.text.verificationCodePlaceholder" />
                    </label>
                    <button type="button" class="secondary-button" :disabled="sendingCode" @click="handleSendCode('code')">
                      {{ sendingCode ? auth.text.sending : auth.text.sendCode }}
                    </button>
                  </div>
                  <p class="support-copy auth-support-copy">
                    {{ auth.text.codeSupport }}
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? auth.text.signingIn : auth.text.codeSignIn }}
                  </button>
                </form>

                <form
                  v-else-if="state.authMode === 'register'"
                  key="register"
                  class="auth-grid"
                  @submit.prevent="submitRegister"
                >
                  <div class="field">
                    <span>{{ auth.text.accountTypeLabel }}</span>
                    <div class="mode-type-switch" role="group" :aria-label="auth.text.accountTypeLabel">
                      <button
                        v-for="option in accountTypeOptions"
                        :key="`register-${option.value}`"
                        type="button"
                        class="mode-type-switch__button"
                        :class="{ 'is-active': registerForm.type === option.value }"
                        :aria-pressed="registerForm.type === option.value"
                        @click="registerForm.type = option.value"
                      >
                        {{ option.label }}
                      </button>
                    </div>
                  </div>
                  <label class="field">
                    <span>{{ auth.text.accountLabel }}</span>
                    <input v-model="registerForm.account" type="text" :placeholder="auth.text.registerAccountPlaceholder" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>{{ auth.text.verificationCodeLabel }}</span>
                      <input v-model="registerForm.code" type="text" :placeholder="auth.text.verificationCodePlaceholder" />
                    </label>
                    <button
                      type="button"
                      class="secondary-button"
                      :disabled="sendingCode"
                      @click="handleSendCode('register')"
                    >
                      {{ sendingCode ? auth.text.sending : auth.text.sendCode }}
                    </button>
                  </div>
                  <label class="field">
                    <span>{{ auth.text.nicknameLabel }}</span>
                    <input v-model="registerForm.nickname" type="text" :placeholder="auth.text.nicknamePlaceholder" />
                  </label>
                  <label class="field">
                    <span>{{ auth.text.passwordLabel }}</span>
                    <input v-model="registerForm.password" type="password" :placeholder="auth.text.registerPasswordPlaceholder" />
                  </label>
                  <p class="support-copy auth-support-copy">
                    {{ auth.text.registerSupport }}
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? auth.text.registering : auth.text.registerAndSignIn }}
                  </button>
                </form>

                <form
                  v-else-if="state.authMode === 'reset'"
                  key="reset"
                  class="auth-grid"
                  @submit.prevent="submitResetPassword"
                >
                  <div class="field">
                    <span>{{ auth.text.accountTypeLabel }}</span>
                    <div class="mode-type-switch" role="group" :aria-label="auth.text.accountTypeLabel">
                      <button
                        v-for="option in accountTypeOptions"
                        :key="`reset-${option.value}`"
                        type="button"
                        class="mode-type-switch__button"
                        :class="{ 'is-active': resetForm.type === option.value }"
                        :aria-pressed="resetForm.type === option.value"
                        @click="resetForm.type = option.value"
                      >
                        {{ option.label }}
                      </button>
                    </div>
                  </div>
                  <label class="field">
                    <span>{{ auth.text.accountLabel }}</span>
                    <input v-model="resetForm.account" type="text" :placeholder="auth.text.resetAccountPlaceholder" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>{{ auth.text.verificationCodeLabel }}</span>
                      <input v-model="resetForm.code" type="text" :placeholder="auth.text.verificationCodePlaceholder" />
                    </label>
                    <button type="button" class="secondary-button" :disabled="sendingCode" @click="handleSendCode('reset')">
                      {{ sendingCode ? auth.text.sending : auth.text.sendCode }}
                    </button>
                  </div>
                  <label class="field">
                    <span>{{ auth.text.newPasswordLabel }}</span>
                    <input v-model="resetForm.newPassword" type="password" :placeholder="auth.text.newPasswordPlaceholder" />
                  </label>
                  <p class="support-copy auth-support-copy">
                    {{ auth.text.resetSupport }}
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? auth.text.resetting : auth.text.resetPassword }}
                  </button>
                </form>

                <form
                  v-else
                  key="appeal"
                  class="auth-grid"
                  @submit.prevent="submitAppeal"
                >
                  <div class="field">
                    <span>{{ auth.text.accountTypeLabel }}</span>
                    <div class="mode-type-switch" role="group" :aria-label="auth.text.accountTypeLabel">
                      <button
                        v-for="option in accountTypeOptions"
                        :key="`appeal-${option.value}`"
                        type="button"
                        class="mode-type-switch__button"
                        :class="{ 'is-active': appealForm.type === option.value }"
                        :aria-pressed="appealForm.type === option.value"
                        @click="appealForm.type = option.value"
                      >
                        {{ option.label }}
                      </button>
                    </div>
                  </div>
                  <label class="field">
                    <span>{{ auth.text.bannedAccountLabel }}</span>
                    <input v-model="appealForm.account" type="text" :placeholder="auth.text.bannedAccountPlaceholder" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>{{ auth.text.verificationCodeLabel }}</span>
                      <input v-model="appealForm.code" type="text" :placeholder="auth.text.verificationCodePlaceholder" />
                    </label>
                    <button type="button" class="secondary-button" :disabled="sendingCode" @click="handleSendCode('appeal')">
                      {{ sendingCode ? auth.text.sending : auth.text.sendCode }}
                    </button>
                  </div>
                  <label class="field field--full">
                    <span>{{ auth.text.appealReasonLabel }}</span>
                    <textarea
                      v-model="appealForm.reason"
                      rows="4"
                      :placeholder="auth.text.appealReasonPlaceholder"
                    />
                  </label>
                  <div v-if="appealStatus" class="appeal-status-card" data-testid="appeal-status">
                    <div class="appeal-status-card__header">
                      <strong>{{ auth.text.appealLabel }} #{{ appealStatus.id }}</strong>
                      <span
                        class="appeal-status-card__state"
                        :class="{
                          'is-approved': appealStatus.status === 1,
                          'is-rejected': appealStatus.status === 2,
                        }"
                      >
                        {{ auth.appealStatusLabel(appealStatus.status, appealStatus.statusText) }}
                      </span>
                    </div>
                    <p v-if="appealStatus.banReason">{{ auth.text.banReasonLabel }}{{ appealStatus.banReason }}</p>
                    <p v-if="appealStatus.reason">{{ auth.text.appealReasonDisplayLabel }}{{ appealStatus.reason }}</p>
                    <p v-if="appealStatus.status === 2 && appealStatus.rejectReason">
                      {{ auth.text.rejectReasonLabel }}{{ appealStatus.rejectReason }}
                    </p>
                    <p v-if="appealStatus.status === 1">{{ auth.text.appealApproved }}</p>
                    <button
                      v-if="appealStatus.status === 1"
                      type="button"
                      class="secondary-button"
                      @click="backToPasswordLogin"
                    >
                      {{ auth.text.backToPassword }}
                    </button>
                    <div class="appeal-status-card__meta">
                      <span>{{ auth.text.submittedAtLabel }} {{ appealStatus.submittedAt ? formatWebDateTime(appealStatus.submittedAt, auth.tag) : '--' }}</span>
                      <span v-if="appealStatus.auditedAt">{{ auth.text.reviewedAtLabel }} {{ formatWebDateTime(appealStatus.auditedAt, auth.tag) }}</span>
                    </div>
                  </div>
                  <p class="support-copy auth-support-copy">
                    {{ auth.text.appealSupport }}
                  </p>
                  <div class="appeal-actions">
                    <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                      {{ loading ? auth.text.submitting : auth.text.submitAppeal }}
                    </button>
                    <button
                      type="button"
                      class="ghost-button"
                      :disabled="appealQuerying"
                      @click="queryAppealProgress"
                    >
                      {{ appealQuerying ? auth.text.querying : auth.text.queryAppeal }}
                    </button>
                  </div>
                </form>
              </Transition>
            </div>

            <div class="auth-stage__footer">
              <span>{{ activeModeMeta.footer }}</span>
              <div class="auth-stage__switches">
                <button
                  v-for="item in secondaryModeLinks"
                  :key="item.mode"
                  type="button"
                  class="ghost-button"
                  @click="switchMode(item.mode)"
                >
                  {{ item.label }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  </Teleport>
</template>
