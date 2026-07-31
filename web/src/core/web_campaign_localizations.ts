import type { Region } from '@/types/browse'

export interface WebCampaignStrings {
  tag: 'zh-CN' | 'en'
  rank: {
    listLoadFailed: string
    detailLoadFailed: string
    eyebrow: string
    title: string
    summary: (region: Region) => string
    all: string
    typeLabel: (type: number, fallback?: string) => string
    loading: string
    empty: string
    leader: string
    placeCount: (count: number) => string
    updated: string
    detailLoading: string
    back: string
    averageSpend: string
  }
  activity: {
    listLoadFailed: string
    detailLoadFailed: string
    eyebrow: string
    title: string
    summary: (region: Region) => string
    allChannels: string
    channelLabel: (channel: number, fallback?: string) => string
    typeLabel: (type: number, fallback?: string) => string
    targetLabel: (type: number, fallback?: string) => string
    loading: string
    empty: string
    resourceCount: (count: number) => string
    noStart: string
    noEnd: string
    detailLoading: string
    back: string
    code: string
    availableItems: (count: number) => string
    landing: string
    noItems: string
    openExternal: string
    viewTarget: (target: string) => string
    noLink: string
  }
  errorTranslations: Record<string, string>
}

const zhCnStrings: WebCampaignStrings = {
  tag: 'zh-CN',
  rank: {
    listLoadFailed: '榜单加载失败',
    detailLoadFailed: '榜单详情加载失败',
    eyebrow: '城市榜单',
    title: '榜单看的是发布快照，不拿实时 SQL 临场发挥。',
    summary: (region) => `当前区域 ${region}，每一份排名都能追到规则版本和榜单周期。`,
    all: '全部',
    typeLabel: (type, fallback = '') => ({ 1: '必吃榜', 2: '好评榜', 3: '热门榜' } as Record<number, string>)[type] ?? fallback,
    loading: '榜单快照加载中...',
    empty: '当前城市还没有已发布榜单。',
    leader: '榜首',
    placeCount: (count) => `共 ${count} 家`,
    updated: '更新',
    detailLoading: '榜单详情加载中...',
    back: '返回榜单',
    averageSpend: '人均',
  },
  activity: {
    listLoadFailed: '活动列表加载失败',
    detailLoadFailed: '活动详情加载失败',
    eyebrow: '运营活动',
    title: '管理端配好的专题，终于能直接在 C 端被点开。',
    summary: (region) => `当前区域 ${region} · 只展示状态为“上线中”且在有效期内的活动。`,
    allChannels: '全部频道',
    channelLabel: (channel, fallback = '') => ({ 1: '首页', 2: '搜索', 3: '频道', 4: '活动页', 5: '社区' } as Record<number, string>)[channel] ?? fallback,
    typeLabel: (type, fallback = '') => ({ 1: '专题活动', 2: '节日活动', 3: '新客活动', 4: '商户扶持', 5: '内容话题' } as Record<number, string>)[type] ?? fallback,
    targetLabel: (type, fallback = '') => ({ 1: '店铺', 2: '团购', 3: '帖子', 4: '榜单', 5: '话题', 6: '外链' } as Record<number, string>)[type] ?? fallback,
    loading: '活动加载中...',
    empty: '当前城市暂时没有上线活动。',
    resourceCount: (count) => `${count} 个资源`,
    noStart: '不限开始',
    noEnd: '不限结束',
    detailLoading: '活动详情加载中...',
    back: '返回活动列表',
    code: '活动编码',
    availableItems: (count) => `当前共 ${count} 个可用资源项。`,
    landing: '落地配置',
    noItems: '这个活动还没有启用中的资源项。',
    openExternal: '打开外链',
    viewTarget: (target) => `查看${target}`,
    noLink: '暂无可用跳转',
  },
  errorTranslations: {},
}

const enStrings: WebCampaignStrings = {
  tag: 'en',
  rank: {
    listLoadFailed: 'Could not load city rankings',
    detailLoadFailed: 'Could not load ranking details',
    eyebrow: 'City rankings',
    title: 'Published city lists with a clear ranking period and methodology.',
    summary: (region) => `Showing published rankings for the ${region} region.`,
    all: 'All',
    typeLabel: (type, fallback = '') => ({ 1: 'Must-try', 2: 'Top rated', 3: 'Trending' } as Record<number, string>)[type] ?? fallback,
    loading: 'Loading ranking snapshots...',
    empty: 'There are no published rankings for this city yet.',
    leader: 'No. 1',
    placeCount: (count) => `${count} ${count === 1 ? 'place' : 'places'}`,
    updated: 'Updated',
    detailLoading: 'Loading ranking details...',
    back: 'Back to rankings',
    averageSpend: 'Average',
  },
  activity: {
    listLoadFailed: 'Could not load activities',
    detailLoadFailed: 'Could not load activity details',
    eyebrow: 'Activities',
    title: 'Current collections, campaigns and local guides.',
    summary: (region) => `Showing live activities in the ${region} region and their valid dates.`,
    allChannels: 'All channels',
    channelLabel: (channel, fallback = '') => ({ 1: 'Home', 2: 'Search', 3: 'Channel', 4: 'Activities', 5: 'Community' } as Record<number, string>)[channel] ?? fallback,
    typeLabel: (type, fallback = '') => ({ 1: 'Featured collection', 2: 'Seasonal campaign', 3: 'New customer offer', 4: 'Merchant spotlight', 5: 'Community topic' } as Record<number, string>)[type] ?? fallback,
    targetLabel: (type, fallback = '') => ({ 1: 'Place', 2: 'Offer', 3: 'Post', 4: 'Ranking', 5: 'Topic', 6: 'External link' } as Record<number, string>)[type] ?? fallback,
    loading: 'Loading activities...',
    empty: 'There are no live activities for this city right now.',
    resourceCount: (count) => `${count} ${count === 1 ? 'item' : 'items'}`,
    noStart: 'No start limit',
    noEnd: 'No end limit',
    detailLoading: 'Loading activity details...',
    back: 'Back to activities',
    code: 'Activity code',
    availableItems: (count) => `${count} active ${count === 1 ? 'item' : 'items'}.`,
    landing: 'Landing configuration',
    noItems: 'This activity does not have any active items yet.',
    openExternal: 'Open external link',
    viewTarget: (target) => `View ${target.toLocaleLowerCase('en')}`,
    noLink: 'No destination available',
  },
  errorTranslations: {
    '榜单加载失败': 'Could not load city rankings',
    '榜单详情加载失败': 'Could not load ranking details',
    '活动列表加载失败': 'Could not load activities',
    '活动详情加载失败': 'Could not load activity details',
  },
}

const STRINGS: Record<Region, WebCampaignStrings> = { CN: zhCnStrings, EU: enStrings }

export function campaignStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebCampaignError(strings: WebCampaignStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const message = error.message.trim()
  return strings.errorTranslations[message] ?? (/\p{Script=Han}/u.test(message) ? fallback : message)
}
