import { apiGet, apiPost } from '@/lib/http'
import type { CouponPage, DealDetail, DealSummary, OrderPage, PaymentIntent, TradeOrder } from '@/types/trade'
export function fetchShopDeals(shopId:number){return apiGet<DealSummary[]>(`/api/c/v1/shops/${shopId}/deals`)}
export function fetchDeal(dealId:number){return apiGet<DealDetail>(`/api/c/v1/deals/${dealId}`)}
export function createOrder(dealId:number,quantity:number){return apiPost<TradeOrder>('/api/c/v1/orders',{dealId,quantity})}
export function fetchOrders(payStatus?:number,page=1,pageSize=20){return apiGet<OrderPage>('/api/c/v1/orders',{payStatus,page,pageSize})}
export function fetchOrder(id:number){return apiGet<TradeOrder>(`/api/c/v1/orders/${id}`)}
export function payOrder(id:number){return apiPost<PaymentIntent>(`/api/c/v1/orders/${id}/pay`)}
export function completeMockPayment(id:number){return apiPost<TradeOrder>(`/api/c/v1/orders/${id}/pay/mock-complete`)}
export function cancelOrder(id:number){return apiPost<TradeOrder>(`/api/c/v1/orders/${id}/cancel`)}
export function refundOrder(id:number,reason:string){return apiPost<TradeOrder>(`/api/c/v1/orders/${id}/refund`,{reason})}
export function fetchCoupons(status?:number,page=1,pageSize=20){return apiGet<CouponPage>('/api/c/v1/coupons',{status,page,pageSize})}
