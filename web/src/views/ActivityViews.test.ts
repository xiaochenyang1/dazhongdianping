import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, defineComponent, h, nextTick } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import ActivityDetailView from './ActivityDetailView.vue'
import ActivityListView from './ActivityListView.vue'

const serviceMocks = vi.hoisted(() => ({
  fetchActivities: vi.fn(),
  fetchActivityDetail: vi.fn(),
}))

const contextMocks = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; cityId: number },
}))

vi.mock('@/services/activity', () => serviceMocks)
vi.mock('@/composables/useAppContext', async () => {
  const { reactive } = await vi.importActual<typeof import('vue')>('vue')
  contextMocks.state = reactive({ region: 'EU', cityId: 101 })
  return { useAppContext: () => contextMocks }
})

const mountedApps: Array<{ unmount: () => void }> = []

async function mountView(component: any, props: Record<string, unknown> = {}) {
  const host = document.createElement('div')
  document.body.appendChild(host)
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<div />' } },
      { path: '/activities', component: { template: '<div />' } },
      { path: '/activities/:id', component: { template: '<div />' } },
      { path: '/shops/:id', component: { template: '<div />' } },
    ],
  })
  await router.push('/')
  await router.isReady()

  const app = createApp(
    defineComponent({
      setup() {
        return () => h(component, props)
      },
    }),
  )
  app.use(router)
  app.mount(host)
  mountedApps.push(app)
  await nextTick()
  await Promise.resolve()
  await nextTick()
  return host
}

describe('Activity views', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
    serviceMocks.fetchActivities.mockReset()
    serviceMocks.fetchActivityDetail.mockReset()
    contextMocks.state.region = 'EU'
    contextMocks.state.cityId = 101
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('renders the public activity list from the current city', async () => {
    serviceMocks.fetchActivities.mockResolvedValue([
      {
        id: 5001,
        name: '欧洲开学季聚餐专题',
        code: 'eu_school_2026_q3',
        region: 'EU',
        cityId: 101,
        cityName: 'Paris',
        channel: 4,
        channelText: '活动页',
        type: 2,
        typeText: '节日活动',
        cover: 'https://placehold.co/activity',
        landingUrl: 'app://activity/eu_school_2026_q3',
        startAt: '2026-07-01 00:00:00',
        endAt: '2026-12-31 23:59:59',
        itemCount: 3,
      },
    ])

    const host = await mountView(ActivityListView)
    expect(serviceMocks.fetchActivities).toHaveBeenCalledWith({
      cityId: 101,
      channel: undefined,
      limit: 20,
    })
    expect(host.textContent).toContain('欧洲开学季聚餐专题')
    expect(host.textContent).toContain('Seasonal campaign')
    expect(host.textContent).toContain('Activities')
    expect(host.textContent).toContain('3 items')
    expect(host.textContent).toContain('01/07/2026 00:00')
  })

  it('renders activity detail items with internal and external links', async () => {
    serviceMocks.fetchActivityDetail.mockResolvedValue({
      id: 5001,
      name: '欧洲开学季聚餐专题',
      code: 'eu_school_2026_q3',
      region: 'EU',
      cityId: 101,
      cityName: 'Paris',
      channel: 4,
      channelText: '活动页',
      type: 2,
      typeText: '节日活动',
      cover: 'https://placehold.co/activity',
      landingUrl: 'app://activity/eu_school_2026_q3',
      rule: {},
      startAt: '2026-07-01 00:00:00',
      endAt: '2026-12-31 23:59:59',
      items: [
        {
          id: 7001,
          activityId: 5001,
          targetType: 1,
          targetTypeText: '店铺',
          targetId: 20001,
          targetName: 'Maison Sichuan Paris',
          title: '巴黎华人火锅局',
          subtitle: '川味聚餐稳，不用靠运气',
          image: 'https://placehold.co/shop',
          sort: 1,
          extra: { badge: '热门' },
          linkUrl: '/shops/20001',
        },
        {
          id: 7004,
          activityId: 5001,
          targetType: 6,
          targetTypeText: '外链',
          targetId: 0,
          targetName: '',
          title: '活动规则',
          subtitle: '补贴说明',
          image: 'https://placehold.co/guide',
          sort: 2,
          extra: { url: 'https://promo.example.com/eu/school', badge: '说明' },
          linkUrl: 'https://promo.example.com/eu/school',
        },
      ],
    })

    const host = await mountView(ActivityDetailView, { activityId: 5001 })
    expect(serviceMocks.fetchActivityDetail).toHaveBeenCalledWith(5001)
    expect(host.textContent).toContain('欧洲开学季聚餐专题')
    expect(host.textContent).toContain('巴黎华人火锅局')
    expect(host.textContent).toContain('View place')
    expect(host.textContent).toContain('Open external link')
    const external = host.querySelector('a[href="https://promo.example.com/eu/school"]')
    expect(external).not.toBeNull()
  })

  it('reloads activity detail by region and ignores the stale response', async () => {
    const pending: Array<(value: any) => void> = []
    serviceMocks.fetchActivityDetail.mockImplementation(
      () => new Promise((resolve) => pending.push(resolve)),
    )

    const host = await mountView(ActivityDetailView, { activityId: 5001 })
    contextMocks.state.region = 'CN'
    await nextTick()
    expect(serviceMocks.fetchActivityDetail).toHaveBeenCalledTimes(2)

    pending[1]({
      id: 5001, name: 'CN activity', code: 'cn_activity', region: 'CN', cityId: 1,
      cityName: 'Shanghai', channel: 4, channelText: 'activity', type: 2,
      typeText: 'seasonal', cover: '/cn.jpg', landingUrl: '', rule: {},
      startAt: null, endAt: null, items: [],
    })
    await Promise.resolve()
    await nextTick()
    pending[0]({
      id: 5001, name: 'stale EU activity', code: 'eu_activity', region: 'EU', cityId: 101,
      cityName: 'Paris', channel: 4, channelText: 'activity', type: 2,
      typeText: 'seasonal', cover: '/eu.jpg', landingUrl: '', rule: {},
      startAt: null, endAt: null, items: [],
    })
    await Promise.resolve()
    await nextTick()

    expect(host.textContent).toContain('CN activity')
    expect(host.textContent).not.toContain('stale EU activity')
    expect(host.textContent).toContain('返回活动列表')
  })
})
