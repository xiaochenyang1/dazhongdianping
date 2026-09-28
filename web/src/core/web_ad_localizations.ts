import type { Region } from '@/types/browse'

export interface WebAdStrings {
  adLabel: string
  sponsored: string
}

const STRINGS: Record<Region, WebAdStrings> = {
  CN: { adLabel: '广告', sponsored: '商家推广' },
  EU: { adLabel: 'Ad', sponsored: 'Sponsored' },
}

export function adStringsForRegion(region: Region) {
  return STRINGS[region]
}
