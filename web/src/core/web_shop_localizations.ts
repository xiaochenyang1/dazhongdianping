import type { Region } from '@/types/browse'

export interface WebShopStrings {
  tag: 'zh-CN' | 'en'
  detail: {
    invalidId: string
    loadFailed: string
    loading: string
    score: string
    averageSpend: string
    openingStatus: string
    openNow: string
    closed: string
    writeReview: string
    allReviews: string
    myReviews: string
    removeFavorite: string
    saveFavorite: string
    share: string
    booking: string
    shareText: (name: string, city: string, score: string) => string
    shareReady: string
    shareFailed: string
    basicEyebrow: string
    basicTitle: string
    address: string
    phone: string
    hours: string
    tasteEnvService: string
    offerStatus: string
    currentOffer: string
    noOffer: string
    dishesEyebrow: string
    dishesTitle: string
    noDishes: string
    dealsEyebrow: string
    dealsTitle: string
    originalPrice: string
    sold: string
    noDeals: string
    galleryEyebrow: string
    galleryTitle: string
    galleryMissing: string
    previewEyebrow: string
    previewTitle: string
    previewViewAll: string
    likes: string
    comments: string
    viewDetails: string
    noReviews: string
    nearbyEyebrow: string
    nearbyTitle: string
    seoTitle: string
    seoDescription: string
    seoDescriptionFor: (summary: string, address: string) => string
  }
  reviews: {
    invalidId: string
    loadFailed: string
    moreLoadFailed: string
    loading: string
    loaded: string
    moreAvailable: (count: number) => string
    allLoaded: string
    averageSpend: string
    priceDetail: string
    perspective: string
    title: (name: string) => string
    score: string
    publicReviews: string
    backToShop: string
    writeReview: string
    support: string
    listEyebrow: string
    listTitle: string
    filterAria: string
    sort: string
    latest: string
    popular: string
    scoreSort: string
    minScore: string
    any: string
    points: (score: string) => string
    images: string
    allImages: string
    withImages: string
    withoutImages: string
    apply: string
    noReviews: string
    likes: string
    comments: string
    viewDetails: string
    loadingMore: string
    loadMore: string
  }
  errorTranslations: Record<string, string>
}

const zhCnStrings: WebShopStrings = {
  tag: 'zh-CN',
  detail: {
    invalidId: '商户 ID 不合法',
    loadFailed: '商户详情加载失败',
    loading: '详情加载中...',
    score: '综合评分',
    averageSpend: '人均',
    openingStatus: '营业状态',
    openNow: '营业中',
    closed: '休息中',
    writeReview: '写点评',
    allReviews: '全部点评',
    myReviews: '我的点评',
    removeFavorite: '取消收藏',
    saveFavorite: '收藏门店',
    share: '分享',
    booking: '在线预订',
    shareText: (name, city, score) => `${name} · ${city} · ${score} 分`,
    shareReady: '分享链接已准备好',
    shareFailed: '分享失败，请稍后重试',
    basicEyebrow: '基础信息',
    basicTitle: '先把最值钱的内容呈现出来。',
    address: '地址',
    phone: '电话',
    hours: '营业时间',
    tasteEnvService: '口味 / 环境 / 服务',
    offerStatus: '优惠状态',
    currentOffer: '当前有团购/优惠',
    noOffer: '暂无优惠',
    dishesEyebrow: '推荐菜',
    dishesTitle: '数据先走后端，后面再扩成完整菜单。',
    noDishes: '这家店暂时还没补推荐菜，先看基础信息和公开点评也够用。',
    dealsEyebrow: '团购优惠',
    dealsTitle: '套餐内容、有效期和规则都从交易域读取。',
    originalPrice: '原价',
    sold: '已售',
    noDeals: '当前门店暂无上架团购。',
    galleryEyebrow: '门店相册',
    galleryTitle: '这块已经和后端详情接口打通。',
    galleryMissing: '门店相册还没补齐，先靠点评和基础信息判断也不至于两眼一抹黑。',
    previewEyebrow: '点评预览',
    previewTitle: '公开点评已经接上了，前台现在能顺手跳去看详情。',
    previewViewAll: '全部点评',
    likes: '点赞',
    comments: '评论',
    viewDetails: '查看详情',
    noReviews: '这家店还没有公开点评，想补第一条就直接去写点评。',
    nearbyEyebrow: '附近推荐',
    nearbyTitle: '附近相似门店',
    seoTitle: '门店详情',
    seoDescription: '查看门店地址、营业时间、评分、优惠、点评与附近推荐。',
    seoDescriptionFor: (summary, address) => `${summary} 地址：${address}。`,
  },
  reviews: {
    invalidId: '商户 ID 不合法',
    loadFailed: '门店点评加载失败',
    moreLoadFailed: '更多点评加载失败',
    loading: '点评列表加载中...',
    loaded: '已加载',
    moreAvailable: (count) => `还有 ${count} 条公开点评可继续往下翻。`,
    allLoaded: '当前这批公开点评已经翻到底了。',
    averageSpend: '人均客单',
    priceDetail: '价格口径和门店详情保持一致，不额外玩花活。',
    perspective: '浏览视角',
    title: (name) => `${name}的公开点评`,
    score: '综合评分',
    publicReviews: '公开点评',
    backToShop: '回到门店',
    writeReview: '写点评',
    support: '当前按公开可见点评集中展示，想看互动细节就直接点进具体点评页。',
    listEyebrow: '点评列表',
    listTitle: '审核通过的公开点评集中放这儿，别都挤在详情页预览里。',
    filterAria: '点评筛选',
    sort: '排序',
    latest: '最新',
    popular: '最热',
    scoreSort: '评分',
    minScore: '最低评分',
    any: '不限',
    points: (score) => `${score} 分`,
    images: '图片',
    allImages: '全部',
    withImages: '带图',
    withoutImages: '无图',
    apply: '应用',
    noReviews: '这家店暂时没有公开点评。',
    likes: '点赞',
    comments: '评论',
    viewDetails: '查看详情',
    loadingMore: '加载中...',
    loadMore: '加载更多点评',
  },
  errorTranslations: {},
}

const enStrings: WebShopStrings = {
  tag: 'en',
  detail: {
    invalidId: 'The place ID is invalid',
    loadFailed: 'Could not load place details',
    loading: 'Loading place details...',
    score: 'Overall rating',
    averageSpend: 'Average',
    openingStatus: 'Opening status',
    openNow: 'Open now',
    closed: 'Closed',
    writeReview: 'Write a review',
    allReviews: 'All reviews',
    myReviews: 'My reviews',
    removeFavorite: 'Remove saved place',
    saveFavorite: 'Save place',
    share: 'Share',
    booking: 'Book online',
    shareText: (name, city, score) => `${name} · ${city} · ${score} rating`,
    shareReady: 'Share link is ready',
    shareFailed: 'Could not share this place. Please try again.',
    basicEyebrow: 'At a glance',
    basicTitle: 'The details that matter for your visit.',
    address: 'Address',
    phone: 'Phone',
    hours: 'Opening hours',
    tasteEnvService: 'Food / Ambience / Service',
    offerStatus: 'Offers',
    currentOffer: 'Offers available now',
    noOffer: 'No offers at the moment',
    dishesEyebrow: 'Recommended dishes',
    dishesTitle: 'Recommended by the place team.',
    noDishes: 'No recommended dishes have been added yet. Browse the details and public reviews instead.',
    dealsEyebrow: 'Offers',
    dealsTitle: 'See packages, validity dates and usage rules from the offers service.',
    originalPrice: 'Was',
    sold: 'sold',
    noDeals: 'No offers are currently available for this place.',
    galleryEyebrow: 'Photo gallery',
    galleryTitle: 'Photos served directly from the place profile.',
    galleryMissing: 'The gallery is not ready yet. The profile and reviews still give you a useful starting point.',
    previewEyebrow: 'Review preview',
    previewTitle: 'Read public reviews and open any one for the full conversation.',
    previewViewAll: 'All reviews',
    likes: 'likes',
    comments: 'comments',
    viewDetails: 'View details',
    noReviews: 'No public reviews yet. Be the first to write one.',
    nearbyEyebrow: 'Nearby picks',
    nearbyTitle: 'Similar places nearby',
    seoTitle: 'Place details',
    seoDescription: 'View place address, opening hours, ratings, offers, reviews and nearby recommendations.',
    seoDescriptionFor: (summary, address) => `${summary} Address: ${address}.`,
  },
  reviews: {
    invalidId: 'The place ID is invalid',
    loadFailed: 'Could not load place reviews',
    moreLoadFailed: 'Could not load more reviews',
    loading: 'Loading reviews...',
    loaded: 'Loaded',
    moreAvailable: (count) => `${count} more public reviews are available.`,
    allLoaded: 'You have reached the end of these public reviews.',
    averageSpend: 'Average spend',
    priceDetail: 'The spend range matches the place profile.',
    perspective: 'View',
    title: (name) => `Public reviews for ${name}`,
    score: 'Overall rating',
    publicReviews: 'Public reviews',
    backToShop: 'Back to place',
    writeReview: 'Write a review',
    support: 'Only public reviews are shown here. Open a review to see its full interactions.',
    listEyebrow: 'Reviews',
    listTitle: 'Approved public reviews, collected in one place.',
    filterAria: 'Review filters',
    sort: 'Sort by',
    latest: 'Latest',
    popular: 'Most liked',
    scoreSort: 'Rating',
    minScore: 'Minimum rating',
    any: 'Any',
    points: (score) => `${score} points`,
    images: 'Photos',
    allImages: 'All',
    withImages: 'With photos',
    withoutImages: 'Without photos',
    apply: 'Apply',
    noReviews: 'No public reviews for this place yet.',
    likes: 'likes',
    comments: 'comments',
    viewDetails: 'View details',
    loadingMore: 'Loading...',
    loadMore: 'Load more reviews',
  },
  errorTranslations: {
    '商户 ID 不合法': 'The place ID is invalid',
    '商户详情加载失败': 'Could not load place details',
    '门店点评加载失败': 'Could not load place reviews',
    '更多点评加载失败': 'Could not load more reviews',
  },
}

const STRINGS: Record<Region, WebShopStrings> = { CN: zhCnStrings, EU: enStrings }

export function shopStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebShopError(strings: WebShopStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const traceMatch = error.message.match(/\s*(\[traceId:\s*[^\]]+\])\s*$/)
  const trace = traceMatch?.[1]
  const message = trace ? error.message.slice(0, traceMatch.index).trim() : error.message.trim()
  const localized = strings.errorTranslations[message]
    ?? (/\p{Script=Han}/u.test(message) ? fallback : message)
  return trace ? `${localized} ${trace}` : localized
}
