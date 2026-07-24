import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchShops: vi.fn(),
  fetchReservationSlots: vi.fn(),
  createReservationSlot: vi.fn(),
  updateReservationSlot: vi.fn(),
  updateReservationSlotStatus: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)

import ReservationSlotsView from './ReservationSlotsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount(permissions = ['reservation:view', 'reservation:confirm']) {
  const host = document.createElement('div')
  const app = createApp(ReservationSlotsView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('ReservationSlotsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchShops.mockResolvedValue({
      list: [{ id: 20001, name: '巴黎川味馆' }],
      total: 1,
      page: 1,
      pageSize: 100,
      hasMore: false,
    })
    mocks.fetchReservationSlots.mockResolvedValue({
      list: [
        {
          id: 9,
          shopId: 20001,
          shopName: '巴黎川味馆',
          bizDate: '2026-07-28',
          startTime: '18:00:00',
          endTime: '20:00:00',
          capacity: 10,
          reservedCount: 2,
          remainingCount: 8,
          confirmMode: 2,
          confirmModeText: '人工确认',
          cancelBeforeMinutes: 120,
          enabled: true,
        },
      ],
      total: 1,
      page: 1,
      pageSize: 100,
      hasMore: false,
    })
    mocks.createReservationSlot.mockResolvedValue({ id: 10 })
    mocks.updateReservationSlotStatus.mockResolvedValue({ id: 9, enabled: false })
  })

  it('loads shops and slots then creates a slot', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.fetchShops).toHaveBeenCalled()
    expect(mocks.fetchReservationSlots).toHaveBeenCalled()
    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('18:00:00')

    host.querySelector<HTMLButtonElement>('[data-testid="create-slot"]')?.click()
    await nextTick()
    host.querySelector<HTMLFormElement>('[data-testid="slot-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createReservationSlot).toHaveBeenCalled()
    app.unmount()
  })

  it('toggles slot enabled state', async () => {
    const { app, host } = mount()
    await flush()
    host.querySelector<HTMLButtonElement>('[data-testid="toggle-slot-9"]')?.click()
    await flush()
    expect(mocks.updateReservationSlotStatus).toHaveBeenCalledWith(9, false)
    app.unmount()
  })

  it('hides edit actions without reservation:confirm', async () => {
    const { app, host } = mount(['reservation:view'])
    await flush()
    expect(host.querySelector('[data-testid="create-slot"]')).toBeNull()
    expect(host.querySelector('[data-testid="toggle-slot-9"]')).toBeNull()
    app.unmount()
  })
})
