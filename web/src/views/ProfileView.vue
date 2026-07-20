<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useUserSession } from '@/composables/useUserSession'
import { getBrowserDeviceId } from '@/lib/device-id'
import {
  bindCurrentUserAccount,
  fetchCurrentUser,
  sendAuthCode,
  updateCurrentUserPassword,
  updateCurrentUserProfile,
} from '@/services/auth'

const { state, setCurrentUser } = useUserSession()

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

const form = reactive({
  nickname: '',
  avatar: '',
  gender: 0,
  signature: '',
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

const bindTargetLabel = computed(() => (bindForm.type === 'email' ? '邮箱' : '手机号'))
const passwordHint = computed(() => {
  if (state.currentUser?.hasPassword) {
    return '当前账号已经有密码了，改密码时得把旧密码填对。'
  }
  return '当前账号还没设过密码，旧密码可以留空，直接补一个新密码就行。'
})

function applyProfile() {
  if (!state.currentUser) {
    return
  }
  form.nickname = state.currentUser.nickname || ''
  form.avatar = state.currentUser.avatar || ''
  form.gender = state.currentUser.gender ?? 0
  form.signature = state.currentUser.signature || ''
}

async function bootstrap() {
  loading.value = true
  errorMessage.value = ''

  try {
    const profile = await fetchCurrentUser()
    setCurrentUser(profile)
    applyProfile()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '资料加载失败'
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
    successMessage.value = '资料已更新。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '资料保存失败'
  } finally {
    saving.value = false
  }
}

async function sendBindCode() {
  const account = bindForm.account.trim()
  if (!account) {
    bindErrorMessage.value = `先把${bindTargetLabel.value}填上，再点发验证码。`
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
    bindSuccessMessage.value = `${bindTargetLabel.value}验证码已发送，${response.nextRetrySeconds} 秒后可重发。`
    bindCodeHint.value = response.mockCode ? `本地 mock 验证码：${response.mockCode}` : ''
  } catch (error) {
    bindErrorMessage.value = error instanceof Error ? error.message : '验证码发送失败'
  } finally {
    bindSending.value = false
  }
}

async function submitBind() {
  const account = bindForm.account.trim()
  const code = bindForm.code.trim()
  if (!account || !code) {
    bindErrorMessage.value = `${bindTargetLabel.value}和验证码都得填，别想糊弄过去。`
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
    bindSuccessMessage.value = `${bindTargetLabel.value}已绑定成功。`
  } catch (error) {
    bindErrorMessage.value = error instanceof Error ? error.message : '账号绑定失败'
  } finally {
    binding.value = false
  }
}

async function submitPassword() {
  const oldPassword = passwordForm.oldPassword.trim()
  const newPassword = passwordForm.newPassword.trim()
  const confirmPassword = passwordForm.confirmPassword.trim()

  if (!newPassword || !confirmPassword) {
    passwordErrorMessage.value = '新密码和确认密码都得填。'
    passwordSuccessMessage.value = ''
    return
  }
  if (newPassword !== confirmPassword) {
    passwordErrorMessage.value = '两次输入的新密码对不上。'
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
    passwordSuccessMessage.value = '密码已经更新。'
  } catch (error) {
    passwordErrorMessage.value = error instanceof Error ? error.message : '密码更新失败'
  } finally {
    passwordSaving.value = false
  }
}

void bootstrap()
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--single">
      <div class="hero-panel__content">
        <p class="eyebrow">我的资料</p>
        <h1>资料、绑定、改密都得在这儿闭环，不然这用户中心就太糊弄了。</h1>
        <p class="hero-panel__summary">这次把用户中心剩的硬骨头一块啃掉，别老挂在文档里装存在感。</p>
      </div>
    </section>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="loading" class="feedback">资料加载中...</p>

    <template v-else-if="state.currentUser">
      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">基础资料</p>
            <h2>先把能改的字段改通，别让资料页只会看不会动。</h2>
          </div>
        </div>

        <form class="review-form" @submit.prevent="saveProfile">
          <div class="field-row field-row--two">
            <label class="field">
              <span>昵称</span>
              <input v-model="form.nickname" type="text" maxlength="64" placeholder="昵称" />
            </label>
            <label class="field">
              <span>头像 URL</span>
              <input v-model="form.avatar" type="text" maxlength="255" placeholder="https://..." />
            </label>
          </div>

          <div class="field-row field-row--two">
            <label class="field">
              <span>性别</span>
              <select v-model="form.gender">
                <option :value="0">未知</option>
                <option :value="1">男</option>
                <option :value="2">女</option>
              </select>
            </label>
            <label class="field">
              <span>偏好区域</span>
              <input :value="state.currentUser.preferredRegion" type="text" readonly />
            </label>
          </div>

          <label class="field field--full">
            <span>签名</span>
            <textarea v-model="form.signature" rows="4" maxlength="255" spellcheck="false" placeholder="写点能代表你的话。" />
          </label>

          <div class="profile-grid">
            <div class="hero-metric">
              <span>邮箱</span>
              <strong>{{ state.currentUser.email || '未绑定' }}</strong>
            </div>
            <div class="hero-metric">
              <span>手机号</span>
              <strong>{{ state.currentUser.phone || '未绑定' }}</strong>
            </div>
            <div class="hero-metric">
              <span>等级 / 积分 / 成长值</span>
              <strong>Lv.{{ state.currentUser.level }} · {{ state.currentUser.points }} 积分 · {{ state.currentUser.growthValue }} 成长值</strong>
            </div>
          </div>

          <div class="hero-actions">
            <button type="submit" class="primary-button" :disabled="saving">
              {{ saving ? '保存中...' : '保存资料' }}
            </button>
            <RouterLink to="/user/growth-records" class="secondary-button">查看成长值流水</RouterLink>
            <RouterLink to="/user/privacy" class="secondary-button">进入隐私中心</RouterLink>
          </div>
        </form>
      </section>

      <section class="content-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">账户安全</p>
            <h2>绑定账号和改密码这两件事，终于不用再留到“下次一定”了。</h2>
          </div>
        </div>

        <div class="stack-list">
          <article class="manage-card">
            <div class="manage-card__header">
              <div>
                <p class="eyebrow">绑定账号</p>
                <h3>邮箱和手机号都能补绑或换绑。</h3>
              </div>
            </div>

            <p v-if="bindErrorMessage" class="feedback is-error">{{ bindErrorMessage }}</p>
            <p v-if="bindSuccessMessage" class="feedback is-success">{{ bindSuccessMessage }}</p>
            <p v-if="bindCodeHint" class="feedback">{{ bindCodeHint }}</p>

            <form class="review-form" @submit.prevent="submitBind">
              <div class="field-row field-row--two">
                <label class="field">
                  <span>绑定类型</span>
                  <select v-model="bindForm.type">
                    <option value="email">邮箱</option>
                    <option value="phone">手机号</option>
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
                  <span>验证码</span>
                  <input v-model="bindForm.code" type="text" placeholder="输入验证码" />
                </label>
                <button type="button" class="secondary-button" :disabled="bindSending" @click="sendBindCode">
                  {{ bindSending ? '发送中...' : '发送验证码' }}
                </button>
              </div>

              <div class="hero-actions">
                <button type="submit" class="primary-button" :disabled="binding">
                  {{ binding ? '绑定中...' : '确认绑定' }}
                </button>
              </div>
            </form>
          </article>

          <article class="manage-card">
            <div class="manage-card__header">
              <div>
                <p class="eyebrow">修改密码</p>
                <h3>有旧密码就校验，没密码就直接补设置。</h3>
              </div>
            </div>

            <p class="support-copy">{{ passwordHint }}</p>
            <p v-if="passwordErrorMessage" class="feedback is-error">{{ passwordErrorMessage }}</p>
            <p v-if="passwordSuccessMessage" class="feedback is-success">{{ passwordSuccessMessage }}</p>

            <form class="review-form" @submit.prevent="submitPassword">
              <div class="field-row field-row--two">
                <label class="field">
                  <span>旧密码</span>
                  <input v-model="passwordForm.oldPassword" type="password" placeholder="已有密码时填写" />
                </label>
                <label class="field">
                  <span>新密码</span>
                  <input v-model="passwordForm.newPassword" type="password" placeholder="设置新密码" />
                </label>
              </div>

              <label class="field">
                <span>确认新密码</span>
                <input v-model="passwordForm.confirmPassword" type="password" placeholder="再输一遍新密码" />
              </label>

              <div class="hero-actions">
                <button type="submit" class="primary-button" :disabled="passwordSaving">
                  {{ passwordSaving ? '保存中...' : '更新密码' }}
                </button>
              </div>
            </form>
          </article>
        </div>
      </section>
    </template>
  </div>
</template>
