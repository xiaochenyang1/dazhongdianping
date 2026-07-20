<script setup lang="ts">
import { Transition, computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { getBrowserDeviceId } from '@/lib/device-id'
import { fetchCurrentUser, loginWithCode, loginWithPassword, registerUser, resetPassword, sendAuthCode } from '@/services/auth'
import type { AuthMode, AuthSessionResponse } from '@/types/auth'

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

const accountTypeOptions = [
  { value: 'email', label: '邮箱' },
  { value: 'phone', label: '手机号' },
] satisfies Array<{
  value: 'email' | 'phone'
  label: string
}>

const modeOptions = [
  {
    mode: 'password',
    label: '密码登录',
    eyebrow: '熟悉账号',
    detail: '已有密码的账号直接从这里进入，最快把收藏、点评和互动任务续上。',
    footer: '输入密码后立刻恢复当前动作，适合回流用户。',
  },
  {
    mode: 'code',
    label: '验证码登录',
    eyebrow: '快速校验',
    detail: '适合临时登录和跨设备兜底，本地环境会直接回显 mock 验证码。',
    footer: '轻量验证一把过，先把登录闭环和回跳链路跑顺。',
  },
  {
    mode: 'register',
    label: '注册账号',
    eyebrow: '首次到店',
    detail: '第一次使用就顺手建账号，后续写点评、互动和资料维护都能接着走。',
    footer: '注册完成即进入登录态，新用户不用再多走一轮。',
  },
  {
    mode: 'reset',
    label: '重置密码',
    eyebrow: '礼宾兜底',
    detail: '忘记密码时先重置再回到密码登录，避免链路卡在门口来回兜圈子。',
    footer: '重置完成会切回密码登录，直接用新密码继续。',
  },
] satisfies Array<{
  mode: AuthMode
  label: string
  eyebrow: string
  detail: string
  footer: string
}>

const panelTitle = computed(() => {
  return (
    {
      password: '先把登录链路跑顺',
      code: '验证码登录',
      register: '注册新账号',
      reset: '找回密码',
    } satisfies Record<AuthMode, string>
  )[state.authMode]
})

const panelSummary = computed(() => {
  if (state.redirectTo) {
    return '拦截后的动作已经替你保留，完成登录后会自动回到刚才的页面和操作，不会让你白点一遍。'
  }

  return '登录、注册、验证码和找回密码统一走同一套礼宾式入口，不再拿生硬的 tab 切来切去糊弄事。'
})

const activeModeMeta = computed(
  () => modeOptions.find((item) => item.mode === state.authMode) ?? modeOptions[0],
)

const activeModeIndex = computed(() => {
  const index = modeOptions.findIndex((item) => item.mode === state.authMode)
  return index >= 0 ? index + 1 : 1
})

const stageHeadline = computed(() => {
  return state.redirectTo ? '登录后直接续上当前任务' : '现在把账号闭环稳稳接上'
})

const stageSummary = computed(() => {
  if (state.redirectTo) {
    return `目标路径 ${state.redirectTo} 已记录在当前会话里，登录完成后会自动跳回。`
  }

  return '当前本地开发环境会直接返回 mockCode，方便把登录、刷新和用户资料链路一起联调透。'
})

const resumeFacts = computed(() => [
  {
    label: state.redirectTo ? '恢复目标' : '运行环境',
    value: state.redirectTo ?? 'mock 验证码联调',
  },
  {
    label: '当前区域',
    value: appState.region,
  },
  {
    label: '设备识别',
    value: browserDeviceId.slice(0, 8).toUpperCase(),
  },
])

const servicePromises = computed(() => [
  {
    title: '动作恢复',
    detail: state.redirectTo
      ? '登录成功后自动回到刚才的收藏、点评或互动动作。'
      : '登录链路和页面浏览处在同一套弹层闭环里。',
  },
  {
    title: '验证码联调',
    detail: '本地环境直接回显 mockCode，不用再去翻后端日志抄验证码。',
  },
  {
    title: '区域一致',
    detail: `当前沿用 ${appState.region} 区域视角，后续资料页和我的点评不会串区。`,
  },
])

const stageFacts = computed(() => [
  {
    label: '当前方式',
    value: activeModeMeta.value.label,
  },
  {
    label: state.redirectTo ? '恢复路径' : '当前提示',
    value: state.redirectTo ?? '验证码可直接联调',
  },
  {
    label: '会话区域',
    value: appState.region,
  },
])

const secondaryModeLinks = computed(() => modeOptions.filter((item) => item.mode !== state.authMode))

watch(
  () => state.authDialogOpen,
  (open) => {
    if (open) {
      errorMessage.value = ''
      successMessage.value = ''
      mockCodeHint.value = ''
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
}

function resolveCodePayload(targetMode: 'code' | 'register' | 'reset') {
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

  return {
    scene: 'login' as const,
    type: codeForm.type,
    account: codeForm.account.trim(),
    deviceId: browserDeviceId,
  }
}

async function handleSendCode(targetMode: 'code' | 'register' | 'reset') {
  const payload = resolveCodePayload(targetMode)
  if (!payload.account) {
    errorMessage.value = '先把账号填上，再点发验证码。'
    return
  }

  sendingCode.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await sendAuthCode(payload)
    successMessage.value = `验证码已发送，${response.nextRetrySeconds} 秒后可重发。`
    mockCodeHint.value = response.mockCode ? `本地 mock 验证码：${response.mockCode}` : ''
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '验证码发送失败'
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
    errorMessage.value = error instanceof Error ? error.message : '密码登录失败'
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
    errorMessage.value = error instanceof Error ? error.message : '验证码登录失败'
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
    errorMessage.value = error instanceof Error ? error.message : '注册失败'
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
    successMessage.value = '密码已重置，回到密码登录直接试。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '重置密码失败'
  } finally {
    loading.value = false
  }
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
                <span class="auth-rail__mark">礼</span>
                <div class="auth-rail__copy">
                  <p class="eyebrow">City Concierge</p>
                  <strong>登录礼宾台</strong>
                </div>
              </div>
              <span class="auth-rail__signal">M2 Flow</span>
            </div>

            <div class="auth-dialog__hero">
              <p class="eyebrow">用户中心 · {{ appState.region }}</p>
              <h2>{{ panelTitle }}</h2>
              <p>{{ panelSummary }}</p>
            </div>

            <article class="auth-resume-card" :class="{ 'is-redirected': !!state.redirectTo }">
              <div class="auth-resume-card__header">
                <span class="auth-resume-card__tag">{{ state.redirectTo ? '拦截恢复' : '联调提示' }}</span>
                <strong>{{ state.redirectTo ? '这次操作已经为你保留' : '账号链路已经准备就绪' }}</strong>
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
                <span class="auth-stage__banner-tag">{{ state.redirectTo ? '继续任务' : '礼宾引导' }}</span>
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
                    <span>邮箱 / 手机号</span>
                    <input v-model="passwordForm.account" type="text" placeholder="user@example.com / +8613800000000" />
                  </label>
                  <label class="field">
                    <span>密码</span>
                    <input v-model="passwordForm.password" type="password" placeholder="输入登录密码" />
                  </label>
                  <p class="support-copy auth-support-copy">
                    已有密码就直接走这条，拦截恢复最快，能少兜一圈就少兜一圈。
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? '登录中...' : '登录' }}
                  </button>
                </form>

                <form
                  v-else-if="state.authMode === 'code'"
                  key="code"
                  class="auth-grid"
                  @submit.prevent="submitCodeLogin"
                >
                  <div class="field">
                    <span>账号类型</span>
                    <div class="mode-type-switch" role="group" aria-label="账号类型">
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
                    <span>账号</span>
                    <input v-model="codeForm.account" type="text" placeholder="收验证码的账号" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>验证码</span>
                      <input v-model="codeForm.code" type="text" placeholder="输入验证码" />
                    </label>
                    <button type="button" class="secondary-button" :disabled="sendingCode" @click="handleSendCode('code')">
                      {{ sendingCode ? '发送中...' : '发验证码' }}
                    </button>
                  </div>
                  <p class="support-copy auth-support-copy">
                    本地环境会直接回显 mock 验证码，省得你来回切日志窗口找数字。
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? '登录中...' : '验证码登录' }}
                  </button>
                </form>

                <form
                  v-else-if="state.authMode === 'register'"
                  key="register"
                  class="auth-grid"
                  @submit.prevent="submitRegister"
                >
                  <div class="field">
                    <span>账号类型</span>
                    <div class="mode-type-switch" role="group" aria-label="账号类型">
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
                    <span>账号</span>
                    <input v-model="registerForm.account" type="text" placeholder="用于注册的新账号" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>验证码</span>
                      <input v-model="registerForm.code" type="text" placeholder="输入验证码" />
                    </label>
                    <button
                      type="button"
                      class="secondary-button"
                      :disabled="sendingCode"
                      @click="handleSendCode('register')"
                    >
                      {{ sendingCode ? '发送中...' : '发验证码' }}
                    </button>
                  </div>
                  <label class="field">
                    <span>昵称</span>
                    <input v-model="registerForm.nickname" type="text" placeholder="不填就按系统默认昵称走" />
                  </label>
                  <label class="field">
                    <span>密码</span>
                    <input v-model="registerForm.password" type="password" placeholder="设置登录密码" />
                  </label>
                  <p class="support-copy auth-support-copy">
                    注册完成后直接进入登录态，适合第一次写点评或准备做互动的新用户。
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? '注册中...' : '注册并登录' }}
                  </button>
                </form>

                <form
                  v-else
                  key="reset"
                  class="auth-grid"
                  @submit.prevent="submitResetPassword"
                >
                  <div class="field">
                    <span>账号类型</span>
                    <div class="mode-type-switch" role="group" aria-label="账号类型">
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
                    <span>账号</span>
                    <input v-model="resetForm.account" type="text" placeholder="找回密码的账号" />
                  </label>
                  <div class="inline-field inline-field--code">
                    <label class="field">
                      <span>验证码</span>
                      <input v-model="resetForm.code" type="text" placeholder="输入验证码" />
                    </label>
                    <button type="button" class="secondary-button" :disabled="sendingCode" @click="handleSendCode('reset')">
                      {{ sendingCode ? '发送中...' : '发验证码' }}
                    </button>
                  </div>
                  <label class="field">
                    <span>新密码</span>
                    <input v-model="resetForm.newPassword" type="password" placeholder="设置新密码" />
                  </label>
                  <p class="support-copy auth-support-copy">
                    重置成功后会回到密码登录，别忘了用新密码把这条链路闭上。
                  </p>
                  <button type="submit" class="primary-button auth-submit-button" :disabled="loading">
                    {{ loading ? '重置中...' : '重置密码' }}
                  </button>
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
