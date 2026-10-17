import { computed, reactive } from 'vue'
import { apiGet } from '@/lib/http'
import { useAppContext } from '@/composables/useAppContext'
import type { Region } from '@/types/browse'

export type LaunchFeature = 'creatorRewards' | 'seckill' | 'groupBuy'
export interface LaunchCapabilities extends Record<LaunchFeature, boolean> { region: Region }

const disabled = (region: Region): LaunchCapabilities => ({
  region, creatorRewards: false, seckill: false, groupBuy: false,
})

export function featureForPath(path: string): LaunchFeature | undefined {
  if (/^\/user\/creator(?:\/|$)/.test(path)) return 'creatorRewards'
  if (/^\/marketing\/seckill(?:\/|$)/.test(path)) return 'seckill'
  if (/^\/marketing\/groupbuy(?:\/|$)/.test(path)) return 'groupBuy'
  return undefined
}

export function createLaunchCapabilityStore(fetcher: (region: Region) => Promise<LaunchCapabilities>) {
  const values = reactive({ CN: disabled('CN'), EU: disabled('EU') })
  const pending = new Map<Region, Promise<LaunchCapabilities>>()

  function load(region: Region): Promise<LaunchCapabilities> {
    const running = pending.get(region)
    if (running) return running
    values[region] = disabled(region)
    const request = (async () => {
      try {
        const response = await Promise.resolve().then(() => fetcher(region))
        if (response.region !== region) throw new Error('Launch region mismatch')
        values[region] = {
          region,
          creatorRewards: response.creatorRewards === true,
          seckill: response.seckill === true,
          groupBuy: response.groupBuy === true,
        }
      } catch {
        values[region] = disabled(region)
      } finally {
        pending.delete(region)
      }
      return values[region]
    })()
    pending.set(region, request)
    return request
  }

  return { values, load }
}

const store = createLaunchCapabilityStore(region =>
  apiGet<LaunchCapabilities>('/api/c/v1/launch-config', undefined, { 'X-Region': region }),
)

export const loadLaunchCapabilities = store.load

export function useLaunchCapabilities() {
  const { state } = useAppContext()
  return { capabilities: computed(() => store.values[state.region]), load: store.load }
}
