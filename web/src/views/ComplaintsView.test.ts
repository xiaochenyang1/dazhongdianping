import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const appState = vi.hoisted(() => ({ region: 'CN' as 'CN' | 'EU' }))
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: appState }),
}))

const complaintMocks = vi.hoisted(() => ({
  fetchMyComplaints: vi.fn(),
  createComplaint: vi.fn(),
  fetchComplaint: vi.fn(),
}))
vi.mock('@/services/complaint', () => complaintMocks)

vi.mock('vue-router', () => ({
  RouterLink: {
    props: ['to'],
    template: '<a><slot /></a>',
  },
}))

import ComplaintsView from './ComplaintsView.vue'

async function flush() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(ComplaintsView)
  app.mount(host)
  return { app, host }
}

function ticket() {
  return {
    id: 7001, ticketNo: 'CT0001', userId: 9001, userNickname: '阿木',
    shopId: 10001, shopName: '沪上渝里', orderId: 0, type: 1, typeText: '商品/服务质量',
    title: '分量不符', content: '套餐份量偏少。', status: 2, statusText: '处理中',
    merchantReply: '按标准配置', merchantRepliedAt: null, resolution: '', resolvedAt: null,
    createdAt: '2026-09-22 10:00:00', updatedAt: '2026-09-22 10:00:00',
  }
}

describe('ComplaintsView', () => {
  beforeEach(() => {
    Object.values(complaintMocks).forEach((m) => m.mockReset())
    appState.region = 'CN'
    complaintMocks.fetchMyComplaints.mockResolvedValue({ list: [ticket()], total: 1, page: 1, pageSize: 20, hasMore: false })
  })

  it('loads and renders my complaints', async () => {
    const { host } = mount()
    await flush()

    expect(complaintMocks.fetchMyComplaints).toHaveBeenCalled()
    expect(host.textContent).toContain('分量不符')
    expect(host.textContent).toContain('处理中')
    expect(host.textContent).toContain('按标准配置')
  })
})
