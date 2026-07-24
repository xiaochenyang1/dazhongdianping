import { beforeEach, describe, expect, it, vi } from 'vitest'

const httpMocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
}))

vi.mock('@/lib/http', () => httpMocks)

import {
  auditRefund,
  createDeal,
  createNewShopDraft,
  createStaff,
  createUpdateShopDraft,
  fetchDeal,
  fetchSettlementStatus,
  fetchShopChange,
  fetchShopChanges,
  fetchStaffs,
  registerMerchant,
  saveShopChange,
  saveShopChangeDishes,
  saveShopChangePhotos,
  submitSettlement,
  submitShopChange,
  updateDeal,
  updateStaffStatus,
  verifyCoupon,
} from './merchant'

describe('merchant identity services', () => {
  beforeEach(() => {
    Object.values(httpMocks).forEach((mock) => mock.mockReset())
  })

  it('uses the merchant registration and settlement contracts', async () => {
    const registration = {
      account: 'owner@example.com',
      password: 'Merchant#123456',
      companyName: 'North Star Foods',
      contactName: 'Alice',
      contactPhone: '+33123456789',
      region: 'EU' as const,
    }
    const settlement = {
      licenseUrl: 'https://files.example/license.png',
      legalPerson: 'Alice',
      shopPhotoUrls: ['https://files.example/shop.png'],
    }

    await registerMerchant(registration)
    await fetchSettlementStatus()
    await submitSettlement(settlement)

    expect(httpMocks.apiPost).toHaveBeenNthCalledWith(1, '/api/b/v1/auth/register', registration)
    expect(httpMocks.apiGet).toHaveBeenCalledWith('/api/b/v1/settle/status')
    expect(httpMocks.apiPost).toHaveBeenNthCalledWith(2, '/api/b/v1/settle/apply', settlement)
  })

  it('uses the merchant staff contracts', async () => {
    const staff = {
      account: 'staff@example.com',
      password: 'Staff#123456',
      name: 'Front Desk',
      phone: '+33111111111',
      email: 'staff@example.com',
      roleIds: [12],
      shopScopeType: 2 as const,
      shopIds: [20001],
    }

    await fetchStaffs({ page: 1, pageSize: 20 })
    await createStaff(staff)
    await updateStaffStatus(9, 2)

    expect(httpMocks.apiGet).toHaveBeenCalledWith('/api/b/v1/staffs', { page: 1, pageSize: 20 })
    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/staffs', staff)
    expect(httpMocks.apiPut).toHaveBeenCalledWith('/api/b/v1/staffs/9/status', { status: 2 })
  })

  it('uses the backend refund audit decision contract', async () => {
    await auditRefund(88, 'approve', '订单与退款申请已核对')

    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/orders/88/refund-audit', {
      decision: 'approve',
      reason: '订单与退款申请已核对',
    })
  })

  it('uses the backend coupon verify contract', async () => {
    await verifyCoupon(' VERIFYME001 ')

    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/coupons/VERIFYME001/verify')
  })

  it('uses the backend deal create/update/detail contracts', async () => {
    const payload = {
      shopId: 20001,
      type: 1,
      title: '双人套餐',
      coverImage: 'https://files.example/deal.jpg',
      price: 49.9,
      originalPrice: 68,
      currency: 'EUR',
      stock: 20,
      validStart: '2026-07-01',
      validEnd: '2026-12-31',
      rules: '周末通用',
      items: [{ name: '主菜', quantity: 1, price: 30, sort: 1 }],
    }

    await createDeal(payload)
    await updateDeal(501, payload)
    await fetchDeal(501)

    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/deals', payload)
    expect(httpMocks.apiPut).toHaveBeenCalledWith('/api/b/v1/deals/501', payload)
    expect(httpMocks.apiGet).toHaveBeenCalledWith('/api/b/v1/deals/501')
  })

  it('uses the backend shop-change draft contracts', async () => {
    const payload = {
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
    }
    const photos = [{ imageUrl: 'https://files.example/new-cover.jpg', photoType: 1, sort: 1 }]
    const dishes = [{ name: '水煮鱼', price: 28, recommendReason: '招牌', sort: 1 }]

    await createNewShopDraft()
    await createUpdateShopDraft(20001)
    await fetchShopChanges({ page: 1, pageSize: 20 })
    await fetchShopChange(9001)
    await saveShopChange(9001, payload)
    await saveShopChangePhotos(9001, photos)
    await saveShopChangeDishes(9001, dishes)
    await submitShopChange(9001)

    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/shops/change-drafts')
    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/shops/20001/change-drafts')
    expect(httpMocks.apiGet).toHaveBeenCalledWith('/api/b/v1/shop-changes', { page: 1, pageSize: 20 })
    expect(httpMocks.apiGet).toHaveBeenCalledWith('/api/b/v1/shop-changes/9001')
    expect(httpMocks.apiPut).toHaveBeenCalledWith('/api/b/v1/shop-changes/9001', payload)
    expect(httpMocks.apiPut).toHaveBeenCalledWith('/api/b/v1/shop-changes/9001/photos', { photos })
    expect(httpMocks.apiPut).toHaveBeenCalledWith('/api/b/v1/shop-changes/9001/dishes', { dishes })
    expect(httpMocks.apiPost).toHaveBeenCalledWith('/api/b/v1/shop-changes/9001/submit')
  })
})
