import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ listMerchantApplications: vi.fn(), auditMerchantApplication: vi.fn() }))
const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['audit:merchant_application:read', 'audit:merchant_application:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import MerchantApplicationAuditView from './MerchantApplicationAuditView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function pendingApplication() {
  return {
    merchantId: 77,
    merchantAccount: 'owner@example.com',
    companyName: 'North Star Foods',
    region: 'EU',
    licenseUrl: 'https://files.example/license.png',
    legalPerson: 'Alice',
    shopPhotoUrls: ['https://files.example/shop.png'],
    status: 0,
    statusText: '待审核',
    rejectReason: '',
    submittedAt: '2026-07-18 08:00:00',
    auditedAt: '',
  }
}

function processedApplication() {
  return {
    ...pendingApplication(),
    merchantId: 78,
    merchantAccount: 'approved@example.com',
    companyName: 'Approved Foods',
    status: 1,
    statusText: '已通过',
    auditedAt: '2026-07-18 10:00:00',
  }
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(MerchantApplicationAuditView)
  app.mount(host)
  return { app, host }
}

function click(host: HTMLElement, text: string) {
  const button = [...host.querySelectorAll('button')].find((item) => item.textContent?.includes(text))
  if (!button) throw new Error(`missing button ${text}`)
  button.click()
}

describe('MerchantApplicationAuditView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['audit:merchant_application:read', 'audit:merchant_application:write']
    mocks.listMerchantApplications.mockResolvedValue({ list: [pendingApplication()], total: 1, page: 1, pageSize: 20, hasMore: false })
    mocks.auditMerchantApplication.mockResolvedValue({ ...pendingApplication(), status: 1, statusText: '已通过' })
  })

  it('loads pending applications and approves one', async () => {
    const { app, host } = mountView()
    await flushView()
    expect(mocks.listMerchantApplications).toHaveBeenCalledWith({ status: 0, page: 1, pageSize: 20 })
    expect(host.textContent).toContain('Merchant Applications')
    expect(host.textContent).toContain('North Star Foods')
    click(host, 'Approve application')
    await flushView()
    expect(mocks.auditMerchantApplication).toHaveBeenCalledWith(77, { status: 1, reason: '' })
    app.unmount()
  })

  it('requires a rejection reason before sending the decision', async () => {
    const { app, host } = mountView()
    await flushView()
    click(host, 'Reject application')
    await nextTick()
    click(host, 'Confirm rejection')
    await nextTick()
    expect(host.textContent).toContain('A rejection reason is required.')
    expect(mocks.auditMerchantApplication).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLTextAreaElement>('[name="rejectReason"]')
    if (!reason) throw new Error('missing rejectReason')
    reason.value = '执照图片无法识别'
    reason.dispatchEvent(new Event('input'))
    click(host, 'Confirm rejection')
    await flushView()
    expect(mocks.auditMerchantApplication).toHaveBeenCalledWith(77, { status: 2, reason: '执照图片无法识别' })
    app.unmount()
  })

  it('preserves application browsing while hiding mutation controls from read-only users', async () => {
    sessionMock.state.permissions = ['audit:merchant_application:read']
    mocks.listMerchantApplications.mockResolvedValue({
      list: [pendingApplication(), processedApplication()],
      total: 2,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    const { app, host } = mountView()
    await flushView()

    expect(host.textContent).toContain('North Star Foods')
    expect(host.textContent).toContain('Approved Foods')
    expect(host.textContent).toContain('This account is read-only and cannot process merchant applications.')
    expect(host.textContent).toContain('Processed')
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Approve application'))).toBe(false)
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Reject application'))).toBe(false)
    expect(host.querySelector('[name="rejectReason"]')).toBeNull()
    app.unmount()
  })

  it('blocks stale approval and rejection controls after write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Approve application'))
    const openRejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Reject application'))
    if (!passButton || !openRejectButton) throw new Error('missing merchant application audit buttons')
    openRejectButton.click()
    await nextTick()

    const reason = host.querySelector<HTMLTextAreaElement>('[name="rejectReason"]')
    const rejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Confirm rejection'))
    if (!reason || !rejectButton) throw new Error('missing opened merchant application rejection controls')
    reason.value = '执照图片无法识别'
    reason.dispatchEvent(new Event('input'))

    sessionMock.state.permissions = ['audit:merchant_application:read']
    passButton.click()
    rejectButton.click()
    openRejectButton.click()
    await flushView()

    expect(mocks.auditMerchantApplication).not.toHaveBeenCalled()
    expect(host.querySelector('[name="rejectReason"]')).toBeNull()
    expect(host.textContent).toContain('This account is read-only and cannot process merchant applications.')
    app.unmount()
  })
})
