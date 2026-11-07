import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const opsMocks = vi.hoisted(() => ({
  createAdminExperiment: vi.fn(),
  deleteAdminFlagScope: vi.fn(),
  fetchAdminExperiments: vi.fn(),
  fetchAdminFlagScopes: vi.fn(),
  fetchAdminFlags: vi.fn(),
  saveAdminFlag: vi.fn(),
  saveAdminFlagScope: vi.fn(),
}))

vi.mock('@/services/ops', () => opsMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  return {
    useAdminSession: () => ({
      state: reactive({ region: 'CN', permissions: ['operations:experiment:read', 'operations:experiment:write'] }),
    }),
  }
})

import ExperimentsAdminView from './ExperimentsAdminView.vue'

const apps: ReturnType<typeof createApp>[] = []

async function flush() {
  await Promise.resolve(); await Promise.resolve(); await nextTick(); await Promise.resolve(); await nextTick()
}

describe('ExperimentsAdminView', () => {
  beforeEach(() => {
    Object.values(opsMocks).forEach((mock) => mock.mockReset())
    opsMocks.fetchAdminFlags.mockResolvedValue([
      { id: 3, flagKey: 'group_buy', description: 'kill switch', enabled: false, rolloutPercent: 0 },
    ])
    opsMocks.fetchAdminExperiments.mockResolvedValue([])
    opsMocks.fetchAdminFlagScopes.mockResolvedValue([
      { id: 31, featureFlagId: 3, scopeType: 'shop', scopeId: 10001, enabled: true, rolloutPercent: 10 },
    ])
    opsMocks.saveAdminFlagScope.mockResolvedValue({})
  })

  afterEach(() => apps.splice(0).forEach((app) => app.unmount()))

  it('loads scoped rollout rules for the group-buy kill switch', async () => {
    const host = document.createElement('div')
    const app = createApp(ExperimentsAdminView)
    app.mount(host)
    apps.push(app)
    await flush()

    const manage = [...host.querySelectorAll('button')]
      .find((button) => button.textContent?.trim() === '灰度规则') as HTMLButtonElement
    manage.click()
    await flush()

    expect(opsMocks.fetchAdminFlagScopes).toHaveBeenCalledWith(3)
    expect(host.textContent).toContain('group_buy 灰度规则')
    expect(host.textContent).toContain('10001')
    expect(host.textContent).toContain('10%')
  })
})
