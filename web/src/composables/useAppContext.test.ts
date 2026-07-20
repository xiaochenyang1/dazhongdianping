import { beforeEach, describe, expect, it, vi } from 'vitest'

describe('PC app region context', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.resetModules()
  })

  it('restores a persisted EU region and exposes a region setter', async () => {
    localStorage.setItem('dzdp:region', 'EU')

    const { useAppContext } = await import('./useAppContext')
    const appContext = useAppContext()

    expect(appContext.state.region).toBe('EU')
    expect(typeof appContext.setRegion).toBe('function')
  })

  it('falls back to CN for unknown persisted values', async () => {
    localStorage.setItem('dzdp:region', 'US')

    const { useAppContext } = await import('./useAppContext')

    expect(useAppContext().state.region).toBe('CN')
  })
})
