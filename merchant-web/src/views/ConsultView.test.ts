import { createApp, nextTick, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchConsultSessions: vi.fn(),
  fetchConsultMessages: vi.fn(),
  sendConsultMessage: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'CN' }))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

import ConsultView from './ConsultView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function session(overrides: Record<string, unknown> = {}) {
  return {
    id: 1, shopId: 10001, shopName: '沪上渝里', userId: 9001, userNickname: '阿木',
    lastMessage: '还有位置吗？', lastMessageAt: null, unread: 1, updatedAt: null, ...overrides,
  }
}

const mounted: App[] = []

function mountView(permissions = ['consult:view', 'consult:reply']) {
  const host = document.createElement('div')
  const app = createApp(ConsultView, { permissions })
  app.mount(host)
  mounted.push(app)
  return { app, host }
}

describe('ConsultView', () => {
  afterEach(() => { mounted.splice(0).forEach((app) => app.unmount()); vi.useRealTimers(); vi.restoreAllMocks() })
  beforeEach(() => {
    vi.useFakeTimers()
    vi.spyOn(document, 'visibilityState', 'get').mockReturnValue('visible')
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionState.region = 'CN'
    mocks.fetchConsultSessions.mockResolvedValue({ list: [session()], hasMore: false, nextBeforeId: null, nextBeforeUpdatedAt: null })
    mocks.fetchConsultMessages.mockResolvedValue({
      session: session({ unread: 0 }),
      messages: [{ id: 1, sessionId: 1, senderType: 1, senderId: 9001, content: '还有位置吗？' }],
    })
    mocks.sendConsultMessage.mockResolvedValue({ id: 2, sessionId: 1, senderType: 2, senderId: 11001, content: '有的' })
  })

  it('opens a session and replies', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchConsultSessions).toHaveBeenCalled()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.dispatchEvent(new Event('click'))
    await flushView()

    expect(mocks.fetchConsultMessages).toHaveBeenCalledWith(1)
    expect(host.textContent).toContain('还有位置吗？')

    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')
    input!.value = '有的'
    input!.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.dispatchEvent(new Event('click'))
    await flushView()

    expect(mocks.sendConsultMessage).toHaveBeenCalledWith(1, '有的')
  })

  it('hides composer without consult:reply', async () => {
    const { host } = mountView(['consult:view'])
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.dispatchEvent(new Event('click'))
    await flushView()
    expect(host.querySelector('[data-testid="consult-send"]')).toBeNull()
  })

  it('receives user messages in the open thread without reopening', async () => {
    const { host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.click()
    await flushView()
    mocks.fetchConsultMessages.mockResolvedValue({ session: session(), messages: [
      { id: 1, senderType: 1, content: '还有位置吗？' }, { id: 3, senderType: 1, content: '我们有三个人' },
    ] })
    await vi.advanceTimersByTimeAsync(3000)
    await flushView()
    expect(host.textContent).toContain('我们有三个人')
    expect(host.querySelectorAll('.messages li')).toHaveLength(2)
  })

  it('guards duplicate sends and preserves failed drafts', async () => {
    const { host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.click()
    await flushView()
    let reject!: (reason: Error) => void
    mocks.sendConsultMessage.mockReturnValue(new Promise((_, fail) => { reject = fail }))
    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!
    input.value = '等您到店'
    input.dispatchEvent(new Event('input'))
    const send = host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!
    send.click(); send.click()
    await flushView()
    expect(mocks.sendConsultMessage).toHaveBeenCalledTimes(1)
    reject(new Error('offline'))
    await flushView()
    expect(input.value).toBe('等您到店')
    expect(send.disabled).toBe(false)
    expect(host.textContent).toContain('offline')
  })

  it('rejects stale messages from the previously selected session', async () => {
    mocks.fetchConsultSessions.mockResolvedValue({ list: [session(), session({ id: 2 })], hasMore: false })
    const { host } = mountView()
    await flushView()
    let resolveOld!: (value: unknown) => void
    mocks.fetchConsultMessages.mockReturnValueOnce(new Promise((resolve) => { resolveOld = resolve }))
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.click()
    await flushView()
    mocks.fetchConsultMessages.mockResolvedValue({ session: session({ id: 2 }),
      messages: [{ id: 4, senderType: 1, content: '第二个会话' }] })
    host.querySelector<HTMLButtonElement>('[data-testid="session-2"]')!.click()
    await flushView()
    resolveOld({ session: session(), messages: [{ id: 1, content: '旧消息' }] })
    await flushView()
    expect(host.textContent).toContain('第二个会话')
    expect(host.textContent).not.toContain('旧消息')
  })

  it('preserves an open thread during polling failures and retries', async () => {
    const { host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.click()
    await flushView()
    mocks.fetchConsultMessages.mockRejectedValue(new Error('offline'))
    await vi.advanceTimersByTimeAsync(3000)
    await flushView()
    expect(host.textContent).toContain('还有位置吗？')
    mocks.fetchConsultMessages.mockResolvedValue({ session: session(), messages: [{ id: 3, senderType: 1, content: '补收回复' }] })
    window.dispatchEvent(new Event('online'))
    await flushView()
    expect(host.textContent).toContain('补收回复')
  })

  it('paginates history, preserves failed history and polls from the read cursor rather than a sent ID', async () => {
    mocks.fetchConsultMessages.mockResolvedValueOnce({ session: session(), messages: [{ id: 4, content: 'latest' }],
      hasMore: true, nextBeforeId: 4, nextAfterId: 4 })
    const { host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.click()
    await flushView()
    mocks.fetchConsultMessages.mockRejectedValueOnce(new Error('history failed'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-load-older"]')!.click()
    await flushView()
    expect(host.textContent).toContain('history failed')
    mocks.fetchConsultMessages.mockResolvedValueOnce({ session: session(), messages: [{ id: 1, content: 'earlier' }],
      hasMore: false, nextBeforeId: 1, nextAfterId: 1 })
    host.querySelector<HTMLButtonElement>('[data-testid="consult-load-older"]')!.click()
    await flushView()
    expect(mocks.fetchConsultMessages).toHaveBeenLastCalledWith(1, { beforeId: 4 })
    expect(host.textContent).toContain('earlier')
    expect(host.querySelector('[data-testid="consult-load-older"]')).toBeNull()
    mocks.sendConsultMessage.mockResolvedValueOnce({ id: 6, content: 'sent reply' })
    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!
    input.value = 'sent reply'; input.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.click()
    await flushView()
    mocks.fetchConsultMessages.mockResolvedValueOnce({ session: session({ unread: 1 }), messages: [{ id: 5, content: 'unseen customer message' }],
      hasMore: true, nextBeforeId: 5, nextAfterId: 5 })
      .mockResolvedValueOnce({ session: session({ unread: 0 }), messages: [{ id: 6, content: 'sent reply' }],
        hasMore: false, nextBeforeId: 6, nextAfterId: 6 })
    await vi.advanceTimersByTimeAsync(3000)
    await flushView()
    expect(mocks.fetchConsultMessages).toHaveBeenCalledWith(1, { afterId: 4 })
    expect(mocks.fetchConsultMessages).toHaveBeenLastCalledWith(1, { afterId: 5 })
    expect(host.textContent).toContain('unseen customer message')
    expect(host.querySelectorAll('.messages li')).toHaveLength(4)
  })

  it('keeps the selected conversation and draft across pages, filtering and background list refresh', async () => {
    mocks.fetchConsultSessions.mockResolvedValueOnce({ list: [session()], hasMore: true, nextBeforeId: 1, nextBeforeUpdatedAt: '2026-11-06T10:00:00' })
    const { host } = mountView(); await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="session-1"]')!.click(); await flushView()
    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!
    input.value = 'Keep this draft'; input.dispatchEvent(new Event('input')); await flushView()
    mocks.fetchConsultSessions.mockResolvedValue({ list: [session({ id: 2 })], hasMore: false })
    host.querySelector<HTMLButtonElement>('[data-testid="sessions-next"]')!.click(); await flushView()
    expect(mocks.fetchConsultSessions).toHaveBeenLastCalledWith({ beforeId: 1, beforeUpdatedAt: '2026-11-06T10:00:00', unreadOnly: false })
    await vi.advanceTimersByTimeAsync(3000); await flushView()
    expect(host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!.value).toBe('Keep this draft')
    expect(host.querySelector('[data-testid="session-1"]')).toBeNull()
    const filter = host.querySelector<HTMLInputElement>('[data-testid="sessions-unread"]')!
    mocks.fetchConsultSessions.mockResolvedValue({ list: [], hasMore: false })
    filter.checked = true; filter.dispatchEvent(new Event('change')); await flushView()
    expect(mocks.fetchConsultSessions).toHaveBeenLastCalledWith({ unreadOnly: true })
    expect(host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!.value).toBe('Keep this draft')
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.click(); await flushView()
    expect(mocks.sendConsultMessage).toHaveBeenCalledWith(1, 'Keep this draft')
  })

  it('ignores a late page after switching the unread filter', async () => {
    let finish!: (value: unknown) => void
    mocks.fetchConsultSessions.mockReturnValueOnce(new Promise(resolve => { finish = resolve }))
    const { host } = mountView(); await flushView()
    mocks.fetchConsultSessions.mockResolvedValue({ list: [session({ id: 2 })], hasMore: false })
    const filter = host.querySelector<HTMLInputElement>('[data-testid="sessions-unread"]')!
    filter.checked = true; filter.dispatchEvent(new Event('change')); await flushView()
    finish({ list: [session()], hasMore: true, nextBeforeId: 1, nextBeforeUpdatedAt: '2026-11-06T10:00:00' }); await flushView()
    expect(host.querySelector('[data-testid="session-1"]')).toBeNull()
    expect(host.querySelector('[data-testid="session-2"]')).not.toBeNull()
  })

})
