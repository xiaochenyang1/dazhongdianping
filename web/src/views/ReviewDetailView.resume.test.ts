import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useUserSession } from '@/composables/useUserSession'

const reviewMocks = vi.hoisted(() => ({
  createReviewComment: vi.fn(),
  fetchOwnedReviewDetail: vi.fn(),
  fetchReviewDetail: vi.fn(),
  listReviewComments: vi.fn(),
  reportReview: vi.fn(),
  toggleReviewLike: vi.fn(),
}))

vi.mock('@/services/review', () => reviewMocks)
vi.mock('vue-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('vue-router')>()
  return {
    ...actual,
    useRoute: () => ({ fullPath: '/reviews/301' }),
  }
})

import ReviewDetailView from './ReviewDetailView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((resolver) => {
    resolve = resolver
  })
  return { promise, resolve }
}

function approvedReviewDetail() {
  return {
    id: 301,
    shopId: 30001,
    shopName: 'London Kitchen',
    userId: 20,
    userName: 'Reviewer',
    content: 'Solid meal',
    scoreOverall: 4.5,
    scoreTaste: 4.5,
    scoreEnv: 4,
    scoreService: 4.5,
    cost: 42,
    currency: 'GBP',
    likeCount: 0,
    commentCount: 0,
    likedByCurrentUser: false,
    auditStatus: 1,
    auditStatusText: 'Approved',
    auditRemark: '',
    status: 1,
    statusText: 'Public',
    tags: [],
    images: [],
    createdAt: '2026-07-10 12:00',
    updatedAt: '2026-07-10 12:00',
  }
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('ReviewDetailView guest resume actions', () => {
  beforeEach(() => {
    Object.values(reviewMocks).forEach((mock) => mock.mockReset())
    localStorage.clear()
    const session = useUserSession()
    session.clearSession()
    session.closeAuthDialog()
  })

  it('replays a queued like after login even if the auth watcher reloads the review first', async () => {
    const reloadingDetail = deferred<ReturnType<typeof approvedReviewDetail>>()

    reviewMocks.fetchReviewDetail
      .mockResolvedValueOnce(approvedReviewDetail())
      .mockImplementationOnce(() => reloadingDetail.promise)
      .mockResolvedValueOnce(approvedReviewDetail())
    reviewMocks.listReviewComments.mockResolvedValue({
      list: [],
      total: 0,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    reviewMocks.toggleReviewLike.mockResolvedValue({
      liked: true,
      likeCount: 1,
    })

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 301 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    const likeButton = host.querySelector('.interaction-toolbar .primary-button') as HTMLButtonElement
    likeButton.click()
    await flushView()

    const session = useUserSession()
    const pendingAction = session.consumePendingAuthAction()
    expect(pendingAction).toBeTypeOf('function')

    session.state.accessToken = 'resumed-token'
    await nextTick()
    await pendingAction?.()
    await flushView()

    reloadingDetail.resolve(approvedReviewDetail())
    await flushView()

    expect(reviewMocks.toggleReviewLike).toHaveBeenCalledWith(301)
    expect(host.textContent).toContain('这次点赞真落下去了。')
    app.unmount()
  })
})
