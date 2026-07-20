import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ listMerchantApplications: vi.fn(), auditMerchantApplication: vi.fn() }))
vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({ useAdminSession: () => ({ state: { region: 'EU' } }) }))

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
    mocks.listMerchantApplications.mockResolvedValue({ list: [pendingApplication()], total: 1, page: 1, pageSize: 20, hasMore: false })
    mocks.auditMerchantApplication.mockResolvedValue({ ...pendingApplication(), status: 1, statusText: '已通过' })
  })

  it('loads pending applications and approves one', async () => {
    const { app, host } = mountView()
    await flushView()
    expect(mocks.listMerchantApplications).toHaveBeenCalledWith({ status: 0, page: 1, pageSize: 20 })
    expect(host.textContent).toContain('North Star Foods')
    click(host, '通过申请')
    await flushView()
    expect(mocks.auditMerchantApplication).toHaveBeenCalledWith(77, { status: 1, reason: '' })
    app.unmount()
  })

  it('requires a rejection reason before sending the decision', async () => {
    const { app, host } = mountView()
    await flushView()
    click(host, '驳回申请')
    await nextTick()
    click(host, '确认驳回')
    await nextTick()
    expect(host.textContent).toContain('驳回原因不能为空')
    expect(mocks.auditMerchantApplication).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLTextAreaElement>('[name="rejectReason"]')
    if (!reason) throw new Error('missing rejectReason')
    reason.value = '执照图片无法识别'
    reason.dispatchEvent(new Event('input'))
    click(host, '确认驳回')
    await flushView()
    expect(mocks.auditMerchantApplication).toHaveBeenCalledWith(77, { status: 2, reason: '执照图片无法识别' })
    app.unmount()
  })
})
