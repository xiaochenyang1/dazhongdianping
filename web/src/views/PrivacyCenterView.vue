<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebPrivacyError, privacyStringsForRegion } from '@/core/web_privacy_localizations'
import { getBrowserDeviceId } from '@/lib/device-id'
import { sendAuthCode } from '@/services/auth'
import {
  acceptPrivacyPolicy,
  cancelPrivacyDeleteTask,
  createPrivacyDeleteTask,
  createPrivacyExportTask,
  downloadPrivacyExport,
  fetchPrivacyExportTasks,
  fetchPrivacyOverview,
  fetchPrivacyPolicyLogs,
  fetchUserDevices,
  logoutUserDevice,
} from '@/services/privacy'
import type {
  PrivacyExportModule,
  PrivacyExportTask,
  PrivacyOverview,
  PrivacyPolicyAcceptLog,
  UserDevice,
} from '@/types/privacy'

const { state } = useUserSession()
const { state: appState } = useAppContext()
const copy = computed(() => privacyStringsForRegion(appState.region))

const loading = ref(false)
const exportCreating = ref(false)
const downloadingTaskId = ref<number>()
const deleteCodeSending = ref(false)
const deleteSubmitting = ref(false)
const deleteCancelling = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const codeHint = ref('')
const overview = ref<PrivacyOverview>()
const exportTasks = ref<PrivacyExportTask[]>([])
const policyLogs = ref<PrivacyPolicyAcceptLog[]>([])
const userDevices = ref<UserDevice[]>([])
const acceptingPolicyType = ref<number>()
const loggingOutDeviceId = ref<number>()
const browserDeviceId = getBrowserDeviceId()

const exportModules = reactive<Record<PrivacyExportModule, boolean>>({
  account: true,
  reviews: true,
  orders: true,
  posts: true,
  reservations: true,
  favorites: true,
  browse_history: true,
  follows: true,
  messages: true,
  circles: true,
  topics: true,
})

const deleteForm = reactive({
  verifyType: 'code' as 'code' | 'password',
  account: state.currentUser?.email || state.currentUser?.phone || '',
  verifyCode: '',
  password: '',
  reason: '',
})

const selectedExportModules = computed(() =>
  (Object.entries(exportModules) as Array<[PrivacyExportModule, boolean]>)
    .filter(([, selected]) => selected)
    .map(([module]) => module),
)
const exportModuleOptions = computed(() =>
  (Object.keys(exportModules) as PrivacyExportModule[]).map((module) => ({ module, ...copy.value.modules[module] })),
)
const latestDeleteTask = computed(() => overview.value?.latestDeleteTask)
const canCancelDeleteTask = computed(() => latestDeleteTask.value?.status === 1)
const deleteAccountType = computed<'email' | 'phone'>(() =>
  deleteForm.account.includes('@') ? 'email' : 'phone',
)

async function loadPrivacyData() {
  const [nextOverview, taskPage, nextPolicyLogs, nextDevices] = await Promise.all([
    fetchPrivacyOverview(),
    fetchPrivacyExportTasks({ page: 1, pageSize: 10 }),
    fetchPrivacyPolicyLogs(),
    fetchUserDevices(),
  ])
  overview.value = nextOverview
  exportTasks.value = taskPage.list
  policyLogs.value = nextPolicyLogs
  userDevices.value = nextDevices

  if (!deleteForm.account) {
    deleteForm.account = state.currentUser?.email || state.currentUser?.phone || ''
  }
}

async function acceptPolicy(policyType: 1 | 2) {
  acceptingPolicyType.value = policyType
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await acceptPrivacyPolicy({
      policyType,
      version: '2026.07',
      locale: copy.value.tag,
      source: 3,
    })
    await loadPrivacyData()
    successMessage.value = copy.value.policyAccepted
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.policyFailed)
  } finally {
    acceptingPolicyType.value = undefined
  }
}

async function logoutDevice(deviceId: number) {
  loggingOutDeviceId.value = deviceId
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await logoutUserDevice(deviceId)
    await loadPrivacyData()
    successMessage.value = copy.value.deviceDeactivated
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.deviceFailed)
  } finally {
    loggingOutDeviceId.value = undefined
  }
}

function policyName(policyType: number) {
  return copy.value.policyName(policyType)
}

function platformName(platform: number) {
  return copy.value.platformName(platform)
}

function deviceStatusText(status: number) {
  return copy.value.deviceStatus(status)
}

async function bootstrap() {
  loading.value = true
  errorMessage.value = ''
  try {
    await loadPrivacyData()
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.loadFailed)
  } finally {
    loading.value = false
  }
}

async function submitExportTask() {
  if (selectedExportModules.value.length === 0) {
    errorMessage.value = copy.value.selectModule
    successMessage.value = ''
    return
  }

  exportCreating.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await createPrivacyExportTask({
      modules: selectedExportModules.value,
      format: 'zip',
    })
    await loadPrivacyData()
    successMessage.value = copy.value.exportCreated
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.exportFailed)
  } finally {
    exportCreating.value = false
  }
}

async function downloadTask(task: PrivacyExportTask) {
  downloadingTaskId.value = task.id
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const blob = await downloadPrivacyExport(task.id)
    const objectUrl = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    anchor.href = objectUrl
    anchor.download = `privacy-export-${task.id}.zip`
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(objectUrl)
    successMessage.value = copy.value.downloadStarted(task.id)
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.downloadFailed)
  } finally {
    downloadingTaskId.value = undefined
  }
}

async function sendDeleteCode() {
  if (!deleteForm.account.trim()) {
    errorMessage.value = copy.value.accountRequired
    successMessage.value = ''
    return
  }

  deleteCodeSending.value = true
  errorMessage.value = ''
  successMessage.value = ''
  codeHint.value = ''
  try {
    const response = await sendAuthCode({
      scene: 'delete',
      type: deleteAccountType.value,
      account: deleteForm.account.trim(),
      deviceId: browserDeviceId,
    })
    successMessage.value = copy.value.deleteCodeSent(response.nextRetrySeconds)
    codeHint.value = response.mockCode ? copy.value.mockCode(response.mockCode) : ''
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.deleteCodeFailed)
  } finally {
    deleteCodeSending.value = false
  }
}

async function submitDeleteTask() {
  const reason = deleteForm.reason.trim()
  const account = deleteForm.account.trim()
  if (!account || !reason) {
    errorMessage.value = copy.value.accountReasonRequired
    successMessage.value = ''
    return
  }

  if (deleteForm.verifyType === 'code' && !deleteForm.verifyCode.trim()) {
    errorMessage.value = copy.value.codeRequired
    successMessage.value = ''
    return
  }
  if (deleteForm.verifyType === 'password' && !deleteForm.password.trim()) {
    errorMessage.value = copy.value.passwordRequired
    successMessage.value = ''
    return
  }

  deleteSubmitting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await createPrivacyDeleteTask({
      verifyType: deleteForm.verifyType,
      account,
      verifyCode: deleteForm.verifyType === 'code' ? deleteForm.verifyCode.trim() : undefined,
      password: deleteForm.verifyType === 'password' ? deleteForm.password.trim() : undefined,
      reason,
    })
    await loadPrivacyData()
    deleteForm.verifyCode = ''
    deleteForm.password = ''
    codeHint.value = ''
    successMessage.value = copy.value.deleteSubmitted
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.deleteSubmitFailed)
  } finally {
    deleteSubmitting.value = false
  }
}

async function cancelDeleteTask() {
  const taskId = latestDeleteTask.value?.id
  if (!taskId) {
    return
  }

  deleteCancelling.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await cancelPrivacyDeleteTask(taskId)
    await loadPrivacyData()
    successMessage.value = copy.value.deleteCancelled
  } catch (error) {
    errorMessage.value = localizeWebPrivacyError(copy.value, error, copy.value.deleteCancelFailed)
  } finally {
    deleteCancelling.value = false
  }
}

watch(
  () => appState.region,
  () => {
    successMessage.value = ''
    codeHint.value = ''
    void bootstrap()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack privacy-center">
    <section class="hero-panel hero-panel--compact privacy-hero">
      <div class="hero-panel__content">
        <p class="eyebrow">{{ copy.heroEyebrow }}</p>
        <h1>{{ copy.heroTitle }}</h1>
        <p class="hero-panel__summary">{{ copy.heroSummary }}</p>
      </div>
      <div class="hero-panel__side privacy-rule-grid">
        <div class="hero-metric">
          <span>{{ copy.dataExport }}</span>
          <strong class="tabular-numbers">{{ copy.dailyLimit(overview?.exportRule.dailyLimit ?? copy.unavailable) }}</strong>
          <p class="tabular-numbers">{{ copy.retention(overview?.exportRule.expireHours ?? copy.unavailable) }}</p>
        </div>
        <div class="hero-metric privacy-hero__delete-rule">
          <span>{{ copy.accountDeletion }}</span>
          <strong class="tabular-numbers">{{ copy.coolingOff(overview?.deleteRule.coolingOffDays ?? copy.unavailable) }}</strong>
          <p>{{ copy.deleteRule }}</p>
        </div>
      </div>
    </section>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="codeHint" class="feedback">{{ codeHint }}</p>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>

    <template v-else>
      <section class="content-section privacy-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.dataExport }}</p>
            <h2>{{ copy.exportTitle }}</h2>
          </div>
          <span class="status-pill status-pill--good">{{ copy.authenticatedDownload }}</span>
        </div>

        <div class="privacy-export-layout">
          <form class="privacy-module-picker" @submit.prevent="submitExportTask">
            <label v-for="option in exportModuleOptions" :key="option.module" class="privacy-module-card">
              <input v-model="exportModules[option.module]" type="checkbox" />
              <span>
                <strong>{{ option.label }}</strong>
                <small>{{ option.description }}</small>
              </span>
            </label>
            <button type="submit" class="primary-button" :disabled="exportCreating">
              {{ exportCreating ? copy.creating : copy.createExport }}
            </button>
          </form>

          <div class="privacy-task-list">
            <article v-for="task in exportTasks" :key="task.id" class="manage-card privacy-task-card">
              <div class="manage-card__header">
                <div>
                  <p class="eyebrow tabular-numbers">{{ copy.task(task.id) }}</p>
                  <h3>{{ task.modules.map((module) => copy.modules[module].label).join(' / ') || copy.unspecifiedModules }}</h3>
                </div>
                <span class="status-pill" :class="task.status === 2 ? 'status-pill--good' : 'status-pill--warn'">
                  {{ copy.exportStatus(task.status) }}
                </span>
              </div>
              <p class="support-copy tabular-numbers">
                {{ copy.createdAt }} {{ formatWebDateTime(task.createdAt, copy.tag) }} · {{ copy.expiresAt }}
                {{ task.expireAt ? formatWebDateTime(task.expireAt, copy.tag) : copy.unavailable }}
              </p>
              <p v-if="task.failReason" class="feedback is-error">{{ task.failReason }}</p>
              <div class="manage-card__footer">
                <span>{{ copy.format }}: {{ task.format.toUpperCase() }}</span>
                <button
                  v-if="task.status === 2 && task.downloadUrl"
                  type="button"
                  class="secondary-button"
                  :disabled="downloadingTaskId === task.id"
                  @click="downloadTask(task)"
                >
                  {{ downloadingTaskId === task.id ? copy.downloading : copy.downloadZip }}
                </button>
              </div>
            </article>
            <p v-if="exportTasks.length === 0" class="feedback">{{ copy.noExports }}</p>
          </div>
        </div>
      </section>

      <section class="content-section privacy-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.agreements }}</p>
            <h2>{{ copy.agreementsTitle }}</h2>
          </div>
          <span class="status-pill status-pill--good">{{ copy.traceable }}</span>
        </div>
        <div class="hero-actions">
          <button type="button" class="secondary-button" :disabled="acceptingPolicyType !== undefined" @click="acceptPolicy(1)">
            {{ acceptingPolicyType === 1 ? copy.recording : copy.confirmPrivacy }}
          </button>
          <button type="button" class="secondary-button" :disabled="acceptingPolicyType !== undefined" @click="acceptPolicy(2)">
            {{ acceptingPolicyType === 2 ? copy.recording : copy.confirmAgreement }}
          </button>
        </div>
        <div class="privacy-task-list">
          <article v-for="log in policyLogs" :key="log.id" class="manage-card">
            <div class="manage-card__header">
              <h3>{{ policyName(log.policyType) }} · {{ log.version }}</h3>
              <span class="status-pill status-pill--muted">{{ log.locale }}</span>
            </div>
            <p class="support-copy tabular-numbers">
              {{ formatWebDateTime(log.acceptedAt, copy.tag) }} · {{ log.userAgent || copy.unknownClient }}
            </p>
          </article>
          <p v-if="policyLogs.length === 0" class="feedback">{{ copy.noAgreements }}</p>
        </div>
      </section>

      <section class="content-section privacy-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.devices }}</p>
            <h2>{{ copy.devicesTitle }}</h2>
          </div>
          <span class="status-pill status-pill--warn">{{ copy.proactiveDeactivate }}</span>
        </div>
        <div class="privacy-task-list">
          <article v-for="device in userDevices" :key="device.id" class="manage-card">
            <div class="manage-card__header">
              <div>
                <h3>{{ platformName(device.platform) }} · {{ device.appVersion }}</h3>
                <p class="support-copy">{{ device.deviceUid }}</p>
              </div>
              <span class="status-pill" :class="device.status === 1 ? 'status-pill--good' : 'status-pill--muted'">
                {{ deviceStatusText(device.status) }}
              </span>
            </div>
            <div class="manage-card__footer">
              <span class="tabular-numbers">
                {{ copy.lastActive }} {{ device.lastActiveAt ? formatWebDateTime(device.lastActiveAt, copy.tag) : copy.unavailable }}
              </span>
              <button
                v-if="device.status === 1"
                type="button"
                class="secondary-button"
                :disabled="loggingOutDeviceId !== undefined"
                @click="logoutDevice(device.id)"
              >
                {{ loggingOutDeviceId === device.id ? copy.deactivating : copy.deactivate }}
              </button>
            </div>
          </article>
          <p v-if="userDevices.length === 0" class="feedback">{{ copy.noDevices }}</p>
        </div>
      </section>

      <section class="content-section privacy-section privacy-danger-zone">
        <div class="section-header">
          <div>
            <p class="eyebrow">{{ copy.accountDeletion }}</p>
            <h2>{{ copy.deletionTitle }}</h2>
          </div>
          <span class="status-pill status-pill--warn">{{ copy.revocable }}</span>
        </div>

        <article v-if="latestDeleteTask" class="manage-card privacy-delete-status">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow tabular-numbers">{{ copy.deleteTask(latestDeleteTask.id) }}</p>
              <h3>{{ copy.deleteStatus(latestDeleteTask.status) }}</h3>
            </div>
            <span class="status-pill" :class="canCancelDeleteTask ? 'status-pill--warn' : 'status-pill--muted'">
              {{ copy.deleteStatus(latestDeleteTask.status) }}
            </span>
          </div>
          <p class="support-copy">{{ copy.reason }}: {{ latestDeleteTask.reason }}</p>
          <p class="support-copy tabular-numbers">
            {{ copy.deadline }}:
            {{ latestDeleteTask.coolingOffExpireAt ? formatWebDateTime(latestDeleteTask.coolingOffExpireAt, copy.tag) : copy.unavailable }}
          </p>
          <div v-if="canCancelDeleteTask" class="hero-actions">
            <button type="button" class="secondary-button" :disabled="deleteCancelling" @click="cancelDeleteTask">
              {{ deleteCancelling ? copy.cancelling : copy.cancelDelete }}
            </button>
          </div>
        </article>

        <form v-if="!canCancelDeleteTask" class="review-form privacy-delete-form" @submit.prevent="submitDeleteTask">
          <div class="mode-type-switch privacy-verify-switch">
            <button
              type="button"
              class="mode-type-switch__button"
              :class="{ 'is-active': deleteForm.verifyType === 'code' }"
              @click="deleteForm.verifyType = 'code'"
            >
              {{ copy.verifyCode }}
            </button>
            <button
              type="button"
              class="mode-type-switch__button"
              :class="{ 'is-active': deleteForm.verifyType === 'password' }"
              @click="deleteForm.verifyType = 'password'"
            >
              {{ copy.verifyPassword }}
            </button>
          </div>

          <div class="field-row field-row--two">
            <label class="field">
              <span>{{ copy.boundAccount }}</span>
              <select v-model="deleteForm.account">
                <option v-if="state.currentUser?.email" :value="state.currentUser.email">{{ state.currentUser.email }}</option>
                <option v-if="state.currentUser?.phone" :value="state.currentUser.phone">{{ state.currentUser.phone }}</option>
              </select>
            </label>
            <label class="field">
              <span>{{ copy.deleteReason }}</span>
              <textarea v-model="deleteForm.reason" name="delete-reason" rows="3" maxlength="255" :placeholder="copy.reasonPlaceholder" />
            </label>
          </div>

          <div v-if="deleteForm.verifyType === 'code'" class="inline-field inline-field--code">
            <label class="field">
              <span>{{ copy.verificationCode }}</span>
              <input v-model="deleteForm.verifyCode" name="delete-code" type="text" :placeholder="copy.codePlaceholder" />
            </label>
            <button type="button" class="secondary-button" :disabled="deleteCodeSending" @click="sendDeleteCode">
              {{ deleteCodeSending ? copy.sending : copy.sendDeleteCode }}
            </button>
          </div>

          <label v-else class="field">
            <span>{{ copy.loginPassword }}</span>
            <input v-model="deleteForm.password" name="delete-password" type="password" :placeholder="copy.passwordPlaceholder" />
          </label>

          <p class="support-copy">{{ copy.deleteIntro(overview?.deleteRule.coolingOffDays ?? copy.unavailable) }}</p>
          <div class="hero-actions">
            <button type="submit" class="secondary-button danger-button" :disabled="deleteSubmitting">
              {{ deleteSubmitting ? copy.submitting : copy.submitDelete }}
            </button>
          </div>
        </form>
      </section>
    </template>
  </div>
</template>
