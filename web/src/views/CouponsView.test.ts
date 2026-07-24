import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const tradeMocks = vi.hoisted(() => ({
  fetchCoupons: vi.fn(),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string | string[] | undefined>,
}))

const routerMocks = vi.hoisted(() => ({
  replace: vi.fn(),
}))

vi.mock('@/services/trade', () => tradeMocks)
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  useRouter: () => routerMocks,
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path" v-bind="$attrs"><slot /></a>',
  },
}))

import CouponsView from './CouponsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(CouponsView)
  app.mount(host)
  return { app, host }
}

describe('CouponsView', () => {
  beforeEach(() => {
    tradeMocks.fetchCoupons.mockReset()
    routerMocks.replace.mockReset()
    routeState.query = {}
    tradeMocks.fetchCoupons.mockResolvedValue({
      list: [
        {
          id: 11,
          orderId: 1,
          code: 'CPABC123',
          status: 1,
          statusText: '待使用',
          dealId: 40001,
          dealTitle: '双人套餐',
          shopId: 10001,
          shopName: '测试火锅',
          coverImage: 'https://example.com/cover.jpg',
          expireAt: '2026-08-01',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
  })

  it('loads coupons and highlights the code from query', async () => {
    routeState.query = { status: '1', code: 'CPABC123' }
    const { app, host } = mount()
    await flush()

    expect(tradeMocks.fetchCoupons).toHaveBeenCalledWith(1, 1, 50)
    expect(host.textContent).toContain('双人套餐')
    expect(host.textContent).toContain('CPABC123')
    expect(host.textContent).toContain('定位券码 CPABC123')
    expect(host.textContent).toContain('查看二维码与使用规则')
    const card = host.querySelector('[data-testid="coupon-card-CPABC123"]') as HTMLAnchorElement | null
    expect(card?.className).toContain('is-highlight')
    expect(card?.getAttribute('href')).toBe('/user/coupons/CPABC123')
    app.unmount()
  })

  it('switches status filter via router query', async () => {
    const { app, host } = mount()
    await flush()

    const expiredTab = host.querySelector('[data-testid="coupon-tab-3"]') as HTMLButtonElement | null
    expect(expiredTab).not.toBeNull()
    expiredTab?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flush()

    expect(routerMocks.replace).toHaveBeenCalledWith({
      path: '/user/coupons',
      query: { status: '3' },
    })
    app.unmount()
  })
})
