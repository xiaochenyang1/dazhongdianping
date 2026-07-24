export type Region = 'CN' | 'EU'

export interface ActivitySummary {
  id: number
  name: string
  code: string
  region: Region
  cityId: number
  cityName: string
  channel: number
  channelText: string
  type: number
  typeText: string
  cover: string
  landingUrl: string
  startAt: string
  endAt: string
  itemCount: number
}

export interface ActivityItem {
  id: number
  activityId: number
  targetType: number
  targetTypeText: string
  targetId: number
  targetName: string
  title: string
  subtitle: string
  image: string
  sort: number
  extra: Record<string, unknown>
  linkUrl: string
}

export interface ActivityDetail {
  id: number
  name: string
  code: string
  region: Region
  cityId: number
  cityName: string
  channel: number
  channelText: string
  type: number
  typeText: string
  cover: string
  landingUrl: string
  rule: Record<string, unknown>
  startAt: string
  endAt: string
  items: ActivityItem[]
}
