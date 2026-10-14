import { describe, expect, it, vi } from 'vitest'
import { createLaunchCapabilityStore, featureForPath, type LaunchCapabilities } from './useLaunchCapabilities'

describe('launch capabilities', () => {
  it('does not expose deferred features while loading or when configuration fails', async () => {
    const store = createLaunchCapabilityStore(vi.fn().mockRejectedValue(new Error('offline')))
    expect(store.values.EU.creatorRewards).toBe(false)
    const result = await store.load('EU')
    expect(result).toEqual({ region: 'EU', creatorRewards: false, seckill: false, groupBuy: false })
  })

  it('keeps late CN responses separate from EU capabilities', async () => {
    let resolveCN!: (value: LaunchCapabilities) => void
    const store = createLaunchCapabilityStore(region => region === 'CN'
      ? new Promise(resolve => { resolveCN = resolve })
      : Promise.resolve({ region: 'EU', creatorRewards: false, seckill: false, groupBuy: false }))
    const cn = store.load('CN')
    await store.load('EU')
    resolveCN({ region: 'CN', creatorRewards: true, seckill: true, groupBuy: true })
    await cn
    expect(store.values.CN.creatorRewards).toBe(true)
    expect(store.values.EU.creatorRewards).toBe(false)
  })

  it('rejects a response for a different region and permits a later retry', async () => {
    const fetcher = vi.fn()
      .mockResolvedValueOnce({ region: 'CN', creatorRewards: true, seckill: true, groupBuy: true })
      .mockResolvedValueOnce({ region: 'EU', creatorRewards: false, seckill: true, groupBuy: false })
    const store = createLaunchCapabilityStore(fetcher)
    expect((await store.load('EU')).seckill).toBe(false)
    expect((await store.load('EU')).seckill).toBe(true)
    expect(store.values.EU.creatorRewards).toBe(false)
  })

  it('checks deferred deep links without blocking ordinary vouchers and bookings', () => {
    expect(featureForPath('/user/creator')).toBe('creatorRewards')
    expect(featureForPath('/marketing/seckill/12')).toBe('seckill')
    expect(featureForPath('/marketing/groupbuy')).toBe('groupBuy')
    expect(featureForPath('/user/reservations')).toBeUndefined()
    expect(featureForPath('/user/coupons')).toBeUndefined()
  })
})
