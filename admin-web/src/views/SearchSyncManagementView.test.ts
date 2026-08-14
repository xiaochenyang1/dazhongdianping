import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  getAdminSearchSyncOverview: vi.fn(),
  listAdminSearchSyncTasks: vi.fn(),
  retryAdminSearchSyncTask: vi.fn(),
  retryFailedAdminSearchSyncTasks: vi.fn(),
  rebuildAdminSearchIndex: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['data:search_index:read', 'data:search_index:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import SearchSyncManagementView from './SearchSyncManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const overview = {
  region: 'EU' as const,
  provider: 'elasticsearch',
  indexName: 'dzdp_shop_eu',
  enabled: true,
  total: 3,
  pending: 1,
  processing: 0,
  retrying: 1,
  stale: 1,
  ready: 2,
}

const task = {
  shopId: 42,
  shopName: 'Canal Cafe',
  region: 'EU' as const,
  cityName: 'Amsterdam',
  version: 7,
  state: 'retrying' as const,
  stateText: 'Retrying',
  attemptCount: 2,
  nextRetryAt: '2026-08-14T14:00:00',
  lockedAt: null,
  lastError: 'index unavailable',
  createdAt: '2026-08-14T12:00:00',
  updatedAt: '2026-08-14T13:00:00',
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
  const app = createApp(SearchSyncManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

function button(host: HTMLElement, label: string) {
  return [...host.querySelectorAll<HTMLButtonElement>('button')]
    .find((candidate) => candidate.textContent?.trim() === label)
}

describe('SearchSyncManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['data:search_index:read', 'data:search_index:write']
    adminMocks.getAdminSearchSyncOverview.mockResolvedValue(overview)
    adminMocks.listAdminSearchSyncTasks.mockResolvedValue({
      list: [task],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    adminMocks.retryAdminSearchSyncTask.mockResolvedValue({ retried: 1 })
    adminMocks.retryFailedAdminSearchSyncTasks.mockResolvedValue({ retried: 2 })
    adminMocks.rebuildAdminSearchIndex.mockResolvedValue({ indexed: 18 })
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads the overview and task queue for the current region', async () => {
    const { host } = mount()
    await flush()

    expect(adminMocks.getAdminSearchSyncOverview).toHaveBeenCalledTimes(1)
    expect(adminMocks.listAdminSearchSyncTasks).toHaveBeenCalledWith({
      keyword: undefined,
      state: undefined,
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('Search Index Sync')
    expect(host.textContent).toContain('dzdp_shop_eu')
    expect(host.textContent).toContain('Canal Cafe')
    expect(host.textContent).toContain('index unavailable')
  })

  it('hides mutations from read-only administrators', async () => {
    sessionMock.state.permissions = ['data:search_index:read']
    const { host } = mount()
    await flush()

    expect(host.textContent).toContain('This account has read-only access.')
    expect(button(host, 'Retry failed tasks')).toBeUndefined()
    expect(button(host, 'Rebuild full index')).toBeUndefined()
    expect(button(host, 'Retry now')).toBeUndefined()
  })

  it('filters tasks and runs recovery actions after confirmation', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { host } = mount()
    await flush()

    const keyword = host.querySelector<HTMLInputElement>('[name="search-sync-keyword"]')!
    keyword.value = 'Canal'
    keyword.dispatchEvent(new Event('input'))
    const state = host.querySelector<HTMLSelectElement>('[name="search-sync-state"]')!
    state.value = 'retrying'
    state.dispatchEvent(new Event('change'))
    host.querySelector('form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.listAdminSearchSyncTasks).toHaveBeenLastCalledWith({
      keyword: 'Canal',
      state: 'retrying',
      page: 1,
      pageSize: 20,
    })

    button(host, 'Retry now')!.click()
    await flush()
    expect(adminMocks.retryAdminSearchSyncTask).toHaveBeenCalledWith(42)
    expect(host.textContent).toContain('The task has been queued again.')

    button(host, 'Retry failed tasks')!.click()
    await flush()
    expect(adminMocks.retryFailedAdminSearchSyncTasks).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('2 unhealthy tasks were queued again.')

    button(host, 'Rebuild full index')!.click()
    await flush()
    expect(adminMocks.rebuildAdminSearchIndex).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('Full index rebuild completed with 18 shops.')
    expect(confirm).toHaveBeenCalledTimes(3)
  })
})
