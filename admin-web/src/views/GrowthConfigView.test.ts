import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchGrowthConfig: vi.fn(),
  updateGrowthRule: vi.fn(),
  updateLevelConfig: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['operations:growth:read', 'operations:growth:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import GrowthConfigView from './GrowthConfigView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

function growthConfig() {
  return {
    rules: [{
      id: 1,
      action: 'review_create',
      actionName: '发布评价',
      growthValue: 10,
      points: 5,
      dailyLimit: 3,
      enabled: true,
      updatedAt: '2026-07-20 10:00:00',
    }],
    levels: [{
      level: 2,
      minGrowth: 100,
      levelName: '探店新秀',
      icon: 'https://cdn.example.com/level-2.png',
      privilegeJson: '{"badge":true}',
      enabled: true,
      updatedAt: '2026-07-20 10:00:00',
    }],
  }
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(GrowthConfigView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

function setInput(host: HTMLElement, name: string, value: string) {
  const input = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!input) throw new Error(`missing input ${name}`)
  input.value = value
  input.dispatchEvent(new Event('input'))
}

describe('GrowthConfigView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['operations:growth:read', 'operations:growth:write']
    mocks.fetchGrowthConfig.mockImplementation(async () => growthConfig())
    mocks.updateGrowthRule.mockResolvedValue(growthConfig().rules[0])
    mocks.updateLevelConfig.mockResolvedValue(growthConfig().levels[0])
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('updates growth rules and level configuration for users with write permission', async () => {
    const { host } = mountView()
    await flushView()

    setInput(host, 'rule-growth-value-1', '12')
    setInput(host, 'rule-points-1', '6')
    setInput(host, 'rule-daily-limit-1', '4')
    host.querySelector<HTMLButtonElement>('[data-testid="save-growth-rule-1"]')?.click()
    await flushView()

    expect(mocks.updateGrowthRule).toHaveBeenCalledWith(1, {
      action: 'review_create',
      actionName: '发布评价',
      growthValue: 12,
      points: 6,
      dailyLimit: 4,
      enabled: true,
    })

    setInput(host, 'level-name-2', '资深探店家')
    setInput(host, 'level-min-growth-2', '180')
    host.querySelector<HTMLButtonElement>('[data-testid="save-growth-level-2"]')?.click()
    await flushView()

    expect(mocks.updateLevelConfig).toHaveBeenCalledWith(2, {
      minGrowth: 180,
      levelName: '资深探店家',
      icon: 'https://cdn.example.com/level-2.png',
      privilegeJson: '{"badge":true}',
      enabled: true,
    })
  })

  it('keeps configuration visible while disabling every write control for read-only users', async () => {
    sessionMock.state.permissions = ['operations:growth:read']
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchGrowthConfig).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('发布点评')
    expect(host.querySelector<HTMLInputElement>('[name="level-name-2"]')?.value).toBe('探店新秀')
    expect([...host.querySelectorAll<HTMLInputElement>('input')].every((input) => input.disabled)).toBe(true)
    expect(host.querySelector('[data-testid^="save-growth-rule-"]')).toBeNull()
    expect(host.querySelector('[data-testid^="save-growth-level-"]')).toBeNull()
    expect(mocks.updateGrowthRule).not.toHaveBeenCalled()
    expect(mocks.updateLevelConfig).not.toHaveBeenCalled()
  })

  it('blocks stale save controls after write permission is revoked', async () => {
    const { host } = mountView()
    await flushView()

    const saveRule = host.querySelector<HTMLButtonElement>('[data-testid="save-growth-rule-1"]')
    const saveLevel = host.querySelector<HTMLButtonElement>('[data-testid="save-growth-level-2"]')
    if (!saveRule || !saveLevel) throw new Error('missing growth configuration save buttons')
    setInput(host, 'rule-growth-value-1', '20')
    setInput(host, 'level-min-growth-2', '200')

    sessionMock.state.permissions = ['operations:growth:read']
    saveRule.click()
    saveLevel.click()
    await flushView()

    expect(mocks.updateGrowthRule).not.toHaveBeenCalled()
    expect(mocks.updateLevelConfig).not.toHaveBeenCalled()
    expect([...host.querySelectorAll<HTMLInputElement>('input')].every((input) => input.disabled)).toBe(true)
    expect(host.querySelector('[data-testid^="save-growth-rule-"]')).toBeNull()
    expect(host.querySelector('[data-testid^="save-growth-level-"]')).toBeNull()
  })
})
