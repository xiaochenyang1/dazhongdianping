import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchReservations: vi.fn(),
  confirmReservation: vi.fn(),
  rejectReservation: vi.fn(),
  arriveReservation: vi.fn(),
  markReservationNoShow: vi.fn(),
  fetchReservationSlots: vi.fn(),
  rescheduleReservation: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'EU' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import ReservationsView from './ReservationsView.vue'

async function flushView() {
  for (let index = 0; index < 5; index += 1) {
    await Promise.resolve()
  }
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
          slotId: 51001,
          reserveTime: '2026-07-22T18:30:00',
          status: 0,
          statusText: '待确认',
          canConfirm: true,
          canReject: true,
          canArrive: false,
          canNoShow: false,
          canReschedule: true,
          peopleCount: 2,
          contactName: 'Lina',
          contactPhone: '+33123456789',
        },
        {
          id: 33,
          reservationNo: 'RSV-33',
          shop: { id: 20001, name: '巴黎川味馆' },
          slotId: 51003,
          reserveTime: '2026-07-22T19:30:00',
          status: 1,
          statusText: '已确认',
          canConfirm: false,
          canReject: false,
          canArrive: true,
          canNoShow: true,
          canReschedule: true,
          peopleCount: 4,
          contactName: 'Noah',
          contactPhone: '+49301234567',
        },
        {
          id: 32,
          reservationNo: 'RSV-32',
          shop: { id: 20001, name: '巴黎川味馆' },
          slotId: 51002,
          reserveTime: '2026-07-20T12:00:00',
          status: 4,
          statusText: '商户拒绝',
          canConfirm: false,
          canReject: false,
          canArrive: false,
          canNoShow: false,
          canReschedule: false,
        },
      ],
      total: 3,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    mocks.fetchReservationSlots.mockResolvedValue({
      list: [
        {
          id: 51004,
          shopId: 20001,
          shopName: '巴黎川味馆',
          bizDate: '2026-07-23',
          startTime: '20:00:00',
          endTime: '21:30:00',
          remainingCount: 6,
          enabled: true,
        },
        {
          id: 52001,
          shopId: 20002,
          shopName: 'Other shop',
          bizDate: '2026-07-23',
          startTime: '20:00:00',
          endTime: '21:30:00',
          remainingCount: 6,
          enabled: true,
        },
      ],
      total: 2,
      page: 1,
      pageSize: 100,
      hasMore: false,
    })
    mocks.confirmReservation.mockResolvedValue({})
    mocks.rejectReservation.mockResolvedValue({})
    mocks.arriveReservation.mockResolvedValue({})
    mocks.markReservationNoShow.mockResolvedValue({})
    mocks.rescheduleReservation.mockResolvedValue({})
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

  it('reschedules to an available slot with a required reason', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(mocks.fetchReservationSlots).toHaveBeenCalledWith({
      enabled: true,
      page: 1,
      pageSize: 100,
    })
    const slot = host.querySelector<HTMLSelectElement>('[name="reservation-slot-31"]')
    const reason = host.querySelector<HTMLInputElement>('[name="reservation-reschedule-reason-31"]')
    if (!slot || !reason) throw new Error('missing reschedule controls')
    expect(slot.textContent).toContain('巴黎川味馆 2026-07-23 20:00:00-21:30:00 (6 remaining)')
    expect(slot.textContent).not.toContain('Other shop')

    host.querySelector<HTMLButtonElement>('[data-testid="reschedule-reservation-btn-31"]')?.click()
    await nextTick()
    expect(host.textContent).toContain('Select a new slot and enter a reschedule reason.')
    expect(mocks.rescheduleReservation).not.toHaveBeenCalled()

    slot.value = '51004'
    slot.dispatchEvent(new Event('change'))
    reason.value = ' Move to the later service '
    reason.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="reschedule-reservation-btn-31"]')?.click()
    await flushView()

    expect(mocks.rescheduleReservation).toHaveBeenCalledWith(31, {
      slotId: 51004,
      reason: 'Move to the later service',
    })
    expect(host.querySelector('[data-testid="reservation-success"]')?.textContent)
      .toContain('Reservation RSV-31 rescheduled.')
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
