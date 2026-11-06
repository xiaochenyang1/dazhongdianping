import { createApp, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { CreatorTask } from '@/types/creator'

const mocks = vi.hoisted(() => ({ fetchCreatorTasks: vi.fn(), claimCreatorTask: vi.fn(), fetchCreatorEvidence: vi.fn(), submitCreatorTask: vi.fn() }))
vi.mock('@/services/creator', () => mocks)
const state = reactive({ region: 'EU' })
const session = reactive({ currentUser: { id: 1 }, accessToken: 'token' })
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state }) }))
vi.mock('@/composables/useUserSession', () => ({ useUserSession: () => ({ state: session }) }))
import CreatorTasksView from './CreatorTasksView.vue'

const mounted: App[] = []
const task = (claimStatus = 1, id = 10): CreatorTask => ({ id, title: `Task ${id}`, description: 'Publish a detailed review', rewardPoints: 20, status: 1, claimStatus })
const page = (list: unknown[], hasMore = false) => ({ list, hasMore })
async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(CreatorTasksView); mounted.push(app); app.mount(host); return host }
function control<T extends HTMLElement = HTMLButtonElement>(host: HTMLElement, id: string) { return host.querySelector<T>(`[data-testid="${id}"]`)! }
function open(host: HTMLElement, id = 10) { control(host, `creator-task-${id}`).querySelector<HTMLButtonElement>('button')!.click() }
function choose(host: HTMLElement, id = 81) { const select = control<HTMLSelectElement>(host, 'evidence-select'); select.value = String(id); select.dispatchEvent(new Event('change')) }
function note(host: HTMLElement, text: string) { const el = control<HTMLTextAreaElement>(host, 'submission-note'); el.value = text; el.dispatchEvent(new Event('input')) }
function submit(host: HTMLElement) { host.querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true })) }

describe('creator task submission', () => {
  beforeEach(() => {
    Object.values(mocks).forEach(mock => mock.mockReset())
    state.region = 'EU'; session.currentUser = { id: 1 }; session.accessToken = 'token'
    mocks.fetchCreatorTasks.mockResolvedValue(page([task()]))
    mocks.fetchCreatorEvidence.mockResolvedValue(page([{ id: 81, title: 'My published review' }]))
  })
  afterEach(() => mounted.splice(0).forEach(app => app.unmount()))

  it('claims, submits selected published work once and displays pending without a self-award action', async () => {
    mocks.fetchCreatorTasks.mockResolvedValueOnce(page([task(0)]))
    mocks.claimCreatorTask.mockResolvedValue({ taskId: 10, claimId: 5, claimStatus: 1 })
    const host = mount(); await flush()
    open(host); await flush()
    expect(mocks.claimCreatorTask).toHaveBeenCalledWith(10)
    open(host); await flush(); choose(host); note(host, 'Photo and menu included'); await flush()
    let complete!: (value: object) => void
    mocks.submitCreatorTask.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    submit(host); submit(host); await flush()
    expect(mocks.submitCreatorTask).toHaveBeenCalledTimes(1)
    expect(mocks.submitCreatorTask).toHaveBeenCalledWith(10, { evidenceType: 'review', evidenceId: 81, note: 'Photo and menu included' })
    mocks.fetchCreatorTasks.mockRejectedValueOnce(new Error('refresh offline'))
    complete({ taskId: 10, claimId: 5, claimStatus: 3 }); await flush()
    expect(host.textContent).toContain('Awaiting review')
    expect(control(host, 'creator-task-10').querySelector('button')).toBeNull()
    expect(host.querySelector('form')).toBeNull()
    expect(host.textContent).toContain('refresh offline')
  })

  it('retains the work selection and resubmission note after an unsuccessful submission', async () => {
    mocks.fetchCreatorTasks.mockResolvedValue(page([{ ...task(4), evidenceType: 'post', submissionNote: 'Original explanation', reviewNote: 'Add menu photo' }]))
    mocks.fetchCreatorEvidence.mockResolvedValue(page([{ id: 81, title: 'My post' }]))
    const host = mount(); await flush(); open(host); await flush()
    expect(host.textContent).toContain('Add menu photo')
    expect(mocks.fetchCreatorEvidence).toHaveBeenCalledWith('post', 1)
    expect(control<HTMLTextAreaElement>(host, 'submission-note').value).toBe('Original explanation')
    choose(host); note(host, 'Menu photo added'); await flush()
    mocks.submitCreatorTask.mockRejectedValueOnce(new Error('submission offline'))
    submit(host); await flush()
    expect(host.textContent).toContain('submission offline')
    expect(control<HTMLSelectElement>(host, 'evidence-select').value).toBe('81')
    expect(control<HTMLTextAreaElement>(host, 'submission-note').value).toBe('Menu photo added')
    mocks.submitCreatorTask.mockResolvedValue({ claimStatus: 3 })
    mocks.fetchCreatorTasks.mockResolvedValue(page([task(3)]))
    submit(host); await flush()
    expect(host.textContent).toContain('Awaiting review')
  })

  it('retries the failed evidence page without losing selection or duplicating work', async () => {
    mocks.fetchCreatorEvidence.mockResolvedValueOnce(page([{ id: 81, title: 'First work' }], true))
    const host = mount(); await flush(); open(host); await flush(); choose(host)
    mocks.fetchCreatorEvidence.mockRejectedValueOnce(new Error('page offline'))
    control(host, 'evidence-more').click(); await flush()
    expect(control<HTMLSelectElement>(host, 'evidence-select').value).toBe('81')
    mocks.fetchCreatorEvidence.mockResolvedValueOnce(page([{ id: 81, title: 'First work' }, { id: 82, title: 'Older work' }]))
    control(host, 'evidence-retry').click(); await flush()
    expect(mocks.fetchCreatorEvidence).toHaveBeenLastCalledWith('review', 2)
    expect(host.querySelectorAll('[data-testid="evidence-select"] option')).toHaveLength(3)
    expect(control<HTMLSelectElement>(host, 'evidence-select').value).toBe('81')
  })

  it('ignores late evidence for another type and requires a fresh selection', async () => {
    let complete!: (value: object) => void
    mocks.fetchCreatorEvidence.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    const host = mount(); await flush(); open(host); await flush()
    const select = control<HTMLSelectElement>(host, 'evidence-type'); select.value = 'post'; select.dispatchEvent(new Event('change')); await flush()
    complete(page([{ id: 90, title: 'Stale review' }])); await flush()
    expect(host.textContent).not.toContain('Stale review')
    expect(control<HTMLButtonElement>(host, 'submit-work').disabled).toBe(true)
    submit(host); await flush(); expect(mocks.submitCreatorTask).not.toHaveBeenCalled()
  })

  it.each(['region', 'account', 'token'])('discards pending submissions and private form data after a %s change', async scope => {
    const host = mount(); await flush(); open(host); await flush(); choose(host); note(host, 'Private draft'); await flush()
    let complete!: (value: object) => void
    mocks.submitCreatorTask.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    submit(host); await flush()
    mocks.fetchCreatorTasks.mockResolvedValue(page([]))
    if (scope === 'region') state.region = 'CN'
    if (scope === 'account') session.currentUser = { id: 2 }
    if (scope === 'token') session.accessToken = 'replacement'
    await flush()
    const requests = mocks.fetchCreatorTasks.mock.calls.length
    complete({ claimStatus: 3 }); await flush()
    expect(mocks.fetchCreatorTasks).toHaveBeenCalledTimes(requests)
    expect(host.textContent).not.toContain('Task 10')
    expect(host.querySelector('textarea')).toBeNull()
  })

  it('keeps failed task pages retryable and ignores old lists after changing region', async () => {
    mocks.fetchCreatorTasks.mockResolvedValueOnce(page([task(2)], true))
    const host = mount(); await flush()
    expect(host.textContent).toContain('Points awarded')
    expect(control(host, 'creator-task-10').querySelector('button')).toBeNull()
    mocks.fetchCreatorTasks.mockRejectedValueOnce(new Error('list offline'))
    control(host, 'creator-next').click(); await flush()
    expect(host.textContent).toContain('Task 10')
    let complete!: (value: object) => void
    mocks.fetchCreatorTasks.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    control(host, 'creator-next').click(); await flush()
    expect(mocks.fetchCreatorTasks).toHaveBeenLastCalledWith(2)
    mocks.fetchCreatorTasks.mockResolvedValue(page([])); state.region = 'CN'; await flush()
    complete(page([task(3, 20)])); await flush()
    expect(host.textContent).toContain('暂时没有任务')
    expect(host.textContent).not.toContain('Task 20')
    expect(control<HTMLButtonElement>(host, 'creator-previous').disabled).toBe(true)
  })
})
