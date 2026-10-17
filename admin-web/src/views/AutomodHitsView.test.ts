import { createApp, nextTick, reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { AdminAuditTask, PageResult } from '@/types/admin'

const mocks = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[]; profile: { id: number } },
  listAuditTasks: vi.fn(),
  getModerationQueueMetrics: vi.fn(),
  fetchAutomodHits: vi.fn(),
  claimAuditTask: vi.fn(),
  releaseAuditTask: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))
vi.mock('@/composables/useAdminSession', () => ({ useAdminSession: () => ({ state: mocks.state }) }))
vi.mock('@/services/admin', () => mocks)
vi.mock('@/services/ops', () => ({ fetchAutomodHits: mocks.fetchAutomodHits }))

import AutomodHitsView from './AutomodHitsView.vue'

const apps: ReturnType<typeof createApp>[] = []
const metric = {
  bizType: 10, bizTypeText: '点评评论', pendingCount: 1, overdueCount: 1, slaMinutes: 1,
  oldestPendingAt: '2026-10-13 08:00:00', processedCount: 0, averageProcessingSeconds: null,
  oldestPendingAgeSeconds: 0,
}
function page(summary = '待复核评论'): PageResult<AdminAuditTask> {
  return {
    list: [{
      id: 101, bizId: 201, bizType: 10, bizTypeText: '点评评论', region: 'CN', status: 0,
      statusText: '待审', shopId: null, shopName: '', submittedBy: '用户', summary, remark: '',
      claimedByAdminId: 1, claimedByAdminName: '审核员', claimedAt: '2026-10-13 08:00:00',
      claimExpiresAt: '2026-10-13 08:00:02', createdAt: '2026-10-13 08:00:00', updatedAt: '2026-10-13 08:00:00',
      claimRemainingSeconds: 2, ageSeconds: 0,
    }], total: 1, page: 1, pageSize: 20, hasMore: false,
  }
}
function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason: Error) => void
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no })
  return { promise, resolve, reject }
}
async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}
function mount() {
  const host = document.createElement('div')
  const app = createApp(AutomodHitsView)
  app.mount(host)
  apps.push(app)
  return host
}
function button(host: HTMLElement, text: string) {
  return [...host.querySelectorAll('button')].find((item) => item.textContent === text)
}

describe('AutomodHitsView', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date', 'performance', 'setTimeout', 'clearTimeout', 'setInterval', 'clearInterval'] })
    // Deliberately unrelated to server timestamps: countdowns must use elapsed seconds.
    vi.setSystemTime(new Date('2030-01-01T00:00:00Z'))
    for (const mock of [mocks.listAuditTasks, mocks.getModerationQueueMetrics, mocks.fetchAutomodHits,
      mocks.claimAuditTask, mocks.releaseAuditTask, mocks.passAuditTask, mocks.rejectAuditTask]) mock.mockReset()
    mocks.state = reactive({ region: 'CN', permissions: ['audit:automod:read', 'audit:automod:write'], profile: { id: 1 } })
    mocks.listAuditTasks.mockResolvedValue(page())
    mocks.getModerationQueueMetrics.mockResolvedValue([metric])
    mocks.fetchAutomodHits.mockResolvedValue({ list: [] })
  })
  afterEach(() => {
    apps.splice(0).forEach((app) => app.unmount())
    vi.useRealTimers()
  })

  it('expires the claim and advances the SLA clock even when queue refresh fails', async () => {
    const host = mount()
    await flush()
    expect(host.textContent).toContain('剩余 1分')
    expect(button(host, '通过并公开')).toBeDefined()

    vi.setSystemTime(new Date('2020-01-01T00:00:00Z'))
    await vi.advanceTimersByTimeAsync(2_000)
    expect(button(host, '通过并公开')).toBeUndefined()
    expect(host.textContent).toContain('已过期')

    mocks.listAuditTasks.mockRejectedValue(new Error('暂时断网'))
    await vi.advanceTimersByTimeAsync(59_000)
    expect(host.textContent).toContain('已超时 1秒')
    expect(host.textContent).toContain('暂时断网')
    expect(button(host, '通过并公开')).toBeUndefined()
  })

  it('does not extend a claim lease while waiting for a slow queue response', async () => {
    const slowQueue = deferred<PageResult<AdminAuditTask>>()
    mocks.listAuditTasks.mockReturnValueOnce(slowQueue.promise)
    const host = mount()
    await vi.advanceTimersByTimeAsync(3_000)
    slowQueue.resolve(page())
    await flush()
    expect(host.textContent).toContain('已过期')
    expect(host.textContent).toContain('剩余 57秒')
    expect(button(host, '通过并公开')).toBeUndefined()
  })

  it('loads the new region immediately and ignores the old region response', async () => {
    const oldRegion = deferred<PageResult<AdminAuditTask>>()
    mocks.listAuditTasks.mockReturnValueOnce(oldRegion.promise).mockResolvedValueOnce(page('EU 内容'))
    const host = mount()
    await flush()
    mocks.state.region = 'EU'
    await flush()
    await flush()
    expect(mocks.listAuditTasks).toHaveBeenLastCalledWith(expect.objectContaining({ region: 'EU' }))
    expect(host.textContent).toContain('EU 内容')
    oldRegion.resolve(page('CN 旧内容'))
    await flush()
    expect(host.textContent).not.toContain('CN 旧内容')
    expect(host.textContent).toContain('EU 内容')
  })

  it('keeps the newest filter result when an older request fails', async () => {
    const oldFilter = deferred<PageResult<AdminAuditTask>>()
    mocks.listAuditTasks.mockReturnValueOnce(oldFilter.promise).mockResolvedValueOnce(page('帖子评论结果'))
    const host = mount()
    await flush()
    const type = host.querySelector('select')!
    type.value = '11'
    type.dispatchEvent(new Event('change'))
    await flush()
    expect(mocks.listAuditTasks).toHaveBeenLastCalledWith(expect.objectContaining({ bizType: 11 }))
    oldFilter.reject(new Error('旧筛选失败'))
    await flush()
    expect(host.textContent).toContain('帖子评论结果')
    expect(host.textContent).not.toContain('旧筛选失败')
  })

  it('keeps owner filtering when opening the overdue queue across content types', async () => {
    const host = mount()
    await flush()
    const owner = host.querySelectorAll('select')[1]!
    owner.value = 'mine'
    owner.dispatchEvent(new Event('change'))
    await flush()
    button(host, '查看超时队列')!.click()
    await flush()
    expect(mocks.listAuditTasks).toHaveBeenLastCalledWith(expect.objectContaining({
      bizType: undefined, overdueOnly: true, assignmentFilter: 'mine', page: 1,
    }))
  })
})
