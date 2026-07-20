import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const reservationMocks = vi.hoisted(() => ({
  fetchReservation: vi.fn(),
  cancelReservation: vi.fn(),
  fetchReservationSlots: vi.fn(),
  rescheduleReservation: vi.fn(),
  createReservation: vi.fn(),
}))

vi.mock('@/services/reservation', () => reservationMocks)
vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn() }),
}))

import ReservationCreateView from './ReservationCreateView.vue'
import ReservationDetailView from './ReservationDetailView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('reservation date defaults', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 7, 3, 10, 0, 0))
    Object.values(reservationMocks).forEach((mock) => mock.mockReset())
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('defaults a new reservation to tomorrow and prevents past dates', () => {
    const host = document.createElement('div')
    const app = createApp(ReservationCreateView, { shopId: 10001 })
    app.mount(host)

    const dateInput = host.querySelector<HTMLInputElement>('input[type="date"]')
    expect(dateInput?.value).toBe('2026-08-04')
    expect(dateInput?.min).toBe('2026-08-03')

    app.unmount()
  })

  it('defaults rescheduling to the day after the existing reservation', async () => {
    reservationMocks.fetchReservation.mockResolvedValue({
      id: 1,
      reservationNo: 'RS202608100001',
      shop: { id: 10001, name: '测试门店' },
      reserveTime: '2026-08-10 18:00:00',
      peopleCount: 2,
      statusText: '已确认',
      canCancel: true,
      canReschedule: true,
      timeline: [],
    })

    const host = document.createElement('div')
    const app = createApp(ReservationDetailView, { reservationId: 1 })
    app.mount(host)
    await flushView()

    const dateInput = host.querySelector<HTMLInputElement>('input[type="date"]')
    expect(dateInput?.value).toBe('2026-08-11')
    expect(dateInput?.min).toBe('2026-08-03')

    app.unmount()
  })
})
