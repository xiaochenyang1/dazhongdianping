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
    permissions: ['audit:merchant_verification:read', 'audit:merchant_verification:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import VerifiedMerchantAuditView from './VerifiedMerchantAuditView.vue'

const task = {
  id: 91,
  bizType: 9,
  bizTypeText: '认证商户',
  bizId: 2001,
  region: 'EU',
  status: 0,
  statusText: '待人审',
  shopId: 20001,
  shopName: 'Maison Sichuan Paris',
  submittedBy: 'Maison Sichuan SARL',
  summary: '商户资质已通过，申请认证标识。',
  remark: '',
  createdAt: '2026-07-25 11:00:00',
  updatedAt: '2026-07-25 11:00:00',
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
  const app = createApp(VerifiedMerchantAuditView)
  app.mount(host)
  return { app, host }
}

describe('VerifiedMerchantAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = [
      'audit:merchant_verification:read',
      'audit:merchant_verification:write',
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

  it('loads merchant verification applications and keeps the authorized approval flow', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 9,
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('Verified Merchants')
    expect(host.textContent).toContain('Maison Sichuan SARL')

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')].find((button) =>
      button.textContent?.includes('Approve verification'),
    )
    if (!passButton) throw new Error('找不到认证商户通过按钮')
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(91, { remark: undefined })
    app.unmount()
  })

  it('preserves details but blocks stale approval controls after write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')].find((button) =>
      button.textContent?.includes('Approve verification'),
    )
    const rejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')].find((button) =>
      button.textContent?.includes('Reject application'),
    )
    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!passButton || !rejectButton || !reason) throw new Error('找不到认证商户处理控件')
    reason.value = '撤权后不应提交'
    reason.dispatchEvent(new Event('input'))

    sessionMock.state.permissions = ['audit:merchant_verification:read']
    passButton.click()
    rejectButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).not.toHaveBeenCalled()
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()
    expect(host.textContent).toContain('Maison Sichuan SARL')
    expect(host.textContent).toContain('This account is read-only and cannot process merchant verification tasks.')
    expect(host.querySelector('textarea[name="approve-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="reject-reason"]')).toBeNull()
    app.unmount()
  })
})
