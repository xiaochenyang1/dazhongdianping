import { createApp, defineComponent, h, nextTick, ref } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const reviewMocks = vi.hoisted(() => ({
  createReviewComment: vi.fn(),
  fetchOwnedReviewDetail: vi.fn(),
  fetchReviewDetail: vi.fn(),
  listReviewComments: vi.fn(),
  reportComment: vi.fn(),
  reportReview: vi.fn(),
  toggleReviewLike: vi.fn(),
}))
const sessionMocks = vi.hoisted(() => ({
  state: { accessToken: undefined as string | undefined },
  openAuthDialog: vi.fn(),
}))
const routeState = vi.hoisted(() => ({
  fullPath: '/reviews/301',
  query: {} as Record<string, string>,
}))

vi.mock('@/services/review', () => reviewMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => sessionMocks,
}))
vi.mock('vue-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('vue-router')>()
  return {
    ...actual,
    useRoute: () => routeState,
  }
})

import ReviewDetailView from './ReviewDetailView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('ReviewDetailView', () => {
  beforeEach(() => {
    Object.values(reviewMocks).forEach((mock) => mock.mockReset())
    sessionMocks.state.accessToken = undefined
    sessionMocks.openAuthDialog.mockReset()
    routeState.fullPath = '/reviews/301'
    routeState.query = {}
    localStorage.clear()
    useAppContext().setRegion('EU')
  })

  it('renders a GBP review cost from the response currency', async () => {
    reviewMocks.fetchReviewDetail.mockResolvedValue({
      id: 301,
      shopId: 30001,
      shopName: 'London Kitchen',
      userId: 0,
      userName: 'Guest',
      authorCertification: { code: 'verified_merchant', label: '认证商户' },
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
      status: 0,
      statusText: 'Hidden',
      tags: [],
      images: [],
      createdAt: '2026-07-10 12:00',
      updatedAt: '2026-07-10 12:00',
    })

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 301 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(reviewMocks.fetchReviewDetail).toHaveBeenCalledWith(301)
    expect(host.textContent).toContain('£42.00 GBP')
    expect(host.textContent).toContain('Public review')
    expect(host.textContent).toContain('Overall rating')
    expect(host.textContent).toContain('10/07/2026 12:00')
    expect(host.textContent).toContain('Verified merchant')
    expect(host.textContent).not.toContain('认证商户')
    expect(host.textContent).not.toContain('¥42.00')
    expect(host.textContent).not.toContain('€42.00')
    app.unmount()
  })

  it('shares a public review with the native share contract', async () => {
    reviewMocks.fetchReviewDetail.mockResolvedValue({
      id: 301,
      shopId: 20001,
      shopName: 'London Dumplings',
      userId: 9,
      userName: 'Aya',
      content: 'Soup was clean and hot.',
      scoreOverall: 4.5,
      scoreTaste: 4.6,
      scoreEnv: 4.3,
      scoreService: 4.4,
      cost: 42,
      currency: 'GBP',
      likeCount: 2,
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
    })
    const share = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'share', { configurable: true, value: share })

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 301 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="share-review"]')?.click()
    await flushView()

    expect(share).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'London Dumplings review by Aya',
        url: expect.any(String),
      }),
    )
    expect(host.querySelector('[data-testid="share-review-message"]')?.textContent).toContain(
      'Share link is ready',
    )
    app.unmount()
    Reflect.deleteProperty(navigator, 'share')
  })

  it('shows owned audit result banner from notification query', async () => {
    routeState.fullPath = '/user/reviews/55?audit=approved'
    routeState.query = { audit: 'approved' }
    reviewMocks.fetchOwnedReviewDetail.mockResolvedValue({
      id: 55,
      shopId: 10001,
      shopName: '沪上渝里',
      userId: 9,
      userName: '我',
      content: '很好吃',
      scoreOverall: 4.8,
      scoreTaste: 5,
      scoreEnv: 4.5,
      scoreService: 4.8,
      cost: 128,
      currency: 'CNY',
      likeCount: 0,
      commentCount: 0,
      likedByCurrentUser: false,
      auditStatus: 1,
      auditStatusText: '已通过',
      auditRemark: '',
      status: 1,
      statusText: '公开',
      tags: [],
      images: [],
      createdAt: '2026-07-25 10:00',
      updatedAt: '2026-07-25 10:00',
    })

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 55, owned: true })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(reviewMocks.fetchOwnedReviewDetail).toHaveBeenCalledWith(55)
    expect(host.querySelector('[data-testid="review-audit-banner"]')?.textContent).toContain(
      'Your review was approved',
    )
    expect(host.textContent).toContain('Moderation statusApproved')
    expect(host.textContent).not.toContain('已通过')
    app.unmount()
  })

  it('shows owned hidden banner when merchant appeal succeeds', async () => {
    routeState.fullPath = '/user/reviews/66?hidden=appeal'
    routeState.query = { hidden: 'appeal' }
    reviewMocks.fetchOwnedReviewDetail.mockResolvedValue({
      id: 66,
      shopId: 20001,
      shopName: '巴黎川菜馆',
      userId: 9,
      userName: '我',
      content: '被隐藏的点评',
      scoreOverall: 2.0,
      scoreTaste: 2,
      scoreEnv: 2,
      scoreService: 2,
      cost: 36,
      currency: 'EUR',
      likeCount: 0,
      commentCount: 0,
      likedByCurrentUser: false,
      auditStatus: 2,
      auditStatusText: '已驳回',
      auditRemark: '商户申诉通过：申诉成立',
      status: 1,
      statusText: '公开',
      tags: [],
      images: [],
      createdAt: '2026-07-25 10:00',
      updatedAt: '2026-07-25 14:00',
    })

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 66, owned: true })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.querySelector('[data-testid="review-hidden-banner"]')?.textContent).toContain(
      'merchant appeal was accepted',
    )
    app.unmount()
  })

  it('reports a review comment and localizes duplicate-report errors in English', async () => {
    sessionMocks.state.accessToken = 'token'
    reviewMocks.fetchReviewDetail.mockResolvedValue({
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
      commentCount: 2,
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
    })
    reviewMocks.listReviewComments.mockResolvedValue({
      list: [
        {
          id: 501,
          reviewId: 301,
          userId: 88,
          userName: 'Commenter',
          content: 'Looks spammy',
          mine: false,
          createdAt: '2026-07-11 09:00',
          replies: [
            {
              id: 502,
              reviewId: 301,
              userId: 10,
              userName: 'Me',
              content: 'My own reply',
              mine: true,
              createdAt: '2026-07-11 09:05',
              replies: [],
            },
          ],
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    reviewMocks.reportComment
      .mockResolvedValueOnce({
        id: 1,
        reviewId: 301,
        commentId: 501,
        reason: 'Spam advertising',
        status: 0,
        statusText: 'Pending',
        createdAt: '2026-07-12 10:00',
      })
      .mockRejectedValueOnce(new Error('你已经举报过这条评论了 [traceId: cmt-rpt-1]'))

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 301 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.querySelector('[data-testid="comment-report-501"]')).toBeTruthy()
    expect(host.querySelector('[data-testid="comment-report-502"]')).toBeNull()

    ;(host.querySelector('[data-testid="comment-report-501"]') as HTMLButtonElement).click()
    await flushView()

    const reasonInput = host.querySelector('[data-testid="comment-report-reason-501"]') as HTMLTextAreaElement
    expect(reasonInput).toBeTruthy()
    reasonInput.value = 'Spam advertising'
    reasonInput.dispatchEvent(new Event('input'))
    ;(host.querySelector('[data-testid="comment-report-submit-501"]') as HTMLButtonElement).click()
    await flushView()

    expect(reviewMocks.reportComment).toHaveBeenCalledWith(301, 501, { reason: 'Spam advertising' })
    expect(host.textContent).toContain('Comment report submitted for moderation.')

    ;(host.querySelector('[data-testid="comment-report-501"]') as HTMLButtonElement).click()
    await flushView()
    const secondReason = host.querySelector('[data-testid="comment-report-reason-501"]') as HTMLTextAreaElement
    secondReason.value = 'Still spam'
    secondReason.dispatchEvent(new Event('input'))
    ;(host.querySelector('[data-testid="comment-report-submit-501"]') as HTMLButtonElement).click()
    await flushView()

    expect(host.textContent).toContain('You have already reported this comment')
    expect(host.textContent).toContain('[traceId: cmt-rpt-1]')
    expect(host.textContent).not.toContain('你已经举报过这条评论了')
    app.unmount()
  })

  it('does not duplicate a comment already returned by a concurrent reload after login', async () => {
    const createdComment = {
      id: 901,
      reviewId: 301,
      userId: 10,
      userName: 'Test User',
      content: 'Only render this once',
      mine: true,
      createdAt: '2026-07-20 10:00',
    }
    reviewMocks.fetchReviewDetail.mockResolvedValue({
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
      commentCount: 1,
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
    })
    reviewMocks.listReviewComments.mockResolvedValue({
      list: [createdComment],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    reviewMocks.createReviewComment.mockResolvedValue(createdComment)

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 301 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    const textarea = host.querySelector('textarea') as HTMLTextAreaElement
    textarea.value = createdComment.content
    textarea.dispatchEvent(new Event('input'))
    ;(host.querySelector('.comment-composer button') as HTMLButtonElement).click()
    await flushView()

    const afterLogin = sessionMocks.openAuthDialog.mock.calls[0]?.[0]?.afterLogin
    expect(afterLogin).toBeTypeOf('function')
    sessionMocks.state.accessToken = 'test-token'
    await afterLogin()
    await flushView()

    expect(reviewMocks.createReviewComment).toHaveBeenCalledTimes(1)
    expect(host.querySelectorAll('.comment-card')).toHaveLength(1)
    app.unmount()
  })

  it('publishes a canonical Review JSON-LD document for an approved public review', async () => {
    reviewMocks.fetchReviewDetail.mockResolvedValue({
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
      likeCount: 2,
      commentCount: 1,
      likedByCurrentUser: false,
      auditStatus: 1,
      auditStatusText: 'Approved',
      auditRemark: '',
      status: 1,
      statusText: 'Public',
      tags: ['brunch'],
      images: [],
      createdAt: '2026-07-10 12:00',
      updatedAt: '2026-07-10 12:00',
    })
    reviewMocks.listReviewComments.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 20, hasMore: false })

    const host = document.createElement('div')
    const app = createApp(ReviewDetailView, { reviewId: 301 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('2 likes · 1 comment')
    const canonical = document.head.querySelector('link[rel="canonical"]')
    expect(canonical?.getAttribute('href')).toBe(`${window.location.origin}/reviews/301`)
    const schema = JSON.parse(document.head.querySelector('script[type="application/ld+json"]')?.textContent ?? '{}')
    expect(schema).toMatchObject({
      '@type': 'Review',
      url: canonical?.getAttribute('href'),
      reviewBody: 'Solid meal',
      author: { '@type': 'Person', name: 'Reviewer' },
      reviewRating: { '@type': 'Rating', ratingValue: 4.5, bestRating: 5 },
    })
    app.unmount()
  })

  it('clears a reused review route and ignores stale detail responses', async () => {
    const pending = new Map<number, (value: any) => void>()
    reviewMocks.fetchReviewDetail.mockImplementation((id: number) => new Promise((resolve) => pending.set(id, resolve)))
    const detail = (id: number, shopName: string) => ({
      id,
      shopId: 30000 + id,
      shopName,
      userId: 20,
      userName: 'Reviewer',
      content: `${shopName} review`,
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
      status: 0,
      statusText: 'Hidden',
      tags: [],
      images: [],
      createdAt: '2026-07-10 12:00',
      updatedAt: '2026-07-10 12:00',
    })
    const reviewId = ref(301)
    const Root = defineComponent({ setup: () => () => h(ReviewDetailView, { reviewId: reviewId.value }) })
    const host = document.createElement('div')
    const app = createApp(Root)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    pending.get(301)?.(detail(301, 'Old review shop'))
    await flushView()
    expect(host.textContent).toContain('Old review shop')

    reviewId.value = 302
    await nextTick()
    expect(document.title).not.toContain('Old review shop')
    reviewId.value = 303
    await nextTick()

    pending.get(303)?.(detail(303, 'Newest review shop'))
    await flushView()
    pending.get(302)?.(detail(302, 'Stale review shop'))
    await flushView()

    expect(host.textContent).toContain('Newest review shop')
    expect(host.textContent).not.toContain('Stale review shop')
    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href'))
      .toBe(`${window.location.origin}/reviews/303`)
    app.unmount()
  })
})
