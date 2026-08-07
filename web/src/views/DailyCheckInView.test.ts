import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const authMocks = vi.hoisted(() => ({
  checkInCurrentUser: vi.fn(),
  fetchCurrentUser: vi.fn(),
  fetchUserCheckInStatus: vi.fn(),
}))

const sessionMocks = vi.hoisted(() => ({
  setCurrentUser: vi.fn(),
}))

vi.mock('@/services/auth', () => authMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => sessionMocks,
}))

import DailyCheckInView from './DailyCheckInView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(DailyCheckInView)
  app.component('RouterLink', RouterLinkStub)
  app.mount(host)
  return { app, host }
}

function uncheckedStatus() {
  return {
    checkedInToday: false,
    streakDays: 3,
    totalCount: 12,
    todayGrowthReward: 2,
    todayPointsReward: 1,
    lastCheckInAt: '2026-08-05 09:30:00',
  }
}

describe('DailyCheckInView', () => {
  beforeEach(() => {
    Object.values(authMocks).forEach((mock) => mock.mockReset())
    sessionMocks.setCurrentUser.mockReset()
    useAppContext().setRegion('CN')
    authMocks.fetchUserCheckInStatus.mockResolvedValue(uncheckedStatus())
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9001,
      nickname: '阿评',
      preferredRegion: 'CN',
      level: 3,
      points: 101,
      growthValue: 202,
    })
  })

  it('shows the current status and credits a completed check-in', async () => {
    authMocks.checkInCurrentUser.mockResolvedValue({
      ...uncheckedStatus(),
      checkedInToday: true,
      streakDays: 4,
      totalCount: 13,
      lastCheckInAt: '2026-08-06 09:31:00',
    })

    const { app, host } = mount()
    await flushView()

    expect(host.textContent).toContain('连续签到')
    expect(host.textContent).toContain('3 天')
    expect(host.textContent).toContain('成长值 +2 · 积分 +1')

    ;(host.querySelector('[data-testid="check-in-submit"]') as HTMLButtonElement).click()
    await flushView()

    expect(authMocks.checkInCurrentUser).toHaveBeenCalledTimes(1)
    expect(authMocks.fetchCurrentUser).toHaveBeenCalledTimes(1)
    expect(sessionMocks.setCurrentUser).toHaveBeenCalledWith(expect.objectContaining({ points: 101, growthValue: 202 }))
    expect(host.textContent).toContain('今日已签到')
    expect(host.textContent).toContain('4 天')
    expect(host.textContent).toContain('签到成功，奖励已入账。')
    app.unmount()
  })

  it('retries an initial status failure', async () => {
    authMocks.fetchUserCheckInStatus
      .mockRejectedValueOnce(new Error('offline'))
      .mockResolvedValueOnce(uncheckedStatus())

    const { app, host } = mount()
    await flushView()

    expect(host.textContent).toContain('offline')
    ;(host.querySelector('[data-testid="check-in-retry"]') as HTMLButtonElement).click()
    await flushView()

    expect(authMocks.fetchUserCheckInStatus).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('立即签到')
    app.unmount()
  })

  it('guards duplicate submissions while the request is pending', async () => {
    let resolveCheckIn!: (value: ReturnType<typeof uncheckedStatus>) => void
    authMocks.checkInCurrentUser.mockReturnValue(new Promise((resolve) => {
      resolveCheckIn = resolve
    }))

    const { app, host } = mount()
    await flushView()

    const submit = host.querySelector('[data-testid="check-in-submit"]') as HTMLButtonElement
    submit.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    submit.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await nextTick()

    expect(authMocks.checkInCurrentUser).toHaveBeenCalledTimes(1)
    expect(submit.disabled).toBe(true)

    resolveCheckIn({ ...uncheckedStatus(), checkedInToday: true })
    await flushView()
    expect(authMocks.checkInCurrentUser).toHaveBeenCalledTimes(1)
    app.unmount()
  })

  it('localizes duplicate check-in errors in English and preserves the trace id', async () => {
    useAppContext().setRegion('EU')
    authMocks.checkInCurrentUser.mockRejectedValue(new Error('今天已经签过到了 [traceId: check-1]'))

    const { app, host } = mount()
    await flushView()
    ;(host.querySelector('[data-testid="check-in-submit"]') as HTMLButtonElement).click()
    await flushView()

    expect(host.textContent).toContain('You already checked in today. [traceId: check-1]')
    expect(host.textContent).not.toContain('今天已经签过到了')
    app.unmount()
  })
})
