import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminOperationActivities: vi.fn(),
  createAdminOperationActivity: vi.fn(),
  updateAdminOperationActivity: vi.fn(),
  updateAdminOperationActivityStatus: vi.fn(),
  removeAdminOperationActivity: vi.fn(),
  listAdminOperationActivityItems: vi.fn(),
  createAdminOperationActivityItem: vi.fn(),
  updateAdminOperationActivityItem: vi.fn(),
  updateAdminOperationActivityItemStatus: vi.fn(),
  removeAdminOperationActivityItem: vi.fn(),
}))

const metaMocks = vi.hoisted(() => ({
  fetchCities: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/services/meta', () => metaMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:activity:read', 'operations:activity:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import OperationActivityManagementView from './OperationActivityManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const cities = [
  { id: 101, code: 'PAR', name: 'Paris' },
  { id: 102, code: 'BER', name: 'Berlin' },
]

const activities = [
  {
    id: 1,
    region: 'EU' as const,
    cityId: 101,
    cityName: 'Paris',
    name: '巴黎开学季活动',
    code: 'eu_school_2026_q3',
    channel: 4,
    channelText: '活动页',
    type: 2,
    typeText: '节日活动',
    status: 1,
    statusText: '待上线',
    cover: 'https://cdn.example.com/activity/eu_school.png',
    landingUrl: 'app://activity/eu_school_2026_q3',
    rule: { audience: ['student'], sort: 'manual' },
    startAt: '2026-09-01 00:00:00',
    endAt: '2026-09-30 23:59:59',
    itemCount: 2,
  },
  {
    id: 2,
    region: 'EU' as const,
    cityId: 0,
    cityName: '',
    name: '欧洲周末好去处',
    code: 'eu_weekend_2026_q3',
    channel: 1,
    channelText: '首页',
    type: 1,
    typeText: '专题活动',
    status: 0,
    statusText: '草稿',
    cover: 'https://cdn.example.com/activity/eu_weekend.png',
    landingUrl: 'app://activity/eu_weekend_2026_q3',
    rule: {},
    startAt: '',
    endAt: '',
    itemCount: 0,
  },
]

const items = [
  {
    id: 11,
    activityId: 1,
    targetType: 1,
    targetTypeText: '店铺',
    targetId: 20001,
    targetName: 'Maison Sichuan Paris',
    title: '留学生火锅局',
    subtitle: '川味聚餐稳，不用靠运气',
    image: 'https://cdn.example.com/activity/item-shop.png',
    sort: 1,
    extra: { badge: '热门', trackCode: 'eu_school_shop_20001' },
    status: 1,
    statusText: '启用',
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
  const app = createApp(OperationActivityManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement | HTMLTextAreaElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing input: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

describe('OperationActivityManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    Object.values(metaMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:activity:read', 'operations:activity:write']
    metaMocks.fetchCities.mockResolvedValue(cities)
    adminMocks.listAdminOperationActivities.mockResolvedValue(activities)
    adminMocks.createAdminOperationActivity.mockResolvedValue({
      ...activities[0],
      id: 3,
      name: '巴黎周末专题',
      code: 'eu_weekend_live',
    })
    adminMocks.updateAdminOperationActivity.mockResolvedValue(activities[0])
    adminMocks.updateAdminOperationActivityStatus.mockResolvedValue({ ...activities[0], status: 2, statusText: '上线中' })
    adminMocks.removeAdminOperationActivity.mockResolvedValue(undefined)
    adminMocks.listAdminOperationActivityItems.mockResolvedValue(items)
    adminMocks.createAdminOperationActivityItem.mockResolvedValue({
      ...items[0],
      id: 12,
      title: '巴黎榜单入口',
      targetType: 4,
      targetTypeText: '榜单',
      targetId: 31001,
      targetName: '巴黎华人必吃榜',
    })
    adminMocks.updateAdminOperationActivityItem.mockResolvedValue(items[0])
    adminMocks.updateAdminOperationActivityItemStatus.mockResolvedValue({ ...items[0], status: 2, statusText: '停用' })
    adminMocks.removeAdminOperationActivityItem.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads activities, applies filters, and auto-loads items for the selected activity', async () => {
    const { app, host } = mount()
    await flush()

    expect(metaMocks.fetchCities).toHaveBeenCalledTimes(1)
    expect(adminMocks.listAdminOperationActivities).toHaveBeenCalledWith(undefined)
    expect(adminMocks.listAdminOperationActivityItems).toHaveBeenCalledWith(1)
    expect(host.textContent).toContain('巴黎开学季活动')
    expect(host.textContent).toContain('留学生火锅局')

    const cityFilter = host.querySelector<HTMLSelectElement>('[name="activity-city-filter"]')
    if (!cityFilter) throw new Error('missing activity city filter')
    cityFilter.value = '101'
    cityFilter.dispatchEvent(new Event('change'))

    const statusFilter = host.querySelector<HTMLSelectElement>('[name="activity-status-filter"]')
    if (!statusFilter) throw new Error('missing activity status filter')
    statusFilter.value = '1'
    statusFilter.dispatchEvent(new Event('change'))

    host.querySelector<HTMLFormElement>('form')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.listAdminOperationActivities).toHaveBeenLastCalledWith({ cityId: 101, status: 1 })
    app.unmount()
  })

  it('creates a new activity from the editor form', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="create-activity"]')?.click()
    await nextTick()

    input(host, 'activity-name', '巴黎周末专题')
    input(host, 'activity-code', 'eu_weekend_live')
    input(host, 'activity-cover', 'https://cdn.example.com/activity/weekend.png')
    input(host, 'activity-landing-url', 'app://activity/eu_weekend_live')
    input(host, 'activity-start-at', '2026-09-01 00:00:00')
    input(host, 'activity-end-at', '2026-09-30 23:59:59')
    input(host, 'activity-rule', '{"audience":["student"]}')
    host.querySelector<HTMLFormElement>('[data-testid="activity-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.createAdminOperationActivity).toHaveBeenCalledWith({
      name: '巴黎周末专题',
      code: 'eu_weekend_live',
      cityId: 0,
      channel: 4,
      type: 1,
      cover: 'https://cdn.example.com/activity/weekend.png',
      landingUrl: 'app://activity/eu_weekend_live',
      rule: { audience: ['student'] },
      startAt: '2026-09-01 00:00:00',
      endAt: '2026-09-30 23:59:59',
    })
    app.unmount()
  })

  it('creates, toggles, and deletes activity items in the selected activity', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="create-activity-item"]')?.click()
    await nextTick()

    const targetType = host.querySelector<HTMLSelectElement>('[name="item-target-type"]')
    if (!targetType) throw new Error('missing item target type')
    targetType.value = '4'
    targetType.dispatchEvent(new Event('change'))
    input(host, 'item-target-id', '31001')
    input(host, 'item-title', '巴黎榜单入口')
    input(host, 'item-subtitle', '先看榜单再订位')
    input(host, 'item-image', 'https://cdn.example.com/activity/item-rank.png')
    input(host, 'item-sort', '3')
    input(host, 'item-track-code', 'eu_school_rank_31001')
    host.querySelector<HTMLFormElement>('[data-testid="activity-item-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.createAdminOperationActivityItem).toHaveBeenCalledWith(1, {
      targetType: 4,
      targetId: 31001,
      title: '巴黎榜单入口',
      subtitle: '先看榜单再订位',
      image: 'https://cdn.example.com/activity/item-rank.png',
      sort: 3,
      extra: { trackCode: 'eu_school_rank_31001' },
    })

    host.querySelector<HTMLButtonElement>('[data-testid="toggle-activity-item-11"]')?.click()
    await flush()
    expect(adminMocks.updateAdminOperationActivityItemStatus).toHaveBeenCalledWith(1, 11, 2)

    host.querySelector<HTMLButtonElement>('[data-testid="delete-activity-item-11"]')?.click()
    await flush()
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('留学生火锅局'))
    expect(adminMocks.removeAdminOperationActivityItem).toHaveBeenCalledWith(1, 11)
    app.unmount()
  })
})
