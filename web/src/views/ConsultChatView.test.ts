import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

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

function mount(props: Record<string, unknown>) {
  const host = document.createElement('div')
  const app = createApp(ConsultChatView, props)
  app.mount(host)
  return { app, host }
}

describe('ConsultChatView', () => {
  beforeEach(() => {
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
})
