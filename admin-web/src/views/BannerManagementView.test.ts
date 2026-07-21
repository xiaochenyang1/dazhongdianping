import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminBanners: vi.fn(),
  createAdminBanner: vi.fn(),
  updateAdminBanner: vi.fn(),
  updateAdminBannerStatus: vi.fn(),
  removeAdminBanner: vi.fn(),
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
    permissions: ['operations:banner:read', 'operations:banner:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import BannerManagementView from './BannerManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const cities = [
  { id: 101, code: 'PAR', name: 'Paris' },
  { id: 102, code: 'BER', name: 'Berlin' },
]

const banners = [
  {
    id: 1,
    region: 'EU' as const,
    cityId: null,
    cityName: '',
    title: '欧洲首页 Banner',
    subtitle: '区域通用',
    imageUrl: 'https://cdn.example.com/banner/global.png',
    linkUrl: '/shops?cityId=101',
    enabled: true,
    sortNo: 1,
  },
  {
    id: 2,
    region: 'EU' as const,
    cityId: 101,
    cityName: 'Paris',
    title: 'Paris 专属 Banner',
    subtitle: '只给 Paris',
    imageUrl: 'https://cdn.example.com/banner/paris.png',
    linkUrl: '/shops?cityId=101&areaId=1011',
    enabled: false,
    sortNo: 2,
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
  const app = createApp(BannerManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing input: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

describe('BannerManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    Object.values(metaMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:banner:read', 'operations:banner:write']
    metaMocks.fetchCities.mockResolvedValue(cities)
    adminMocks.listAdminBanners.mockResolvedValue(banners)
    adminMocks.createAdminBanner.mockResolvedValue({
      id: 3,
      region: 'EU',
      cityId: null,
      cityName: '',
      title: '新区 Banner',
      subtitle: '欢迎页',
      imageUrl: 'https://cdn.example.com/banner/new.png',
      linkUrl: '/shops?cityId=101',
      enabled: true,
      sortNo: 9,
    })
    adminMocks.updateAdminBannerStatus.mockResolvedValue({ ...banners[1], enabled: true })
    adminMocks.removeAdminBanner.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads banners and applies the city filter with the public-display query shape', async () => {
    const { app, host } = mount()
    await flush()

    expect(metaMocks.fetchCities).toHaveBeenCalledTimes(1)
    expect(adminMocks.listAdminBanners).toHaveBeenCalledWith(undefined)
    expect(host.textContent).toContain('欧洲首页 Banner')
    expect(host.textContent).toContain('Paris 专属 Banner')

    const cityFilter = host.querySelector<HTMLSelectElement>('[name="banner-city-filter"]')
    if (!cityFilter) throw new Error('missing banner city filter')
    cityFilter.value = '101'
    cityFilter.dispatchEvent(new Event('change'))
    host.querySelector<HTMLFormElement>('form')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.listAdminBanners).toHaveBeenLastCalledWith({ cityId: 101 })
    app.unmount()
  })

  it('creates a new region-wide banner from the editor form', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="create-banner"]')?.click()
    await nextTick()

    input(host, 'banner-title', '新区 Banner')
    input(host, 'banner-subtitle', '欢迎页')
    input(host, 'banner-image-url', 'https://cdn.example.com/banner/new.png')
    input(host, 'banner-link-url', '/shops?cityId=101')
    input(host, 'banner-sort-no', '9')
    host.querySelector<HTMLFormElement>('[data-testid="banner-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.createAdminBanner).toHaveBeenCalledWith({
      cityId: null,
      title: '新区 Banner',
      subtitle: '欢迎页',
      imageUrl: 'https://cdn.example.com/banner/new.png',
      linkUrl: '/shops?cityId=101',
      sortNo: 9,
    })
    app.unmount()
  })

  it('toggles and deletes existing banners through the management actions', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="toggle-banner-2"]')?.click()
    await flush()
    expect(adminMocks.updateAdminBannerStatus).toHaveBeenCalledWith(2, true)

    host.querySelector<HTMLButtonElement>('[data-testid="delete-banner-1"]')?.click()
    await flush()
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('欧洲首页 Banner'))
    expect(adminMocks.removeAdminBanner).toHaveBeenCalledWith(1)
    app.unmount()
  })
})
