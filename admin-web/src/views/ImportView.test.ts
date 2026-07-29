import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  importShops: vi.fn(),
  listImportBatches: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['data:import:read', 'data:import:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import ImportView from './ImportView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(ImportView)
  app.mount(host)
  return { app, host }
}

function batchPage() {
  return {
    list: [
      {
        id: 41,
        fileName: 'seed-eu-shops.json',
        region: 'EU',
        total: 1,
        success: 1,
        failed: 0,
        status: 1,
        statusText: '完成',
        errorFile: '',
        createdAt: '2026-07-25 10:00:00',
      },
    ],
    total: 1,
    page: 1,
    pageSize: 10,
    hasMore: false,
  }
}

describe('ImportView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['data:import:read', 'data:import:write']
    adminMocks.listImportBatches.mockResolvedValue(batchPage())
    adminMocks.importShops.mockResolvedValue({
      batchId: 42,
      total: 1,
      success: 1,
      failed: 0,
      status: 1,
      statusText: '完成',
      errorFile: '',
      errorMessages: [],
    })
  })

  it('loads import batches and submits the EU example payload', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listImportBatches).toHaveBeenCalledWith({
      region: 'EU',
      status: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('Seed Imports')
    expect(host.textContent).toContain('Import batches')

    const submitButton = host.querySelector<HTMLButtonElement>('[data-testid="import-submit"]')
    if (!submitButton) throw new Error('missing import submit button')
    submitButton.click()
    await flushView()

    expect(adminMocks.importShops).toHaveBeenCalledWith({
      fileName: 'seed-eu-shops.json',
      region: 'EU',
      records: [
        expect.objectContaining({
          shopName: 'Paris Seed Import Sichuan Bistro',
          summary: 'Sample shop used to demonstrate the EU import flow.',
        }),
      ],
    })
    expect(host.textContent).toContain('Import complete: 1 succeeded, 0 failed.')
    expect(host.textContent).toContain('Completed')
    app.unmount()
  })

  it('requires a non-empty JSON array before importing', async () => {
    const { app, host } = mountView()
    await flushView()

    const textarea = host.querySelector<HTMLTextAreaElement>('[data-testid="import-records-textarea"]')
    if (!textarea) throw new Error('missing import records textarea')
    textarea.value = '[]'
    textarea.dispatchEvent(new Event('input'))

    const submitButton = host.querySelector<HTMLButtonElement>('[data-testid="import-submit"]')
    if (!submitButton) throw new Error('missing import submit button')
    submitButton.click()
    await flushView()

    expect(adminMocks.importShops).not.toHaveBeenCalled()
    expect(host.textContent).toContain('Import records must be a non-empty JSON array.')
    app.unmount()
  })
})
