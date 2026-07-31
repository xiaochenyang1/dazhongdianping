import type { Region } from '@/types/browse'
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
  errorTranslations: Record<string, string>
}

const growthActionsZh: Record<string, string> = {
  review_create: '发布点评', review_liked: '点评获赞', review_image: '带图点评', order_complete: '完成订单',
}
const growthRemarksZh: Record<string, string> = {
  review_create: '发点评奖励', review_liked: '点评获赞奖励', review_image: '带图点评奖励', order_complete: '完成订单奖励',
}
const growthActionsEn: Record<string, string> = {
  review_create: 'Review published', review_liked: 'Review liked', review_image: 'Photo review', order_complete: 'Order completed',
}
const growthRemarksEn: Record<string, string> = {
  review_create: 'Review publishing reward', review_liked: 'Review like reward', review_image: 'Photo review reward', order_complete: 'Order completion reward',
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
  growth: {
    loadFailed: 'Could not load growth history', eyebrow: 'Growth history', title: 'Track every growth and points change.',
    summary: 'Review rewards from reviews, interactions and completed orders.', backProfile: 'Back to profile', myReviews: 'My reviews', currentLevel: 'Current level',
    pointsAndGrowth: 'Points / growth', latest: 'Latest entry', noRecords: 'No entries', listEyebrow: 'History', listTitle: 'Review growth and points changes by date.',
    pageSize: 'Rows per page', rows: (count) => `${count} rows`, refresh: 'Refresh history', loading: 'Loading growth history...',
    empty: 'No growth or points history yet.', defaultRemark: 'Reward credited to your account.', change: 'Change', balance: 'Balance',
    creditedAt: 'Credited', action: 'Action', business: (id) => `Reference #${id}`, viewReview: 'View review',
    pagination: (page, total) => `Page ${page} · ${total} total`, type: (type, fallback) => ({ 1: 'Growth value', 2: 'Points' })[type] || fallback,
    actionLabel: (action, fallback) => growthActionsEn[action] || (/\p{Script=Han}/u.test(fallback) ? action : fallback),
    remarkLabel: (action, fallback) => growthRemarksEn[action] || (/\p{Script=Han}/u.test(fallback) ? action : fallback),
  },
  errorTranslations: { '用户登录状态不存在': 'Your session has expired. Sign in again.' },
}

const STRINGS: Record<Region, WebUserStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function userStringsForRegion(region: Region) { return STRINGS[region] }

export function localizeWebUserError(strings: WebUserStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  return strings.errorTranslations[error.message.trim()] || (HAN_TEXT.test(error.message) ? fallback : error.message || fallback)
}
