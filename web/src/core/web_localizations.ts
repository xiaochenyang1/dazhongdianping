import type { Region } from '@/types/browse'

export type WebLocaleTag = 'zh-CN' | 'en'

interface RouteMetaText {
  title: string
  description: string
}

export interface WebStrings {
  tag: WebLocaleTag
  brand: {
    title: string
    subtitle: string
    signal: string
  }
  common: {
    requestFailed: string
    refreshSessionFailed: string
    downloadFailed: string
  }
  nav: Array<{ to: string; label: string; matchPrefix?: string }>
  search: {
    label: string
    placeholder: string
    submit: string
    suggestionsAria: string
    suggested: string
    shop: string
    category: string
    recent: string
    clear: string
    clearing: string
    hot: string
    heat: (score: number) => string
    removeHistoryAria: string
    historyLoading: string
    loading: string
  }
  region: {
    label: string
    cnPerspective: string
    euPerspective: string
  }
  notifications: {
    trigger: string
    heading: string
    connected: string
    offline: string
    markAllRead: string
    viewAll: string
    loading: string
    empty: string
    hints: Record<string, string>
  }
  session: {
    login: string
    userFallback: string
    userInitial: string
    logout: string
    loggingOut: string
  }
  defaultRoute: RouteMetaText
  routes: Record<string, RouteMetaText>
}

const zhCnStrings: WebStrings = {
  tag: 'zh-CN',
  brand: {
    title: '大众点评(仿)',
    subtitle: '本地生活 PC 端',
    signal: '实时服务',
  },
  common: {
    requestFailed: '请求失败',
    refreshSessionFailed: '刷新登录态失败',
    downloadFailed: '文件下载失败',
  },
  nav: [
    { to: '/', label: '首页' },
    { to: '/shops', label: '商户列表' },
    { to: '/ranks', label: '城市榜单', matchPrefix: '/ranks' },
    { to: '/activities', label: '运营活动', matchPrefix: '/activities' },
    { to: '/community', label: '华人社区', matchPrefix: '/community' },
    { to: '/user/reviews', label: '我的点评', matchPrefix: '/user/reviews' },
    { to: '/user/favorites', label: '我的收藏', matchPrefix: '/user/favorites' },
    { to: '/user/notifications', label: '消息中心', matchPrefix: '/user/notifications' },
    { to: '/user/browse-history', label: '我的足迹', matchPrefix: '/user/browse-history' },
    { to: '/user/orders', label: '我的订单', matchPrefix: '/user/orders' },
    { to: '/user/coupons', label: '我的券', matchPrefix: '/user/coupons' },
    { to: '/user/reservations', label: '我的预订', matchPrefix: '/user/reservations' },
    { to: '/user/profile', label: '我的资料', matchPrefix: '/user/profile' },
    { to: '/user/check-in', label: '每日签到', matchPrefix: '/user/check-in' },
    { to: '/user/growth-records', label: '成长值流水', matchPrefix: '/user/growth-records' },
  ],
  search: {
    label: '搜索商户',
    placeholder: '搜火锅、咖啡、商圈',
    submit: '搜索',
    suggestionsAria: '搜索建议',
    suggested: '猜你要找',
    shop: '商户',
    category: '分类',
    recent: '最近搜过',
    clear: '清空',
    clearing: '清空中...',
    hot: '当前热词',
    heat: (score) => `${score} 热度`,
    removeHistoryAria: '删除这条搜索历史',
    historyLoading: '搜索历史加载中...',
    loading: '搜索中...',
  },
  region: {
    label: '区域视角',
    cnPerspective: '国内站视角',
    euPerspective: '欧洲站视角',
  },
  notifications: {
    trigger: '通知',
    heading: '消息通知',
    connected: '实时在线',
    offline: '离线补偿',
    markAllRead: '全部已读',
    viewAll: '查看全部',
    loading: '加载中...',
    empty: '暂无通知',
    hints: {
      'message.direct': '请在 APP 查看',
      'reservation.reminder': '预订提醒',
      'coupon.reminder': '券码到期提醒',
      'coupon.expired': '券码已过期',
      'order.paid': '支付成功',
      'order.refund.result': '退款结果',
      'reservation.created': '预订创建',
      'reservation.status': '预订状态',
      'review.audit.result': '点评审核',
      'expert.certification.result': '达人认证',
      'post.audit.result': '帖子审核',
      'coupon.verified': '券码核销',
      'review.hidden': '点评处理',
      'topic.update': '话题更新',
      'social.mention': '@提醒',
      'review.like': '点评获赞',
      'review.comment': '点评评论',
      'review.comment.reply': '评论回复',
      'review.reply': '商家回复',
      'post.comment': '帖子评论',
      'post.comment.reply': '帖子评论回复',
      'post.like': '帖子获赞',
      'post.repost': '帖子转发',
      'social.follow': '新增关注',
    },
  },
  session: {
    login: '登录 / 注册',
    userFallback: '已登录用户',
    userInitial: '我',
    logout: '退出',
    loggingOut: '退出中...',
  },
  defaultRoute: {
    title: '大众点评(仿)',
    description: '大众点评仿站本地生活平台，支持商户浏览、点评、交易和用户中心。',
  },
  routes: {
    home: { title: '首页', description: '浏览本地生活推荐、精选门店和城市频道。' },
    'shop-list': { title: '商户列表', description: '按城市、分类和商圈筛选本地生活商户。' },
    'rank-list': { title: '城市榜单', description: '浏览按城市和分类发布的必吃榜、好评榜与热门榜。' },
    'activity-list': { title: '运营活动', description: '浏览当前区域上线中的运营专题与活动资源。' },
    'activity-detail': { title: '活动详情', description: '查看运营活动详情和关联资源。' },
    community: { title: '华人社区', description: '浏览欧洲华人攻略、探店和生活经验。' },
    'community-post': { title: '社区帖子', description: '阅读公开社区帖子与评论。' },
    'circle-list': { title: '官方圈子', description: '浏览当前区域官方社区圈子。' },
    'circle-detail': { title: '圈子详情', description: '查看官方圈子资料和公开帖子。' },
    'topic-list': { title: '话题广场', description: '浏览推荐话题与最近 7 天热榜。' },
    'topic-detail': { title: '话题详情', description: '查看话题热度构成和公开社区帖子。' },
    'rank-detail': { title: '榜单详情', description: '查看榜单发布快照、门店排名和入榜理由。' },
    'shop-detail': { title: '商户详情', description: '查看商户资料、相册、推荐菜和公开点评。' },
    'deal-detail': { title: '团购详情', description: '查看团购内容、有效期和使用规则并下单。' },
    'reservation-create': { title: '在线预订', description: '查询门店可订时段并提交预订。' },
    'shop-reviews': { title: '门店点评', description: '查看门店公开点评、评分和互动计数。' },
    'review-create': { title: '写点评', description: '发布门店点评并提交评分、正文、标签和图片。' },
    'review-detail': { title: '点评详情', description: '查看公开点评详情、图片和互动。' },
    'review-edit': { title: '编辑点评', description: '编辑我的点评并重新提交审核。' },
    'my-reviews': { title: '我的点评', description: '管理我发布过的点评和审核状态。' },
    'user-notifications': { title: '消息中心', description: '查看站内通知并标记已读。' },
    'user-favorites': { title: '我的收藏', description: '查看和管理收藏的门店与帖子。' },
    'user-browse-history': { title: '我的足迹', description: '查看和管理最近浏览过的门店。' },
    'user-orders': { title: '我的订单', description: '查看团购订单及支付退款状态。' },
    'user-order-detail': { title: '订单详情', description: '查看订单、支付和券码信息。' },
    'user-coupons': { title: '我的券', description: '查看待使用、已使用、过期和退款券码。' },
    'user-coupon-detail': { title: '券码详情', description: '查看券码状态、使用规则和核销二维码。' },
    'user-reservations': { title: '我的预订', description: '查看预订状态和改期记录。' },
    'user-reservation-detail': { title: '预订详情', description: '查看、取消或改期预订。' },
    'my-review-detail': { title: '我的点评详情', description: '查看点评详情、审核状态和驳回原因。' },
    'user-profile': { title: '我的资料', description: '查看和修改个人资料、绑定账号和登录密码。' },
    'user-check-in': { title: '每日签到', description: '完成每日签到并查看连续天数、累计次数和奖励。' },
    'user-growth-records': { title: '成长值流水', description: '查看成长值和积分流水。' },
    'user-privacy': { title: '隐私中心', description: '导出个人数据并管理账号删除申请。' },
    'public-user-profile': { title: '用户主页', description: '查看公开用户资料和点评概览。' },
    'public-user-followers': { title: '用户粉丝', description: '查看用户公开粉丝列表。' },
    'public-user-following': { title: '用户关注', description: '查看用户公开关注列表。' },
  },
}

const enStrings: WebStrings = {
  tag: 'en',
  brand: {
    title: 'Local Reviews (Demo)',
    subtitle: 'Local life on the web',
    signal: 'Live services',
  },
  common: {
    requestFailed: 'Request failed',
    refreshSessionFailed: 'Could not refresh your session',
    downloadFailed: 'Could not download the file',
  },
  nav: [
    { to: '/', label: 'Home' },
    { to: '/shops', label: 'Places' },
    { to: '/ranks', label: 'City rankings', matchPrefix: '/ranks' },
    { to: '/activities', label: 'Activities', matchPrefix: '/activities' },
    { to: '/community', label: 'Community', matchPrefix: '/community' },
    { to: '/user/reviews', label: 'My reviews', matchPrefix: '/user/reviews' },
    { to: '/user/favorites', label: 'Saved', matchPrefix: '/user/favorites' },
    { to: '/user/notifications', label: 'Messages', matchPrefix: '/user/notifications' },
    { to: '/user/browse-history', label: 'History', matchPrefix: '/user/browse-history' },
    { to: '/user/orders', label: 'Orders', matchPrefix: '/user/orders' },
    { to: '/user/coupons', label: 'Vouchers', matchPrefix: '/user/coupons' },
    { to: '/user/reservations', label: 'Bookings', matchPrefix: '/user/reservations' },
    { to: '/user/profile', label: 'Profile', matchPrefix: '/user/profile' },
    { to: '/user/check-in', label: 'Check-in', matchPrefix: '/user/check-in' },
    { to: '/user/growth-records', label: 'Rewards', matchPrefix: '/user/growth-records' },
  ],
  search: {
    label: 'Search places',
    placeholder: 'Search hotpot, coffee or an area',
    submit: 'Search',
    suggestionsAria: 'Search suggestions',
    suggested: 'Suggestions',
    shop: 'Place',
    category: 'Category',
    recent: 'Recent searches',
    clear: 'Clear',
    clearing: 'Clearing...',
    hot: 'Trending searches',
    heat: (score) => `${score} heat`,
    removeHistoryAria: 'Remove this search from history',
    historyLoading: 'Loading search history...',
    loading: 'Searching...',
  },
  region: {
    label: 'Region',
    cnPerspective: 'China site',
    euPerspective: 'Europe site',
  },
  notifications: {
    trigger: 'Notifications',
    heading: 'Notifications',
    connected: 'Live',
    offline: 'Offline fallback',
    markAllRead: 'Mark all read',
    viewAll: 'View all',
    loading: 'Loading...',
    empty: 'No notifications',
    hints: {
      'message.direct': 'Open in the app',
      'reservation.reminder': 'Booking reminder',
      'coupon.reminder': 'Voucher expiry reminder',
      'coupon.expired': 'Voucher expired',
      'order.paid': 'Payment complete',
      'order.refund.result': 'Refund result',
      'reservation.created': 'Booking created',
      'reservation.status': 'Booking status',
      'review.audit.result': 'Review moderation',
      'expert.certification.result': 'Expert certification',
      'post.audit.result': 'Post moderation',
      'coupon.verified': 'Voucher redeemed',
      'review.hidden': 'Review update',
      'topic.update': 'Topic update',
      'social.mention': 'Mention',
      'review.like': 'Review liked',
      'review.comment': 'Review comment',
      'review.comment.reply': 'Comment reply',
      'review.reply': 'Merchant reply',
      'post.comment': 'Post comment',
      'post.comment.reply': 'Post comment reply',
      'post.like': 'Post liked',
      'post.repost': 'Post reposted',
      'social.follow': 'New follower',
    },
  },
  session: {
    login: 'Sign in / Register',
    userFallback: 'Signed-in user',
    userInitial: 'U',
    logout: 'Sign out',
    loggingOut: 'Signing out...',
  },
  defaultRoute: {
    title: 'Local Reviews (Demo)',
    description: 'Browse places, reviews, offers and local community content.',
  },
  routes: {
    home: { title: 'Home', description: 'Browse local recommendations, featured places and city channels.' },
    'shop-list': { title: 'Places', description: 'Filter local places by city, category and area.' },
    'rank-list': { title: 'City rankings', description: 'Browse must-try, top-rated and trending city rankings.' },
    'activity-list': { title: 'Activities', description: 'Browse active campaigns and regional collections.' },
    'activity-detail': { title: 'Activity details', description: 'View campaign details and linked resources.' },
    community: { title: 'Community', description: 'Browse local guides, reviews and practical community posts.' },
    'community-post': { title: 'Community post', description: 'Read a public community post and its comments.' },
    'circle-list': { title: 'Official groups', description: 'Browse official community groups in the current region.' },
    'circle-detail': { title: 'Group details', description: 'View group information and public posts.' },
    'topic-list': { title: 'Topics', description: 'Browse recommended topics and the seven-day trending list.' },
    'topic-detail': { title: 'Topic details', description: 'View topic activity and public community posts.' },
    'rank-detail': { title: 'Ranking details', description: 'View the published ranking, places and selection notes.' },
    'shop-detail': { title: 'Place details', description: 'View place information, photos, dishes and public reviews.' },
    'deal-detail': { title: 'Offer details', description: 'View an offer, validity dates and usage rules before ordering.' },
    'reservation-create': { title: 'Book a table', description: 'Check available time slots and submit a booking.' },
    'shop-reviews': { title: 'Place reviews', description: 'Browse public reviews, ratings and interactions.' },
    'review-create': { title: 'Write a review', description: 'Submit ratings, text, tags and photos.' },
    'review-detail': { title: 'Review details', description: 'View a public review, photos and interactions.' },
    'review-edit': { title: 'Edit review', description: 'Edit your review and resubmit it for moderation.' },
    'my-reviews': { title: 'My reviews', description: 'Manage your reviews and moderation status.' },
    'user-notifications': { title: 'Notifications', description: 'View notifications and mark them as read.' },
    'user-favorites': { title: 'Saved', description: 'View and manage saved places and posts.' },
    'user-browse-history': { title: 'Browse history', description: 'View and manage recently visited places.' },
    'user-orders': { title: 'Orders', description: 'View offer orders, payment and refund status.' },
    'user-order-detail': { title: 'Order details', description: 'View order, payment and voucher information.' },
    'user-coupons': { title: 'Vouchers', description: 'View available, used, expired and refunded vouchers.' },
    'user-coupon-detail': { title: 'Voucher details', description: 'View voucher status, rules and redemption code.' },
    'user-reservations': { title: 'Bookings', description: 'View booking status and rescheduling history.' },
    'user-reservation-detail': { title: 'Booking details', description: 'View, cancel or reschedule a booking.' },
    'my-review-detail': { title: 'My review details', description: 'View your review, moderation status and feedback.' },
    'user-profile': { title: 'Profile', description: 'Manage your profile, linked accounts and password.' },
    'user-check-in': { title: 'Daily check-in', description: 'Complete today\'s check-in and review your streak and rewards.' },
    'user-growth-records': { title: 'Rewards activity', description: 'View growth and points activity.' },
    'user-privacy': { title: 'Privacy centre', description: 'Export personal data and manage account deletion.' },
    'public-user-profile': { title: 'User profile', description: 'View a public profile and review summary.' },
    'public-user-followers': { title: 'Followers', description: 'View a public follower list.' },
    'public-user-following': { title: 'Following', description: 'View a public following list.' },
  },
}

const STRINGS: Record<WebLocaleTag, WebStrings> = {
  'zh-CN': zhCnStrings,
  en: enStrings,
}

export function localeForRegion(region: Region): WebLocaleTag {
  return region === 'EU' ? 'en' : 'zh-CN'
}

export function webStringsForRegion(region: Region): WebStrings {
  return STRINGS[localeForRegion(region)]
}

export function webRouteMetaForName(region: Region, name: unknown): RouteMetaText {
  const strings = webStringsForRegion(region)
  return strings.routes[String(name ?? '')] ?? strings.defaultRoute
}

export function applyWebDocumentMeta(region: Region, name: unknown) {
  const strings = webStringsForRegion(region)
  const meta = webRouteMetaForName(region, name)
  document.documentElement.lang = strings.tag
  document.title = `${meta.title} | ${strings.brand.title}`
  let descriptionTag = document.querySelector('meta[name="description"]')
  if (!descriptionTag) {
    descriptionTag = document.createElement('meta')
    descriptionTag.setAttribute('name', 'description')
    document.head.appendChild(descriptionTag)
  }
  descriptionTag.setAttribute('content', meta.description)
}

export function formatWebDateTime(raw: string, locale: WebLocaleTag) {
  const match = raw.trim().match(
    /^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2}))?/,
  )
  if (!match) return raw
  const [, year, month, day, hour = '00', minute = '00'] = match
  return locale === 'en'
    ? `${day}/${month}/${year} ${hour}:${minute}`
    : `${year}/${Number(month)}/${Number(day)} ${hour}:${minute}`
}
