import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminPointsProducts: vi.fn(),
  createAdminPointsProduct: vi.fn(),
  updateAdminPointsProduct: vi.fn(),
  updateAdminPointsProductStatus: vi.fn(),
  removeAdminPointsProduct: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:points:read', 'operations:points:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import PointsProductManagementView from './PointsProductManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const products = [
  {
    id: 1,
    region: 'EU',
    name: 'Coffee voucher',
    coverImage: 'https://cdn.test/coffee.png',
    description: 'One free latte',
    pointsPrice: 200,
    stock: 10,
    exchangeLimitPerUser: 1,
    exchangeCount: 3,
    fulfillType: 1,
    fulfillTypeText: 'Auto code',
    status: 1,
    sort: 0,
    soldOut: false,
    createdAt: '2026-07-01 10:00:00',
    updatedAt: '2026-07-01 10:00:00',
  },
  {
    id: 2,
    region: 'EU',
    name: 'Tote bag',
    coverImage: '',
    description: '',
    pointsPrice: 800,
    stock: 0,
    exchangeLimitPerUser: 0,
    exchangeCount: 12,
    fulfillType: 2,
    fulfillTypeText: 'Manual',
    status: 0,
    sort: 3,
    soldOut: true,
    createdAt: '2026-07-02 10:00:00',
    updatedAt: '2026-07-02 10:00:00',
  },
]

function pageOf(list: typeof products, hasMore = false) {
  return { list, total: list.length, page: 1, pageSize: 10, hasMore }
}

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(PointsProductManagementView)
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

function select(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLSelectElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing select: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('change'))
}

describe('PointsProductManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:points:read', 'operations:points:write']
    adminMocks.listAdminPointsProducts.mockResolvedValue(pageOf(products))
    adminMocks.createAdminPointsProduct.mockResolvedValue(products[0])
    adminMocks.updateAdminPointsProduct.mockResolvedValue(products[0])
    adminMocks.updateAdminPointsProductStatus.mockResolvedValue({ ...products[1], status: 1 })
    adminMocks.removeAdminPointsProduct.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads points products for the current region', async () => {
    const { app, host } = mount()
    await flush()

    expect(adminMocks.listAdminPointsProducts).toHaveBeenCalledWith({ page: 1, pageSize: 10 })
    expect(host.textContent).toContain('Coffee voucher')
    expect(host.textContent).toContain('Tote bag')
    expect(host.textContent).toContain('Auto code')
    expect(host.textContent).toContain('Manual')
    expect(host.textContent).toContain('Sold out')
    expect(host.textContent).toContain('Unlimited')
    app.unmount()
  })

  it('creates a product with the chosen fulfilment type', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="create-points-product"]')?.click()
    await nextTick()

    input(host, 'points-product-name', 'Notebook')
    input(host, 'points-product-cover', 'https://cdn.test/notebook.png')
    input(host, 'points-product-description', 'Branded notebook')
    input(host, 'points-product-price', '500')
    input(host, 'points-product-stock', '25')
    input(host, 'points-product-limit', '2')
    select(host, 'points-product-fulfill-type', '2')
    input(host, 'points-product-sort', '5')
    host.querySelector<HTMLFormElement>('[data-testid="points-product-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.createAdminPointsProduct).toHaveBeenCalledWith({
      name: 'Notebook',
      coverImage: 'https://cdn.test/notebook.png',
      description: 'Branded notebook',
      pointsPrice: 500,
      stock: 25,
      exchangeLimitPerUser: 2,
      fulfillType: 2,
      sort: 5,
    })
    app.unmount()
  })

  it('edits an existing product through the prefilled editor', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="edit-points-product-1"]')?.click()
    await nextTick()

    expect(host.querySelector<HTMLInputElement>('[name="points-product-name"]')?.value).toBe('Coffee voucher')
    input(host, 'points-product-price', '250')
    host.querySelector<HTMLFormElement>('[data-testid="points-product-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.updateAdminPointsProduct).toHaveBeenCalledWith(1, expect.objectContaining({
      name: 'Coffee voucher',
      pointsPrice: 250,
      fulfillType: 1,
    }))
    app.unmount()
  })

  it('lists, unlists and deletes products', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    expect(host.querySelector<HTMLButtonElement>('[data-testid="toggle-points-product-2"]')?.textContent?.trim()).toBe('List')
    host.querySelector<HTMLButtonElement>('[data-testid="toggle-points-product-2"]')?.click()
    await flush()
    expect(adminMocks.updateAdminPointsProductStatus).toHaveBeenCalledWith(2, 1)

    host.querySelector<HTMLButtonElement>('[data-testid="toggle-points-product-1"]')?.click()
    await flush()
    expect(adminMocks.updateAdminPointsProductStatus).toHaveBeenCalledWith(1, 0)

    host.querySelector<HTMLButtonElement>('[data-testid="delete-points-product-1"]')?.click()
    await flush()
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('Coffee voucher'))
    expect(adminMocks.removeAdminPointsProduct).toHaveBeenCalledWith(1)
    app.unmount()
  })

  it('hides write actions for read-only accounts', async () => {
    sessionMock.state.permissions = ['operations:points:read']
    const { app, host } = mount()
    await flush()

    expect(host.querySelector('[data-testid="create-points-product"]')).toBeNull()
    expect(host.querySelector('[data-testid="edit-points-product-1"]')).toBeNull()
    expect(host.textContent).toContain('read-only')
    app.unmount()
  })

  it('pages forward only when the server reports more rows', async () => {
    adminMocks.listAdminPointsProducts.mockResolvedValue(pageOf(products, true))
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="points-product-next"]')?.click()
    await flush()

    expect(adminMocks.listAdminPointsProducts).toHaveBeenLastCalledWith({ page: 2, pageSize: 10 })
    app.unmount()
  })
})
