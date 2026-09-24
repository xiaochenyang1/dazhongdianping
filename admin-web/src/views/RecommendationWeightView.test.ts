import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchRecommendationWeight: vi.fn(),
  updateRecommendationWeight: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['operations:recommendation:read', 'operations:recommendation:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import RecommendationWeightView from './RecommendationWeightView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

function weight() {
  return { region: 'CN', affinityWeight: 40, qualityWeight: 25, popularityWeight: 20, distanceWeight: 15 }
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
  const app = createApp(RecommendationWeightView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

describe('RecommendationWeightView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['operations:recommendation:read', 'operations:recommendation:write']
    mocks.fetchRecommendationWeight.mockImplementation(async () => weight())
    mocks.updateRecommendationWeight.mockImplementation(async () => ({
      ...weight(),
      affinityWeight: 50,
      distanceWeight: 10,
    }))
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads current weights and saves updates for writers', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchRecommendationWeight).toHaveBeenCalled()
    const affinity = host.querySelectorAll<HTMLInputElement>('input[type="number"]')[0]
    expect(affinity.value).toBe('40')

    affinity.value = '50'
    affinity.dispatchEvent(new Event('input'))
    const distance = host.querySelectorAll<HTMLInputElement>('input[type="number"]')[3]
    distance.value = '10'
    distance.dispatchEvent(new Event('input'))

    host.querySelector('form')?.dispatchEvent(new Event('submit', { cancelable: true }))
    await flushView()

    expect(mocks.updateRecommendationWeight).toHaveBeenCalledWith({
      affinityWeight: 50,
      qualityWeight: 25,
      popularityWeight: 20,
      distanceWeight: 10,
    })
    expect(host.textContent).toContain('推荐权重已保存。')
  })

  it('disables editing without write permission', async () => {
    sessionMock.state.permissions = ['operations:recommendation:read']
    const { host } = mountView()
    await flushView()

    const inputs = host.querySelectorAll<HTMLInputElement>('input[type="number"]')
    inputs.forEach((input) => expect(input.disabled).toBe(true))
    expect(host.querySelector<HTMLButtonElement>('button[type="submit"]')?.disabled).toBe(true)
  })
})
