import { createApp, h, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const appState = vi.hoisted(() => ({ region: 'CN' as 'CN' | 'EU' }))
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: appState }),
}))

const consultMocks = vi.hoisted(() => ({
  startConsult: vi.fn(),
  fetchConsultSessions: vi.fn(),
  fetchConsultThread: vi.fn(),
  sendConsultMessage: vi.fn(),
}))
vi.mock('@/services/consult', () => consultMocks)

vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a><slot /></a>' },
}))

import ConsultChatView from './ConsultChatView.vue'

async function flush() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

const mounted: App[] = []

function mount(initial: Record<string, unknown>) {
  const props = reactive(initial)
  const host = document.createElement('div')
  const app = createApp({ render: () => h(ConsultChatView, props as { sessionId: number }) })
  mounted.push(app)
  app.mount(host)
  return { app, host, props }
}

describe('ConsultChatView', () => {
  afterEach(() => { mounted.splice(0).forEach((app) => app.unmount()); vi.useRealTimers(); vi.restoreAllMocks() })
  beforeEach(() => {
    vi.useFakeTimers()
    vi.spyOn(document, 'visibilityState', 'get').mockReturnValue('visible')
    Object.values(consultMocks).forEach((m) => m.mockReset())
    appState.region = 'CN'
    consultMocks.fetchConsultThread.mockResolvedValue({
      session: { id: 5, shopId: 10001, shopName: '沪上渝里', userId: 9001, userNickname: '阿木', lastMessage: '你好', unread: 0 },
      messages: [{ id: 1, sessionId: 5, senderType: 2, senderId: 11001, content: '欢迎咨询' }],
    })
    consultMocks.sendConsultMessage.mockResolvedValue({ id: 2, sessionId: 5, senderType: 1, senderId: 9001, content: '有位置吗' })
  })

  it('loads the thread and sends a message', async () => {
    const { host } = mount({ sessionId: 5 })
    await flush()

    expect(consultMocks.fetchConsultThread).toHaveBeenCalledWith(5)
    expect(host.textContent).toContain('欢迎咨询')

    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')
    input!.value = '有位置吗'
    input!.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.dispatchEvent(new Event('click'))
    await flush()

    expect(consultMocks.sendConsultMessage).toHaveBeenCalledWith(5, '有位置吗')
    expect(host.textContent).toContain('有位置吗')
  })

  it('receives remote replies without navigation and deduplicates sent messages', async () => {
    const { host } = mount({ sessionId: 5 })
    await flush()
    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!
    input.value = '有位置吗'
    input.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.click()
    await flush()
    consultMocks.fetchConsultThread.mockResolvedValue({
      session: { id: 5, shopName: '沪上渝里' },
      messages: [{ id: 1, senderType: 2, content: '欢迎咨询' },
        { id: 2, senderType: 1, content: '有位置吗' }, { id: 3, senderType: 2, content: '还有一桌' }],
    })
    await vi.advanceTimersByTimeAsync(3000)
    await flush()
    expect(host.textContent).toContain('还有一桌')
    expect(host.querySelectorAll('.chat-messages li')).toHaveLength(3)
  })

  it('keeps messages and the draft after failures and catches up when online', async () => {
    const { host } = mount({ sessionId: 5 })
    await flush()
    consultMocks.sendConsultMessage.mockRejectedValue(new Error('send offline'))
    consultMocks.fetchConsultThread.mockRejectedValue(new Error('poll offline'))
    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!
    input.value = '保留草稿'
    input.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.click()
    await flush()
    await vi.advanceTimersByTimeAsync(3000)
    expect(input.value).toBe('保留草稿')
    expect(host.textContent).toContain('欢迎咨询')
    expect(host.textContent).toContain('send offline')
    consultMocks.fetchConsultThread.mockResolvedValue({ session: { id: 5, shopName: '沪上渝里' },
      messages: [{ id: 3, senderType: 2, content: '网络恢复后补收' }] })
    window.dispatchEvent(new Event('online'))
    await flush()
    expect(host.textContent).toContain('网络恢复后补收')
    expect(input.value).toBe('保留草稿')
  })

  it('ignores a late response from a different conversation', async () => {
    let resolveOld!: (value: unknown) => void
    consultMocks.fetchConsultThread.mockReturnValueOnce(new Promise((resolve) => { resolveOld = resolve }))
    const { host, props } = mount({ sessionId: 5 })
    await flush()
    consultMocks.fetchConsultThread.mockResolvedValue({ session: { id: 6, shopName: '另一家店' },
      messages: [{ id: 6, senderType: 2, content: '新会话消息' }] })
    props.sessionId = 6
    await flush()
    resolveOld({ session: { id: 5, shopName: '旧店' }, messages: [{ id: 1, content: '过时消息' }] })
    await flush()
    expect(host.textContent).toContain('新会话消息')
    expect(host.textContent).not.toContain('过时消息')
  })

  it('pauses hidden polling and removes timers on unmount', async () => {
    const { app } = mount({ sessionId: 5 })
    await flush()
    const calls = consultMocks.fetchConsultThread.mock.calls.length
    vi.spyOn(document, 'visibilityState', 'get').mockReturnValue('hidden')
    await vi.advanceTimersByTimeAsync(9000)
    expect(consultMocks.fetchConsultThread).toHaveBeenCalledTimes(calls)
    vi.spyOn(document, 'visibilityState', 'get').mockReturnValue('visible')
    document.dispatchEvent(new Event('visibilitychange'))
    await flush()
    expect(consultMocks.fetchConsultThread).toHaveBeenCalledTimes(calls + 1)
    app.unmount()
    mounted.splice(mounted.indexOf(app), 1)
    expect(vi.getTimerCount()).toBe(0)
  })

  it('loads older pages independently and never skips an unseen reply when sending', async () => {
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 5, shopName: '店铺' },
      messages: [{ id: 3, content: 'third' }, { id: 4, content: 'fourth' }],
      hasMore: true, nextBeforeId: 3, nextAfterId: 4 })
    const { host } = mount({ sessionId: 5 })
    await flush()
    const older = () => host.querySelector<HTMLButtonElement>('[data-testid="consult-load-older"]')!
    consultMocks.fetchConsultThread.mockRejectedValueOnce(new Error('history offline'))
    older().click()
    await flush()
    expect(host.textContent).toContain('history offline')
    expect(host.textContent).toContain('fourth')
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 5 },
      messages: [{ id: 1, content: 'first' }, { id: 2, content: 'second' }],
      hasMore: false, nextBeforeId: 1, nextAfterId: 2 })
    older().click()
    await flush()
    expect(consultMocks.fetchConsultThread).toHaveBeenLastCalledWith(5, { beforeId: 3 })
    expect(host.querySelector('[data-testid="consult-load-older"]')).toBeNull()
    expect([...host.querySelectorAll('.chat-messages .text')].map(el => el.textContent)).toEqual(['first', 'second', 'third', 'fourth'])
    consultMocks.sendConsultMessage.mockResolvedValueOnce({ id: 6, content: 'sent' })
    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="consult-input"]')!
    input.value = 'sent'; input.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-send"]')!.click()
    await flush()
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 5 },
      messages: [{ id: 5, content: 'unseen reply' }, { id: 6, content: 'sent' }],
      hasMore: false, nextBeforeId: 5, nextAfterId: 6 })
    await vi.advanceTimersByTimeAsync(3000)
    await flush()
    expect(consultMocks.fetchConsultThread).toHaveBeenLastCalledWith(5, { afterId: 4 })
    expect(host.textContent).toContain('unseen reply')
    expect(host.querySelectorAll('.chat-messages li')).toHaveLength(6)
  })

  it('drains multiple incremental pages and retains the last successful cursor after failure', async () => {
    const { host } = mount({ sessionId: 5 })
    await flush()
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 5 },
      messages: [{ id: 2, content: 'batch one' }], hasMore: true, nextBeforeId: 2, nextAfterId: 2 })
      .mockRejectedValueOnce(new Error('catch-up interrupted'))
    await vi.advanceTimersByTimeAsync(3000)
    await flush()
    expect(consultMocks.fetchConsultThread).toHaveBeenLastCalledWith(5, { afterId: 2 })
    expect(host.textContent).toContain('batch one')
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 5 },
      messages: [{ id: 3, content: 'batch two' }], hasMore: false, nextBeforeId: 3, nextAfterId: 3 })
    window.dispatchEvent(new Event('online'))
    await flush()
    expect(consultMocks.fetchConsultThread).toHaveBeenLastCalledWith(5, { afterId: 2 })
    expect(host.textContent).toContain('batch two')
  })

  it('ignores a historical page returned after switching conversations', async () => {
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 5 },
      messages: [{ id: 4, content: 'fourth' }], hasMore: true, nextBeforeId: 4, nextAfterId: 4 })
    const { host, props } = mount({ sessionId: 5 })
    await flush()
    let finish!: (value: unknown) => void
    consultMocks.fetchConsultThread.mockReturnValueOnce(new Promise(resolve => { finish = resolve }))
    host.querySelector<HTMLButtonElement>('[data-testid="consult-load-older"]')!.click()
    await flush()
    consultMocks.fetchConsultThread.mockResolvedValueOnce({ session: { id: 6 },
      messages: [{ id: 10, content: 'new conversation' }], hasMore: false, nextBeforeId: 10, nextAfterId: 10 })
    props.sessionId = 6
    await flush()
    finish({ session: { id: 5 }, messages: [{ id: 1, content: 'old history' }], hasMore: true, nextBeforeId: 1, nextAfterId: 1 })
    await flush()
    expect(host.textContent).toContain('new conversation')
    expect(host.textContent).not.toContain('old history')
    expect(host.querySelector('[data-testid="consult-load-older"]')).toBeNull()
  })

})
