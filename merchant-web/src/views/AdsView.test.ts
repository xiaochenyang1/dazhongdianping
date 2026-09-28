import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchAds: vi.fn(),
  fetchShops: vi.fn(),
  createAd: vi.fn(),
  updateAd: vi.fn(),
  pauseAd: vi.fn(),
  resumeAd: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'CN' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import AdsView from './AdsView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function campaign(overrides: Record<string, unknown> = {}) {
  return {
    id: 8001, shopId: 10001, shopName: '沪上渝里', name: '火锅推广', slotType: 1,
    slotTypeText: '搜索结果', keyword: '火锅', bidCpc: 2.5, dailyBudget: 100, spentToday: 0,
    totalSpent: 0, status: 1, statusText: '投放中', auditStatus: 2, auditStatusText: '已通过',
    rejectReason: '', ...overrides,
  }
}

function mountView(permissions = ['ad:view', 'ad:manage']) {
  const host = document.createElement('div')
  const app = createApp(AdsView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('AdsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionState.region = 'CN'
    mocks.fetchAds.mockResolvedValue({ list: [campaign()], total: 1, page: 1, pageSize: 50, hasMore: false })
    mocks.fetchShops.mockResolvedValue({ list: [{ id: 10001, name: '沪上渝里' }], total: 1, page: 1, pageSize: 100, hasMore: false })
    mocks.createAd.mockResolvedValue(campaign({ id: 8009 }))
    mocks.pauseAd.mockResolvedValue(campaign({ status: 2 }))
  })

  it('lists campaigns and creates one', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchAds).toHaveBeenCalled()
    expect(host.textContent).toContain('火锅推广')

    const createBtn = Array.from(host.querySelectorAll('button')).find((b) => b.textContent === '新建投放')
    createBtn?.dispatchEvent(new Event('click'))
    await flushView()

    const nameInput = host.querySelector<HTMLInputElement>('.ad-form input[type="text"]')
    nameInput!.value = '新推广'
    nameInput!.dispatchEvent(new Event('input'))
    host.querySelector('.ad-form')?.dispatchEvent(new Event('submit', { cancelable: true }))
    await flushView()

    expect(mocks.createAd).toHaveBeenCalled()
    expect(mocks.createAd.mock.calls[0][0].name).toBe('新推广')
  })

  it('pauses a serving campaign', async () => {
    const { host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="toggle-8001"]')!.dispatchEvent(new Event('click'))
    await flushView()
    expect(mocks.pauseAd).toHaveBeenCalledWith(8001)
  })

  it('hides management controls without ad:manage', async () => {
    const { host } = mountView(['ad:view'])
    await flushView()
    expect(Array.from(host.querySelectorAll('button')).some((b) => b.textContent === '新建投放')).toBe(false)
    expect(host.querySelector('[data-testid="toggle-8001"]')).toBeNull()
  })
})
