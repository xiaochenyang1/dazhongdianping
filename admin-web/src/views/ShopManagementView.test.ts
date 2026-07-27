import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listShops: vi.fn(),
  getShop: vi.fn(),
  createShop: vi.fn(),
  updateShop: vi.fn(),
  removeShop: vi.fn(),
}))

const metaMocks = vi.hoisted(() => ({
  fetchAreas: vi.fn(),
  fetchCategories: vi.fn(),
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
    permissions: ['data:shop:read', 'data:shop:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import ShopManagementView from './ShopManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const categories = [{ id: 20, name: 'Dining', children: [{ id: 21, name: 'Bistro' }] }]
const cities = [{ id: 101, name: 'Paris' }, { id: 102, name: 'Berlin' }]
const areas = [{ id: 1011, cityId: 101, name: 'Le Marais' }]

const summary = {
  id: 201,
  merchantId: 2001,
  merchantName: 'Maison Foods',
  name: 'Maison Bistro',
  region: 'EU' as const,
  categoryName: 'Bistro',
  cityName: 'Paris',
  areaName: 'Le Marais',
  pricePerCapita: 26,
  status: 1,
  statusText: '营业',
  openNow: true,
  createdAt: '2026-07-18 10:00:00',
}

const detail = {
  ...summary,
  categoryId: 21,
  cityId: 101,
  areaId: 1011,
  coverUrl: 'https://cdn.example.com/shops/maison.png',
  phone: '+33 1 23 45 67 89',
  score: 4.6,
  tasteScore: 4.7,
  envScore: 4.5,
  serviceScore: 4.6,
  currency: 'EUR',
  address: '12 Rue du Temple',
  latitude: 48.859,
  longitude: 2.356,
  businessHours: '10:00-22:00',
  summary: 'A neighborhood bistro.',
  hasDeal: true,
  tags: ['Bistro', 'Dinner'],
  updatedAt: '2026-07-19 10:00:00',
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
  await new Promise((resolve) => setTimeout(resolve, 0))
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(ShopManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement | HTMLTextAreaElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing shop field: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

function submit(host: HTMLElement) {
  const form = host.querySelector<HTMLFormElement>('[data-testid="shop-editor"]')
  if (!form) throw new Error('missing shop editor')
  form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
}

describe('ShopManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    Object.values(metaMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['data:shop:read', 'data:shop:write']
    metaMocks.fetchCategories.mockResolvedValue(categories)
    metaMocks.fetchCities.mockResolvedValue(cities)
    metaMocks.fetchAreas.mockImplementation(async (cityId: number) => cityId === 101 ? areas : [])
    adminMocks.listShops.mockResolvedValue({ list: [summary], total: 1, page: 1, pageSize: 10, hasMore: false })
    adminMocks.getShop.mockResolvedValue(detail)
    adminMocks.createShop.mockResolvedValue({ ...detail, id: 202, name: 'New Bistro' })
    adminMocks.updateShop.mockResolvedValue({ ...detail, name: 'Maison Bistro Updated' })
    adminMocks.removeShop.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('keeps create, update, and delete workflows available to writers', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { host } = mountView()
    await flushView()

    expect(adminMocks.listShops).toHaveBeenCalledWith(expect.objectContaining({ region: 'EU', page: 1, pageSize: 10 }))
    host.querySelector<HTMLButtonElement>('[data-testid="create-shop"]')?.click()
    await flushView()
    input(host, 'shop-name', 'New Bistro')
    input(host, 'shop-address', '8 Rue Vieille du Temple')
    input(host, 'shop-summary', 'A new neighborhood bistro.')
    submit(host)
    await flushView()

    expect(adminMocks.createShop).toHaveBeenCalledWith(expect.objectContaining({
      region: 'EU',
      categoryId: 21,
      cityId: 101,
      areaId: 1011,
      name: 'New Bistro',
    }))

    host.querySelector<HTMLButtonElement>('[data-testid="open-shop-201"]')?.click()
    await flushView()
    input(host, 'shop-name', 'Maison Bistro Updated')
    submit(host)
    await flushView()

    expect(adminMocks.getShop).toHaveBeenCalledWith(201)
    expect(adminMocks.updateShop).toHaveBeenCalledWith(201, expect.objectContaining({ name: 'Maison Bistro Updated' }))

    host.querySelector<HTMLButtonElement>('[data-testid="delete-shop-201"]')?.click()
    await flushView()
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('Maison Bistro'))
    expect(adminMocks.removeShop).toHaveBeenCalledWith(201)
  })

  it('preserves list filtering and detail browsing for read-only users', async () => {
    sessionMock.state.permissions = ['data:shop:read']
    const { host } = mountView()
    await flushView()

    expect(host.textContent).toContain('Maison Bistro')
    expect(host.querySelector('[data-testid="create-shop"]')).toBeNull()
    expect(host.querySelector('[data-testid="delete-shop-201"]')).toBeNull()
    expect(host.querySelector('[data-testid="save-shop"]')).toBeNull()
    expect(host.querySelector<HTMLButtonElement>('[data-testid="open-shop-201"]')?.textContent).toContain('查看')

    host.querySelector<HTMLButtonElement>('[data-testid="open-shop-201"]')?.click()
    await flushView()

    expect(adminMocks.getShop).toHaveBeenCalledWith(201)
    expect(host.querySelector<HTMLInputElement>('[name="shop-name"]')?.value).toBe('Maison Bistro')
    expect(host.querySelector<HTMLFieldSetElement>('[data-testid="shop-editor-fields"]')?.disabled).toBe(true)
    expect(host.textContent).toContain('当前账号仅可查看门店资料，无维护权限。')
  })

  it('blocks stale create, save, and delete controls after write permission is revoked', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { host } = mountView()
    await flushView()

    const createButton = host.querySelector<HTMLButtonElement>('[data-testid="create-shop"]')
    const deleteButton = host.querySelector<HTMLButtonElement>('[data-testid="delete-shop-201"]')
    const editor = host.querySelector<HTMLFormElement>('[data-testid="shop-editor"]')
    if (!createButton || !deleteButton || !editor) throw new Error('missing shop mutation controls')

    sessionMock.state.permissions = ['data:shop:read']
    createButton.click()
    deleteButton.click()
    editor.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flushView()

    expect(confirm).not.toHaveBeenCalled()
    expect(adminMocks.createShop).not.toHaveBeenCalled()
    expect(adminMocks.updateShop).not.toHaveBeenCalled()
    expect(adminMocks.removeShop).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="create-shop"]')).toBeNull()
    expect(host.querySelector('[data-testid="delete-shop-201"]')).toBeNull()
    expect(host.querySelector('[data-testid="save-shop"]')).toBeNull()
  })
})
