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
    permissions: ['audit:expert_certification:read', 'audit:expert_certification:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import ExpertCertificationAuditView from './ExpertCertificationAuditView.vue'

const task = {
  id: 71,
  bizType: 7,
  bizTypeText: '达人认证',
  bizId: 9007,
  region: 'EU',
  status: 0,
  statusText: '待人审',
  shopId: null,
  shopName: '',
  submittedBy: '伦敦探店家',
  summary: '长期发布伦敦餐厅实地探访。',
  remark: '',
  createdAt: '2026-07-25 10:00:00',
  updatedAt: '2026-07-25 10:00:00',
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(ExpertCertificationAuditView)
  app.mount(host)
  return { app, host }
}

describe('ExpertCertificationAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = [
      'audit:expert_certification:read',
      'audit:expert_certification:write',
    ]
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [task],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
    adminMocks.passAuditTask.mockResolvedValue({ ...task, status: 1, statusText: '通过' })
  })

  it('loads expert applications and keeps the authorized approval flow', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 7,
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('Expert Certifications')
    expect(host.textContent).toContain('长期发布伦敦餐厅实地探访')

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')].find((button) =>
      button.textContent?.includes('Approve certification'),
    )
    if (!passButton) throw new Error('找不到达人认证通过按钮')
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(71, { remark: undefined })
    app.unmount()
  })

  it('preserves details but blocks stale approval controls after write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')].find((button) =>
      button.textContent?.includes('Approve certification'),
    )
    const rejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')].find((button) =>
      button.textContent?.includes('Reject application'),
    )
    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!passButton || !rejectButton || !reason) throw new Error('找不到达人认证处理控件')
    reason.value = '撤权后不应提交'
    reason.dispatchEvent(new Event('input'))

    sessionMock.state.permissions = ['audit:expert_certification:read']
    passButton.click()
    rejectButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).not.toHaveBeenCalled()
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()
    expect(host.textContent).toContain('长期发布伦敦餐厅实地探访')
    expect(host.textContent).toContain('This account is read-only and cannot process certifications.')
    expect(host.querySelector('textarea[name="approve-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="reject-reason"]')).toBeNull()
    app.unmount()
  })
})
