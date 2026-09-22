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

const routerMocks = vi.hoisted(() => ({ push: vi.fn() }))
vi.mock('vue-router', () => ({
  useRouter: () => ({ push: routerMocks.push }),
  RouterLink: { props: ['to'], template: '<a><slot /></a>' },
}))

import ComplaintCreateView from './ComplaintCreateView.vue'

async function flush() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount(props: Record<string, unknown>) {
  const host = document.createElement('div')
  const app = createApp(ComplaintCreateView, props)
  app.mount(host)
  return { app, host }
}

describe('ComplaintCreateView', () => {
  beforeEach(() => {
    Object.values(complaintMocks).forEach((m) => m.mockReset())
    routerMocks.push.mockReset()
    appState.region = 'CN'
    complaintMocks.createComplaint.mockResolvedValue({ id: 7002 })
  })

  it('submits a complaint with shop and order context', async () => {
    const { host } = mount({ shopId: 10001, orderId: 55 })
    await flush()

    const title = host.querySelector<HTMLInputElement>('input[type="text"]')
    title!.value = '菜品与描述不符'
    title!.dispatchEvent(new Event('input'))
    const content = host.querySelector<HTMLTextAreaElement>('textarea')
    content!.value = '实际份量偏少，希望核实。'
    content!.dispatchEvent(new Event('input'))

    host.querySelector('form')?.dispatchEvent(new Event('submit', { cancelable: true }))
    await flush()

    expect(complaintMocks.createComplaint).toHaveBeenCalledWith({
      shopId: 10001,
      orderId: 55,
      type: 1,
      title: '菜品与描述不符',
      content: '实际份量偏少，希望核实。',
    })
    expect(routerMocks.push).toHaveBeenCalledWith('/user/complaints')
  })

  it('blocks submission without a shop', async () => {
    const { host } = mount({})
    await flush()
    expect(host.querySelector('form')).toBeNull()
    expect(host.textContent).toContain('缺少门店信息')
  })
})
