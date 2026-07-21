import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchReservations: vi.fn(),
  confirmReservation: vi.fn(),
  rejectReservation: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)

import ReservationsView from './ReservationsView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView(permissions = ['reservation:view', 'reservation:confirm']) {
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
        },
        {
          id: 32,
          reservationNo: 'RSV-32',
          shop: { id: 20001, name: '巴黎川味馆' },
          reserveTime: '2026-07-20T12:00:00',
          status: 2,
          statusText: '已拒绝',
          canConfirm: false,
          canReject: false,
        },
      ],
      total: 2,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    mocks.confirmReservation.mockResolvedValue({})
    mocks.rejectReservation.mockResolvedValue({})
  })

  it('renders backend reservation fields and gates actions by state', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('2026-07-22T18:30:00')
    expect(host.querySelector('[data-testid="reservation-actions-31"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="reservation-actions-32"]')).toBeNull()

    host.querySelector<HTMLButtonElement>('[data-testid="confirm-reservation-31"]')?.click()
    await flushView()
    expect(mocks.confirmReservation).toHaveBeenCalledWith(31)
    app.unmount()
  })

  it('requires and sends a rejection reason', async () => {
    const { app, host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="reject-reservation-31"]')?.click()
    await nextTick()
    expect(host.textContent).toContain('请填写拒绝原因')
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

  it('hides reservation controls without reservation:confirm permission', async () => {
    const { app, host } = mountView(['reservation:view'])
    await flushView()

    expect(host.querySelector('[data-testid="reservation-actions-31"]')).toBeNull()
    expect(host.querySelector('[data-testid="confirm-reservation-31"]')).toBeNull()
    expect(mocks.confirmReservation).not.toHaveBeenCalled()
    expect(mocks.rejectReservation).not.toHaveBeenCalled()
    app.unmount()
  })
})
