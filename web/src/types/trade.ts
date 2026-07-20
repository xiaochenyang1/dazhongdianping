import type { PageResult } from './browse'
export interface DealSummary { id:number;shopId:number;shopName:string;title:string;coverImage:string;price:number;originalPrice:number;currency:string;stock:number;soldCount:number }
export interface DealItem { id:number;dealId:number;name:string;quantity:number;price:number;sort:number }
export interface DealDetail extends DealSummary { items:DealItem[];rules:string;validStart:string;validEnd:string }
export interface Coupon { id:number;orderId:number;code:string;status:number;statusText:string;dealId:number;dealTitle:string;shopId:number;shopName:string;coverImage:string;expireAt:string }
export interface TradeOrder { id:number;orderNo:string;dealId:number;dealTitle:string;shopId:number;shopName:string;coverImage:string;quantity:number;unitPrice:number;amount:number;currency:string;payStatus:number;payStatusText:string;status:number;coupons?:Coupon[] }
export interface PaymentIntent { paymentId:number;channel:string;channelTxn:string;orderNo:string;amount:number;currency:string }
export type OrderPage=PageResult<TradeOrder>;export type CouponPage=PageResult<Coupon>
