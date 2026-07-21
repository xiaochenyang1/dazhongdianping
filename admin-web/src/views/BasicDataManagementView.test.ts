import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listGeoCategories: vi.fn(),
  createGeoCategory: vi.fn(),
  updateGeoCategory: vi.fn(),
  updateGeoCategoryStatus: vi.fn(),
  removeGeoCategory: vi.fn(),
  listGeoCities: vi.fn(),
  createGeoCity: vi.fn(),
  updateGeoCity: vi.fn(),
  updateGeoCityStatus: vi.fn(),
  removeGeoCity: vi.fn(),
  listGeoAreas: vi.fn(),
  createGeoArea: vi.fn(),
  updateGeoArea: vi.fn(),
  updateGeoAreaStatus: vi.fn(),
  removeGeoArea: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/geodata', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({ region: 'EU' as const, permissions: ['data:geo:read'] })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import BasicDataManagementView from './BasicDataManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const categories = [
  { id: 200, parentId: 0, name: 'Dining', sortNo: 1, status: 1 },
  { id: 201, parentId: 200, name: 'Chinese', sortNo: 1, status: 1 },
]
const cities = [
  { id: 101, code: 'PAR', name: 'Paris', sortNo: 1, status: 1 },
  { id: 102, code: 'BER', name: 'Berlin', sortNo: 2, status: 1 },
]
const areas = [{ id: 1011, cityId: 101, name: 'Le Marais', sortNo: 1, status: 1 }]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(BasicDataManagementView)
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

describe('BasicDataManagementView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['data:geo:read']
    mocks.listGeoCategories.mockResolvedValue(categories)
    mocks.listGeoCities.mockResolvedValue(cities)
    mocks.listGeoAreas.mockImplementation(async (cityId: number) => cityId === 101 ? areas : [])
    mocks.createGeoCategory.mockResolvedValue({ id: 203, parentId: 200, name: 'Noodles', sortNo: 3, status: 1 })
    mocks.updateGeoCategory.mockResolvedValue(categories[0])
    mocks.updateGeoCategoryStatus.mockResolvedValue({ ...categories[0], status: 0 })
    mocks.removeGeoCategory.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads category and city data while hiding every write command from read-only users', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listGeoCategories).toHaveBeenCalledTimes(1)
    expect(mocks.listGeoCities).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('分类')
    expect(host.textContent).toContain('Dining')
    host.querySelector<HTMLButtonElement>('[data-testid="tab-cities"]')?.click()
    await nextTick()
    expect(host.textContent).toContain('Paris')
    expect(host.querySelector('[data-testid="create-category"]')).toBeNull()
    expect(host.querySelector('[data-testid^="edit-category-"]')).toBeNull()
    expect(host.querySelector('[data-testid^="status-category-"]')).toBeNull()
    expect(host.querySelector('[data-testid^="delete-category-"]')).toBeNull()
    app.unmount()
  })

  it('clears old areas and loads the newly selected city', async () => {
    const { app, host } = mount()
    await flush()

    const areaTab = host.querySelector<HTMLButtonElement>('[data-testid="tab-areas"]')
    if (!areaTab) throw new Error('missing area tab')
    areaTab.click()
    await nextTick()

    const citySelect = host.querySelector<HTMLSelectElement>('[data-testid="area-city-select"]')
    if (!citySelect) throw new Error('missing city select')
    citySelect.value = '101'
    citySelect.dispatchEvent(new Event('change'))
    expect(host.textContent).not.toContain('Le Marais')
    await flush()

    expect(mocks.listGeoAreas).toHaveBeenLastCalledWith(101)
    expect(host.textContent).toContain('Le Marais')
    app.unmount()
  })

  it('clears area loading when the city selection is reset while a request is pending', async () => {
    let resolveAreas!: (value: typeof areas) => void
    mocks.listGeoAreas.mockImplementationOnce(() => new Promise((resolve) => {
      resolveAreas = resolve
    }))
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="tab-areas"]')?.click()
    await nextTick()
    const citySelect = host.querySelector<HTMLSelectElement>('[data-testid="area-city-select"]')
    if (!citySelect) throw new Error('missing city select')
    citySelect.value = '101'
    citySelect.dispatchEvent(new Event('change'))
    await nextTick()
    expect(host.textContent).toContain('正在加载商圈')

    citySelect.value = ''
    citySelect.dispatchEvent(new Event('change'))
    resolveAreas(areas)
    await flush()

    expect(host.textContent).not.toContain('正在加载商圈')
    app.unmount()
  })

  it('clears area loading when the region changes while a request is pending', async () => {
    let resolveAreas!: (value: typeof areas) => void
    mocks.listGeoAreas.mockImplementationOnce(() => new Promise((resolve) => {
      resolveAreas = resolve
    }))
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="tab-areas"]')?.click()
    await nextTick()
    const citySelect = host.querySelector<HTMLSelectElement>('[data-testid="area-city-select"]')
    if (!citySelect) throw new Error('missing city select')
    citySelect.value = '101'
    citySelect.dispatchEvent(new Event('change'))
    await nextTick()
    expect(host.textContent).toContain('正在加载商圈')

    sessionMock.state.region = 'CN'
    resolveAreas(areas)
    await flush()

    expect(host.textContent).not.toContain('正在加载商圈')
    app.unmount()
  })

  it('creates categories and preserves the form and backend conflict message on failure', async () => {
    sessionMock.state.permissions = ['data:geo:read', 'data:geo:write']
    mocks.createGeoCategory.mockRejectedValueOnce(new Error('分类名称已存在'))
    const { app, host } = mount()
    await flush()

    const createButton = host.querySelector<HTMLButtonElement>('[data-testid="create-category"]')
    if (!createButton) throw new Error('missing create category button')
    createButton.click()
    await nextTick()

    const parent = host.querySelector<HTMLSelectElement>('[name="category-parent"]')
    if (!parent) throw new Error('missing category parent')
    parent.value = '200'
    parent.dispatchEvent(new Event('change'))
    input(host, 'category-name', 'Noodles')
    input(host, 'category-sort', '3')
    host.querySelector<HTMLFormElement>('[data-testid="category-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createGeoCategory).toHaveBeenCalledWith({ parentId: 200, name: 'Noodles', sortNo: 3 })
    expect(host.textContent).toContain('分类名称已存在')
    expect(host.querySelector<HTMLInputElement>('[name="category-name"]')?.value).toBe('Noodles')
    expect(host.querySelector('[data-testid="category-form"]')).not.toBeNull()
    app.unmount()
  })

  it('reloads the current region and clears selected areas when the session region changes', async () => {
    const { app, host } = mount()
    await flush()

    const areaTab = host.querySelector<HTMLButtonElement>('[data-testid="tab-areas"]')
    areaTab?.click()
    await nextTick()
    const citySelect = host.querySelector<HTMLSelectElement>('[data-testid="area-city-select"]')
    if (!citySelect) throw new Error('missing city select')
    citySelect.value = '101'
    citySelect.dispatchEvent(new Event('change'))
    await flush()
    expect(host.textContent).toContain('Le Marais')

    sessionMock.state.region = 'CN'
    await flush()

    expect(mocks.listGeoCategories).toHaveBeenCalledTimes(2)
    expect(mocks.listGeoCities).toHaveBeenCalledTimes(2)
    expect(host.textContent).not.toContain('Le Marais')
    expect(host.querySelector<HTMLSelectElement>('[data-testid="area-city-select"]')?.value).toBe('')
    app.unmount()
  })
})
