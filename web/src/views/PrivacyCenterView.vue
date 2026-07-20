<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useUserSession } from '@/composables/useUserSession'
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
  follows: true,
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
      locale: 'zh-CN',
      source: 3,
    })
    await loadPrivacyData()
    successMessage.value = '协议同意记录已留痕。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '协议留痕失败'
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
    successMessage.value = '设备已停用并清除推送 token。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '停用设备失败'
  } finally {
    loggingOutDeviceId.value = undefined
  }
}

function policyName(policyType: number) {
  return ({ 1: '隐私政策', 2: '用户协议', 3: 'Cookie/营销告知' } as Record<number, string>)[policyType] ?? '未知协议'
}

function platformName(platform: number) {
  return ({ 1: 'iOS', 2: 'Android', 3: 'Web' } as Record<number, string>)[platform] ?? '未知设备'
}

function deviceStatusText(status: number) {
  return ({ 1: '启用', 2: '已停用', 3: '已登出' } as Record<number, string>)[status] ?? '未知状态'
}

async function bootstrap() {
  loading.value = true
  errorMessage.value = ''
  try {
    await loadPrivacyData()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '隐私中心加载失败'
  } finally {
    loading.value = false
  }
}

async function submitExportTask() {
  if (selectedExportModules.value.length === 0) {
    errorMessage.value = '至少选择一个导出模块。'
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
    successMessage.value = '数据导出任务已创建，文件准备好后可直接下载。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '创建导出任务失败'
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
    successMessage.value = `导出任务 #${task.id} 已开始下载。`
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '下载导出文件失败'
  } finally {
    downloadingTaskId.value = undefined
  }
}

async function sendDeleteCode() {
  if (!deleteForm.account.trim()) {
    errorMessage.value = '先选择或填写当前已绑定账号。'
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
    successMessage.value = `注销验证码已发送，${response.nextRetrySeconds} 秒后可重发。`
    codeHint.value = response.mockCode ? `本地 mock 验证码：${response.mockCode}` : ''
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '注销验证码发送失败'
  } finally {
    deleteCodeSending.value = false
  }
}

async function submitDeleteTask() {
  const reason = deleteForm.reason.trim()
  const account = deleteForm.account.trim()
  if (!account || !reason) {
    errorMessage.value = '校验账号和删除原因都得填。'
    successMessage.value = ''
    return
  }

  if (deleteForm.verifyType === 'code' && !deleteForm.verifyCode.trim()) {
    errorMessage.value = '验证码还没填。'
    successMessage.value = ''
    return
  }
  if (deleteForm.verifyType === 'password' && !deleteForm.password.trim()) {
    errorMessage.value = '登录密码还没填。'
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
    successMessage.value = '删除申请已进入冷静期，反悔时可以在到期前撤销。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '提交删除申请失败'
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
    successMessage.value = '删除申请已撤销，账号会继续保留。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '撤销删除申请失败'
  } finally {
    deleteCancelling.value = false
  }
}

void bootstrap()
</script>

<template>
  <div class="page-stack privacy-center">
    <section class="hero-panel hero-panel--compact privacy-hero">
      <div class="hero-panel__content">
        <p class="eyebrow">隐私中心</p>
        <h1>你的数据能带走，账号要删除也得留条明白路。</h1>
        <p class="hero-panel__summary">导出不是摆设，注销也不是“一点就没”。这里把任务状态、文件期限和冷静期都摊开讲清楚。</p>
      </div>
      <div class="hero-panel__side privacy-rule-grid">
        <div class="hero-metric">
          <span>数据导出</span>
          <strong class="tabular-numbers">每天最多 {{ overview?.exportRule.dailyLimit ?? '—' }} 次</strong>
          <p class="tabular-numbers">文件保留 {{ overview?.exportRule.expireHours ?? '—' }} 小时</p>
        </div>
        <div class="hero-metric privacy-hero__delete-rule">
          <span>账号删除</span>
          <strong class="tabular-numbers">{{ overview?.deleteRule.coolingOffDays ?? '—' }} 天冷静期</strong>
          <p>到期前可以撤销；到期后账号与已落地个人数据会按规则匿名化。</p>
        </div>
      </div>
    </section>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="codeHint" class="feedback">{{ codeHint }}</p>
    <p v-if="loading" class="feedback">隐私规则和任务加载中...</p>

    <template v-else>
      <section class="content-section privacy-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">数据导出</p>
            <h2>先选范围，再生成一个有有效期的 ZIP。</h2>
          </div>
          <span class="status-pill status-pill--good">认证下载</span>
        </div>

        <div class="privacy-export-layout">
          <form class="privacy-module-picker" @submit.prevent="submitExportTask">
            <label class="privacy-module-card">
              <input v-model="exportModules.account" type="checkbox" />
              <span>
                <strong>账号数据</strong>
                <small>资料、绑定账号、成长值流水和搜索历史。</small>
              </span>
            </label>
            <label class="privacy-module-card">
              <input v-model="exportModules.reviews" type="checkbox" />
              <span>
                <strong>点评数据</strong>
                <small>我发布过的点评、评分、审核状态和互动计数。</small>
              </span>
            </label>
            <label class="privacy-module-card">
              <input v-model="exportModules.orders" type="checkbox" />
              <span>
                <strong>订单数据</strong>
                <small>团购订单、金额、支付状态和创建时间。</small>
              </span>
            </label>
            <label class="privacy-module-card">
              <input v-model="exportModules.posts" type="checkbox" />
              <span>
                <strong>帖子数据</strong>
                <small>我发布过的帖子、图片、话题、审核状态和互动计数。</small>
              </span>
            </label>
            <label class="privacy-module-card">
              <input v-model="exportModules.reservations" type="checkbox" />
              <span>
                <strong>预订数据</strong>
                <small>预订门店、到店时间、联系人和状态。</small>
              </span>
            </label>
            <label class="privacy-module-card">
              <input v-model="exportModules.favorites" type="checkbox" />
              <span>
                <strong>收藏数据</strong>
                <small>收藏对象、门店快照和收藏时间。</small>
              </span>
            </label>
            <label class="privacy-module-card">
              <input v-model="exportModules.follows" type="checkbox" />
              <span>
                <strong>关注关系</strong>
                <small>我关注的人、关注我的人和关系建立时间。</small>
              </span>
            </label>
            <p class="support-copy">私信业务尚未落地，因此暂不开放对应导出项，不拿空数组装完成。</p>
            <button type="submit" class="primary-button" :disabled="exportCreating">
              {{ exportCreating ? '创建中...' : '创建导出任务' }}
            </button>
          </form>

          <div class="privacy-task-list">
            <article v-for="task in exportTasks" :key="task.id" class="manage-card privacy-task-card">
              <div class="manage-card__header">
                <div>
                  <p class="eyebrow tabular-numbers">任务 #{{ task.id }}</p>
                  <h3>{{ task.modules.join(' / ') || '未指定模块' }}</h3>
                </div>
                <span class="status-pill" :class="task.status === 2 ? 'status-pill--good' : 'status-pill--warn'">
                  {{ task.statusText }}
                </span>
              </div>
              <p class="support-copy tabular-numbers">创建于 {{ task.createdAt }} · 到期 {{ task.expireAt || '—' }}</p>
              <p v-if="task.failReason" class="feedback is-error">{{ task.failReason }}</p>
              <div class="manage-card__footer">
                <span>格式：{{ task.format.toUpperCase() }}</span>
                <button
                  v-if="task.status === 2 && task.downloadUrl"
                  type="button"
                  class="secondary-button"
                  :disabled="downloadingTaskId === task.id"
                  @click="downloadTask(task)"
                >
                  {{ downloadingTaskId === task.id ? '下载中...' : '下载 ZIP' }}
                </button>
              </div>
            </article>
            <p v-if="exportTasks.length === 0" class="feedback">还没有导出任务，选好范围后创建第一份。</p>
          </div>
        </div>
      </section>

      <section class="content-section privacy-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">协议留痕</p>
            <h2>确认过哪个版本，别靠记忆打官司。</h2>
          </div>
          <span class="status-pill status-pill--good">可追溯</span>
        </div>
        <div class="hero-actions">
          <button type="button" class="secondary-button" :disabled="acceptingPolicyType !== undefined" @click="acceptPolicy(1)">
            {{ acceptingPolicyType === 1 ? '记录中...' : '确认隐私政策' }}
          </button>
          <button type="button" class="secondary-button" :disabled="acceptingPolicyType !== undefined" @click="acceptPolicy(2)">
            {{ acceptingPolicyType === 2 ? '记录中...' : '确认用户协议' }}
          </button>
        </div>
        <div class="privacy-task-list">
          <article v-for="log in policyLogs" :key="log.id" class="manage-card">
            <div class="manage-card__header">
              <h3>{{ policyName(log.policyType) }} · {{ log.version }}</h3>
              <span class="status-pill status-pill--muted">{{ log.locale }}</span>
            </div>
            <p class="support-copy tabular-numbers">{{ log.acceptedAt }} · {{ log.userAgent || '未知客户端' }}</p>
          </article>
          <p v-if="policyLogs.length === 0" class="feedback">还没有协议同意记录。</p>
        </div>
      </section>

      <section class="content-section privacy-section">
        <div class="section-header">
          <div>
            <p class="eyebrow">设备管理</p>
            <h2>登录过哪些设备，一眼看明白。</h2>
          </div>
          <span class="status-pill status-pill--warn">主动停用</span>
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
              <span class="tabular-numbers">最近活跃 {{ device.lastActiveAt || '—' }}</span>
              <button
                v-if="device.status === 1"
                type="button"
                class="secondary-button"
                :disabled="loggingOutDeviceId !== undefined"
                @click="logoutDevice(device.id)"
              >
                {{ loggingOutDeviceId === device.id ? '停用中...' : '停用设备' }}
              </button>
            </div>
          </article>
          <p v-if="userDevices.length === 0" class="feedback">还没有登记设备。</p>
        </div>
      </section>

      <section class="content-section privacy-section privacy-danger-zone">
        <div class="section-header">
          <div>
            <p class="eyebrow">账号删除</p>
            <h2>这是危险操作，所以步骤得明确，后果也得说人话。</h2>
          </div>
          <span class="status-pill status-pill--warn">可撤销冷静期</span>
        </div>

        <article v-if="latestDeleteTask" class="manage-card privacy-delete-status">
          <div class="manage-card__header">
            <div>
              <p class="eyebrow tabular-numbers">删除任务 #{{ latestDeleteTask.id }}</p>
              <h3>{{ latestDeleteTask.statusText }}</h3>
            </div>
            <span class="status-pill" :class="canCancelDeleteTask ? 'status-pill--warn' : 'status-pill--muted'">
              {{ latestDeleteTask.statusText }}
            </span>
          </div>
          <p class="support-copy">原因：{{ latestDeleteTask.reason }}</p>
          <p class="support-copy tabular-numbers">冷静期截止：{{ latestDeleteTask.coolingOffExpireAt || '—' }}</p>
          <div v-if="canCancelDeleteTask" class="hero-actions">
            <button type="button" class="secondary-button" :disabled="deleteCancelling" @click="cancelDeleteTask">
              {{ deleteCancelling ? '撤销中...' : '撤销删除申请' }}
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
              验证码校验
            </button>
            <button
              type="button"
              class="mode-type-switch__button"
              :class="{ 'is-active': deleteForm.verifyType === 'password' }"
              @click="deleteForm.verifyType = 'password'"
            >
              密码校验
            </button>
          </div>

          <div class="field-row field-row--two">
            <label class="field">
              <span>当前已绑定账号</span>
              <select v-model="deleteForm.account">
                <option v-if="state.currentUser?.email" :value="state.currentUser.email">{{ state.currentUser.email }}</option>
                <option v-if="state.currentUser?.phone" :value="state.currentUser.phone">{{ state.currentUser.phone }}</option>
              </select>
            </label>
            <label class="field">
              <span>删除原因</span>
              <textarea v-model="deleteForm.reason" name="delete-reason" rows="3" maxlength="255" placeholder="请说明删除原因" />
            </label>
          </div>

          <div v-if="deleteForm.verifyType === 'code'" class="inline-field inline-field--code">
            <label class="field">
              <span>验证码</span>
              <input v-model="deleteForm.verifyCode" name="delete-code" type="text" placeholder="输入注销验证码" />
            </label>
            <button type="button" class="secondary-button" :disabled="deleteCodeSending" @click="sendDeleteCode">
              {{ deleteCodeSending ? '发送中...' : '发送注销验证码' }}
            </button>
          </div>

          <label v-else class="field">
            <span>登录密码</span>
            <input v-model="deleteForm.password" name="delete-password" type="password" placeholder="输入当前登录密码" />
          </label>

          <p class="support-copy">提交后进入 {{ overview?.deleteRule.coolingOffDays ?? '—' }} 天冷静期；到期处理后当前登录态会失效，账号不能再登录。</p>
          <div class="hero-actions">
            <button type="submit" class="secondary-button danger-button" :disabled="deleteSubmitting">
              {{ deleteSubmitting ? '提交中...' : '提交删除申请' }}
            </button>
          </div>
        </form>
      </section>
    </template>
  </div>
</template>
