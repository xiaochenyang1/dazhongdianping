import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const reviewMocks = vi.hoisted(() => ({
  listUserReviews: vi.fn(),
  deleteReview: vi.fn(),
}))

vi.mock('@/services/review', () => reviewMocks)

import MyReviewsView from './MyReviewsView.vue'

const RouterLinkStub = defineComponent({ props: ['to'], template: '<a><slot /></a>' })

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function result() {
  return {
    list: [{
      id: 71,
      shopId: 9,
      shopName: 'Berlin Cafe',
      content: 'A quiet place to work.',
      scoreOverall: 4.5,
      auditStatus: 0,
      auditStatusText: '待审',
      auditRemark: '',
      tags: ['coffee'],
      createdAt: '2026-07-20 09:30:00',
    }],
    total: 1,
    page: 1,
    pageSize: 10,
    hasMore: false,
  }
}

describe('MyReviewsView', () => {
  beforeEach(() => {
    reviewMocks.listUserReviews.mockReset().mockResolvedValue(result())
    reviewMocks.deleteReview.mockReset().mockResolvedValue(undefined)
    useAppContext().setRegion('CN')
  })

  it('localizes moderation status and reloads reviews for EU', async () => {
    useAppContext().setRegion('EU')
    const host = document.createElement('div')
    const app = createApp(MyReviewsView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('My reviews')
    expect(host.textContent).toContain('Pending')
    expect(host.textContent).toContain('Created 20/07/2026 09:30')
    expect(host.textContent).not.toContain('待审')

    useAppContext().setRegion('CN')
    await flushView()
    expect(reviewMocks.listUserReviews).toHaveBeenCalledTimes(2)
    app.unmount()
  })
})
