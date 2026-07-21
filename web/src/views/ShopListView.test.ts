import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  fetchAreas: vi.fn(),
  fetchCategories: vi.fn(),
  fetchCities: vi.fn(),
  fetchShops: vi.fn(),
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: { region: 'EU', cityId: 101 }, setCityId: vi.fn() }),
}))
vi.mock('vue-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('vue-router')>()
  return {
    ...actual,
    RouterLink: { props: ['to'], template: '<a><slot /></a>' },
    useRoute: () => ({ query: {} }),
  }
})
vi.mock('@/components/ShopCard.vue', () => ({
  default: { props: ['shop'], template: '<div data-testid="shop-name">{{ shop.name }}</div>' },
}))

import ShopListView from './ShopListView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(ShopListView)
  app.component('RouterLink', { props: ['to'], template: '<a><slot /></a>' })
  app.mount(host)
  return { app, host }
}

function setInput(host: HTMLElement, testId: string, value: string) {
  const input = host.querySelector<HTMLInputElement>(`[data-testid="${testId}"]`)
  if (!input) throw new Error(`missing input ${testId}`)
  input.value = value
  input.dispatchEvent(new Event('input', { bubbles: true }))
}

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((nextResolve, nextReject) => {
    resolve = nextResolve
    reject = nextReject
  })
  return { promise, resolve, reject }
}

function applyFilters(host: HTMLElement) {
  const button = [...host.querySelectorAll('button')]
    .find((item) => item.textContent?.includes('应用筛选'))
  if (!button) throw new Error('missing apply filters button')
  button.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
}

describe('ShopListView', () => {
  beforeEach(() => {
    Object.values(browseMocks).forEach((mock) => mock.mockReset())
    browseMocks.fetchCategories.mockResolvedValue([{ id: 200, name: 'Dining', children: [] }])
    browseMocks.fetchCities.mockResolvedValue([{ id: 101, code: 'PAR', name: 'Paris' }])
    browseMocks.fetchAreas.mockResolvedValue([{ id: 1011, name: 'Le Marais' }])
    browseMocks.fetchShops.mockResolvedValue({
      list: [{ id: 1, name: 'First shop' }],
      total: 1,
      page: 1,
      pageSize: 12,
      hasMore: false,
    })
  })

  it('sends price score deal and open filters to the search endpoint', async () => {
    const { app, host } = mount()
    await flush()
    expect(host.textContent).toContain('First shop')

    setInput(host, 'filter-min-price', '10')
    setInput(host, 'filter-max-price', '50')
    setInput(host, 'filter-min-score', '4.5')
    const dealSelect = host.querySelector<HTMLSelectElement>('[data-testid="filter-has-deal"]')
    const openSelect = host.querySelector<HTMLSelectElement>('[data-testid="filter-open-now"]')
    if (!dealSelect || !openSelect) throw new Error('missing boolean filters')
    dealSelect.value = 'true'
    dealSelect.dispatchEvent(new Event('change', { bubbles: true }))
    openSelect.value = 'true'
    openSelect.dispatchEvent(new Event('change', { bubbles: true }))
    await nextTick()

    const apply = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('应用筛选'))
    expect(apply).toBeDefined()
    apply?.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
    await flush()

    expect(browseMocks.fetchShops).toHaveBeenCalledTimes(2)
    expect(browseMocks.fetchShops).toHaveBeenLastCalledWith(expect.objectContaining({
      cityId: 101,
      minPrice: 10,
      maxPrice: 50,
      minScore: 4.5,
      hasDeal: true,
      openNow: true,
      page: 1,
      pageSize: 12,
    }))
    app.unmount()
  })

  it('loads the next real page and appends results without losing the server total', async () => {
    browseMocks.fetchShops
      .mockResolvedValueOnce({
        list: [{ id: 1, name: 'First shop' }],
        total: 2,
        page: 1,
        pageSize: 12,
        hasMore: true,
      })
      .mockResolvedValueOnce({
        list: [{ id: 2, name: 'Second shop' }],
        total: 2,
        page: 2,
        pageSize: 12,
        hasMore: false,
      })

    const { app, host } = mount()
    await flush()
    expect(host.textContent).toContain('First shop')

    const loadMore = host.querySelector<HTMLButtonElement>('[data-testid="load-more-shops"]')
    expect(loadMore).not.toBeNull()
    loadMore?.click()
    await flush()

    expect(browseMocks.fetchShops).toHaveBeenNthCalledWith(2, expect.objectContaining({ page: 2, pageSize: 12 }))
    expect(host.textContent).toContain('First shop')
    expect(host.textContent).toContain('Second shop')
    expect(host.textContent).toContain('当前命中2')
    expect(host.querySelector('[data-testid="load-more-shops"]')).toBeNull()
    app.unmount()
  })

  it('keeps the newest filter result when an older request resolves later', async () => {
    const { app, host } = mount()
    await flush()
    const older = deferred<any>()
    const newer = deferred<any>()
    browseMocks.fetchShops.mockReset()
    browseMocks.fetchShops.mockImplementation((query: { minPrice?: number }) => (
      query.minPrice === 10 ? older.promise : newer.promise
    ))

    setInput(host, 'filter-min-price', '10')
    applyFilters(host)
    await nextTick()
    setInput(host, 'filter-min-price', '20')
    applyFilters(host)
    await nextTick()

    newer.resolve({ list: [{ id: 2, name: 'Newest shop' }], total: 1, page: 1, pageSize: 12, hasMore: false })
    await flush()
    older.resolve({ list: [{ id: 3, name: 'Stale shop' }], total: 1, page: 1, pageSize: 12, hasMore: false })
    await flush()

    expect(host.textContent).toContain('Newest shop')
    expect(host.textContent).not.toContain('Stale shop')
    app.unmount()
  })

  it('shows an area loading error when changing cities instead of leaking a rejected promise', async () => {
    browseMocks.fetchCities.mockResolvedValue([
      { id: 101, code: 'PAR', name: 'Paris' },
      { id: 102, code: 'BER', name: 'Berlin' },
    ])
    const { app, host } = mount()
    await flush()
    browseMocks.fetchAreas.mockRejectedValueOnce(new Error('商圈加载失败'))
    browseMocks.fetchShops.mockClear()

    const citySelect = host.querySelector<HTMLSelectElement>('select')
    if (!citySelect) throw new Error('missing city select')
    citySelect.value = '102'
    citySelect.dispatchEvent(new Event('change', { bubbles: true }))
    await flush()

    expect(host.textContent).toContain('商圈加载失败')
    expect(browseMocks.fetchShops).not.toHaveBeenCalled()
    app.unmount()
  })
})
