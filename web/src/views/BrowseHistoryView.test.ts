import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const historyMocks = vi.hoisted(() => ({
  fetchBrowseHistory: vi.fn(),
  clearBrowseHistory: vi.fn(),
  removeBrowseHistoryItem: vi.fn(),
}))

const appContextMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU' },
}))

vi.mock('@/services/browse-history', () => historyMocks)
vi.mock('@/composables/useAppContext', async () => {
  const { reactive } = await import('vue')
  appContextMock.state = reactive({ region: 'CN' as const })
  return { useAppContext: () => ({ state: appContextMock.state }) }
})
vi.mock('vue-router', () => ({
  RouterLink: {
    name: 'RouterLink',
    props: ['to'],
    template: '<a><slot /></a>',
  },
}))

import BrowseHistoryView from './BrowseHistoryView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const items = [
  {
    id: 1,
    shopId: 10001,
    shopName: '渝里火锅徐汇店',
    coverUrl: 'https://example.com/a.jpg',
    score: 4.6,
    pricePerCapita: 88,
    currency: 'CNY',
    address: '徐汇路 1 号',
    cityName: '上海',
    areaName: '徐汇',
    hasDeal: true,
    openNow: true,
    tags: ['火锅'],
    viewCount: 2,
    lastViewedAt: '2026-07-24 20:00',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(BrowseHistoryView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

describe('BrowseHistoryView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(historyMocks).forEach((mock) => mock.mockReset())
    appContextMock.state.region = 'CN'
    historyMocks.fetchBrowseHistory.mockResolvedValue({ list: items, total: 1, page: 1, pageSize: 50, hasMore: false })
    historyMocks.clearBrowseHistory.mockResolvedValue(undefined)
    historyMocks.removeBrowseHistoryItem.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads browse history for the current region', async () => {
    const { app, host } = mount()
    await flush()
    expect(historyMocks.fetchBrowseHistory).toHaveBeenCalledWith(1, 50)
    expect(host.textContent).toContain('渝里火锅徐汇店')
    expect(host.textContent).toContain('看过 2 次')
    app.unmount()
  })

  it('removes one history item and can clear all', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    const removeButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('移除'))
    removeButton?.click()
    await flush()
    expect(historyMocks.removeBrowseHistoryItem).toHaveBeenCalledWith(10001)

    historyMocks.fetchBrowseHistory.mockResolvedValue({ list: items, total: 1, page: 1, pageSize: 50, hasMore: false })
    // remount with items again for clear path
    app.unmount()
    const second = mount()
    await flush()
    second.host.querySelector<HTMLButtonElement>('[data-testid="clear-browse-history"]')?.click()
    await flush()
    expect(confirm).toHaveBeenCalled()
    expect(historyMocks.clearBrowseHistory).toHaveBeenCalled()
    second.app.unmount()
  })
})
