import type { Region } from '@/types/browse'
import { formatEnglishCount } from './web_count_localizations'
import type { WebLocaleTag } from '@/core/web_localizations'

export interface WebUserStrings {
  tag: WebLocaleTag
  common: {
    previous: string
    next: string
    refresh: string
  }
  reviews: {
    loadFailed: string
    deleteFailed: string
    deleteConfirm: string
    deleted: (id: number) => string
    eyebrow: string
    title: string
    summary: (region: Region) => string
    filters: string
    filtersTitle: string
    auditStatus: string
    allStatuses: string
    status: (value: number) => string
    apply: string
    loading: string
    empty: string
    review: (id: number) => string
    rejectReason: string
    ratingAndDate: (rating: string, date: string) => string
    viewDetails: string
    edit: string
    publicPage: string
    deleting: string
    delete: string
    page: (page: number) => string
  }
  publicProfile: {
    invalidId: string
    loadFailed: string
    loading: string
    eyebrow: string
    reviewCount: (count: number) => string
    noSignature: string
    myProfile: string
    myReviews: string
    basics: string
    basicsTitle: string
    level: string
    pointsAndGrowth: string
    publicReviews: string
    publicRelations: string
    followers: (count: number) => string
    following: (count: number) => string
    noReviews: string
  }
  relationships: {
    loadFailed: string
    eyebrow: string
    followers: (count: number) => string
    following: (count: number) => string
    summary: string
    followerCount: (count: number) => string
    followedAt: string
    emptyFollowers: string
    emptyFollowing: string
  }
  checkIn: {
    loadFailed: string
    submitFailed: string
    success: string
    eyebrow: string
    title: string
    summary: string
    backProfile: string
    growthHistory: string
    todayStatus: string
    checkedIn: string
    notCheckedIn: string
    streak: string
    streakValue: (count: number) => string
    total: string
    totalValue: (count: number) => string
    reward: string
    rewardValue: (growth: number, points: number) => string
    detailEyebrow: string
    detailTitle: string
    availableHint: string
    checkedHint: string
    lastCheckIn: string
    never: string
    loading: string
    retry: string
    refresh: string
    refreshing: string
    submit: string
    submitting: string
    submitted: string
  }
  growth: {
    loadFailed: string
    eyebrow: string
    title: string
    summary: string
    backProfile: string
    myReviews: string
    currentLevel: string
    pointsAndGrowth: string
    latest: string
    noRecords: string
    listEyebrow: string
    listTitle: string
    pageSize: string
    rows: (count: number) => string
    refresh: string
    loading: string
    empty: string
    defaultRemark: string
    change: string
    balance: string
    creditedAt: string
    action: string
    business: (id: number) => string
    viewReview: string
    pagination: (page: number, total: number) => string
    type: (type: number, fallback: string) => string
    actionLabel: (action: string, fallback: string) => string
    remarkLabel: (action: string, fallback: string) => string
  }
  pointsMall: {
    loadFailed: string
    exchangeFailed: string
    exchangeSuccess: (name: string) => string
    exchangeSuccessWithCode: (code: string) => string
    eyebrow: string
    title: string
    summary: string
    backProfile: string
    checkIn: string
    growthHistory: string
    balance: string
    level: string
    tabProducts: string
    tabExchanges: string
    productsEyebrow: string
    productsTitle: string
    exchangesEyebrow: string
    exchangesTitle: string
    pageSize: string
    rows: (count: number) => string
    refresh: string
    loading: string
    emptyProducts: string
    emptyExchanges: string
    pointsPrice: (points: number) => string
    stock: (count: number) => string
    limit: (count: number) => string
    unlimited: string
    soldOut: string
    fulfillAuto: string
    fulfillManual: string
    fulfillType: (type: number, fallback: string) => string
    exchange: string
    exchanging: string
    confirmExchange: (name: string, points: number) => string
    insufficientPoints: string
    status: (status: number, fallback: string) => string
    redeemCode: string
    noRedeemCode: string
    cost: string
    quantity: string
    orderedAt: string
    fulfilledAt: string
    remark: string
    pagination: (page: number, total: number) => string
    previous: string
    next: string
    productDetail: string
    exchangeNow: string
    backToMall: string
    viewDetail: string
    yourBalance: string
    pointsUnit: string
    stockLabel: string
    exchangeLimitLabel: string
    fulfillTypeLabel: string
    exchangeCount: string
    productDescription: string
    abundant: string
    insufficientBalance: string
  }
  errorTranslations: Record<string, string>
}

const growthActionsZh: Record<string, string> = {
  review_create: '发布点评', review_liked: '点评获赞', review_image: '带图点评', order_complete: '完成订单', check_in: '每日签到',
  points_exchange: '积分兑换', points_exchange_refund: '兑换退回',
}
const growthRemarksZh: Record<string, string> = {
  review_create: '发点评奖励', review_liked: '点评获赞奖励', review_image: '带图点评奖励', order_complete: '完成订单奖励', check_in: '每日签到奖励',
  points_exchange: '积分商城兑换', points_exchange_refund: '兑换取消退回积分',
}
const growthActionsEn: Record<string, string> = {
  review_create: 'Review published', review_liked: 'Review liked', review_image: 'Photo review', order_complete: 'Order completed', check_in: 'Daily check-in',
  points_exchange: 'Points exchange', points_exchange_refund: 'Exchange refund',
}
const growthRemarksEn: Record<string, string> = {
  review_create: 'Review publishing reward', review_liked: 'Review like reward', review_image: 'Photo review reward', order_complete: 'Order completion reward', check_in: 'Daily check-in reward',
  points_exchange: 'Points mall redemption', points_exchange_refund: 'Points refunded after cancelled exchange',
}

const zhCnStrings: WebUserStrings = {
  tag: 'zh-CN',
  common: { previous: '上一页', next: '下一页', refresh: '刷新' },
  reviews: {
    loadFailed: '我的点评加载失败', deleteFailed: '点评删除失败', deleteConfirm: '确认删除这条点评？删除后无法恢复。',
    deleted: (id) => `点评 #${id} 已删除。`, eyebrow: '我的点评', title: '写过的、待审的、被驳回的，都在这里统一管理。',
    summary: (region) => `当前区域 ${region}，可查看点评内容与审核状态。`, filters: '筛选', filtersTitle: '按审核状态查找点评。',
    auditStatus: '审核状态', allStatuses: '全部状态', status: (value) => ({ 0: '待审', 1: '通过', 2: '驳回' })[value] || '未知状态',
    apply: '应用筛选', loading: '我的点评加载中...', empty: '当前还没有点评记录，先去门店详情页写一条。',
    review: (id) => `点评 #${id}`, rejectReason: '驳回原因', ratingAndDate: (rating, date) => `评分 ${rating} · 创建于 ${date}`,
    viewDetails: '查看详情', edit: '编辑', publicPage: '公开页', deleting: '删除中...', delete: '删除', page: (page) => `第 ${page} 页`,
  },
  publicProfile: {
    invalidId: '用户 ID 不合法', loadFailed: '用户主页加载失败', loading: '用户主页加载中...', eyebrow: '公开主页',
    reviewCount: (count) => `公开点评 ${count} 条`, noSignature: '这个人暂时没有留下签名。', myProfile: '去我的资料页', myReviews: '看我的点评',
    basics: '基础数据', basicsTitle: '仅展示用户主动公开的信息。', level: '等级', pointsAndGrowth: '积分 / 成长值', publicReviews: '公开点评',
    publicRelations: '公开关系', followers: (count) => `粉丝 ${count}`, following: (count) => `关注 ${count}`,
    noReviews: '这个用户现在还没有公开可见的点评。',
  },
  relationships: {
    loadFailed: '关系列表加载失败', eyebrow: '公开关系 · 只读', followers: (count) => `粉丝 ${count} 人`, following: (count) => `关注 ${count} 人`,
    summary: 'PC 端只展示公开关系，不提供关注或取关操作。', followerCount: (count) => `粉丝 ${count}`, followedAt: '建立关系于',
    emptyFollowers: '暂时没有公开粉丝。', emptyFollowing: '暂时没有公开关注。',
  },
  checkIn: {
    loadFailed: '签到状态加载失败', submitFailed: '签到失败', success: '签到成功，奖励已入账。', eyebrow: '每日签到',
    title: '签到一次，连续记录每天的成长。', summary: '每日签到会按当前规则发放成长值与积分，同一天只能签到一次。',
    backProfile: '回我的资料', growthHistory: '查看奖励流水', todayStatus: '今日状态', checkedIn: '已签到', notCheckedIn: '待签到',
    streak: '连续签到', streakValue: (count) => `${count} 天`, total: '累计签到', totalValue: (count) => `${count} 次`, reward: '今日奖励',
    rewardValue: (growth, points) => `成长值 +${growth} · 积分 +${points}`, detailEyebrow: '签到状态', detailTitle: '确认今天的奖励和连续天数。',
    availableHint: '签到成功后，奖励会立即进入成长值和积分流水。', checkedHint: '今天的签到已经完成，明天继续可延续连续天数。',
    lastCheckIn: '上次签到', never: '还没有签到记录', loading: '签到状态加载中...', retry: '重试', refresh: '刷新状态', refreshing: '刷新中...',
    submit: '立即签到', submitting: '签到中...', submitted: '今日已签到',
  },
  growth: {
    loadFailed: '成长值流水加载失败', eyebrow: '成长值流水', title: '每一笔成长值和积分都清晰可查。',
    summary: '查看点评、互动和订单奖励带来的成长值与积分变化。', backProfile: '回我的资料', myReviews: '去我的点评', currentLevel: '当前等级',
    pointsAndGrowth: '积分 / 成长值', latest: '最近一笔', noRecords: '暂无流水', listEyebrow: '流水列表', listTitle: '按时间核对成长值和积分变动。',
    pageSize: '每页条数', rows: (count) => `${count} 条`, refresh: '刷新流水', loading: '成长值流水加载中...',
    empty: '现在还没有流水，完成点评或订单后会显示在这里。', defaultRemark: '系统奖励已入账。', change: '变动', balance: '余额',
    creditedAt: '入账时间', action: '动作', business: (id) => `业务 #${id}`, viewReview: '查看点评',
    pagination: (page, total) => `第 ${page} 页，共 ${total} 条`, type: (type, fallback) => ({ 1: '成长值', 2: '积分' })[type] || fallback,
    actionLabel: (action, fallback) => fallback || growthActionsZh[action] || action,
    remarkLabel: (action, fallback) => fallback || growthRemarksZh[action] || action,
  },
  pointsMall: {
    loadFailed: '积分商城加载失败',
    exchangeFailed: '兑换失败',
    exchangeSuccess: (name) => `兑换「${name}」成功，可在「我的兑换」查看进度。`,
    exchangeSuccessWithCode: (code) => `兑换成功，兑换码：${code}`,
    eyebrow: '积分商城',
    title: '用积分兑换优惠与福利。',
    summary: '浏览可兑商品、确认积分余额，并在「我的兑换」跟踪发放状态与兑换码。',
    backProfile: '回我的资料',
    checkIn: '去签到赚积分',
    growthHistory: '查看积分流水',
    balance: '当前积分',
    level: '当前等级',
    tabProducts: '可兑商品',
    tabExchanges: '我的兑换',
    productsEyebrow: '商品列表',
    productsTitle: '按积分价格浏览当前区域上架商品。',
    exchangesEyebrow: '兑换记录',
    exchangesTitle: '查看待发放、已发放和已取消的兑换单。',
    pageSize: '每页条数',
    rows: (count) => `${count} 条`,
    refresh: '刷新',
    loading: '加载中...',
    emptyProducts: '当前区域暂无可兑商品。',
    emptyExchanges: '还没有兑换记录，去商品页挑一件吧。',
    pointsPrice: (points) => `${points} 积分`,
    stock: (count) => `库存 ${count}`,
    limit: (count) => `每人限兑 ${count} 次`,
    unlimited: '不限兑换次数',
    soldOut: '已兑完',
    fulfillAuto: '自动发放',
    fulfillManual: '人工发放',
    fulfillType: (type, fallback) => ({ 1: '自动发放', 2: '人工发放' })[type] || fallback,
    exchange: '立即兑换',
    exchanging: '兑换中...',
    confirmExchange: (name, points) => `确认花费 ${points} 积分兑换「${name}」？`,
    insufficientPoints: '积分不足，无法兑换该商品。',
    status: (status, fallback) => ({ 0: '待发放', 1: '已发放', 2: '已取消' })[status] || fallback,
    redeemCode: '兑换码',
    noRedeemCode: '发放后可见',
    cost: '消耗积分',
    quantity: '数量',
    orderedAt: '下单时间',
    fulfilledAt: '发放时间',
    remark: '备注',
    pagination: (page, total) => `第 ${page} 页，共 ${total} 条`,
    previous: '上一页',
    next: '下一页',
    productDetail: '商品详情',
    exchangeNow: '立即兑换',
    backToMall: '返回商城',
    viewDetail: '查看详情',
    yourBalance: '您的余额',
    pointsUnit: '积分',
    stockLabel: '剩余库存',
    exchangeLimitLabel: '兑换限制',
    fulfillTypeLabel: '发放方式',
    exchangeCount: '已兑换次数',
    productDescription: '商品说明',
    abundant: '充足',
    insufficientBalance: '积分不足',
  },
  errorTranslations: {},
}

const enStrings: WebUserStrings = {
  tag: 'en',
  common: { previous: 'Previous', next: 'Next', refresh: 'Refresh' },
  reviews: {
    loadFailed: 'Could not load your reviews', deleteFailed: 'Could not delete the review', deleteConfirm: 'Delete this review? This cannot be undone.',
    deleted: (id) => `Review #${id} deleted.`, eyebrow: 'My reviews', title: 'Manage published, pending and rejected reviews.',
    summary: (region) => `Viewing reviews and moderation status for the ${region} region.`, filters: 'Filters', filtersTitle: 'Filter reviews by moderation status.',
    auditStatus: 'Moderation status', allStatuses: 'All statuses', status: (value) => ({ 0: 'Pending', 1: 'Approved', 2: 'Rejected' })[value] || 'Unknown status',
    apply: 'Apply filters', loading: 'Loading your reviews...', empty: 'You have not written any reviews in this region yet.',
    review: (id) => `Review #${id}`, rejectReason: 'Moderation note', ratingAndDate: (rating, date) => `Rating ${rating} · Created ${date}`,
    viewDetails: 'View details', edit: 'Edit', publicPage: 'Public page', deleting: 'Deleting...', delete: 'Delete', page: (page) => `Page ${page}`,
  },
  publicProfile: {
    invalidId: 'The user ID is invalid', loadFailed: 'Could not load this profile', loading: 'Loading profile...', eyebrow: 'Public profile',
    reviewCount: (count) => `${count} public ${count === 1 ? 'review' : 'reviews'}`, noSignature: 'This user has not added a bio yet.', myProfile: 'Go to my profile', myReviews: 'View my reviews',
    basics: 'Public stats', basicsTitle: 'Only information intended for public viewing is shown.', level: 'Level', pointsAndGrowth: 'Points / growth', publicReviews: 'Public reviews',
    publicRelations: 'Public connections', followers: (count) => `${count} ${count === 1 ? 'follower' : 'followers'}`, following: (count) => `${count} following`,
    noReviews: 'This user has no publicly visible reviews yet.',
  },
  relationships: {
    loadFailed: 'Could not load connections', eyebrow: 'Public connections · Read only', followers: (count) => `${count} ${count === 1 ? 'follower' : 'followers'}`,
    following: (count) => `${count} following`, summary: 'The desktop site shows public connections without follow or unfollow controls.',
    followerCount: (count) => `${count} ${count === 1 ? 'follower' : 'followers'}`, followedAt: 'Connected',
    emptyFollowers: 'No public followers yet.', emptyFollowing: 'No public following yet.',
  },
  checkIn: {
    loadFailed: 'Could not load check-in status', submitFailed: 'Could not check in', success: 'Check-in complete. Your rewards were credited.', eyebrow: 'Daily check-in',
    title: 'Build a streak one day at a time.', summary: 'A daily check-in credits the current growth and points reward once per calendar day.',
    backProfile: 'Back to profile', growthHistory: 'View rewards activity', todayStatus: 'Today', checkedIn: 'Checked in', notCheckedIn: 'Available',
    streak: 'Current streak', streakValue: (count) => `${count}-day streak`, total: 'Total check-ins', totalValue: (count) => formatEnglishCount(count, 'check-in'), reward: 'Today\'s reward',
    rewardValue: (growth, points) => `+${growth} growth · +${points} points`, detailEyebrow: 'Check-in status', detailTitle: 'Review today\'s reward and your current streak.',
    availableHint: 'The reward is added to your growth and points activity immediately after check-in.', checkedHint: 'Today is complete. Check in tomorrow to continue your streak.',
    lastCheckIn: 'Last check-in', never: 'No check-ins yet', loading: 'Loading check-in status...', retry: 'Retry', refresh: 'Refresh status', refreshing: 'Refreshing...',
    submit: 'Check in now', submitting: 'Checking in...', submitted: 'Checked in today',
  },
  growth: {
    loadFailed: 'Could not load growth history', eyebrow: 'Growth history', title: 'Track every growth and points change.',
    summary: 'Review rewards from reviews, interactions and completed orders.', backProfile: 'Back to profile', myReviews: 'My reviews', currentLevel: 'Current level',
    pointsAndGrowth: 'Points / growth', latest: 'Latest entry', noRecords: 'No entries', listEyebrow: 'History', listTitle: 'Review growth and points changes by date.',
    pageSize: 'Rows per page', rows: (count) => formatEnglishCount(count, 'row'), refresh: 'Refresh history', loading: 'Loading growth history...',
    empty: 'No growth or points history yet.', defaultRemark: 'Reward credited to your account.', change: 'Change', balance: 'Balance',
    creditedAt: 'Credited', action: 'Action', business: (id) => `Reference #${id}`, viewReview: 'View review',
    pagination: (page, total) => `Page ${page} · ${total} total`, type: (type, fallback) => ({ 1: 'Growth value', 2: 'Points' })[type] || fallback,
    actionLabel: (action, fallback) => growthActionsEn[action] || (/\p{Script=Han}/u.test(fallback) ? action : fallback),
    remarkLabel: (action, fallback) => growthRemarksEn[action] || (/\p{Script=Han}/u.test(fallback) ? action : fallback),
  },
  pointsMall: {
    loadFailed: 'Could not load the points mall',
    exchangeFailed: 'Could not complete the exchange',
    exchangeSuccess: (name) => `Redeemed "${name}". Track it under My exchanges.`,
    exchangeSuccessWithCode: (code) => `Exchange complete. Redeem code: ${code}`,
    eyebrow: 'Points mall',
    title: 'Redeem points for offers and perks.',
    summary: 'Browse catalog items, confirm your balance, and track fulfillment status and redeem codes under My exchanges.',
    backProfile: 'Back to profile',
    checkIn: 'Check in for points',
    growthHistory: 'View points activity',
    balance: 'Points balance',
    level: 'Level',
    tabProducts: 'Catalog',
    tabExchanges: 'My exchanges',
    productsEyebrow: 'Catalog',
    productsTitle: 'Browse live products for the current region by points price.',
    exchangesEyebrow: 'Exchange history',
    exchangesTitle: 'Review pending, fulfilled and cancelled redemptions.',
    pageSize: 'Rows per page',
    rows: (count) => formatEnglishCount(count, 'row'),
    refresh: 'Refresh',
    loading: 'Loading...',
    emptyProducts: 'No redeemable products in this region yet.',
    emptyExchanges: 'No exchanges yet. Pick something from the catalog.',
    pointsPrice: (points) => formatEnglishCount(points, 'point'),
    stock: (count) => `Stock ${count}`,
    limit: (count) => `Limit ${count} per user`,
    unlimited: 'No per-user limit',
    soldOut: 'Sold out',
    fulfillAuto: 'Auto fulfill',
    fulfillManual: 'Manual fulfill',
    fulfillType: (type, fallback) => ({ 1: 'Auto fulfill', 2: 'Manual fulfill' })[type] || fallback,
    exchange: 'Redeem now',
    exchanging: 'Redeeming...',
    confirmExchange: (name, points) => `Spend ${formatEnglishCount(points, 'point')} to redeem “${name}”?`,
    insufficientPoints: 'Not enough points for this product.',
    status: (status, fallback) => ({ 0: 'Pending', 1: 'Fulfilled', 2: 'Cancelled' })[status] || fallback,
    redeemCode: 'Redeem code',
    noRedeemCode: 'Visible after fulfillment',
    cost: 'Points spent',
    quantity: 'Quantity',
    orderedAt: 'Ordered',
    fulfilledAt: 'Fulfilled',
    remark: 'Note',
    pagination: (page, total) => `Page ${page} · ${total} total`,
    previous: 'Previous',
    next: 'Next',
    productDetail: 'Product detail',
    exchangeNow: 'Redeem now',
    backToMall: 'Back to mall',
    viewDetail: 'View details',
    yourBalance: 'Your balance',
    pointsUnit: 'points',
    stockLabel: 'Stock',
    exchangeLimitLabel: 'Redemption limit',
    fulfillTypeLabel: 'Fulfillment',
    exchangeCount: 'Redeemed',
    productDescription: 'Description',
    abundant: 'Abundant',
    insufficientBalance: 'Insufficient balance',
  },
  errorTranslations: {
    '用户登录状态不存在': 'Your session has expired. Sign in again.',
    '今天已经签过到了': 'You already checked in today.',
    '商品不存在或已下架': 'This product is unavailable or has been taken down.',
    '商品已兑完': 'This product is sold out.',
    '已达到该商品的兑换上限': 'You have reached the exchange limit for this product.',
    '积分不足': 'You do not have enough points.',
  },
}

const STRINGS: Record<Region, WebUserStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function userStringsForRegion(region: Region) { return STRINGS[region] }

export function localizeWebUserError(strings: WebUserStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const traceMatch = error.message.match(/\s*(\[traceId:\s*[^\]]+\])\s*$/)
  const trace = traceMatch?.[1]
  const message = trace ? error.message.slice(0, traceMatch.index).trim() : error.message.trim()
  const localized = strings.errorTranslations[message] || (HAN_TEXT.test(message) ? fallback : message || fallback)
  return trace ? `${localized} ${trace}` : localized
}
