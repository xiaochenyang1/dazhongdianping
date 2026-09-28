import type { Region } from '@/types/browse'

export interface WebGuideStrings {
  eyebrow: string
  title: string
  summary: string
  loading: string
  empty: string
  loadFailed: string
  open: string
  shop: string
}

const zh: WebGuideStrings = {
  eyebrow: '攻略',
  title: '本地生活攻略',
  summary: '按城市整理的探店专题，只展示已发布内容。',
  loading: '加载中...',
  empty: '当前区域还没有已发布攻略。',
  loadFailed: '攻略加载失败',
  open: '查看',
  shop: '相关门店',
}

const en: WebGuideStrings = {
  eyebrow: 'Guides',
  title: 'Local guides',
  summary: 'Published city guides only.',
  loading: 'Loading...',
  empty: 'No published guides in this region.',
  loadFailed: 'Could not load guides',
  open: 'Open',
  shop: 'Place',
}

export function guideStringsForRegion(region: Region) {
  return region === 'EU' ? en : zh
}
