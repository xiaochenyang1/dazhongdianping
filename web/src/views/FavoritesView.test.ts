import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const favoriteMocks = vi.hoisted(() => ({
  fetchFavorites: vi.fn(),
  removeFavorite: vi.fn(),
}))
const appContextMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU' },
}))

vi.mock('@/services/favorite', () => favoriteMocks)
vi.mock('@/composables/useAppContext', async () => {
  const { reactive } = await import('vue')
  appContextMock.state = reactive({ region: 'CN' as 'CN' | 'EU' })
  return { useAppContext: () => ({ state: appContextMock.state }) }
})
vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>' },
}))

import FavoritesView from './FavoritesView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(FavoritesView)
  app.mount(host)
  return { app, host }
}

describe('FavoritesView', () => {
  beforeEach(() => {
    favoriteMocks.fetchFavorites.mockReset()
    favoriteMocks.removeFavorite.mockReset()
    appContextMock.state.region = 'CN'
    favoriteMocks.fetchFavorites.mockResolvedValue({
      list: [
        {
          id: 11,
          targetType: 1,
          targetTypeText: '店铺',
          targetId: 10001,
          target: {
            id: 10001,
            name: '渝里火锅徐汇店',
            coverUrl: '/hotpot.jpg',
            score: 4.7,
            pricePerCapita: 138,
            currency: 'CNY',
            address: '上海市徐汇区',
            cityName: '上海',
            areaName: '徐汇',
            hasDeal: true,
            openNow: true,
            tags: ['火锅'],
            merchantCertification: { code: 'verified_merchant', label: '认证商户' },
          },
          createdAt: '2026-07-25 10:00:00',
        },
        {
          id: 12,
          targetType: 2,
          targetTypeText: '帖子',
          targetId: 88,
          target: {
            id: 88,
            name: '周末早午餐避坑指南',
            coverUrl: '/post.jpg',
            score: 0,
            pricePerCapita: 0,
            currency: '',
            address: '',
            cityName: '',
            areaName: '',
            hasDeal: false,
            openNow: false,
            tags: [],
          },
          createdAt: '2026-07-25 11:00:00',
        },
      ],
      total: 2,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
    favoriteMocks.removeFavorite.mockResolvedValue(undefined)
  })

  it('loads all favorites and renders shops plus posts', async () => {
    const { app, host } = mount()
    await flush()

    expect(favoriteMocks.fetchFavorites).toHaveBeenCalledWith(undefined, 1, 50)
    expect(host.textContent).toContain('渝里火锅徐汇店')
    expect(host.textContent).toContain('认证商户')
    expect(host.textContent).toContain('周末早午餐避坑指南')
    expect(host.textContent).toContain('查看帖子')
    app.unmount()
  })

  it('filters post favorites and removes them', async () => {
    favoriteMocks.fetchFavorites
      .mockResolvedValueOnce({
        list: [
          {
            id: 12,
            targetType: 2,
            targetTypeText: '帖子',
            targetId: 88,
            target: {
              id: 88,
              name: '周末早午餐避坑指南',
              coverUrl: '/post.jpg',
              score: 0,
              pricePerCapita: 0,
              currency: '',
              address: '',
              cityName: '',
              areaName: '',
              hasDeal: false,
              openNow: false,
              tags: [],
            },
            createdAt: '2026-07-25 11:00:00',
          },
        ],
        total: 1,
        page: 1,
        pageSize: 50,
        hasMore: false,
      })
      .mockResolvedValueOnce({
        list: [
          {
            id: 12,
            targetType: 2,
            targetTypeText: '帖子',
            targetId: 88,
            target: {
              id: 88,
              name: '周末早午餐避坑指南',
              coverUrl: '/post.jpg',
              score: 0,
              pricePerCapita: 0,
              currency: '',
              address: '',
              cityName: '',
              areaName: '',
              hasDeal: false,
              openNow: false,
              tags: [],
            },
            createdAt: '2026-07-25 11:00:00',
          },
        ],
        total: 1,
        page: 1,
        pageSize: 50,
        hasMore: false,
      })

    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="favorite-filter-post"]')?.click()
    await flush()
    expect(favoriteMocks.fetchFavorites).toHaveBeenCalledWith(2, 1, 50)

    const removeButton = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('取消收藏'))
    removeButton?.click()
    await flush()

    expect(favoriteMocks.removeFavorite).toHaveBeenCalledWith(2, 88)
    expect(host.textContent).toContain('已取消帖子收藏')
    app.unmount()
  })

  it('localizes favorite types, certification and dates for EU', async () => {
    appContextMock.state.region = 'EU'
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('Saved items')
    expect(host.textContent).toContain('Verified merchant')
    expect(host.textContent).toContain('View post')
    expect(host.textContent).toContain('25/07/2026')
    expect(host.textContent).not.toContain('认证商户')
    expect(host.textContent).not.toContain('查看帖子')
    app.unmount()
  })
})
