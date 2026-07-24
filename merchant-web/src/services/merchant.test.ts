import { beforeEach, describe, expect, it, vi } from 'vitest'

const httpMocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
}))

vi.mock('@/lib/http', () => httpMocks)

import {
  auditRefund,
  createStaff,
  fetchSettlementStatus,
  fetchStaffs,
  registerMerchant,
  submitSettlement,
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
})
