import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const serviceMocks = vi.hoisted(() => ({ fetchSettlementStatus: vi.fn(), submitSettlement: vi.fn() }))

vi.mock('@/services/merchant', () => serviceMocks)
vi.mock('vue-router', () => ({ RouterLink: { props: ['to'], template: '<a><slot /></a>' } }))

import SettlementView from './SettlementView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(SettlementView)
  app.mount(host)
  return { app, host }
}

describe('SettlementView', () => {
  beforeEach(() => {
    Object.values(serviceMocks).forEach((mock) => mock.mockReset())
  })

  it('prefills a rejected application and resubmits the edited evidence', async () => {
    serviceMocks.fetchSettlementStatus.mockResolvedValue({
      merchantId: 7,
      licenseUrl: 'https://old.example/license.png',
      legalPerson: 'Alice',
      shopPhotoUrls: ['https://old.example/shop.png'],
      status: 2,
      statusText: '已驳回',
      rejectReason: '执照图片模糊',
    })
    serviceMocks.submitSettlement.mockResolvedValue({ status: 0, statusText: '待审核' })
    const { app, host } = mountView()
    await flushView()

    expect(host.textContent).toContain('执照图片模糊')
    const license = host.querySelector<HTMLInputElement>('[name="licenseUrl"]')
    if (!license) throw new Error('missing licenseUrl')
    license.value = 'https://new.example/license.png'
    license.dispatchEvent(new Event('input'))
    host.querySelector('form')?.dispatchEvent(new Event('submit'))
    await flushView()

    expect(serviceMocks.submitSettlement).toHaveBeenCalledWith({
      licenseUrl: 'https://new.example/license.png',
      legalPerson: 'Alice',
      shopPhotoUrls: ['https://old.example/shop.png'],
    })
    expect(host.textContent).toContain('待审核')
    app.unmount()
  })

  it('keeps a pending application read only', async () => {
    serviceMocks.fetchSettlementStatus.mockResolvedValue({
      merchantId: 7,
      licenseUrl: 'https://files.example/license.png',
      legalPerson: 'Alice',
      shopPhotoUrls: ['https://files.example/shop.png'],
      status: 0,
      statusText: '待审核',
    })
    const { app, host } = mountView()
    await flushView()
    expect(host.textContent).toContain('资料已经进入审核队列')
    expect(host.querySelector('form')).toBeNull()
    app.unmount()
  })
})
