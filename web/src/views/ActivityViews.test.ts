import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, defineComponent, h, nextTick } from 'vue'
import { createMemoryHistory, createRouter, RouterLink } from 'vue-router'
import ActivityDetailView from './ActivityDetailView.vue'
import ActivityListView from './ActivityListView.vue'

const serviceMocks = vi.hoisted(() => ({
  fetchActivities: vi.fn(),
  fetchActivityDetail: vi.fn(),
}))

const contextMocks = vi.hoisted(() => ({
  state: { region: 'EU' as const, cityId: 101 },
}))

vi.mock('@/services/activity', () => serviceMocks)
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => contextMocks,
}))

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
  app.component('RouterLink', RouterLink)
  app.mount(host)
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
    expect(host.textContent).toContain('活动页')
    expect(host.textContent).toContain('3 个资源')
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
    expect(host.textContent).toContain('查看店铺')
    expect(host.textContent).toContain('打开外链')
    const external = host.querySelector('a[href="https://promo.example.com/eu/school"]')
    expect(external).not.toBeNull()
  })
})
