import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchReservations: vi.fn(),
  confirmReservation: vi.fn(),
  rejectReservation: vi.fn(),
  arriveReservation: vi.fn(),
  markReservationNoShow: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'EU' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import ReservationsView from './ReservationsView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView(permissions = ['reservation:view', 'reservation:confirm', 'reservation:arrive']) {
  const host = document.createElement('div')
  const app = createApp(ReservationsView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('ReservationsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchReservations.mockResolvedValue({
      list: [
        {
          id: 31,
          reservationNo: 'RSV-31',
          shop: { id: 20001, name: '巴黎川味馆' },
          reserveTime: '2026-07-22T18:30:00',
          status: 0,
          statusText: '待确认',
          canConfirm: true,
          canReject: true,
          canArrive: false,
          canNoShow: false,
          peopleCount: 2,
          contactName: 'Lina',
          contactPhone: '+33123456789',
        },
        {
          id: 33,
          reservationNo: 'RSV-33',
          shop: { id: 20001, name: '巴黎川味馆' },
          reserveTime: '2026-07-22T19:30:00',
          status: 1,
          statusText: '已确认',
          canConfirm: false,
          canReject: false,
          canArrive: true,
          canNoShow: true,
          peopleCount: 4,
          contactName: 'Noah',
          contactPhone: '+49301234567',
        },
        {
          id: 32,
          reservationNo: 'RSV-32',
          shop: { id: 20001, name: '巴黎川味馆' },
          reserveTime: '2026-07-20T12:00:00',
          status: 4,
          statusText: '商户拒绝',
          canConfirm: false,
          canReject: false,
          canArrive: false,
          canNoShow: false,
        },
      ],
      total: 3,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    mocks.confirmReservation.mockResolvedValue({})
    mocks.rejectReservation.mockResolvedValue({})
    mocks.arriveReservation.mockResolvedValue({})
    mocks.markReservationNoShow.mockResolvedValue({})
  })

  it('renders backend reservation fields and gates actions by state', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(mocks.fetchReservations).toHaveBeenCalledWith({
      page: 1,
      pageSize: 50,
      status: 0,
    })
    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('2026-07-22T18:30:00')
    expect(host.textContent).toContain('Lina')
    expect(host.textContent).toContain('2 guests')
    expect(host.querySelector('[data-testid="reservation-actions-31"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="reservation-actions-33"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="reservation-actions-32"]')).toBeNull()
    expect(host.querySelector('[data-testid="arrive-reservation-33"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="noshow-reservation-33"]')).not.toBeNull()

    host.querySelector<HTMLButtonElement>('[data-testid="confirm-reservation-31"]')?.click()
    await flushView()
    expect(mocks.confirmReservation).toHaveBeenCalledWith(31)
    expect(host.querySelector('[data-testid="reservation-success"]')?.textContent).toContain('Reservation RSV-31 confirmed.')
    app.unmount()
  })

  it('requires and sends a rejection reason', async () => {
    const { app, host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="reject-reservation-31"]')?.click()
    await nextTick()
    expect(host.textContent).toContain('Enter a rejection reason.')
    expect(mocks.rejectReservation).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLInputElement>('[name="reservation-reason-31"]')
    if (!reason) throw new Error('missing reservation reason')
    reason.value = '该时段已经满位，无法继续接待'
    reason.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="reject-reservation-31"]')?.click()
    await flushView()
    expect(mocks.rejectReservation).toHaveBeenCalledWith(31, '该时段已经满位，无法继续接待')
    app.unmount()
  })

  it('marks confirmed reservations as arrived or no-show', async () => {
    const { app, host } = mountView()
    await flushView()

    host.querySelector<HTMLButtonElement>('[data-testid="arrive-reservation-33"]')?.click()
    await flushView()
    expect(mocks.arriveReservation).toHaveBeenCalledWith(33)

    host.querySelector<HTMLButtonElement>('[data-testid="noshow-reservation-33"]')?.click()
    await flushView()
    expect(mocks.markReservationNoShow).toHaveBeenCalledWith(33)
    app.unmount()
  })

  it('hides reservation controls without fulfillment permissions', async () => {
    const { app, host } = mountView(['reservation:view'])
    await flushView()

    expect(host.querySelector('[data-testid="reservation-actions-31"]')).toBeNull()
    expect(host.querySelector('[data-testid="confirm-reservation-31"]')).toBeNull()
    expect(host.querySelector('[data-testid="arrive-reservation-33"]')).toBeNull()
    expect(mocks.confirmReservation).not.toHaveBeenCalled()
    expect(mocks.rejectReservation).not.toHaveBeenCalled()
    expect(mocks.arriveReservation).not.toHaveBeenCalled()
    expect(mocks.markReservationNoShow).not.toHaveBeenCalled()
    app.unmount()
  })
})
