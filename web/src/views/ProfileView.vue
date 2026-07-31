<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebProfileError, profileStringsForRegion } from '@/core/web_profile_localizations'
import { getBrowserDeviceId } from '@/lib/device-id'
import {
  applyCurrentUserExpertCertification,
  bindCurrentUserAccount,
  fetchCurrentUser,
  sendAuthCode,
  updateCurrentUserPassword,
  updateCurrentUserProfile,
} from '@/services/auth'

const { state, setCurrentUser } = useUserSession()
const { state: appState } = useAppContext()
const route = useRoute()
const copy = computed(() => profileStringsForRegion(appState.region))
const certificationCopy = computed(() => discoveryStringsForRegion(appState.region).shopCard)

const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const bindSending = ref(false)
const binding = ref(false)
const bindErrorMessage = ref('')
const bindSuccessMessage = ref('')
const bindCodeHint = ref('')
const browserDeviceId = getBrowserDeviceId()

const passwordSaving = ref(false)
const passwordErrorMessage = ref('')
const passwordSuccessMessage = ref('')
const expertApplying = ref(false)
const expertErrorMessage = ref('')
const expertSuccessMessage = ref('')
const expertBanner = computed(() => {
  const marker = String(route.query.expert || '')
  if (marker === 'approved') return copy.value.expertApprovedBanner
  if (marker === 'rejected') return copy.value.expertRejectedBanner
  return ''
})

const form = reactive({
  nickname: '',
  avatar: '',
  gender: 0,
  signature: '',
})

const expertForm = reactive({
  reason: '',
})

const bindForm = reactive({
  type: 'email' as 'email' | 'phone',
  account: '',
  code: '',
})

const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: '',
})

const bindTargetLabel = computed(() => (bindForm.type === 'email' ? copy.value.email : copy.value.phone))
const expertCertification = computed(() => state.currentUser?.expertCertification ?? null)
const expertStatusClass = computed(() => {
  const status = expertCertification.value?.status ?? 0
  if (status === 2) {
    return 'status-pill status-pill--good'
  }
  if (status === 3) {
    return 'status-pill status-pill--muted'
  }
  return 'status-pill status-pill--warn'
})
const expertButtonText = computed(() => {
  const status = expertCertification.value?.status ?? 0
  if (status === 1) {
    return copy.value.reviewing
  }
  if (status === 2) {
    return copy.value.certified
  }
  if (status === 3) {
    return copy.value.resubmitExpert
  }
  return copy.value.submitExpert
})
const passwordHint = computed(() => {
  if (state.currentUser?.hasPassword) {
    return copy.value.hasPasswordHint
  }
  return copy.value.noPasswordHint
})

function applyProfile() {
  if (!state.currentUser) {
    return
  }
  form.nickname = state.currentUser.nickname || ''
  form.avatar = state.currentUser.avatar || ''
  form.gender = state.currentUser.gender ?? 0
  form.signature = state.currentUser.signature || ''
  expertForm.reason = state.currentUser.expertCertification?.reason || ''
}

async function bootstrap() {
  loading.value = true
  errorMessage.value = ''

  try {
    const profile = await fetchCurrentUser()
    setCurrentUser(profile)
    applyProfile()
  } catch (error) {
    errorMessage.value = localizeWebProfileError(copy.value, error, copy.value.loadFailed)
  } finally {
    loading.value = false
  }
}

async function saveProfile() {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const profile = await updateCurrentUserProfile({
      nickname: form.nickname.trim(),
      avatar: form.avatar.trim(),
      gender: Number(form.gender),
      signature: form.signature.trim(),
    })
    setCurrentUser(profile)
    applyProfile()
    successMessage.value = copy.value.saved
  } catch (error) {
    errorMessage.value = localizeWebProfileError(copy.value, error, copy.value.saveFailed)
  } finally {
    saving.value = false
  }
}

async function sendBindCode() {
  const account = bindForm.account.trim()
  if (!account) {
    bindErrorMessage.value = copy.value.fillTarget(bindTargetLabel.value)
    bindSuccessMessage.value = ''
    return
  }

  bindSending.value = true
  bindErrorMessage.value = ''
  bindSuccessMessage.value = ''
  bindCodeHint.value = ''

  try {
    const response = await sendAuthCode({
      scene: 'bind',
      type: bindForm.type,
      account,
      deviceId: browserDeviceId,
    })
    bindSuccessMessage.value = copy.value.codeSent(bindTargetLabel.value, response.nextRetrySeconds)
    bindCodeHint.value = response.mockCode ? copy.value.mockCode(response.mockCode) : ''
  } catch (error) {
    bindErrorMessage.value = localizeWebProfileError(copy.value, error, copy.value.sendCodeFailed)
  } finally {
    bindSending.value = false
  }
}

async function submitBind() {
  const account = bindForm.account.trim()
  const code = bindForm.code.trim()
  if (!account || !code) {
    bindErrorMessage.value = copy.value.fillAccountAndCode(bindTargetLabel.value)
    bindSuccessMessage.value = ''
    return
  }

  binding.value = true
  bindErrorMessage.value = ''
  bindSuccessMessage.value = ''

  try {
    const profile = await bindCurrentUserAccount({
      type: bindForm.type,
      account,
      code,
    })
    setCurrentUser(profile)
    applyProfile()
    bindForm.code = ''
    bindCodeHint.value = ''
    bindSuccessMessage.value = copy.value.bound(bindTargetLabel.value)
  } catch (error) {
    bindErrorMessage.value = localizeWebProfileError(copy.value, error, copy.value.bindFailed)
  } finally {
    binding.value = false
  }
}

async function submitPassword() {
  const oldPassword = passwordForm.oldPassword.trim()
  const newPassword = passwordForm.newPassword.trim()
  const confirmPassword = passwordForm.confirmPassword.trim()

  if (!newPassword || !confirmPassword) {
    passwordErrorMessage.value = copy.value.passwordRequired
    passwordSuccessMessage.value = ''
    return
  }
  if (newPassword !== confirmPassword) {
    passwordErrorMessage.value = copy.value.passwordsMismatch
    passwordSuccessMessage.value = ''
    return
  }

  passwordSaving.value = true
  passwordErrorMessage.value = ''
  passwordSuccessMessage.value = ''

  try {
    await updateCurrentUserPassword({
      oldPassword: oldPassword || undefined,
      newPassword,
    })
    if (state.currentUser) {
      setCurrentUser({
        ...state.currentUser,
        hasPassword: true,
      })
    }
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
    passwordSuccessMessage.value = copy.value.passwordUpdated
  } catch (error) {
    passwordErrorMessage.value = localizeWebProfileError(copy.value, error, copy.value.passwordFailed)
  } finally {
    passwordSaving.value = false
  }
}

async function submitExpertCertification() {
  if (!state.currentUser) {
    return
  }

  const status = state.currentUser.expertCertification?.status ?? 0
  const reason = expertForm.reason.trim()
  if (status === 2) {
    expertErrorMessage.value = copy.value.expertAlreadyApproved
    expertSuccessMessage.value = ''
    return
  }
  if (status === 1) {
    expertErrorMessage.value = copy.value.expertPending
    expertSuccessMessage.value = ''
    return
  }
  if (!reason) {
    expertErrorMessage.value = copy.value.expertReasonRequired
    expertSuccessMessage.value = ''
    return
  }

  expertApplying.value = true
  expertErrorMessage.value = ''
  expertSuccessMessage.value = ''

  try {
    const certification = await applyCurrentUserExpertCertification({ reason })
    setCurrentUser({
      ...state.currentUser,
      expertCertification: certification,
    })
    expertForm.reason = certification.reason
    expertSuccessMessage.value = certification.status === 1
      ? copy.value.expertSubmitted
      : copy.value.expertUpdated
  } catch (error) {
    expertErrorMessage.value = localizeWebProfileError(copy.value, error, copy.value.expertFailed)
  } finally {
    expertApplying.value = false
  }
}

watch(
  () => appState.region,
  () => {
    successMessage.value = ''
    bindErrorMessage.value = ''
    bindSuccessMessage.value = ''
    passwordErrorMessage.value = ''
    passwordSuccessMessage.value = ''
    expertErrorMessage.value = ''
    expertSuccessMessage.value = ''
    void bootstrap()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--single">
      <div class="hero-panel__content">
        <p class="eyebrow">{{ copy.heroEyebrow }}</p>
        <h1>{{ copy.heroTitle }}</h1>
        <p class="hero-panel__summary">{{ copy.heroSummary }}</p>
      </div>
    </section>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>

    <template v-else-if="state.currentUser">
      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.basicProfile }}</p>
            <h2>{{ copy.basicProfileTitle }}</h2>
          </div>
        </div>

        <form class="review-form" @submit.prevent="saveProfile">
          <div class="field-row field-row--two">
            <label class="field">
              <span>{{ copy.nickname }}</span>
              <input v-model="form.nickname" type="text" maxlength="64" :placeholder="copy.nickname" />
            </label>
            <label class="field">
              <span>{{ copy.avatarUrl }}</span>
              <input v-model="form.avatar" type="text" maxlength="255" placeholder="https://..." />
            </label>
          </div>

          <div class="field-row field-row--two">
            <label class="field">
              <span>{{ copy.gender }}</span>
              <select v-model="form.gender">
                <option :value="0">{{ copy.genderUnknown }}</option>
                <option :value="1">{{ copy.genderMale }}</option>
                <option :value="2">{{ copy.genderFemale }}</option>
              </select>
            </label>
            <label class="field">
              <span>{{ copy.preferredRegion }}</span>
              <input :value="state.currentUser.preferredRegion" type="text" readonly />
            </label>
          </div>

          <label class="field field--full">
            <span>{{ copy.signature }}</span>
            <textarea v-model="form.signature" rows="4" maxlength="255" spellcheck="false" :placeholder="copy.signaturePlaceholder" />
          </label>

          <div class="profile-grid">
            <div class="hero-metric">
              <span>{{ copy.email }}</span>
              <strong>{{ state.currentUser.email || copy.unbound }}</strong>
            </div>
            <div class="hero-metric">
              <span>{{ copy.phone }}</span>
              <strong>{{ state.currentUser.phone || copy.unbound }}</strong>
            </div>
            <div class="hero-metric">
              <span>{{ copy.accountStats }}</span>
              <strong>{{ copy.stats(state.currentUser.level, state.currentUser.points, state.currentUser.growthValue) }}</strong>
            </div>
          </div>

          <div class="hero-actions">
            <button type="submit" class="primary-button" :disabled="saving">
              {{ saving ? copy.saving : copy.saveProfile }}
            </button>
            <RouterLink to="/user/growth-records" class="secondary-button">{{ copy.growthHistory }}</RouterLink>
            <RouterLink to="/user/privacy" class="secondary-button">{{ copy.privacyCenter }}</RouterLink>
          </div>
        </form>
      </section>

      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.accountSecurity }}</p>
            <h2>{{ copy.accountSecurityTitle }}</h2>
          </div>
        </div>

        <div class="stack-list">
          <article class="manage-card">
            <div class="manage-card__header">
              <div>
                <p class="eyebrow">{{ copy.accountBinding }}</p>
                <h3>{{ copy.accountBindingTitle }}</h3>
              </div>
            </div>

            <p v-if="bindErrorMessage" class="feedback is-error">{{ bindErrorMessage }}</p>
            <p v-if="bindSuccessMessage" class="feedback is-success">{{ bindSuccessMessage }}</p>
            <p v-if="bindCodeHint" class="feedback">{{ bindCodeHint }}</p>

            <form class="review-form" @submit.prevent="submitBind">
              <div class="field-row field-row--two">
                <label class="field">
                  <span>{{ copy.bindType }}</span>
                  <select v-model="bindForm.type">
                    <option value="email">{{ copy.email }}</option>
                    <option value="phone">{{ copy.phone }}</option>
                  </select>
                </label>
                <label class="field">
                  <span>{{ bindTargetLabel }}</span>
                  <input
                    v-model="bindForm.account"
                    type="text"
                    :placeholder="bindForm.type === 'email' ? 'user@example.com' : '+447700900123'"
                  />
                </label>
              </div>

              <div class="inline-field">
                <label class="field">
                  <span>{{ copy.verificationCode }}</span>
                  <input v-model="bindForm.code" type="text" :placeholder="copy.codePlaceholder" />
                </label>
                <button type="button" class="secondary-button" :disabled="bindSending" @click="sendBindCode">
                  {{ bindSending ? copy.sending : copy.sendCode }}
                </button>
              </div>

              <div class="hero-actions">
                <button type="submit" class="primary-button" :disabled="binding">
                  {{ binding ? copy.binding : copy.confirmBind }}
                </button>
              </div>
            </form>
          </article>

          <article class="manage-card">
            <div class="manage-card__header">
              <div>
                <p class="eyebrow">{{ copy.changePassword }}</p>
                <h3>{{ copy.changePasswordTitle }}</h3>
              </div>
            </div>

            <p class="support-copy">{{ passwordHint }}</p>
            <p v-if="passwordErrorMessage" class="feedback is-error">{{ passwordErrorMessage }}</p>
            <p v-if="passwordSuccessMessage" class="feedback is-success">{{ passwordSuccessMessage }}</p>

            <form class="review-form" @submit.prevent="submitPassword">
              <div class="field-row field-row--two">
                <label class="field">
                  <span>{{ copy.oldPassword }}</span>
                  <input v-model="passwordForm.oldPassword" type="password" :placeholder="copy.oldPasswordPlaceholder" />
                </label>
                <label class="field">
                  <span>{{ copy.newPassword }}</span>
                  <input v-model="passwordForm.newPassword" type="password" :placeholder="copy.newPasswordPlaceholder" />
                </label>
              </div>

              <label class="field">
                <span>{{ copy.confirmPassword }}</span>
                <input v-model="passwordForm.confirmPassword" type="password" :placeholder="copy.confirmPasswordPlaceholder" />
              </label>

              <div class="hero-actions">
                <button type="submit" class="primary-button" :disabled="passwordSaving">
                  {{ passwordSaving ? copy.saving : copy.updatePassword }}
                </button>
              </div>
            </form>
          </article>
        </div>
      </section>

      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.expertCertification }}</p>
            <h2>{{ copy.expertCertificationTitle }}</h2>
          </div>
        </div>

        <article class="manage-card">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow">{{ copy.currentStatus }}</p>
              <h3>{{ copy.currentStatusTitle }}</h3>
            </div>
            <span :class="expertStatusClass">{{ copy.expertStatus(expertCertification?.status ?? 0) }}</span>
          </div>

          <p v-if="expertBanner" class="feedback is-success" data-testid="expert-audit-banner">{{ expertBanner }}</p>
          <p v-if="expertErrorMessage" class="feedback is-error">{{ expertErrorMessage }}</p>
          <p v-if="expertSuccessMessage" class="feedback is-success">{{ expertSuccessMessage }}</p>

          <div class="profile-grid">
            <div class="hero-metric">
              <span>{{ copy.publicBadge }}</span>
              <strong v-if="expertCertification?.badge">
                <span class="verified-badge verified-badge--compact">
                  {{ certificationCopy.certificationLabel(expertCertification.badge.code, expertCertification.badge.label) }}
                </span>
              </strong>
              <strong v-else>{{ copy.badgeHidden }}</strong>
            </div>
            <div class="hero-metric">
              <span>{{ copy.submittedAt }}</span>
              <strong>{{ expertCertification?.submittedAt ? formatWebDateTime(expertCertification.submittedAt, copy.tag) : copy.notSubmitted }}</strong>
            </div>
            <div class="hero-metric">
              <span>{{ copy.reviewedAt }}</span>
              <strong>{{ expertCertification?.reviewedAt ? formatWebDateTime(expertCertification.reviewedAt, copy.tag) : copy.unavailable }}</strong>
            </div>
          </div>

          <p v-if="expertCertification?.rejectReason" class="feedback is-error">
            {{ copy.rejectReason }}: {{ expertCertification.rejectReason }}
          </p>

          <form class="review-form" @submit.prevent="submitExpertCertification">
            <label class="field field--full">
              <span>{{ copy.applicationReason }}</span>
              <textarea
                v-model="expertForm.reason"
                rows="5"
                maxlength="500"
                spellcheck="false"
                :placeholder="copy.reasonPlaceholder"
                :disabled="expertCertification?.status === 1 || expertCertification?.status === 2"
              />
            </label>
            <div class="hero-actions">
              <button
                type="submit"
                class="primary-button"
                :disabled="expertApplying || expertCertification?.status === 1 || expertCertification?.status === 2"
              >
                {{ expertApplying ? copy.submitting : expertButtonText }}
              </button>
            </div>
          </form>
        </article>
      </section>
    </template>
  </div>
</template>
