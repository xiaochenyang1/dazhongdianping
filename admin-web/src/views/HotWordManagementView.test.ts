import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminHotWords: vi.fn(),
  createAdminHotWord: vi.fn(),
  updateAdminHotWord: vi.fn(),
  updateAdminHotWordStatus: vi.fn(),
  removeAdminHotWord: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:hotword:read', 'operations:hotword:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import HotWordManagementView from './HotWordManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const hotWords = [
  {
    id: 1,
    region: 'EU' as const,
    keyword: 'Cafe',
    enabled: true,
    sortNo: 0,
  },
  {
    id: 2,
    region: 'EU' as const,
    keyword: 'Chinese',
    enabled: false,
    sortNo: 1,
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
  const app = createApp(HotWordManagementView)
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

describe('HotWordManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:hotword:read', 'operations:hotword:write']
    adminMocks.listAdminHotWords.mockResolvedValue(hotWords)
    adminMocks.createAdminHotWord.mockResolvedValue({
      id: 3,
      region: 'EU',
      keyword: 'Remote',
      enabled: true,
      sortNo: 9,
    })
    adminMocks.updateAdminHotWordStatus.mockResolvedValue({ ...hotWords[1], enabled: true })
    adminMocks.removeAdminHotWord.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads hot words for the current region', async () => {
    const { app, host } = mount()
    await flush()

    expect(adminMocks.listAdminHotWords).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('Cafe')
    expect(host.textContent).toContain('Chinese')
    expect(host.textContent).toContain('当前区域 EU')
    app.unmount()
  })

  it('creates a new hot word from the editor form', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="create-hotword"]')?.click()
    await nextTick()

    input(host, 'hotword-keyword', 'Remote')
    input(host, 'hotword-sort-no', '9')
    host.querySelector<HTMLFormElement>('[data-testid="hotword-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.createAdminHotWord).toHaveBeenCalledWith({
      keyword: 'Remote',
      sortNo: 9,
    })
    app.unmount()
  })

  it('toggles and deletes configured hot words', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="toggle-hotword-2"]')?.click()
    await flush()
    expect(adminMocks.updateAdminHotWordStatus).toHaveBeenCalledWith(2, true)

    host.querySelector<HTMLButtonElement>('[data-testid="delete-hotword-1"]')?.click()
    await flush()
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('Cafe'))
    expect(adminMocks.removeAdminHotWord).toHaveBeenCalledWith(1)
    app.unmount()
  })
})
