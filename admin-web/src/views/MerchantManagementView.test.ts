import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminMerchants: vi.fn(),
  getAdminMerchant: vi.fn(),
  updateAdminMerchantStatus: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { permissions: string[]; region: 'CN' | 'EU' },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    permissions: ['system:merchant:read', 'system:merchant:write'],
    region: 'EU' as const,
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import MerchantManagementView from './MerchantManagementView.vue'

const merchants = [
  {
    id: 1001,
    account: 'merchant_cn_hotpot@example.com',
    companyName: '沪上渝里餐饮',
    contactName: '王磊',
    contactPhone: '13800138001',
    region: 'CN' as const,
    auditStatus: 1,
    auditStatusText: '已通过',
    status: 1,
    statusText: '正常',
    shopCount: 2,
    operatorCount: 3,
    activeOperatorCount: 2,
    disableReason: '',
    createdAt: '2026-01-01 08:00:00',
    updatedAt: '2026-07-30 10:00:00',
  },
  {
    id: 1002,
    account: 'merchant_cn_cafe@example.com',
    companyName: '梧桐咖啡',
    contactName: '陈晓',
    contactPhone: '13800138002',
    region: 'CN' as const,
    auditStatus: 0,
    auditStatusText: '待审核',
    status: 2,
    statusText: '已停用',
    shopCount: 1,
    operatorCount: 1,
    activeOperatorCount: 0,
    disableReason: '资质复核中',
    createdAt: '2026-01-02 08:00:00',
    updatedAt: '2026-07-31 10:00:00',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(MerchantManagementView)
  app.mount(host)
  return { app, host }
}

function click(host: HTMLElement, text: string, occurrence = 0) {
  const buttons = [...host.querySelectorAll('button')].filter((item) => item.textContent?.includes(text))
  const button = buttons[occurrence]
  if (!button) throw new Error(`missing button: ${text}`)
  button.click()
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing input: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

function select(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLSelectElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing select: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('change'))
}

describe('MerchantManagementView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.permissions = ['system:merchant:read', 'system:merchant:write']
    sessionMock.state.region = 'EU'
    mocks.listAdminMerchants.mockResolvedValue({ list: merchants, total: 2, page: 1, pageSize: 20, hasMore: false })
  })

  it('loads merchants and applies all filters including pending audit status', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminMerchants).toHaveBeenCalledWith({
      keyword: undefined,
      merchantId: undefined,
      auditStatus: undefined,
      status: undefined,
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('Merchant Accounts')
    expect(host.textContent).toContain('沪上渝里餐饮')
    expect(host.textContent).toContain('2 shops · 2/3 staff accounts active')

    input(host, 'merchant-keyword', '咖啡')
    input(host, 'merchant-id', '1002')
    select(host, 'merchant-audit-status', '0')
    select(host, 'merchant-status', '2')
    await nextTick()
    click(host, 'Apply filters')
    await flush()

    expect(mocks.listAdminMerchants).toHaveBeenLastCalledWith({
      keyword: '咖啡',
      merchantId: 1002,
      auditStatus: 0,
      status: 2,
      page: 1,
      pageSize: 20,
    })
    app.unmount()
  })

  it('loads merchant details and displays the latest disable reason', async () => {
    mocks.getAdminMerchant.mockResolvedValue(merchants[1])
    const { app, host } = mount()
    await flush()

    click(host, 'Details', 1)
    await flush()

    expect(mocks.getAdminMerchant).toHaveBeenCalledWith(1002)
    expect(host.textContent).toContain('Latest disable reason')
    expect(host.textContent).toContain('资质复核中')
    app.unmount()
  })

  it('requires a reason before disabling and refreshes after success', async () => {
    mocks.updateAdminMerchantStatus.mockResolvedValue({ ...merchants[0], status: 2 })
    const { app, host } = mount()
    await flush()

    click(host, 'Disable')
    await nextTick()
    click(host, 'Confirm disable')
    await flush()
    expect(mocks.updateAdminMerchantStatus).not.toHaveBeenCalled()
    expect(host.textContent).toContain('A disable reason is required.')

    const textarea = host.querySelector<HTMLTextAreaElement>('[name="disableReason"]')
    if (!textarea) throw new Error('missing textarea: disableReason')
    textarea.value = 'Repeated violations'
    textarea.dispatchEvent(new Event('input'))
    await nextTick()
    click(host, 'Confirm disable')
    await flush()

    expect(mocks.updateAdminMerchantStatus).toHaveBeenCalledWith(1001, {
      action: 'disable',
      reason: 'Repeated violations',
    })
    expect(mocks.listAdminMerchants).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('All merchant sessions were revoked.')
    app.unmount()
  })

  it('restores a disabled merchant', async () => {
    mocks.updateAdminMerchantStatus.mockResolvedValue({ ...merchants[1], status: 1 })
    const { app, host } = mount()
    await flush()

    click(host, 'Restore')
    await flush()

    expect(mocks.updateAdminMerchantStatus).toHaveBeenCalledWith(1002, { action: 'enable', reason: '' })
    expect(mocks.listAdminMerchants).toHaveBeenCalledTimes(2)
    app.unmount()
  })

  it('hides write actions when the admin has read-only permission', async () => {
    sessionMock.state.permissions = ['system:merchant:read']
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('Details')
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Disable'))).toBe(false)
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Restore'))).toBe(false)
    app.unmount()
  })
})
