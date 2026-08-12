import type { Region } from '@/types/browse'
import type { WebLocaleTag } from '@/core/web_localizations'

type StatusLabel = (status?: number, fallback?: string) => string

export interface WebTradeStrings {
  tag: WebLocaleTag
  common: {
    notAvailable: string
    processing: string
    remaining: (count: number) => string
    people: (count: number) => string
  }
  statuses: {
    all: string
    pay: StatusLabel
    coupon: StatusLabel
    reservation: StatusLabel
    refund: StatusLabel
    confirmMode: StatusLabel
    timelineAction: StatusLabel
    operator: StatusLabel
    timelineRemark: (actionType: number, remark?: string) => string
  }
  deal: {
    loadFailed: string
    createOrderFailed: string
    loading: string
    sold: (count: number) => string
    offerPrice: string
    originalPrice: string
    validUntil: string
    quantity: string
    buyNow: string
  }
  reservationCreate: {
    slotLoadFailed: string
    submitFailed: string
    selectSlotFirst: string
    eyebrow: string
    title: string
    date: string
    people: string
    searchSlots: string
    contactName: string
    contactPhone: string
    phonePlaceholder: string
    remark: string
    remarkPlaceholder: string
    submit: string
  }
  orders: {
    loadFailed: string
    cancelFailed: string
    refundFailed: string
    cancelSuccess: (orderNo: string) => string
    refundSuccess: (orderNo: string) => string
    refundPrompt: string
    refundDefaultReason: string
    eyebrow: string
    title: string
    currentFilter: (status: string) => string
    loading: string
    empty: string
    quantity: (count: number) => string
    orderNo: (value: string) => string
    viewDetails: string
    cancel: string
    refund: string
  }
  orderDetail: {
    loadFailed: string
    paymentFailed: string
    mockPaymentFailed: string
    cancelFailed: string
    refundFailed: string
    refundApproved: string
    refundRejected: string
    mockPaymentSuccess: string
    cancelConfirm: string
    cancelSuccess: string
    refundPrompt: string
    refundDefaultReason: string
    refundSuccess: string
    order: string
    title: string
    back: string
    loading: string
    startPayment: string
    completeMockPayment: (channel: string) => string
    stripePayment: string
    stripePaymentFailed: string
    stripeProcessing: string
    stripeReceived: string
    refreshOrder: string
    cancel: string
    requestRefund: string
    refundProgress: string
    amount: string
    reason: string
    auditNote: string
    requestedAt: string
    auditedAt: string
    vouchers: string
    voucherHint: string
  }
  coupons: {
    loadFailed: string
    eyebrow: string
    title: string
    currentFilter: (status: string) => string
    highlightedCode: (code: string) => string
    loading: string
    empty: string
    expiresAt: string
    noExpiry: string
    viewDetails: string
  }
  couponDetail: {
    loadFailed: string
    copyFailed: string
    usable: string
    unusable: string
    eyebrow: string
    back: string
    loading: string
    qrAlt: (code: string) => string
    verifyHint: (backendHint?: string) => string
    code: string
    copied: string
    copyCode: string
    viewOrder: string
    viewPlace: string
    status: string
    expiresAt: string
    noExpiry: string
    offerValidity: string
    redeemedAt: string
    rules: string
    noRules: string
  }
  reservations: {
    loadFailed: string
    eyebrow: string
    title: string
    currentFilter: (status: string) => string
    loading: string
    empty: string
    reservationNo: (value: string) => string
  }
  reservationDetail: {
    loadFailed: string
    cancelFailed: string
    slotLoadFailed: string
    rescheduleFailed: string
    confirmedBanner: string
    arrivedBanner: string
    rejectedBanner: string
    noShowBanner: string
    cancelSuccess: string
    rescheduleSuccess: string
    rescheduleReason: string
    reservation: string
    loading: string
    cancel: string
    findSlots: string
    timeline: string
  }
  errorTranslations: Record<string, string>
}

const HAN_TEXT = /\p{Script=Han}/u

function enumLabel(
  labels: Record<number, string>,
  status: number | undefined,
  fallback: string | undefined,
  unknown: string,
  allowHanFallback: boolean,
) {
  if (status != null && labels[status]) return labels[status]
  const value = fallback?.trim()
  if (value && (allowHanFallback || !HAN_TEXT.test(value))) return value
  return unknown
}

function createStatusLabels(
  labels: {
    pay: Record<number, string>
    coupon: Record<number, string>
    reservation: Record<number, string>
    refund: Record<number, string>
    confirmMode: Record<number, string>
    timelineAction: Record<number, string>
    operator: Record<number, string>
  },
  unknown: string,
  allowHanFallback: boolean,
) {
  const get = (values: Record<number, string>): StatusLabel => (status, fallback) =>
    enumLabel(values, status, fallback, unknown, allowHanFallback)
  return {
    pay: get(labels.pay),
    coupon: get(labels.coupon),
    reservation: get(labels.reservation),
    refund: get(labels.refund),
    confirmMode: get(labels.confirmMode),
    timelineAction: get(labels.timelineAction),
    operator: get(labels.operator),
  }
}

const zhStatuses = createStatusLabels({
  pay: { 0: '待支付', 1: '已支付', 2: '已退款', 3: '部分退款' },
  coupon: { 1: '待使用', 2: '已使用', 3: '已过期', 4: '已退款' },
  reservation: { 0: '待确认', 1: '已确认', 2: '已到店', 3: '用户取消', 4: '商户拒绝', 5: '爽约' },
  refund: { 0: '申请中', 1: '退款成功', 2: '已驳回' },
  confirmMode: { 1: '自动确认', 2: '人工确认' },
  timelineAction: { 1: '创建预订', 2: '商户确认', 3: '商户拒绝', 4: '用户取消', 5: '用户改期', 6: '商户改期', 7: '确认到店', 8: '标记爽约', 9: '到店提醒' },
  operator: { 1: '用户', 2: '商户', 3: '系统' },
}, '未知状态', true)

const enStatuses = createStatusLabels({
  pay: { 0: 'Pending payment', 1: 'Paid', 2: 'Refunded', 3: 'Partially refunded' },
  coupon: { 1: 'Available', 2: 'Used', 3: 'Expired', 4: 'Refunded' },
  reservation: { 0: 'Pending confirmation', 1: 'Confirmed', 2: 'Arrived', 3: 'Cancelled by customer', 4: 'Rejected by the place', 5: 'No-show' },
  refund: { 0: 'Pending', 1: 'Refunded', 2: 'Rejected' },
  confirmMode: { 1: 'Instant confirmation', 2: 'Manual confirmation' },
  timelineAction: { 1: 'Booking created', 2: 'Confirmed by place', 3: 'Rejected by place', 4: 'Cancelled by customer', 5: 'Rescheduled by customer', 6: 'Rescheduled by place', 7: 'Arrival confirmed', 8: 'Marked as no-show', 9: 'Arrival reminder' },
  operator: { 1: 'Customer', 2: 'Place', 3: 'System' },
}, 'Unknown status', false)

const knownTimelineRemarks: Record<string, string> = {
  '创建预订': 'Booking created',
  '商户确认': 'Confirmed by place',
  '商户拒绝': 'Rejected by place',
  '用户取消': 'Cancelled by customer',
  '用户在线改期': 'Rescheduled online by customer',
  '用户改期': 'Rescheduled by customer',
  '商户改期': 'Rescheduled by place',
  '确认到店': 'Arrival confirmed',
  '标记爽约': 'Marked as no-show',
  '到店提醒': 'Arrival reminder',
}

const zhCnStrings: WebTradeStrings = {
  tag: 'zh-CN',
  common: {
    notAvailable: '—',
    processing: '处理中...',
    remaining: (count) => `余 ${count}`,
    people: (count) => `${count} 人`,
  },
  statuses: {
    all: '全部',
    ...zhStatuses,
    timelineRemark: (_actionType, remark) => remark?.trim() || '—',
  },
  deal: {
    loadFailed: '团购加载失败',
    createOrderFailed: '下单失败',
    loading: '团购加载中...',
    sold: (count) => `已售 ${count}`,
    offerPrice: '团购价',
    originalPrice: '原价',
    validUntil: '有效期',
    quantity: '购买数量',
    buyNow: '立即购买',
  },
  reservationCreate: {
    slotLoadFailed: '时段加载失败',
    submitFailed: '预订提交失败',
    selectSlotFirst: '先选一个可订时段。',
    eyebrow: '在线预订',
    title: '先看真实余量，再提交联系人信息。',
    date: '日期',
    people: '人数',
    searchSlots: '查询时段',
    contactName: '联系人',
    contactPhone: '联系电话',
    phonePlaceholder: '+8613812345678',
    remark: '备注',
    remarkPlaceholder: '靠窗 / 包厢',
    submit: '提交预订',
  },
  orders: {
    loadFailed: '订单加载失败',
    cancelFailed: '取消订单失败',
    refundFailed: '申请退款失败',
    cancelSuccess: (orderNo) => `订单 ${orderNo} 已取消`,
    refundSuccess: (orderNo) => `订单 ${orderNo} 已提交退款申请`,
    refundPrompt: '退款原因',
    refundDefaultReason: '行程有变',
    eyebrow: '我的订单',
    title: '支付状态和订单状态分开看，账才不会乱。',
    currentFilter: (status) => `当前筛选：${status}`,
    loading: '订单加载中...',
    empty: '当前筛选下暂无订单。',
    quantity: (count) => `数量 ${count}`,
    orderNo: (value) => `订单号 ${value}`,
    viewDetails: '查看详情',
    cancel: '取消',
    refund: '退款',
  },
  orderDetail: {
    loadFailed: '订单加载失败',
    paymentFailed: '支付发起失败',
    mockPaymentFailed: '模拟支付失败',
    cancelFailed: '取消失败',
    refundFailed: '退款申请失败',
    refundApproved: '退款已通过，订单状态已更新。',
    refundRejected: '退款已驳回，可查看审核说明。',
    mockPaymentSuccess: '模拟支付成功，券码已生成。',
    cancelConfirm: '确认取消这张未支付订单？',
    cancelSuccess: '订单已取消。',
    refundPrompt: '退款原因',
    refundDefaultReason: '行程有变',
    refundSuccess: '退款申请已提交，等待商户或平台处理。',
    order: '订单',
    title: '订单详情',
    back: '返回订单列表',
    loading: '订单加载中...',
    startPayment: '发起支付',
    completeMockPayment: (channel) => `模拟 ${channel} 支付成功`,
    stripePayment: '使用银行卡支付',
    stripePaymentFailed: '银行卡支付失败',
    stripeProcessing: '正在确认支付结果...',
    stripeReceived: '支付已收到，订单确认中，请稍后刷新。',
    refreshOrder: '刷新订单',
    cancel: '取消订单',
    requestRefund: '申请退款',
    refundProgress: '退款进度',
    amount: '金额',
    reason: '申请原因',
    auditNote: '审核说明',
    requestedAt: '申请时间',
    auditedAt: '审核时间',
    vouchers: '券码',
    voucherHint: '点击券码可查看核销二维码与使用规则。',
  },
  coupons: {
    loadFailed: '券加载失败',
    eyebrow: '我的券',
    title: '每张券独立核销，退款、过期和到期提醒也各算各的。',
    currentFilter: (status) => `当前筛选：${status}`,
    highlightedCode: (code) => `定位券码 ${code}`,
    loading: '券码加载中...',
    empty: '当前筛选下暂无券码。',
    expiresAt: '有效期至',
    noExpiry: '不限期',
    viewDetails: '查看二维码与使用规则',
  },
  couponDetail: {
    loadFailed: '券码详情加载失败',
    copyFailed: '复制失败，请手动选择券码',
    usable: '可核销',
    unusable: '不可核销',
    eyebrow: '券码详情',
    back: '返回我的券',
    loading: '券码详情加载中...',
    qrAlt: (code) => `券码二维码 ${code}`,
    verifyHint: (backendHint) => backendHint?.trim() || '到店后出示二维码或券码，由商户核销。',
    code: '券码',
    copied: '已复制',
    copyCode: '复制券码',
    viewOrder: '查看订单',
    viewPlace: '查看门店',
    status: '状态',
    expiresAt: '有效期至',
    noExpiry: '不限期',
    offerValidity: '团购有效期',
    redeemedAt: '核销时间',
    rules: '使用规则',
    noRules: '暂无补充规则',
  },
  reservations: {
    loadFailed: '预订加载失败',
    eyebrow: '我的预订',
    title: '待确认、已确认、取消和改期都在一条时间线上。',
    currentFilter: (status) => `当前筛选：${status}`,
    loading: '预订加载中...',
    empty: '当前筛选下暂无预订。',
    reservationNo: (value) => `预订号 ${value}`,
  },
  reservationDetail: {
    loadFailed: '预订加载失败',
    cancelFailed: '取消失败',
    slotLoadFailed: '时段加载失败',
    rescheduleFailed: '改期失败',
    confirmedBanner: '商户已确认你的预订。',
    arrivedBanner: '商户已确认你到店。',
    rejectedBanner: '商户已拒绝本次预订。',
    noShowBanner: '商户已将本次预订标记为爽约。',
    cancelSuccess: '预订已取消。',
    rescheduleSuccess: '改期申请已提交。',
    rescheduleReason: '用户在线改期',
    reservation: '预订',
    loading: '预订加载中...',
    cancel: '取消预订',
    findSlots: '查询改期时段',
    timeline: '变更时间线',
  },
  errorTranslations: {},
}

const enStrings: WebTradeStrings = {
  tag: 'en',
  common: {
    notAvailable: '—',
    processing: 'Working...',
    remaining: (count) => `${count} remaining`,
    people: (count) => `${count} ${count === 1 ? 'person' : 'people'}`,
  },
  statuses: {
    all: 'All',
    ...enStatuses,
    timelineRemark: (actionType, remark) => {
      const value = remark?.trim()
      if (!value) return '—'
      return knownTimelineRemarks[value]
        ?? (HAN_TEXT.test(value) ? enStatuses.timelineAction(actionType) : value)
    },
  },
  deal: {
    loadFailed: 'Could not load this offer',
    createOrderFailed: 'Could not place the order',
    loading: 'Loading offer...',
    sold: (count) => `${count} sold`,
    offerPrice: 'Offer price',
    originalPrice: 'Regular price',
    validUntil: 'Valid until',
    quantity: 'Quantity',
    buyNow: 'Buy now',
  },
  reservationCreate: {
    slotLoadFailed: 'Could not load available times',
    submitFailed: 'Could not submit the booking',
    selectSlotFirst: 'Choose an available time first.',
    eyebrow: 'Online booking',
    title: 'Check live availability, then add your contact details.',
    date: 'Date',
    people: 'Guests',
    searchSlots: 'Find times',
    contactName: 'Contact name',
    contactPhone: 'Phone number',
    phonePlaceholder: '+33 6 12 34 56 78',
    remark: 'Notes',
    remarkPlaceholder: 'Window table / private room',
    submit: 'Book now',
  },
  orders: {
    loadFailed: 'Could not load orders',
    cancelFailed: 'Could not cancel the order',
    refundFailed: 'Could not request a refund',
    cancelSuccess: (orderNo) => `Order ${orderNo} was cancelled`,
    refundSuccess: (orderNo) => `Refund requested for order ${orderNo}`,
    refundPrompt: 'Reason for refund',
    refundDefaultReason: 'Plans changed',
    eyebrow: 'My orders',
    title: 'Track payment, fulfilment and refunds in one place.',
    currentFilter: (status) => `Current filter: ${status}`,
    loading: 'Loading orders...',
    empty: 'No orders match this filter.',
    quantity: (count) => `Quantity ${count}`,
    orderNo: (value) => `Order ${value}`,
    viewDetails: 'View details',
    cancel: 'Cancel',
    refund: 'Refund',
  },
  orderDetail: {
    loadFailed: 'Could not load order details',
    paymentFailed: 'Could not start payment',
    mockPaymentFailed: 'Could not complete the test payment',
    cancelFailed: 'Could not cancel the order',
    refundFailed: 'Could not request a refund',
    refundApproved: 'Your refund was approved and the order was updated.',
    refundRejected: 'Your refund was rejected. See the review note for details.',
    mockPaymentSuccess: 'Test payment completed. Your vouchers are ready.',
    cancelConfirm: 'Cancel this unpaid order?',
    cancelSuccess: 'Order cancelled.',
    refundPrompt: 'Reason for refund',
    refundDefaultReason: 'Plans changed',
    refundSuccess: 'Refund requested. The place or support team will review it.',
    order: 'Order',
    title: 'Order details',
    back: 'Back to orders',
    loading: 'Loading order details...',
    startPayment: 'Start payment',
    completeMockPayment: (channel) => `Complete ${channel} test payment`,
    stripePayment: 'Pay by card',
    stripePaymentFailed: 'Card payment failed',
    stripeProcessing: 'Confirming your payment...',
    stripeReceived: 'Payment received. The order is being confirmed — please refresh shortly.',
    refreshOrder: 'Refresh order',
    cancel: 'Cancel order',
    requestRefund: 'Request refund',
    refundProgress: 'Refund progress',
    amount: 'Amount',
    reason: 'Reason',
    auditNote: 'Review note',
    requestedAt: 'Requested',
    auditedAt: 'Reviewed',
    vouchers: 'Vouchers',
    voucherHint: 'Open a voucher to view its QR code and usage rules.',
  },
  coupons: {
    loadFailed: 'Could not load vouchers',
    eyebrow: 'My vouchers',
    title: 'Track each voucher, its redemption status and expiry date.',
    currentFilter: (status) => `Current filter: ${status}`,
    highlightedCode: (code) => `Voucher ${code}`,
    loading: 'Loading vouchers...',
    empty: 'No vouchers match this filter.',
    expiresAt: 'Expires',
    noExpiry: 'No expiry',
    viewDetails: 'View QR code and usage rules',
  },
  couponDetail: {
    loadFailed: 'Could not load voucher details',
    copyFailed: 'Could not copy the code. Select it manually instead.',
    usable: 'Ready to redeem',
    unusable: 'Not redeemable',
    eyebrow: 'Voucher details',
    back: 'Back to vouchers',
    loading: 'Loading voucher details...',
    qrAlt: (code) => `QR code for voucher ${code}`,
    verifyHint: (backendHint) => {
      const value = backendHint?.trim()
      return value && !HAN_TEXT.test(value)
        ? value
        : 'Show this QR code or voucher code at the place to redeem it.'
    },
    code: 'Voucher code',
    copied: 'Copied',
    copyCode: 'Copy code',
    viewOrder: 'View order',
    viewPlace: 'View place',
    status: 'Status',
    expiresAt: 'Expires',
    noExpiry: 'No expiry',
    offerValidity: 'Offer validity',
    redeemedAt: 'Redeemed',
    rules: 'Usage rules',
    noRules: 'No additional rules',
  },
  reservations: {
    loadFailed: 'Could not load bookings',
    eyebrow: 'My bookings',
    title: 'Track confirmations, changes and cancellations in one timeline.',
    currentFilter: (status) => `Current filter: ${status}`,
    loading: 'Loading bookings...',
    empty: 'No bookings match this filter.',
    reservationNo: (value) => `Booking ${value}`,
  },
  reservationDetail: {
    loadFailed: 'Could not load booking details',
    cancelFailed: 'Could not cancel the booking',
    slotLoadFailed: 'Could not load available times',
    rescheduleFailed: 'Could not reschedule the booking',
    confirmedBanner: 'The place confirmed your booking.',
    arrivedBanner: 'The place confirmed your arrival.',
    rejectedBanner: 'The place declined this booking.',
    noShowBanner: 'The place marked this booking as a no-show.',
    cancelSuccess: 'Booking cancelled.',
    rescheduleSuccess: 'Your rescheduling request was submitted.',
    rescheduleReason: 'Customer rescheduled online',
    reservation: 'Booking',
    loading: 'Loading booking details...',
    cancel: 'Cancel booking',
    findSlots: 'Find a new time',
    timeline: 'Change timeline',
  },
  errorTranslations: {
    '团购不存在': 'This offer is not available',
    '订单不存在': 'Order not found',
    '券码不存在': 'Voucher not found',
    '券码不能为空': 'Enter a voucher code',
    '预订不存在': 'Booking not found',
    '预订时段不存在': 'This booking time is no longer available',
    '当前时段余量不足': 'There is not enough availability for this time',
    '新时段余量不足': 'There is not enough availability for the new time',
    '已超过允许取消时间': 'This booking can no longer be cancelled',
    '预订当前不可取消': 'This booking cannot be cancelled',
    '预订当前不可改期': 'This booking cannot be rescheduled',
    '用户登录状态不存在': 'Your session has expired. Sign in again.',
  },
}

const STRINGS: Record<Region, WebTradeStrings> = { CN: zhCnStrings, EU: enStrings }

export function tradeStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebTradeError(strings: WebTradeStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const traceMatch = error.message.match(/\s*(\[traceId:\s*[^\]]+\])\s*$/)
  const trace = traceMatch?.[1]
  const message = trace ? error.message.slice(0, traceMatch.index).trim() : error.message.trim()
  const localized = strings.errorTranslations[message]
    ?? (HAN_TEXT.test(message) ? fallback : message || fallback)
  return trace ? `${localized} ${trace}` : localized
}

export function formatWebTradeDate(raw: string, locale: WebLocaleTag) {
  const match = raw.trim().match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (!match) return raw
  const [, year, month, day] = match
  return locale === 'en'
    ? `${day}/${month}/${year}`
    : `${year}/${Number(month)}/${Number(day)}`
}
