import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchVerifiedCertification: vi.fn(),
  applyVerifiedCertification: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'EU' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import VerifiedCertificationView from './VerifiedCertificationView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(VerifiedCertificationView)
  app.mount(host)
  return { app, host }
}

describe('VerifiedCertificationView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
  })

  it('renders a rejected application and resubmits it', async () => {
    mocks.fetchVerifiedCertification.mockResolvedValue({
      id: 15,
      status: 3,
      statusText: '已驳回',
      reason: 'Old reason',
      evidenceUrls: ['https://old.example/proof.png'],
      rejectReason: 'Evidence blurred',
      badge: null,
      submittedAt: '2026-07-20 10:00:00',
      auditedAt: '2026-07-21 11:00:00',
      effectiveStartAt: '',
      effectiveEndAt: '',
    })
    mocks.applyVerifiedCertification.mockResolvedValue({
      id: 15,
      status: 1,
      statusText: '待审核',
      reason: 'Service standards and compliance evidence are attached.',
      evidenceUrls: ['https://new.example/proof.png'],
      rejectReason: '',
      badge: null,
      submittedAt: '2026-07-29 09:00:00',
      auditedAt: '',
      effectiveStartAt: '',
      effectiveEndAt: '',
    })

    const { app, host } = mountView()
    await flushView()

    expect(host.textContent).toContain('Rejected')
    expect(host.textContent).toContain('Evidence blurred')
    expect(host.textContent).toContain('Resubmit verified merchant application')

    const textareas = host.querySelectorAll<HTMLTextAreaElement>('textarea')
    textareas[0].value = 'Service standards and compliance evidence are attached.'
    textareas[0].dispatchEvent(new Event('input'))
    textareas[1].value = 'https://new.example/proof.png'
    textareas[1].dispatchEvent(new Event('input'))
    host.querySelector('form')?.dispatchEvent(new Event('submit'))
    await flushView()

    expect(mocks.applyVerifiedCertification).toHaveBeenCalledWith({
      reason: 'Service standards and compliance evidence are attached.',
      evidenceUrls: ['https://new.example/proof.png'],
    })
    expect(host.textContent).toContain('Verified merchant application submitted. Awaiting review.')
    expect(host.textContent).toContain('Pending review')
    app.unmount()
  })
})
