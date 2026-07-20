import { describe, expect, it, vi } from 'vitest'
import { apiGet, apiPost } from '@/lib/http'
import { createOrder, fetchDeal, fetchShopDeals, payOrder } from './trade'
vi.mock('@/lib/http',()=>({apiGet:vi.fn(),apiPost:vi.fn()}))
describe('trade service',()=>{
 it('loads shop deals and deal detail',()=>{fetchShopDeals(10001);expect(apiGet).toHaveBeenCalledWith('/api/c/v1/shops/10001/deals');fetchDeal(40001);expect(apiGet).toHaveBeenCalledWith('/api/c/v1/deals/40001')})
 it('creates and pays order',()=>{createOrder(40001,2);expect(apiPost).toHaveBeenCalledWith('/api/c/v1/orders',{dealId:40001,quantity:2});payOrder(9);expect(apiPost).toHaveBeenCalledWith('/api/c/v1/orders/9/pay')})
})
