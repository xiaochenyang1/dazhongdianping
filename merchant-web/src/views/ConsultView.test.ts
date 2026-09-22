import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

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

function mountView(permissions = ['consult:view', 'consult:reply']) {
  const host = document.createElement('div')
  const app = createApp(ConsultView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('ConsultView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionState.region = 'CN'
    mocks.fetchConsultSessions.mockResolvedValue([session()])
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
})
