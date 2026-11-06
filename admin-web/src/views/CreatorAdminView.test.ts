import { createApp, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { CreatorClaim } from '@/services/creator'

const mocks = vi.hoisted(() => ({ fetchCreatorClaims: vi.fn(), reviewCreatorClaim: vi.fn(), fetchAdminCreatorTasks: vi.fn(), saveAdminCreatorTask: vi.fn() }))
vi.mock('@/services/creator', () => mocks)
vi.mock('@/services/ops', () => mocks)
const state = reactive({ region: 'CN', token: 'token', profile: { id: 1 }, permissions: ['operations:creator:write'] })
vi.mock('@/composables/useAdminSession', () => ({ useAdminSession: () => ({ state }) }))
import CreatorAdminView from './CreatorAdminView.vue'

const mounted: App[] = []
const claim = (id = 5): CreatorClaim => ({ id, taskId: 10, userId: 20, taskTitle: `Task ${id}`, taskDescription: 'Original requirements', rewardPoints: 20, claimStatus: 3, evidenceType: 'review', evidenceId: 81, submissionNote: 'The work is ready', submissionVersion: 2, submittedAt: '2026-11-06T12:00:00', reviewNote: '', reviewedAt: null, completedAt: null, evidenceHash: 'a'.repeat(64), evidence: { id: 81, title: 'My review', content: 'Detailed work to inspect', shopId: 10001, score: 4.5, images: ['https://example.invalid/work.jpg'], createdAt: '2026-11-06T10:00:00', updatedAt: '2026-11-06T11:00:00' } })
const page = (list: unknown[], hasMore = false) => ({ list, hasMore })
async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(CreatorAdminView); mounted.push(app); app.mount(host); return host }
function control<T extends HTMLElement = HTMLButtonElement>(host: HTMLElement, id: string) { return host.querySelector<T>(`[data-testid="${id}"]`)! }
function select(host: HTMLElement, id = 5) { control(host, `creator-claim-${id}`).querySelector<HTMLButtonElement>('button')!.click() }
function note(host: HTMLElement, value: string) { const el = control<HTMLTextAreaElement>(host, 'creator-review-note'); el.value = value; el.dispatchEvent(new Event('input')) }
function approve(host: HTMLElement) { control(host, 'creator-claim-detail').querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true })) }

describe('creator admin review', () => {
  beforeEach(() => {
    Object.values(mocks).forEach(mock => mock.mockReset())
    state.region = 'CN'; state.token = 'token'; state.profile = { id: 1 }; state.permissions = ['operations:creator:write']
    mocks.fetchCreatorClaims.mockResolvedValue(page([claim()]))
    mocks.fetchAdminCreatorTasks.mockResolvedValue(page([{ id: 10, title: 'Configurable task', description: 'Requirements', rewardPoints: 20, status: 1 }]))
  })
  afterEach(() => mounted.splice(0).forEach(app => app.unmount()))

  it('shows original requirements and full work, then approves exactly once with the displayed version and hash', async () => {
    const host = mount(); await flush(); select(host); await flush()
    expect(host.textContent).toContain('Original requirements'); expect(host.textContent).toContain('Detailed work to inspect')
    expect(host.querySelector('img')?.src).toBe('https://example.invalid/work.jpg')
    let complete!: (value: object) => void
    mocks.reviewCreatorClaim.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    note(host, ' Verified '); await flush(); approve(host); approve(host); await flush()
    expect(mocks.reviewCreatorClaim).toHaveBeenCalledTimes(1)
    expect(mocks.reviewCreatorClaim).toHaveBeenCalledWith(5, { approved: true, submissionVersion: 2, evidenceHash: 'a'.repeat(64), note: 'Verified' })
    mocks.fetchCreatorClaims.mockRejectedValueOnce(new Error('refresh offline'))
    complete({ ...claim(), claimStatus: 2, reviewNote: 'Verified' }); await flush()
    expect(host.textContent).toContain('积分已发放')
    expect(host.textContent).toContain('refresh offline')
    expect(control(host, 'creator-approve')).toBeNull()
  })

  it('requires a rejection reason and preserves it when the server reports a stale submission', async () => {
    const host = mount(); await flush(); select(host); await flush()
    control(host, 'creator-reject').click(); await flush()
    expect(mocks.reviewCreatorClaim).not.toHaveBeenCalled()
    expect(host.textContent).toContain('请填写驳回原因')
    note(host, 'Add a menu photo'); await flush()
    mocks.reviewCreatorClaim.mockRejectedValueOnce(new Error('成果已重新提交，请刷新后审核'))
    control(host, 'creator-reject').click(); await flush()
    expect(control<HTMLTextAreaElement>(host, 'creator-review-note').value).toBe('Add a menu photo')
    expect(host.textContent).toContain('请刷新后审核')
    mocks.reviewCreatorClaim.mockResolvedValue({ ...claim(), claimStatus: 4, reviewNote: 'Add a menu photo' })
    mocks.fetchCreatorClaims.mockResolvedValue(page([]))
    control(host, 'creator-reject').click(); await flush()
    expect(mocks.reviewCreatorClaim).toHaveBeenLastCalledWith(5, { approved: false, submissionVersion: 2, evidenceHash: 'a'.repeat(64), note: 'Add a menu photo' })
    expect(host.textContent).toContain('用户可以修改后重新提交')
    expect(control(host, 'creator-approve')).toBeNull()
  })

  it('disables approval for unavailable work and respects read-only permissions', async () => {
    mocks.fetchCreatorClaims.mockResolvedValue(page([{ ...claim(), evidence: null, evidenceHash: null }]))
    const host = mount(); await flush(); select(host); await flush()
    expect(control<HTMLButtonElement>(host, 'creator-approve').disabled).toBe(true)
    approve(host); await flush(); expect(mocks.reviewCreatorClaim).not.toHaveBeenCalled()
    expect(control<HTMLButtonElement>(host, 'creator-reject').disabled).toBe(false)
    state.permissions = []; await flush()
    expect(control(host, 'creator-review-note')).toBeNull()
    control(host, 'creator-tasks-tab').click(); await flush()
    expect(host.textContent).toContain('Configurable task')
    expect(control(host, 'creator-task-form')).toBeNull()
  })

  it('renders only safe web image links from submitted content', async () => {
    const item = claim()
    item.evidence!.images = ['javascript:alert(1)', 'data:text/html,test', 'file:///etc/passwd', 'https://example.invalid/safe.jpg', '/uploads/local.jpg']
    mocks.fetchCreatorClaims.mockResolvedValue(page([item]))
    const host = mount(); await flush(); select(host); await flush()
    const links = [...host.querySelectorAll<HTMLAnchorElement>('.work-images a')]
    expect(links).toHaveLength(2)
    expect(links.every(link => ['http:', 'https:'].includes(new URL(link.href).protocol))).toBe(true)
  })

  it('keeps failed pages retryable and discards responses for old status filters', async () => {
    mocks.fetchCreatorClaims.mockResolvedValueOnce(page([claim()], true))
    const host = mount(); await flush()
    mocks.fetchCreatorClaims.mockRejectedValueOnce(new Error('offline'))
    control(host, 'creator-next').click(); await flush()
    expect(host.textContent).toContain('Task 5')
    let complete!: (value: object) => void
    mocks.fetchCreatorClaims.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    control(host, 'creator-next').click(); await flush()
    expect(mocks.fetchCreatorClaims).toHaveBeenLastCalledWith(2, 3)
    mocks.fetchCreatorClaims.mockResolvedValue(page([]))
    const filter = control<HTMLSelectElement>(host, 'creator-review-filter'); filter.value = '4'; filter.dispatchEvent(new Event('change')); await flush()
    complete(page([claim(6)])); await flush()
    expect(mocks.fetchCreatorClaims).toHaveBeenLastCalledWith(1, 4)
    expect(host.textContent).not.toContain('Task 6')
    expect(control<HTMLButtonElement>(host, 'creator-previous').disabled).toBe(true)
  })

  it.each(['region', 'account', 'token'])('ignores late approval and clears personal data after a %s change', async scope => {
    const host = mount(); await flush(); select(host); await flush(); note(host, 'Private note'); await flush()
    let complete!: (value: object) => void
    mocks.reviewCreatorClaim.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    approve(host); await flush()
    mocks.fetchCreatorClaims.mockResolvedValue(page([]))
    if (scope === 'region') state.region = 'EU'
    if (scope === 'account') state.profile = { id: 2 }
    if (scope === 'token') state.token = 'replacement'
    await flush()
    const requests = mocks.fetchCreatorClaims.mock.calls.length
    complete({ ...claim(), claimStatus: 2 }); await flush()
    expect(mocks.fetchCreatorClaims).toHaveBeenCalledTimes(requests)
    expect(control(host, 'creator-claim-detail')).toBeNull()
    expect(host.textContent).not.toContain('Task 5')
    expect(host.textContent).not.toContain('积分已发放')
  })

  it('validates and saves task configuration while keeping existing claims frozen', async () => {
    const host = mount(); await flush(); control(host, 'creator-tasks-tab').click(); await flush()
    expect(host.textContent).toContain('已领取的要求与奖励保持不变')
    host.querySelector<HTMLButtonElement>('tbody button')!.click(); await flush()
    const form = control<HTMLFormElement>(host, 'creator-task-form')
    const title = form.querySelector<HTMLInputElement>('input:not([type])')!; title.value = ' Updated task '; title.dispatchEvent(new Event('input'))
    const reward = form.querySelector<HTMLInputElement>('input[type="number"]')!; reward.value = '1.5'; reward.dispatchEvent(new Event('input'))
    form.dispatchEvent(new Event('submit', { cancelable: true })); await flush()
    expect(mocks.saveAdminCreatorTask).not.toHaveBeenCalled()
    reward.value = '50'; reward.dispatchEvent(new Event('input'))
    mocks.saveAdminCreatorTask.mockResolvedValue({})
    form.dispatchEvent(new Event('submit', { cancelable: true })); await flush()
    expect(mocks.saveAdminCreatorTask).toHaveBeenCalledWith({ title: 'Updated task', description: 'Requirements', rewardPoints: 50, status: 1 }, 10)
    expect(host.textContent).toContain('任务已保存')
  })
})
