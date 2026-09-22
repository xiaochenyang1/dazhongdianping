import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchShops: vi.fn(),
  fetchWaitlistQueue: vi.fn(),
  callWaitlist: vi.fn(),
  seatWaitlist: vi.fn(),
  passWaitlist: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'CN' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import WaitlistView from './WaitlistView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function entry(overrides: Record<string, unknown> = {}) {
  return {
    id: 1, shopId: 10001, shopName: '沪上渝里', userId: 9001, userNickname: '阿木',
    tableType: 1, tableTypeText: '小桌', partySize: 2, queueNo: 1, status: 1, statusText: '排队中',
    aheadCount: 0, ...overrides,
  }
}

function mountView(permissions = ['waitlist:view', 'waitlist:manage']) {
  const host = document.createElement('div')
  const app = createApp(WaitlistView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('WaitlistView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionState.region = 'CN'
    mocks.fetchShops.mockResolvedValue({ list: [{ id: 10001, name: '沪上渝里' }], total: 1, page: 1, pageSize: 100, hasMore: false })
    mocks.fetchWaitlistQueue.mockResolvedValue([entry()])
    mocks.callWaitlist.mockResolvedValue(entry({ status: 2 }))
  })

  it('loads the queue and calls a party', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchWaitlistQueue).toHaveBeenCalledWith(10001)
    expect(host.textContent).toContain('阿木')

    host.querySelector<HTMLButtonElement>('[data-testid="call-1"]')!.dispatchEvent(new Event('click'))
    await flushView()
    expect(mocks.callWaitlist).toHaveBeenCalledWith(1)
  })

  it('hides actions without waitlist:manage', async () => {
    const { host } = mountView(['waitlist:view'])
    await flushView()
    expect(host.querySelector('[data-testid="call-1"]')).toBeNull()
  })
})
