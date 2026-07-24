import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchShops: vi.fn(),
  fetchShopChanges: vi.fn(),
  fetchShopChange: vi.fn(),
  fetchCategories: vi.fn(),
  fetchCities: vi.fn(),
  fetchAreas: vi.fn(),
  createNewShopDraft: vi.fn(),
  createUpdateShopDraft: vi.fn(),
  saveShopChange: vi.fn(),
  saveShopChangePhotos: vi.fn(),
  saveShopChangeDishes: vi.fn(),
  submitShopChange: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: { region: 'EU', token: 'token', account: 'owner@example.com' } }),
}))

import ShopsView from './ShopsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount(permissions = ['shop:edit', 'shop:view']) {
  const host = document.createElement('div')
  const app = createApp(ShopsView, { permissions })
  const vm = app.mount(host) as any
  return { app, host, vm }
}

const draftDetail = {
  id: 9001,
  changeType: 2,
  targetShopId: 20001,
  categoryId: 201,
  cityId: 101,
  areaId: 1011,
  name: 'Maison Sichuan Draft',
  coverUrl: 'https://files.example/new-cover.jpg',
  phone: '+33142345678',
  pricePerCapita: 42,
  currency: 'EUR',
  address: '18 Rue du Temple, Paris',
  latitude: 48.8566,
  longitude: 2.3522,
  businessHours: '11:30-22:30',
  summary: '新版门店资料',
  openNow: true,
  tags: ['Chinese', 'Spicy'],
  status: 0,
  statusText: '草稿',
  photos: [{ imageUrl: 'https://files.example/new-cover.jpg', photoType: 1, sort: 1 }],
  dishes: [{ name: '水煮鱼', price: 28, recommendReason: '招牌', sort: 1 }],
}

describe('ShopsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchShops.mockResolvedValue({
      list: [{ id: 20001, name: 'Maison Sichuan Paris', region: 'EU', cityName: 'Paris', score: 4.6, statusText: '营业中' }],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
    mocks.fetchShopChanges.mockResolvedValue({
      list: [{ id: 9001, changeType: 2, targetShopId: 20001, name: 'Maison Sichuan Draft', status: 0, statusText: '草稿' }],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
    mocks.fetchCategories.mockResolvedValue([{ id: 200, name: 'Dining', children: [{ id: 201, name: 'Chinese', children: [] }] }])
    mocks.fetchCities.mockResolvedValue([{ id: 101, name: 'Paris', code: 'PAR' }])
    mocks.fetchAreas.mockResolvedValue([{ id: 1011, name: 'Le Marais', cityId: 101 }])
    mocks.createUpdateShopDraft.mockResolvedValue(draftDetail)
    mocks.fetchShopChange.mockResolvedValue(draftDetail)
    mocks.saveShopChange.mockResolvedValue(draftDetail)
    mocks.saveShopChangePhotos.mockResolvedValue(draftDetail)
    mocks.saveShopChangeDishes.mockResolvedValue(draftDetail)
    mocks.submitShopChange.mockResolvedValue({ ...draftDetail, status: 1, statusText: '待审核' })
  })

  it('creates an update draft from a live shop and submits after saving', async () => {
    const { app, host, vm } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="shop-draft-from-20001"]')?.click()
    await flush()

    expect(mocks.createUpdateShopDraft).toHaveBeenCalledWith(20001)
    expect(host.textContent).toContain('编辑草稿 #9001')

    vm.form.name = 'Maison Sichuan Updated'
    vm.form.summary = '更新后的门店简介'
    await nextTick()

    await vm.submit()
    await flush()

    expect(mocks.saveShopChange).toHaveBeenCalledWith(
      9001,
      expect.objectContaining({
        name: 'Maison Sichuan Updated',
        summary: '更新后的门店简介',
        categoryId: 201,
        cityId: 101,
        areaId: 1011,
      }),
    )
    expect(mocks.saveShopChangePhotos).toHaveBeenCalledWith(9001, [
      { imageUrl: 'https://files.example/new-cover.jpg', photoType: 1, sort: 1 },
    ])
    expect(mocks.saveShopChangeDishes).toHaveBeenCalledWith(9001, [
      { name: '水煮鱼', price: 28, recommendReason: '招牌', sort: 1 },
    ])
    expect(mocks.submitShopChange).toHaveBeenCalledWith(9001)
    expect(host.textContent).toContain('门店变更已提交审核')
    app.unmount()
  })

  it('opens existing draft from draft list', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="shop-draft-open-9001"]')?.click()
    await flush()

    expect(mocks.fetchShopChange).toHaveBeenCalledWith(9001)
    expect(host.querySelector('[data-testid="shop-draft-editor"]')).not.toBeNull()
    app.unmount()
  })
})
