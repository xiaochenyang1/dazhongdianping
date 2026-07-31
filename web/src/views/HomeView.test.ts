import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  fetchCategories: vi.fn(),
  fetchCities: vi.fn(),
  fetchHomeBanners: vi.fn(),
  fetchHomeFeed: vi.fn(),
}))

const activityMocks = vi.hoisted(() => ({
  fetchActivities: vi.fn(),
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/services/activity', () => activityMocks)
vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a><slot /></a>' },
}))

import { useAppContext } from '@/composables/useAppContext'
import HomeView from './HomeView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

describe('HomeView', () => {
  beforeEach(() => {
    Object.values(browseMocks).forEach((mock) => mock.mockReset())
    activityMocks.fetchActivities.mockReset()
    localStorage.clear()
    useAppContext().setRegion('EU')
    useAppContext().setCityId(101)

    browseMocks.fetchCategories.mockResolvedValue([
      { id: 1, name: 'Dining', children: [{ id: 2, name: 'Chinese food', children: [] }] },
    ])
    browseMocks.fetchCities.mockResolvedValue([{ id: 101, code: 'PAR', name: 'Paris' }])
    browseMocks.fetchHomeBanners.mockResolvedValue([{
      id: 1,
      title: 'Paris favourites',
      subtitle: 'Places worth a visit',
      imageUrl: '/banner.jpg',
      linkUrl: '/shops',
    }])
    browseMocks.fetchHomeFeed.mockResolvedValue([{
      id: 1,
      type: 'shop',
      title: 'A neighbourhood favourite',
      subtitle: 'Loved by local diners',
      coverUrl: '/feed.jpg',
      shopId: 20001,
    }])
    activityMocks.fetchActivities.mockResolvedValue([{
      id: 8,
      name: 'Summer in Paris',
      code: 'summer-paris',
      region: 'EU',
      cityId: 101,
      cityName: 'Paris',
      channel: 4,
      channelText: '活动页',
      type: 2,
      typeText: '节日活动',
      cover: '/activity.jpg',
      landingUrl: '/activities/8',
      startAt: '2026-07-01 00:00:00',
      endAt: '2026-08-31 23:59:59',
      itemCount: 1,
    }])
  })

  it('renders the complete discovery shell in English for EU', async () => {
    const host = document.createElement('div')
    const app = createApp(HomeView)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('Discover places, collections and local favourites')
    expect(host.textContent).toContain('Browse places')
    expect(host.textContent).toContain('Seasonal campaign')
    expect(host.textContent).toContain('Paris · Activities · 1 item')
    expect(host.textContent).toContain('View more places')
    expect(host.textContent).not.toMatch(/[一-龥]/)

    app.unmount()
  })
})
