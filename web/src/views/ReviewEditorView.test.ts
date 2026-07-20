import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  fetchShopDetail: vi.fn(),
}))
const fileMocks = vi.hoisted(() => ({
  uploadImage: vi.fn(),
}))
const reviewMocks = vi.hoisted(() => ({
  createReview: vi.fn(),
  fetchOwnedReviewDetail: vi.fn(),
  updateReview: vi.fn(),
}))
const routerMocks = vi.hoisted(() => ({
  push: vi.fn(),
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/services/file', () => fileMocks)
vi.mock('@/services/review', () => reviewMocks)
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: { region: 'CN' } }),
}))
vi.mock('vue-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('vue-router')>()
  return {
    ...actual,
    useRouter: () => ({ push: routerMocks.push }),
  }
})

import ReviewEditorView from './ReviewEditorView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('ReviewEditorView', () => {
  beforeEach(() => {
    Object.values(browseMocks).forEach((mock) => mock.mockReset())
    Object.values(fileMocks).forEach((mock) => mock.mockReset())
    Object.values(reviewMocks).forEach((mock) => mock.mockReset())
    Object.values(routerMocks).forEach((mock) => mock.mockReset())
  })

  it('submits the GBP currency returned by the shop detail response', async () => {
    browseMocks.fetchShopDetail.mockResolvedValue({
      id: 30001,
      name: 'London Kitchen',
      cityName: 'London',
      areaName: 'Soho',
      coverUrl: '/shop.jpg',
      summary: 'British dining',
      currency: 'GBP',
    })
    reviewMocks.createReview.mockResolvedValue({ id: 701 })
    routerMocks.push.mockResolvedValue(undefined)

    const host = document.createElement('div')
    const app = createApp(ReviewEditorView, { shopId: 30001 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    const selects = Array.from(host.querySelectorAll('select'))
    const currencySelect = selects[selects.length - 1] as HTMLSelectElement
    expect(currencySelect.value).toBe('GBP')

    const form = host.querySelector('form')
    expect(form).not.toBeNull()
    form?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flushView()

    expect(reviewMocks.createReview).toHaveBeenCalledWith(
      expect.objectContaining({
        shopId: 30001,
        currency: 'GBP',
      }),
    )
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reviews/701')
    app.unmount()
  })
})
