import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const serviceMocks = vi.hoisted(() => ({
  fetchReservation: vi.fn(),
  cancelReservation: vi.fn(),
  fetchReservationSlots: vi.fn(),
  rescheduleReservation: vi.fn(),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string>,
}))

vi.mock('@/services/reservation', () => serviceMocks)
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
}))

import ReservationDetailView from './ReservationDetailView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount(reservationId = 33) {
  const host = document.createElement('div')
  const app = createApp(ReservationDetailView, { reservationId })
  app.mount(host)
  return { app, host }
}

describe('ReservationDetailView', () => {
  beforeEach(() => {
    useAppContext().setRegion('CN')
    Object.values(serviceMocks).forEach((mock) => mock.mockReset())
    routeState.query = {}
    serviceMocks.fetchReservation.mockResolvedValue({
      id: 33,
      reservationNo: 'R1001',
      shop: { id: 20001, name: '巴黎川菜馆', coverImage: '', address: 'Paris' },
      slotId: 51001,
      reserveTime: '2026-07-26 18:30:00',
      peopleCount: 2,
      contactName: 'Lina',
      contactPhone: '+33123456789',
      remark: '',
      status: 1,
      statusText: '已确认',
      confirmMode: 2,
      confirmModeText: '人工确认',
      rescheduleCount: 0,
      canCancel: true,
      canReschedule: true,
      timeline: [
        {
          actionType: 2,
          actionText: '商户确认',
          operatorType: 2,
          operatorText: '商户',
          remark: '商户确认',
          createdAt: '2026-07-25 10:00:00',
        },
      ],
    })
  })

  it('loads reservation detail and shows status banner from notification query', async () => {
    routeState.query = { status: 'confirmed' }
    const { app, host } = mount()
    await flush()

    expect(serviceMocks.fetchReservation).toHaveBeenCalledWith(33)
    expect(host.textContent).toContain('巴黎川菜馆')
    expect(host.textContent).toContain('已确认')
    expect(host.querySelector('[data-testid="reservation-status-banner"]')?.textContent).toContain(
      '商户已确认你的预订',
    )
    expect(host.textContent).toContain('商户确认')
    app.unmount()
  })

  it('localizes reservation status and timeline values for EU', async () => {
    useAppContext().setRegion('EU')
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('Confirmed')
    expect(host.textContent).toContain('Confirmed by place')
    expect(host.textContent).toContain('Place')
    expect(host.textContent).toContain('25/07/2026')
    expect(host.textContent).not.toContain('已确认')
    expect(host.textContent).not.toContain('商户确认')
    app.unmount()
  })
})
