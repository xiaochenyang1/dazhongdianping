import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const privacyMocks = vi.hoisted(() => ({
  acceptPrivacyPolicy: vi.fn(),
  cancelPrivacyDeleteTask: vi.fn(),
  createPrivacyDeleteTask: vi.fn(),
  createPrivacyExportTask: vi.fn(),
  downloadPrivacyExport: vi.fn(),
  fetchPrivacyExportTasks: vi.fn(),
  fetchPrivacyOverview: vi.fn(),
  fetchPrivacyPolicyLogs: vi.fn(),
  fetchUserDevices: vi.fn(),
  logoutUserDevice: vi.fn(),
}))
const authMocks = vi.hoisted(() => ({
  sendAuthCode: vi.fn(),
}))

vi.mock('@/services/privacy', () => privacyMocks)
vi.mock('@/services/auth', () => authMocks)
vi.mock('@/lib/device-id', () => ({
  getBrowserDeviceId: () => 'privacy-browser-device',
}))
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({
    state: {
      currentUser: {
        id: 9001,
        nickname: '阿评',
        email: 'demo.cn@example.com',
        phone: null,
      },
    },
  }),
}))

import PrivacyCenterView from './PrivacyCenterView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function clickButton(host: HTMLElement, label: string) {
  const button = Array.from(host.querySelectorAll('button')).find((item) => item.textContent?.includes(label))
  if (!button) {
    throw new Error(`找不到按钮: ${label}`)
  }
  button.click()
}

function submitFormForButton(host: HTMLElement, label: string) {
  const button = Array.from(host.querySelectorAll('button')).find((item) => item.textContent?.includes(label))
  const form = button?.closest('form')
  if (!form) {
    throw new Error(`找不到表单按钮: ${label}`)
  }
  form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
}

describe('PrivacyCenterView', () => {
  beforeEach(() => {
    Object.values(privacyMocks).forEach((mock) => mock.mockReset())
    Object.values(authMocks).forEach((mock) => mock.mockReset())
    privacyMocks.fetchPrivacyOverview.mockResolvedValue({
      exportRule: { dailyLimit: 2, defaultFormat: 'zip', expireHours: 24 },
      deleteRule: { coolingOffDays: 7, reverifyRequired: true },
      latestExportTask: null,
      latestDeleteTask: null,
    })
    privacyMocks.fetchPrivacyExportTasks.mockResolvedValue({
      list: [
        {
          id: 8,
          status: 2,
          statusText: '可下载',
          modules: ['account', 'reviews'],
          format: 'zip',
          downloadUrl: '/api/c/v1/privacy/export-tasks/8/download',
          expireAt: '2026-07-14 08:00:00',
          failReason: '',
          createdAt: '2026-07-13 08:00:00',
          updatedAt: '2026-07-13 08:00:01',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
    privacyMocks.fetchPrivacyPolicyLogs.mockResolvedValue([
      {
        id: 3,
        policyType: 1,
        version: '2026.07',
        locale: 'zh-CN',
        source: 3,
        requestIp: '127.0.0.1',
        userAgent: 'Chrome/126',
        acceptedAt: '2026-07-16 10:00:00',
      },
    ])
    privacyMocks.fetchUserDevices.mockResolvedValue([
      {
        id: 7,
        deviceUid: 'web-device-001',
        platform: 3,
        pushChannel: 0,
        pushTokenSet: false,
        appVersion: 'web',
        status: 1,
        lastActiveAt: '2026-07-16 10:00:00',
        createdAt: '2026-07-16 09:00:00',
        updatedAt: '2026-07-16 10:00:00',
      },
    ])
  })

  it('loads privacy rules and creates an export task', async () => {
    privacyMocks.createPrivacyExportTask.mockResolvedValue({ id: 9 })
    const host = document.createElement('div')
    const app = createApp(PrivacyCenterView)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('每天最多 2 次')
    expect(host.textContent).toContain('文件保留 24 小时')
    expect(host.textContent).toContain('任务 #8')
    expect(host.textContent).toContain('订单数据')
    expect(host.textContent).toContain('预订数据')
    expect(host.textContent).toContain('收藏数据')
    expect(host.textContent).toContain('帖子数据')
    expect(host.textContent).toContain('关注关系')
    expect(host.textContent).not.toContain('私信数据')
    expect(host.textContent).toContain('协议留痕')
    expect(host.textContent).toContain('Chrome/126')
    expect(host.textContent).toContain('设备管理')
    expect(host.textContent).toContain('web-device-001')

    submitFormForButton(host, '创建导出任务')
    await flushView()

    expect(privacyMocks.createPrivacyExportTask).toHaveBeenCalledWith({
      modules: ['account', 'reviews', 'orders', 'posts', 'reservations', 'favorites', 'follows'],
      format: 'zip',
    })
    expect(privacyMocks.fetchPrivacyOverview).toHaveBeenCalledTimes(2)
    expect(privacyMocks.fetchPrivacyExportTasks).toHaveBeenCalledTimes(2)
    app.unmount()
  })

  it('records policy acceptance and logs out a user device', async () => {
    privacyMocks.acceptPrivacyPolicy.mockResolvedValue({ id: 4 })
    privacyMocks.logoutUserDevice.mockResolvedValue({ id: 7, status: 3 })
    const host = document.createElement('div')
    const app = createApp(PrivacyCenterView)
    app.mount(host)
    await flushView()

    clickButton(host, '确认隐私政策')
    await flushView()
    expect(privacyMocks.acceptPrivacyPolicy).toHaveBeenCalledWith({
      policyType: 1,
      version: '2026.07',
      locale: 'zh-CN',
      source: 3,
    })

    clickButton(host, '停用设备')
    await flushView()
    expect(privacyMocks.logoutUserDevice).toHaveBeenCalledWith(7)
    app.unmount()
  })

  it('downloads a ready export task through the authenticated service', async () => {
    privacyMocks.downloadPrivacyExport.mockResolvedValue(new Blob(['privacy']))
    const createObjectURL = vi.fn(() => 'blob:privacy-export')
    const revokeObjectURL = vi.fn()
    Object.defineProperty(URL, 'createObjectURL', { configurable: true, value: createObjectURL })
    Object.defineProperty(URL, 'revokeObjectURL', { configurable: true, value: revokeObjectURL })
    const anchorClick = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined)
    const host = document.createElement('div')
    const app = createApp(PrivacyCenterView)
    app.mount(host)
    await flushView()

    clickButton(host, '下载 ZIP')
    await flushView()

    expect(privacyMocks.downloadPrivacyExport).toHaveBeenCalledWith(8)
    expect(createObjectURL).toHaveBeenCalledTimes(1)
    expect(anchorClick).toHaveBeenCalledTimes(1)
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:privacy-export')
    app.unmount()
  })

  it('sends a delete code, creates a delete task, and cancels the cooling-off task', async () => {
    authMocks.sendAuthCode.mockResolvedValue({ nextRetrySeconds: 60, mockCode: '123456' })
    privacyMocks.createPrivacyDeleteTask.mockResolvedValue({ id: 12 })
    privacyMocks.fetchPrivacyOverview
      .mockResolvedValueOnce({
        exportRule: { dailyLimit: 2, defaultFormat: 'zip', expireHours: 24 },
        deleteRule: { coolingOffDays: 7, reverifyRequired: true },
        latestExportTask: null,
        latestDeleteTask: null,
      })
      .mockResolvedValue({
        exportRule: { dailyLimit: 2, defaultFormat: 'zip', expireHours: 24 },
        deleteRule: { coolingOffDays: 7, reverifyRequired: true },
        latestExportTask: null,
        latestDeleteTask: {
          id: 12,
          status: 1,
          statusText: '冷静期中',
          verifyType: 'code',
          account: 'demo.cn@example.com',
          reason: '暂时离开',
          coolingOffExpireAt: '2026-07-20 08:00:00',
          completedAt: null,
          cancelledAt: null,
          createdAt: '2026-07-13 08:00:00',
          updatedAt: '2026-07-13 08:00:00',
        },
      })
    privacyMocks.cancelPrivacyDeleteTask.mockResolvedValue({ id: 12, status: 4 })

    const host = document.createElement('div')
    const app = createApp(PrivacyCenterView)
    app.mount(host)
    await flushView()

    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="delete-reason"]')
    const code = host.querySelector<HTMLInputElement>('input[name="delete-code"]')
    if (!reason || !code) {
      throw new Error('注销表单不存在')
    }
    reason.value = '暂时离开'
    reason.dispatchEvent(new Event('input'))
    code.value = '123456'
    code.dispatchEvent(new Event('input'))

    clickButton(host, '发送注销验证码')
    await flushView()
    expect(authMocks.sendAuthCode).toHaveBeenCalledWith({
      scene: 'delete',
      type: 'email',
      account: 'demo.cn@example.com',
      deviceId: 'privacy-browser-device',
    })

    submitFormForButton(host, '提交删除申请')
    await flushView()
    expect(privacyMocks.createPrivacyDeleteTask).toHaveBeenCalledWith({
      verifyType: 'code',
      account: 'demo.cn@example.com',
      verifyCode: '123456',
      password: undefined,
      reason: '暂时离开',
    })

    clickButton(host, '撤销删除申请')
    await flushView()
    expect(privacyMocks.cancelPrivacyDeleteTask).toHaveBeenCalledWith(12)
    app.unmount()
  })
})
