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
    permissions: ['audit:review:read', 'audit:review:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import AuditReviewView from './AuditReviewView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(AuditReviewView)
  app.mount(host)
  return { app, host }
}

function pendingTask() {
  return {
    id: 31,
    bizType: 3,
    bizTypeText: '点评审核',
    bizId: 19,
    region: 'EU',
    status: 0,
    statusText: '待人审',
    shopId: 20001,
    shopName: 'Paris Bistro',
    submittedBy: '巴黎食客',
    summary: '服务细致，晚餐套餐搭配合理。',
    remark: '',
    createdAt: '2026-07-16 09:00:00',
    updatedAt: '2026-07-16 09:00:00',
  }
}

describe('AuditReviewView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['audit:review:read', 'audit:review:write']
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [pendingTask()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
  })

  it('loads pending review audits and passes the selected task', async () => {
    adminMocks.passAuditTask.mockResolvedValue({ ...pendingTask(), status: 1, statusText: '通过' })
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 3,
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('Review Audit')
    expect(host.textContent).toContain('服务细致，晚餐套餐搭配合理')

    const remark = host.querySelector<HTMLTextAreaElement>('textarea[name="approve-remark"]')
    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Approve review'))
    if (!remark || !passButton) throw new Error('找不到点评审核通过控件')
    remark.value = '内容真实'
    remark.dispatchEvent(new Event('input'))
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(31, { remark: '内容真实' })
    app.unmount()
  })

  it('requires a reason and rejects the selected review audit', async () => {
    adminMocks.rejectAuditTask.mockResolvedValue({ ...pendingTask(), status: 2, statusText: '驳回' })
    const { app, host } = mountView()
    await flushView()

    const rejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Reject review'))
    if (!rejectButton) throw new Error('找不到驳回点评按钮')
    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('A rejection reason is required.')
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!reason) throw new Error('找不到点评驳回原因输入框')
    reason.value = '点评包含广告引流'
    reason.dispatchEvent(new Event('input'))
    rejectButton.click()
    await flushView()

    expect(adminMocks.rejectAuditTask).toHaveBeenCalledWith(31, { reason: '点评包含广告引流' })
    app.unmount()
  })

  it('keeps list and detail browsing while hiding write controls from read-only users', async () => {
    sessionMock.state.permissions = ['audit:review:read']
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('Paris Bistro')
    expect(host.textContent).toContain('服务细致，晚餐套餐搭配合理')
    expect(host.textContent).toContain('This account is read-only and cannot process review audits.')
    expect(host.querySelector('textarea[name="approve-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="reject-reason"]')).toBeNull()
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Approve review'))).toBe(false)
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Reject review'))).toBe(false)
    app.unmount()
  })

  it('blocks mutations through stale buttons after write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Approve review'))
    const rejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Reject review'))
    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!passButton || !rejectButton || !reason) throw new Error('找不到点评审核写入控件')
    reason.value = '点评包含广告引流'
    reason.dispatchEvent(new Event('input'))

    sessionMock.state.permissions = ['audit:review:read']
    passButton.click()
    rejectButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).not.toHaveBeenCalled()
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()
    expect(host.querySelector('textarea[name="approve-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="reject-reason"]')).toBeNull()
    app.unmount()
  })
})
