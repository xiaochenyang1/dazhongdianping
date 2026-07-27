import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAuditTasks: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['audit:review_appeal:read', 'audit:review_appeal:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import ReviewAppealAuditView from './ReviewAppealAuditView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(ReviewAppealAuditView)
  app.mount(host)
  return { app, host }
}

function pendingTask() {
  return {
    id: 76,
    bizType: 6,
    bizTypeText: '商户点评申诉',
    bizId: 901,
    region: 'EU' as const,
    status: 0,
    statusText: '待人审',
    shopId: 20001,
    shopName: '巴黎川味馆',
    submittedBy: '巴黎川味餐饮',
    summary: '该点评包含与实际消费无关的恶意辱骂。',
    remark: '',
    createdAt: '2026-07-24 13:00:00',
    updatedAt: '2026-07-24 13:00:00',
  }
}

describe('ReviewAppealAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = [
      'audit:review_appeal:read',
      'audit:review_appeal:write',
    ]
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [pendingTask()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
  })

  it('loads review appeals and passes the selected pending task', async () => {
    adminMocks.passAuditTask.mockResolvedValue({
      ...pendingTask(),
      status: 1,
      statusText: '通过',
    })
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 6,
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('该点评包含与实际消费无关的恶意辱骂。')

    const remark = host.querySelector<HTMLTextAreaElement>(
      'textarea[name="review-appeal-pass-remark"]',
    )
    const passButton = host.querySelector<HTMLButtonElement>(
      '[data-testid="review-appeal-pass"]',
    )
    if (!remark || !passButton) throw new Error('找不到申诉通过控件')
    remark.value = '商户证据完整'
    remark.dispatchEvent(new Event('input'))
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(76, { remark: '商户证据完整' })
    expect(host.textContent).toContain('点评已隐藏')
    app.unmount()
  })

  it('requires a reason and rejects the selected pending task', async () => {
    adminMocks.rejectAuditTask.mockResolvedValue({
      ...pendingTask(),
      status: 2,
      statusText: '驳回',
    })
    const { app, host } = mountView()
    await flushView()

    const rejectButton = host.querySelector<HTMLButtonElement>(
      '[data-testid="review-appeal-reject"]',
    )
    const reason = host.querySelector<HTMLTextAreaElement>(
      'textarea[name="review-appeal-reject-reason"]',
    )
    if (!rejectButton || !reason) throw new Error('找不到申诉驳回控件')

    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('驳回原因不能为空')
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()

    reason.value = '点评内容未违反平台规则'
    reason.dispatchEvent(new Event('input'))
    rejectButton.click()
    await flushView()

    expect(adminMocks.rejectAuditTask).toHaveBeenCalledWith(76, {
      reason: '点评内容未违反平台规则',
    })
    app.unmount()
  })

  it('keeps appeal list and details visible while hiding write controls from read-only users', async () => {
    sessionMock.state.permissions = ['audit:review_appeal:read']
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('该点评包含与实际消费无关的恶意辱骂。')
    expect(host.textContent).toContain('当前账号仅可查看，无申诉处理权限。')
    expect(host.querySelector('textarea[name="review-appeal-pass-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="review-appeal-reject-reason"]')).toBeNull()
    expect(host.querySelector('[data-testid="review-appeal-pass"]')).toBeNull()
    expect(host.querySelector('[data-testid="review-appeal-reject"]')).toBeNull()
    app.unmount()
  })

  it('blocks stale pass and reject controls when write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const passButton = host.querySelector<HTMLButtonElement>(
      '[data-testid="review-appeal-pass"]',
    )
    const rejectButton = host.querySelector<HTMLButtonElement>(
      '[data-testid="review-appeal-reject"]',
    )
    if (!passButton || !rejectButton) throw new Error('找不到申诉处理按钮')

    sessionMock.state.permissions = ['audit:review_appeal:read']
    passButton.click()
    rejectButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).not.toHaveBeenCalled()
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="review-appeal-pass"]')).toBeNull()
    expect(host.querySelector('[data-testid="review-appeal-reject"]')).toBeNull()
    expect(host.textContent).toContain('当前账号仅可查看，无申诉处理权限。')
    app.unmount()
  })
})
