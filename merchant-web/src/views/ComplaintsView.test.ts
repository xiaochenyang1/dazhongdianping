import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchComplaints: vi.fn(),
  replyComplaint: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'CN' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import ComplaintsView from './ComplaintsView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function ticket(overrides: Record<string, unknown> = {}) {
  return {
    id: 7001, ticketNo: 'CT0001', userId: 9001, userNickname: '阿木',
    shopId: 10001, shopName: '沪上渝里', orderId: 0, type: 1, typeText: '商品/服务质量',
    title: '分量不符', content: '套餐份量偏少。', status: 1, statusText: '待受理',
    merchantReply: '', merchantRepliedAt: null, resolution: '', resolvedAt: null,
    createdAt: '2026-09-22 10:00:00', updatedAt: '2026-09-22 10:00:00',
    ...overrides,
  }
}

function mountView(permissions = ['complaint:view', 'complaint:reply']) {
  const host = document.createElement('div')
  const app = createApp(ComplaintsView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('ComplaintsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionState.region = 'CN'
    mocks.fetchComplaints.mockResolvedValue({ list: [ticket()], total: 1, page: 1, pageSize: 50, hasMore: false })
    mocks.replyComplaint.mockResolvedValue(ticket({ status: 2, merchantReply: '按标准配置' }))
  })

  it('lists complaints and submits a rebuttal', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchComplaints).toHaveBeenCalled()
    expect(host.textContent).toContain('CT0001')

    const textarea = host.querySelector<HTMLTextAreaElement>('textarea[name="reply-7001"]')
    expect(textarea).not.toBeNull()
    textarea!.value = '份量按标准配置'
    textarea!.dispatchEvent(new Event('input'))

    const btn = host.querySelector<HTMLButtonElement>('[data-testid="submit-reply-7001"]')
    btn!.dispatchEvent(new Event('click'))
    await flushView()

    expect(mocks.replyComplaint).toHaveBeenCalledWith(7001, '份量按标准配置')
  })

  it('hides reply actions without complaint:reply permission', async () => {
    const { host } = mountView(['complaint:view'])
    await flushView()

    expect(host.querySelector('[data-testid="reply-actions-7001"]')).toBeNull()
  })
})
