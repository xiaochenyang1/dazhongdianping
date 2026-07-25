import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const reservationMocks = vi.hoisted(() => ({
  fetchReservations: vi.fn(),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string | string[] | undefined>,
}))

const routerMocks = vi.hoisted(() => ({
  replace: vi.fn(),
}))

vi.mock('@/services/reservation', () => reservationMocks)
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  useRouter: () => routerMocks,
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path" v-bind="$attrs"><slot /></a>',
  },
}))

import ReservationsView from './ReservationsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(ReservationsView)
  app.mount(host)
  return { app, host }
}

const sample = {
  id: 11,
  reservationNo: 'RS-11',
  shop: {
    id: 2,
    name: '柏林茶馆',
    coverImage: 'https://example.com/cover.jpg',
    address: 'Berlin Mitte',
  },
  slotId: 1,
  reserveTime: '2026-07-20T18:00:00',
  peopleCount: 2,
  contactName: 'Li',
  contactPhone: '+447700900000',
  remark: '',
  status: 1,
  statusText: '已确认',
  confirmMode: 1,
  confirmModeText: '自动确认',
  rescheduleCount: 0,
  canCancel: true,
  canReschedule: true,
}

describe('ReservationsView', () => {
  beforeEach(() => {
    reservationMocks.fetchReservations.mockReset()
    routerMocks.replace.mockReset()
    routeState.query = {}
    reservationMocks.fetchReservations.mockResolvedValue({
      list: [sample],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
  })

  it('loads reservations with status from query', async () => {
    routeState.query = { status: '1' }
    const { app, host } = mount()
    await flush()

    expect(reservationMocks.fetchReservations).toHaveBeenCalledWith(1, 1, 50)
    expect(host.textContent).toContain('柏林茶馆')
    expect(host.textContent).toContain('RS-11')
    expect(host.textContent).toContain('当前筛选：已确认')
    expect(host.querySelector('[data-testid="reservation-card-11"]')).not.toBeNull()
    app.unmount()
  })

  it('switches status filter via router query', async () => {
    const { app, host } = mount()
    await flush()

    const pendingTab = host.querySelector(
      '[data-testid="reservation-tab-0"]',
    ) as HTMLButtonElement | null
    expect(pendingTab).not.toBeNull()
    pendingTab?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flush()

    expect(routerMocks.replace).toHaveBeenCalledWith({
      path: '/user/reservations',
      query: { status: '0' },
    })
    app.unmount()
  })
})
