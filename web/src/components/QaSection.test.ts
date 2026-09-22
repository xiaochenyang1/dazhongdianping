import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const appState = vi.hoisted(() => ({ region: 'CN' as 'CN' | 'EU' }))
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state: appState }) }))

const sessionState = vi.hoisted(() => ({ accessToken: 'token-1' as string }))
const sessionMocks = vi.hoisted(() => ({ openAuthDialog: vi.fn() }))
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({ state: sessionState, openAuthDialog: sessionMocks.openAuthDialog }),
}))

const qaMocks = vi.hoisted(() => ({
  fetchQuestions: vi.fn(),
  askQuestion: vi.fn(),
  fetchAnswers: vi.fn(),
  answerQuestion: vi.fn(),
}))
vi.mock('@/services/qa', () => qaMocks)

import QaSection from './QaSection.vue'

async function flush() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount(shopId = 10001) {
  const host = document.createElement('div')
  const app = createApp(QaSection, { shopId })
  app.mount(host)
  return { app, host }
}

describe('QaSection', () => {
  beforeEach(() => {
    Object.values(qaMocks).forEach((m) => m.mockReset())
    sessionMocks.openAuthDialog.mockReset()
    sessionState.accessToken = 'token-1'
    appState.region = 'CN'
    qaMocks.fetchQuestions.mockResolvedValue({
      list: [{ id: 7, shopId: 10001, userId: 9001, userNickname: '阿木', content: '需要预约吗？', answerCount: 1, latestAnswer: '建议预约' }],
      total: 1, page: 1, pageSize: 10, hasMore: false,
    })
    qaMocks.askQuestion.mockResolvedValue({ id: 8 })
    qaMocks.fetchAnswers.mockResolvedValue([{ id: 1, questionId: 7, userId: 9002, userNickname: '客', content: '建议预约' }])
  })

  it('loads questions and posts a new one', async () => {
    const { host } = mount()
    await flush()

    expect(qaMocks.fetchQuestions).toHaveBeenCalledWith(10001)
    expect(host.textContent).toContain('需要预约吗？')

    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="qa-ask-input"]')
    input!.value = '有停车位吗'
    input!.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="qa-ask-submit"]')!.dispatchEvent(new Event('click'))
    await flush()

    expect(qaMocks.askQuestion).toHaveBeenCalledWith(10001, '有停车位吗')
  })

  it('prompts login when asking without a session', async () => {
    sessionState.accessToken = ''
    const { host } = mount()
    await flush()

    const input = host.querySelector<HTMLTextAreaElement>('[data-testid="qa-ask-input"]')
    input!.value = '匿名问题'
    input!.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="qa-ask-submit"]')!.dispatchEvent(new Event('click'))
    await flush()

    expect(sessionMocks.openAuthDialog).toHaveBeenCalled()
    expect(qaMocks.askQuestion).not.toHaveBeenCalled()
  })
})
