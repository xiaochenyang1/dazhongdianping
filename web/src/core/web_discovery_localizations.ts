import type { Region } from '@/types/browse'
import { formatEnglishCount, isSingularEnglishCount } from './web_count_localizations'

type SortKey = 'smart' | 'score' | 'popular' | 'distance'

export interface WebDiscoveryStrings {
  tag: 'zh-CN' | 'en'
  home: {
    loadFailed: string
    contentLoadFailed: string
    heroEyebrow: string
    heroTitle: string
    currentRegion: string
    currentCity: string
    browsePlaces: string
    switchCity: string
    regionHeader: string
    pageStatus: string
    loading: string
    browsable: string
    bannersEyebrow: string
    bannersTitle: string
    viewDestination: string
    activitiesEyebrow: string
    activitiesTitle: string
    viewAllActivities: string
    resourceCount: (count: number) => string
    categoriesEyebrow: string
    categoriesTitle: string
    feedEyebrow: string
    feedTitle: string
    viewMorePlaces: string
    viewDetails: string
    activityType: (type: number, fallback: string) => string
    activityChannel: (channel: number, fallback: string) => string
  }
  shopList: {
    loadFailed: string
    areasLoadFailed: string
    geolocationUnsupported: string
    geolocationFailed: string
    unselectedCity: string
    sorts: Record<SortKey, string>
    regionTag: (region: Region) => string
    keywordTag: (keyword: string) => string
    priceTag: (min: string, max: string) => string
    scoreTag: (score: string) => string
    hasDealTag: string
    noDealTag: string
    openTag: string
    closedTag: string
    factMatches: string
    factCity: string
    factFilters: string
    loading: string
    partialResults: (count: number) => string
    allResults: (count: number) => string
    areaScope: (area: string) => string
    cityScope: string
    defaultBrowse: string
    contextCount: (count: number) => string
    moreResults: string
    resultsComplete: string
    filtersEyebrow: string
    filtersTitle: string
    filtersSupport: (region: Region, city: string) => string
    keywordLabel: string
    keywordPlaceholder: string
    cityLabel: string
    areaLabel: string
    allAreas: string
    categoryLabel: string
    allCategories: string
    sortLabel: string
    minPriceLabel: string
    maxPriceLabel: string
    minScoreLabel: string
    any: string
    dealLabel: string
    hasDeal: string
    noDeal: string
    openStatusLabel: string
    openNow: string
    closed: string
    applyFilters: string
    reset: string
    resultsEyebrow: string
    resultsTitle: (region: Region) => string
    resultsSupport: string
    backHome: string
    loadingResults: string
    emptyResults: string
    loadingMore: string
    loadMore: string
  }
  shopCard: {
    averageSpend: string
    openNow: string
    closed: string
    dealAvailable: string
    distanceFromYou: (distance: string) => string
    certificationLabel: (code: string, fallback: string) => string
  }
  errorTranslations: Record<string, string>
}

const zhCnStrings: WebDiscoveryStrings = {
  tag: 'zh-CN',
  home: {
    loadFailed: '首页加载失败',
    contentLoadFailed: '首页内容加载失败',
    heroEyebrow: 'M1 骨架已接后端公开浏览接口',
    heroTitle: '先把首页、列表、详情跑通，别上来就做一锅大乱炖。',
    currentRegion: '当前区域',
    currentCity: '当前城市',
    browsePlaces: '去看商户列表',
    switchCity: '切换城市',
    regionHeader: '区域头',
    pageStatus: '首页状态',
    loading: '加载中',
    browsable: '可浏览',
    bannersEyebrow: '首页 Banner',
    bannersTitle: '运营位先接实数据，不搞假按钮糊人。',
    viewDestination: '查看落点',
    activitiesEyebrow: '运营活动',
    activitiesTitle: '管理端上线的专题，首页直接透出。',
    viewAllActivities: '查看全部活动',
    resourceCount: (count) => `${count} 个资源`,
    categoriesEyebrow: '分类导航',
    categoriesTitle: '分类树已经按区域从后端拿回来了。',
    feedEyebrow: '推荐 Feed',
    feedTitle: '这个列表已经和后端示例数据通了，后面再慢慢换真运营配置。',
    viewMorePlaces: '去列表页看更多',
    viewDetails: '查看详情',
    activityType: (_type, fallback) => fallback,
    activityChannel: (_channel, fallback) => fallback,
  },
  shopList: {
    loadFailed: '商户列表加载失败',
    areasLoadFailed: '商圈加载失败',
    geolocationUnsupported: '当前浏览器不支持定位，无法按距离排序。',
    geolocationFailed: '定位未授权或获取失败，无法按距离排序。',
    unselectedCity: '未选城市',
    sorts: {
      smart: '智能排序',
      score: '评分优先',
      popular: '热门优先',
      distance: '距离优先',
    },
    regionTag: (region) => `区域 ${region}`,
    keywordTag: (keyword) => `关键词 ${keyword}`,
    priceTag: (min, max) => `人均 ${min} - ${max}`,
    scoreTag: (score) => `评分 >= ${score}`,
    hasDealTag: '有团购',
    noDealTag: '无团购',
    openTag: '营业中',
    closedTag: '休息中',
    factMatches: '当前命中',
    factCity: '当前城市',
    factFilters: '筛选状态',
    loading: '加载中',
    partialResults: (count) => `当前只先摊开 ${count} 家，别一口气把列表灌满。`,
    allResults: (count) => `这轮返回的 ${count} 家门店已经全部展示完。`,
    areaScope: (area) => `当前已经收进 ${area} 商圈。`,
    cityScope: '当前先按整座城市控制搜索范围。',
    defaultBrowse: '默认浏览',
    contextCount: (count) => `${count} 条上下文`,
    moreResults: '后端还有更多结果，继续细筛会更利索。',
    resultsComplete: '当前结果已经收口，再换条件看更直接。',
    filtersEyebrow: '筛选区',
    filtersTitle: '先把最小可用的列表过滤闭环跑通。',
    filtersSupport: (region, city) => `当前会话会带着 ${region} 区域和 ${city} 城市一起筛，先把串区这种低级错误堵死。`,
    keywordLabel: '关键词',
    keywordPlaceholder: '店名、标签、地址',
    cityLabel: '城市',
    areaLabel: '商圈',
    allAreas: '全部商圈',
    categoryLabel: '一级分类',
    allCategories: '全部分类',
    sortLabel: '排序',
    minPriceLabel: '最低人均',
    maxPriceLabel: '最高人均',
    minScoreLabel: '最低评分',
    any: '不限',
    dealLabel: '团购',
    hasDeal: '有团购',
    noDeal: '无团购',
    openStatusLabel: '营业状态',
    openNow: '营业中',
    closed: '休息中',
    applyFilters: '应用筛选',
    reset: '重置',
    resultsEyebrow: '商户列表',
    resultsTitle: (region) => `当前区域 ${region}，先把可浏览链路做扎实。`,
    resultsSupport: '头部搜索、列表筛选和区域切换现在共用同一套查询上下文，不再让结果一会儿东一会儿西。',
    backHome: '返回首页',
    loadingResults: '正在拉取商户列表...',
    emptyResults: '当前筛选下没有数据，先别怀疑人生，改个条件试试。',
    loadingMore: '加载中...',
    loadMore: '加载更多门店',
  },
  shopCard: {
    averageSpend: '人均',
    openNow: '营业中',
    closed: '休息中',
    dealAvailable: '有团购',
    distanceFromYou: (distance) => `距你 ${distance}`,
    certificationLabel: (_code, fallback) => fallback,
  },
  errorTranslations: {},
}

const enStrings: WebDiscoveryStrings = {
  tag: 'en',
  home: {
    loadFailed: 'Could not load the home page',
    contentLoadFailed: 'Could not load home content',
    heroEyebrow: 'Live discovery data from the public API',
    heroTitle: 'Discover places, collections and local favourites in one clear journey.',
    currentRegion: 'Region',
    currentCity: 'City',
    browsePlaces: 'Browse places',
    switchCity: 'Switch city',
    regionHeader: 'Request region',
    pageStatus: 'Page status',
    loading: 'Loading',
    browsable: 'Ready to browse',
    bannersEyebrow: 'Featured',
    bannersTitle: 'Live recommendations selected for your region.',
    viewDestination: 'View feature',
    activitiesEyebrow: 'Campaigns',
    activitiesTitle: 'Current collections and campaigns from the local team.',
    viewAllActivities: 'View all activities',
    resourceCount: (count) => `${count} ${count === 1 ? 'item' : 'items'}`,
    categoriesEyebrow: 'Categories',
    categoriesTitle: 'Explore categories available in this region.',
    feedEyebrow: 'Recommended for you',
    feedTitle: 'A selection of places and stories from your current city.',
    viewMorePlaces: 'View more places',
    viewDetails: 'View details',
    activityType: (type, fallback) => ({
      1: 'Featured collection',
      2: 'Seasonal campaign',
      3: 'New customer offer',
      4: 'Merchant spotlight',
      5: 'Community topic',
    }[type] ?? fallback),
    activityChannel: (channel, fallback) => ({
      1: 'Home',
      2: 'Search',
      3: 'Channel',
      4: 'Activities',
      5: 'Community',
    }[channel] ?? fallback),
  },
  shopList: {
    loadFailed: 'Could not load places',
    areasLoadFailed: 'Could not load areas',
    geolocationUnsupported: 'This browser does not support location, so distance sorting is unavailable.',
    geolocationFailed: 'Location access was denied or unavailable, so distance sorting is unavailable.',
    unselectedCity: 'No city selected',
    sorts: {
      smart: 'Recommended',
      score: 'Highest rated',
      popular: 'Most popular',
      distance: 'Nearest first',
    },
    regionTag: (region) => `Region ${region}`,
    keywordTag: (keyword) => `Search: ${keyword}`,
    priceTag: (min, max) => `Average spend ${min} - ${max}`,
    scoreTag: (score) => `Rating ≥ ${score}`,
    hasDealTag: 'Offers available',
    noDealTag: 'No offers',
    openTag: 'Open now',
    closedTag: 'Closed',
    factMatches: 'Matches',
    factCity: 'City',
    factFilters: 'Filters',
    loading: 'Loading',
    partialResults: (count) => `Showing ${formatEnglishCount(count, 'place')}. Refine the filters to narrow the list.`,
    allResults: (count) => `${formatEnglishCount(count, 'matching place')} ${isSingularEnglishCount(count) ? 'is' : 'are'} shown.`,
    areaScope: (area) => `Search limited to ${area}.`,
    cityScope: 'Search currently covers the whole city.',
    defaultBrowse: 'Default view',
    contextCount: (count) => formatEnglishCount(count, 'active filter'),
    moreResults: 'More results are available. Refine the filters or load the next page.',
    resultsComplete: 'You have reached the end of these results.',
    filtersEyebrow: 'Filters',
    filtersTitle: 'Find the right place for this visit.',
    filtersSupport: (region, city) => `Results stay scoped to the ${region} region and ${city}.`,
    keywordLabel: 'Keyword',
    keywordPlaceholder: 'Name, tag or address',
    cityLabel: 'City',
    areaLabel: 'Area',
    allAreas: 'All areas',
    categoryLabel: 'Category',
    allCategories: 'All categories',
    sortLabel: 'Sort by',
    minPriceLabel: 'Minimum spend',
    maxPriceLabel: 'Maximum spend',
    minScoreLabel: 'Minimum rating',
    any: 'Any',
    dealLabel: 'Offers',
    hasDeal: 'Offers available',
    noDeal: 'No offers',
    openStatusLabel: 'Opening status',
    openNow: 'Open now',
    closed: 'Closed',
    applyFilters: 'Apply filters',
    reset: 'Reset',
    resultsEyebrow: 'Places',
    resultsTitle: (region) => `Places available in the ${region} region`,
    resultsSupport: 'Header search, page filters and region selection share the same search context.',
    backHome: 'Back to home',
    loadingResults: 'Loading places...',
    emptyResults: 'No places match these filters. Try broadening your search.',
    loadingMore: 'Loading...',
    loadMore: 'Load more places',
  },
  shopCard: {
    averageSpend: 'Average',
    openNow: 'Open now',
    closed: 'Closed',
    dealAvailable: 'Offer available',
    distanceFromYou: (distance) => `${distance} away`,
    certificationLabel: (code, fallback) => code === 'verified_merchant' ? 'Verified merchant' : fallback,
  },
  errorTranslations: {
    '首页加载失败': 'Could not load the home page',
    '首页内容加载失败': 'Could not load home content',
    '商户列表加载失败': 'Could not load places',
    '商圈加载失败': 'Could not load areas',
  },
}

const STRINGS: Record<Region, WebDiscoveryStrings> = {
  CN: zhCnStrings,
  EU: enStrings,
}

export function discoveryStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebDiscoveryError(
  strings: WebDiscoveryStrings,
  error: unknown,
  fallback: string,
) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const traceMatch = error.message.match(/\s*(\[traceId:\s*[^\]]+\])\s*$/)
  const trace = traceMatch?.[1]
  const message = trace ? error.message.slice(0, traceMatch.index).trim() : error.message.trim()
  const localized = strings.errorTranslations[message]
    ?? (/\p{Script=Han}/u.test(message) ? fallback : message)
  return trace ? `${localized} ${trace}` : localized
}
