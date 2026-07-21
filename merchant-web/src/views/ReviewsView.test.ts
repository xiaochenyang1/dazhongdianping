import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchReviews: vi.fn(),
  saveReply: vi.fn(),
  createAppealDraft: vi.fn(),
  saveAppeal: vi.fn(),
  submitAppeal: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)

import ReviewsView from './ReviewsView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView(permissions = ['shop:view', 'review:reply', 'review:appeal']) {
  const host = document.createElement('div')
  const app = createApp(ReviewsView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('ReviewsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchReviews.mockResolvedValue({
      list: [
        {
          id: 7,
          userName: 'Alice',
          scoreOverall: 4.5,
          content: '味道稳定，服务也不错。',
          merchantReply: { id: 71, content: '感谢支持，欢迎再来。' },
          appeal: { id: 72, status: 1, statusText: '待审核' },
        },
        {
          id: 8,
          userName: 'Bob',
          scoreOverall: 2,
          content: '测试点评内容。',
          merchantReply: null,
          appeal: null,
        },
      ],
      total: 2,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    mocks.saveReply.mockResolvedValue({})
    mocks.createAppealDraft.mockResolvedValue({ id: 80 })
    mocks.saveAppeal.mockResolvedValue({})
    mocks.submitAppeal.mockResolvedValue({})
  })

  it('renders backend review fields and prefills an existing merchant reply', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(host.textContent).toContain('Alice')
    expect(host.textContent).toContain('4.5')
    expect(host.textContent).not.toContain('[object Object]')
    expect(host.querySelector<HTMLTextAreaElement>('[name="reply-7"]')?.value).toBe('感谢支持，欢迎再来。')
    expect(host.querySelector('[data-testid="appeal-actions-7"]')).toBeNull()
    expect(host.textContent).toContain('待审核')
    app.unmount()
  })

  it('submits a new appeal from an eligible review', async () => {
    const { app, host } = mountView()
    await flushView()

    const reason = host.querySelector<HTMLTextAreaElement>('[name="appeal-reason-8"]')
    if (!reason) throw new Error('missing appeal reason')
    reason.value = '该点评描述与当日订单记录明显不符，请复核处理。'
    reason.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="submit-appeal-8"]')?.click()
    await flushView()

    expect(mocks.createAppealDraft).toHaveBeenCalledWith(8)
    expect(mocks.saveAppeal).toHaveBeenCalledWith(80, {
      reason: '该点评描述与当日订单记录明显不符，请复核处理。',
      evidenceUrls: [],
    })
    expect(mocks.submitAppeal).toHaveBeenCalledWith(80)
    app.unmount()
  })

  it('renders reviews without reply or appeal controls when write permissions are absent', async () => {
    const { app, host } = mountView(['shop:view'])
    await flushView()

    expect(host.textContent).toContain('Alice')
    expect(host.textContent).toContain('感谢支持，欢迎再来。')
    expect(host.querySelector('[data-testid="reply-actions-7"]')).toBeNull()
    expect(host.querySelector('[data-testid="appeal-actions-8"]')).toBeNull()
    expect(mocks.saveReply).not.toHaveBeenCalled()
    expect(mocks.createAppealDraft).not.toHaveBeenCalled()
    app.unmount()
  })
})
