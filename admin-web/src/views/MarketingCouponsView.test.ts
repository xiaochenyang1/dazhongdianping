import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchCouponTemplates: vi.fn(),
  createCouponTemplate: vi.fn(),
  updateCouponTemplate: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['operations:marketing:read', 'operations:marketing:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import MarketingCouponsView from './MarketingCouponsView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

function template(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 5001,
    region: 'CN',
    name: '满100减20',
    type: 1,
    typeText: '满减券',
    thresholdAmount: 100,
    discountAmount: 20,
    currency: 'CNY',
    shopId: 0,
    totalQuantity: 1000,
    claimedQuantity: 10,
    perUserLimit: 1,
    validDays: 30,
    claimStart: null,
    claimEnd: null,
    status: 1,
    ...overrides,
  }
}

function page(list: unknown[]) {
  return { list, total: list.length, page: 1, pageSize: 50, hasMore: false }
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
  const app = createApp(MarketingCouponsView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

describe('MarketingCouponsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['operations:marketing:read', 'operations:marketing:write']
    mocks.fetchCouponTemplates.mockImplementation(async () => page([template()]))
    mocks.createCouponTemplate.mockImplementation(async () => template({ id: 5099, name: '新客立减15' }))
    mocks.updateCouponTemplate.mockImplementation(async () => template())
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('lists templates and creates a new one', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchCouponTemplates).toHaveBeenCalled()
    expect(host.textContent).toContain('满100减20')

    const createButton = Array.from(host.querySelectorAll('button')).find((b) => b.textContent === '新建券模板')
    createButton?.dispatchEvent(new Event('click'))
    await flushView()

    const nameInput = host.querySelector<HTMLInputElement>('.coupon-form input[type="text"]')
    expect(nameInput).not.toBeNull()
    nameInput!.value = '新客立减15'
    nameInput!.dispatchEvent(new Event('input'))
    const discount = host.querySelectorAll<HTMLInputElement>('.coupon-form input[type="number"]')
    // threshold, discount, shopId, totalQuantity, perUserLimit, validDays (threshold hidden only when type=2)
    discount[1].value = '15'
    discount[1].dispatchEvent(new Event('input'))

    host.querySelector('.coupon-form')?.dispatchEvent(new Event('submit', { cancelable: true }))
    await flushView()

    expect(mocks.createCouponTemplate).toHaveBeenCalled()
    const payload = mocks.createCouponTemplate.mock.calls[0][0]
    expect(payload.name).toBe('新客立减15')
    expect(payload.discountAmount).toBe(15)
    expect(host.textContent).toContain('券模板已创建。')
  })

  it('hides write controls without permission', async () => {
    sessionMock.state.permissions = ['operations:marketing:read']
    const { host } = mountView()
    await flushView()

    const createButton = Array.from(host.querySelectorAll('button')).find((b) => b.textContent === '新建券模板')
    expect(createButton).toBeUndefined()
    const editButton = Array.from(host.querySelectorAll('button')).find((b) => b.textContent === '编辑')
    expect(editButton).toBeUndefined()
    expect(host.textContent).toContain('你只有营销券的只读权限。')
  })
})
