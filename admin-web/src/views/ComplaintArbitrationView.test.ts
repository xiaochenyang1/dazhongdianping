import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchComplaints: vi.fn(),
  fetchComplaint: vi.fn(),
  disposeComplaint: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['audit:complaint:read', 'audit:complaint:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import ComplaintArbitrationView from './ComplaintArbitrationView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

function ticket(overrides: Record<string, unknown> = {}) {
  return {
    id: 7001,
    ticketNo: 'CT0001',
    userId: 9001,
    userNickname: '审评员阿木',
    shopId: 10001,
    shopName: '沪上渝里',
    orderId: 0,
    type: 1,
    typeText: '商品/服务质量',
    title: '分量不符',
    content: '套餐份量偏少。',
    status: 1,
    statusText: '待受理',
    merchantReply: '',
    merchantRepliedAt: null,
    resolution: '',
    resolvedAt: null,
    createdAt: '2026-09-22 10:00:00',
    updatedAt: '2026-09-22 10:00:00',
    logs: [{ id: 1, actorType: 1, actorTypeText: '用户', action: 1, actionText: '创建投诉', remark: '套餐份量偏少。', createdAt: '2026-09-22 10:00:00' }],
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
  const app = createApp(ComplaintArbitrationView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

describe('ComplaintArbitrationView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['audit:complaint:read', 'audit:complaint:write']
    mocks.fetchComplaints.mockImplementation(async () => page([ticket()]))
    mocks.fetchComplaint.mockImplementation(async () => ticket())
    mocks.disposeComplaint.mockImplementation(async () => ticket({ status: 3, statusText: '已解决' }))
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('lists tickets, opens detail and disposes', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchComplaints).toHaveBeenCalled()
    expect(host.textContent).toContain('CT0001')

    const viewBtn = Array.from(host.querySelectorAll('button')).find((b) => b.textContent === '查看')
    viewBtn?.dispatchEvent(new Event('click'))
    await flushView()

    expect(mocks.fetchComplaint).toHaveBeenCalledWith(7001)
    const textarea = host.querySelector<HTMLTextAreaElement>('.dispose-form textarea')
    expect(textarea).not.toBeNull()
    textarea!.value = '判定成立'
    textarea!.dispatchEvent(new Event('input'))

    host.querySelector('.dispose-form')?.dispatchEvent(new Event('submit', { cancelable: true }))
    await flushView()

    expect(mocks.disposeComplaint).toHaveBeenCalledWith(7001, { resolved: true, resolution: '判定成立' })
    expect(host.textContent).toContain('投诉已处置。')
  })

  it('hides dispose form without write permission', async () => {
    sessionMock.state.permissions = ['audit:complaint:read']
    const { host } = mountView()
    await flushView()

    const viewBtn = Array.from(host.querySelectorAll('button')).find((b) => b.textContent === '查看')
    viewBtn?.dispatchEvent(new Event('click'))
    await flushView()

    expect(host.querySelector('.dispose-form')).toBeNull()
    expect(host.textContent).toContain('你只有投诉纠纷的只读权限。')
  })
})
