import type { PageResult } from './browse'

export interface GuideSection {
  id: number
  heading: string
  body: string
  shopId: number
  sortNo: number
}

export interface GuideArticle {
  id: number
  cityId: number
  title: string
  summary: string
  coverUrl: string
  status: number
  createdAt?: string
  sections?: GuideSection[]
}

export type GuidePage = PageResult<GuideArticle>
