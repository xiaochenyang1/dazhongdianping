import type { Region } from '@/types/browse'
import type { WebLocaleTag } from '@/core/web_localizations'

export interface WebCollectionStrings {
  tag: WebLocaleTag
  favorites: {
    loadFailed: string
    removeFailed: string
    emptyAll: string
    emptyShop: string
    emptyPost: string
    viewPost: string
    viewShop: string
    post: string
    averageSpend: string
    postRemoved: string
    shopRemoved: string
    eyebrow: string
    title: string
    summary: string
    filterAria: string
    all: string
    shops: string
    posts: string
    loading: string
    savedAt: string
    remove: string
  }
  history: {
    loadFailed: string
    removeFailed: string
    clearFailed: string
    removed: string
    cleared: string
    clearConfirm: string
    eyebrow: string
    title: string
    summary: string
    clear: string
    loading: string
    empty: string
    averageSpend: string
    viewed: (count: number) => string
    latest: string
    revisit: string
    remove: string
  }
  errorTranslations: Record<string, string>
}

const zhCnStrings: WebCollectionStrings = {
  tag: 'zh-CN',
  favorites: {
    loadFailed: '收藏加载失败',
    removeFailed: '取消收藏失败',
    emptyAll: '当前区域还没有收藏内容。',
    emptyShop: '当前区域还没有收藏门店。',
    emptyPost: '当前区域还没有收藏帖子。可在 APP 收藏后回来查看。',
    viewPost: '查看帖子',
    viewShop: '查看门店',
    post: '帖子',
    averageSpend: '人均',
    postRemoved: '已取消帖子收藏',
    shopRemoved: '已取消门店收藏',
    eyebrow: '我的收藏',
    title: '真喜欢的店和帖子都留在这儿。',
    summary: '收藏按当前区域隔离；门店可在 PC 收藏，帖子可在 APP 收藏后回这里查看。',
    filterAria: '收藏类型',
    all: '全部',
    shops: '门店',
    posts: '帖子',
    loading: '收藏加载中...',
    savedAt: '收藏于',
    remove: '取消收藏',
  },
  history: {
    loadFailed: '足迹加载失败',
    removeFailed: '删除失败',
    clearFailed: '清空失败',
    removed: '已移除该足迹',
    cleared: '足迹已清空',
    clearConfirm: '确认清空当前区域的浏览足迹？',
    eyebrow: '我的足迹',
    title: '最近看过的店记在这儿，方便回访。',
    summary: '仅登录用户访问门店详情时记录；按当前区域隔离，游客访问不写足迹。',
    clear: '清空足迹',
    loading: '足迹加载中...',
    empty: '当前区域还没有浏览足迹。',
    averageSpend: '人均',
    viewed: (count) => `看过 ${count} 次`,
    latest: '最近',
    revisit: '再去看看',
    remove: '移除',
  },
  errorTranslations: {},
}

const enStrings: WebCollectionStrings = {
  tag: 'en',
  favorites: {
    loadFailed: 'Could not load saved items',
    removeFailed: 'Could not remove the saved item',
    emptyAll: 'No saved items in this region yet.',
    emptyShop: 'No saved places in this region yet.',
    emptyPost: 'No saved posts in this region yet. Save posts in the app to see them here.',
    viewPost: 'View post',
    viewShop: 'View place',
    post: 'Post',
    averageSpend: 'Average spend',
    postRemoved: 'Post removed from saved items',
    shopRemoved: 'Place removed from saved items',
    eyebrow: 'Saved items',
    title: 'Keep your favourite places and posts close at hand.',
    summary: 'Saved items are separated by region. Save places here or posts in the app.',
    filterAria: 'Saved item type',
    all: 'All',
    shops: 'Places',
    posts: 'Posts',
    loading: 'Loading saved items...',
    savedAt: 'Saved',
    remove: 'Remove',
  },
  history: {
    loadFailed: 'Could not load browsing history',
    removeFailed: 'Could not remove this visit',
    clearFailed: 'Could not clear browsing history',
    removed: 'Visit removed',
    cleared: 'Browsing history cleared',
    clearConfirm: 'Clear browsing history for this region?',
    eyebrow: 'Browsing history',
    title: 'Return to places you recently viewed.',
    summary: 'Visits are recorded for signed-in users and kept separate by region.',
    clear: 'Clear history',
    loading: 'Loading browsing history...',
    empty: 'No browsing history in this region yet.',
    averageSpend: 'Average spend',
    viewed: (count) => `Viewed ${count} ${count === 1 ? 'time' : 'times'}`,
    latest: 'Latest',
    revisit: 'View again',
    remove: 'Remove',
  },
  errorTranslations: {
    '用户登录状态不存在': 'Your session has expired. Sign in again.',
    '收藏记录不存在': 'This saved item no longer exists.',
    '浏览足迹不存在': 'This browsing history item no longer exists.',
  },
}

const STRINGS: Record<Region, WebCollectionStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function collectionStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebCollectionError(strings: WebCollectionStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const localized = strings.errorTranslations[error.message.trim()]
  if (localized) return localized
  return HAN_TEXT.test(error.message) ? fallback : error.message || fallback
}
