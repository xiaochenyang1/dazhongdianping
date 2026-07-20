import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const reviewMocks = vi.hoisted(() => ({
  createReviewComment: vi.fn(),
  fetchOwnedReviewDetail: vi.fn(),
  fetchReviewDetail: vi.fn(),
  listReviewComments: vi.fn(),
  reportReview: vi.fn(),
  toggleReviewLike: vi.fn(),
}))

vi.mock('@/services/review', () => reviewMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({
    state: { accessToken: undefined },
    openAuthDialog: vi.fn(),
  }),
}))
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

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('ReviewDetailView', () => {
  beforeEach(() => {
    Object.values(reviewMocks).forEach((mock) => mock.mockReset())
  })

  it('renders a GBP review cost from the response currency', async () => {
    reviewMocks.fetchReviewDetail.mockResolvedValue({
      id: 301,
      shopId: 30001,
      shopName: 'London Kitchen',
      userId: 0,
      userName: 'Guest',
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
    expect(host.textContent).not.toContain('¥42.00')
    expect(host.textContent).not.toContain('€42.00')
    app.unmount()
  })
})
