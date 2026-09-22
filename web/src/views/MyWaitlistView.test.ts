import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const appState = vi.hoisted(() => ({ region: 'CN' as 'CN' | 'EU' }))
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state: appState }) }))

const mocks = vi.hoisted(() => ({
  joinWaitlist: vi.fn(),
  fetchMyWaitlist: vi.fn(),
  cancelWaitlist: vi.fn(),
}))
vi.mock('@/services/waitlist', () => mocks)

import MyWaitlistView from './MyWaitlistView.vue'

async function flush() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(MyWaitlistView)
  app.mount(host)
  return { app, host }
}

function entry(overrides: Record<string, unknown> = {}) {
  return {
    id: 1, shopId: 10001, shopName: '沪上渝里', tableType: 1, tableTypeText: '小桌',
    partySize: 2, queueNo: 3, status: 1, statusText: '排队中', aheadCount: 2, ...overrides,
  }
}

describe('MyWaitlistView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((m) => m.mockReset())
    appState.region = 'CN'
    mocks.fetchMyWaitlist.mockResolvedValue([entry()])
    mocks.cancelWaitlist.mockResolvedValue(entry({ status: 5 }))
  })

  it('lists active queue with ahead count and cancels', async () => {
    const { host } = mount()
    await flush()

    expect(mocks.fetchMyWaitlist).toHaveBeenCalled()
    expect(host.textContent).toContain('沪上渝里')
    expect(host.textContent).toContain('前面还有 2 桌')

    host.querySelector<HTMLButtonElement>('[data-testid="cancel-1"]')!.dispatchEvent(new Event('click'))
    await flush()
    expect(mocks.cancelWaitlist).toHaveBeenCalledWith(1)
  })
})
