import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/lib/http'

const authMocks = vi.hoisted(() => ({
  fetchCurrentUser: vi.fn(),
  loginWithCode: vi.fn(),
  loginWithPassword: vi.fn(),
  queryBanAppeal: vi.fn(),
  registerUser: vi.fn(),
  resetPassword: vi.fn(),
  sendAuthCode: vi.fn(),
  submitBanAppeal: vi.fn(),
}))

const routerMocks = vi.hoisted(() => ({
  push: vi.fn(),
}))

const sessionMocks = vi.hoisted(() => ({
  state: null as unknown as {
    authDialogOpen: boolean
    authMode: string
    redirectTo: string | null
    accessToken: string
    refreshToken: string
    currentUser: unknown
  },
  closeAuthDialog: vi.fn(),
  consumePendingAuthAction: vi.fn(() => null),
  setSession: vi.fn(),
  setCurrentUser: vi.fn(),
  clearSession: vi.fn(),
  setAuthMode: vi.fn(),
}))

vi.mock('@/services/auth', () => authMocks)
vi.mock('@/composables/useUserSession', async () => {
  const { reactive } = await import('vue')
  sessionMocks.state = reactive({
    authDialogOpen: true,
    authMode: 'password',
    redirectTo: null,
    accessToken: '',
    refreshToken: '',
    currentUser: null,
  })
  return {
    useUserSession: () => sessionMocks,
  }
})
vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: routerMocks.push,
  }),
}))

import AuthDialog from './AuthDialog.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountDialog() {
  const host = document.createElement('div')
  document.body.appendChild(host)
  const app = createApp(AuthDialog)
  app.mount(host)
  return app
}

function fillInput(placeholder: string, value: string) {
  const input = Array.from(document.querySelectorAll('input')).find(
    (item) => item.placeholder === placeholder,
  )
  if (!input) {
    throw new Error(`input not found: ${placeholder}`)
  }
  input.value = value
  input.dispatchEvent(new Event('input'))
}

function fillTextarea(value: string) {
  const textarea = document.querySelector('textarea')
  if (!textarea) {
    throw new Error('textarea not found')
  }
  textarea.value = value
  textarea.dispatchEvent(new Event('input'))
}

function submitActiveForm() {
  const form = document.querySelector('form.auth-grid')
  if (!form) {
    throw new Error('active form not found')
  }
  form.dispatchEvent(new Event('submit', { cancelable: true }))
}

function findButton(label: string) {
  const button = Array.from(document.querySelectorAll('button')).find(
    (item) => item.textContent?.trim() === label,
  )
  if (!button) {
    throw new Error(`button not found: ${label}`)
  }
  return button
}

function pendingAppeal() {
  return {
    id: 12,
    status: 0,
    statusText: '待审核',
    reason: '账号被误封，请复核我的发帖记录。',
    rejectReason: '',
    banReason: '发布垃圾广告',
    submittedAt: '2026-07-24 10:00:00',
    auditedAt: '',
  }
}

let app: ReturnType<typeof mountDialog> | null = null

describe('AuthDialog 封禁申诉链路', () => {
  beforeEach(() => {
    Object.values(authMocks).forEach((mock) => mock.mockReset())
    routerMocks.push.mockReset()
    sessionMocks.closeAuthDialog.mockReset()
    sessionMocks.setSession.mockReset()
    sessionMocks.setCurrentUser.mockReset()
    sessionMocks.clearSession.mockReset()
    sessionMocks.setAuthMode.mockReset()
    sessionMocks.setAuthMode.mockImplementation((mode: string) => {
      sessionMocks.state.authMode = mode
    })
    sessionMocks.state.authDialogOpen = true
    sessionMocks.state.authMode = 'password'
    sessionMocks.state.redirectTo = null
  })

  afterEach(() => {
    app?.unmount()
    app = null
    document.body.innerHTML = ''
  })

  it('密码登录被封禁时展示申诉入口，点击后带账号进入申诉表单', async () => {
    authMocks.loginWithPassword.mockRejectedValue(
      new ApiError('账号已被封禁，暂时无法登录 [traceId: t-1]', {
        status: 401,
        messageKey: 'auth.user_banned',
      }),
    )

    app = mountDialog()
    await flushView()

    fillInput('user@example.com / +8613800000000', 'banned@example.com')
    fillInput('输入登录密码', 'Secret123!')
    submitActiveForm()
    await flushView()

    const cta = document.querySelector('.auth-ban-appeal-cta')
    expect(cta).not.toBeNull()
    expect(cta?.textContent).toContain('banned@example.com')

    findButton('提交封禁申诉').click()
    await flushView()
    await new Promise((resolve) => setTimeout(resolve, 80))
    await flushView()

    expect(sessionMocks.state.authMode).toBe('appeal')
    const accountInput = Array.from(document.querySelectorAll('input')).find(
      (item) => item.placeholder === '被封禁的邮箱 / 手机号',
    )
    expect(accountInput?.value).toBe('banned@example.com')
  })

  it('申诉表单可发验证码并提交，成功后展示待审核状态卡', async () => {
    authMocks.sendAuthCode.mockResolvedValue({
      sent: true,
      expireSeconds: 300,
      nextRetrySeconds: 60,
      mockCode: '123456',
    })
    authMocks.submitBanAppeal.mockResolvedValue(pendingAppeal())

    sessionMocks.state.authMode = 'appeal'
    app = mountDialog()
    await flushView()

    fillInput('被封禁的邮箱 / 手机号', 'banned@example.com')
    findButton('发验证码').click()
    await flushView()

    expect(authMocks.sendAuthCode).toHaveBeenCalledWith(
      expect.objectContaining({ scene: 'appeal', type: 'email', account: 'banned@example.com' }),
    )

    fillInput('输入验证码', '123456')
    fillTextarea('账号被误封，请复核我的发帖记录，理由足够长。')
    submitActiveForm()
    await flushView()

    expect(authMocks.submitBanAppeal).toHaveBeenCalledWith({
      type: 'email',
      account: 'banned@example.com',
      code: '123456',
      reason: '账号被误封，请复核我的发帖记录，理由足够长。',
    })
    const statusCard = document.querySelector('[data-testid="appeal-status"]')
    expect(statusCard).not.toBeNull()
    expect(statusCard?.textContent).toContain('#12')
    expect(statusCard?.textContent).toContain('待审核')
    expect(statusCard?.textContent).toContain('封禁原因：发布垃圾广告')
  })

  it('申诉理由太短时直接拦截，不调用提交接口', async () => {
    sessionMocks.state.authMode = 'appeal'
    app = mountDialog()
    await flushView()

    fillInput('被封禁的邮箱 / 手机号', 'banned@example.com')
    fillInput('输入验证码', '123456')
    fillTextarea('太短')
    submitActiveForm()
    await flushView()

    expect(authMocks.submitBanAppeal).not.toHaveBeenCalled()
    expect(document.querySelector('.feedback.is-error')?.textContent).toContain('至少写 10 个字')
  })

  it('查询申诉进度会刷新状态卡，驳回时展示驳回原因', async () => {
    authMocks.queryBanAppeal.mockResolvedValue({
      ...pendingAppeal(),
      status: 2,
      statusText: '已驳回',
      rejectReason: '证据充分，维持封禁',
      auditedAt: '2026-07-24 12:00:00',
    })

    sessionMocks.state.authMode = 'appeal'
    app = mountDialog()
    await flushView()

    fillInput('被封禁的邮箱 / 手机号', 'banned@example.com')
    fillInput('输入验证码', '123456')
    findButton('查询申诉进度').click()
    await flushView()

    expect(authMocks.queryBanAppeal).toHaveBeenCalledWith({
      type: 'email',
      account: 'banned@example.com',
      code: '123456',
    })
    const statusCard = document.querySelector('[data-testid="appeal-status"]')
    expect(statusCard?.textContent).toContain('已驳回')
    expect(statusCard?.textContent).toContain('证据充分，维持封禁')
  })

  it('申诉已通过时提供回到密码登录入口并预填账号', async () => {
    authMocks.queryBanAppeal.mockResolvedValue({
      ...pendingAppeal(),
      status: 1,
      statusText: '已通过',
      auditedAt: '2026-07-24 12:00:00',
    })

    sessionMocks.state.authMode = 'appeal'
    app = mountDialog()
    await flushView()

    fillInput('被封禁的邮箱 / 手机号', 'banned@example.com')
    fillInput('输入验证码', '123456')
    findButton('查询申诉进度').click()
    await flushView()

    const statusCard = document.querySelector('[data-testid="appeal-status"]')
    expect(statusCard?.textContent).toContain('已通过')

    findButton('回到密码登录').click()
    await flushView()

    expect(sessionMocks.state.authMode).toBe('password')
    await new Promise((resolve) => setTimeout(resolve, 80))
    await flushView()
    const accountInput = Array.from(document.querySelectorAll('input')).find(
      (item) => item.placeholder === 'user@example.com / +8613800000000',
    )
    expect(accountInput?.value).toBe('banned@example.com')
  })
})
