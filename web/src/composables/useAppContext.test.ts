import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

describe('PC app region context', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.resetModules()
    vi.stubEnv('VITE_DEFAULT_REGION', 'CN')
  })

  afterEach(() => vi.unstubAllEnvs())

  it('starts an EU release on EU for a new visitor', async () => {
    vi.stubEnv('VITE_DEFAULT_REGION', 'EU')
    const { useAppContext } = await import('./useAppContext')
    expect(useAppContext().state.region).toBe('EU')
  })

  it('preserves an explicit region preference across release defaults', async () => {
    vi.stubEnv('VITE_DEFAULT_REGION', 'EU')
    localStorage.setItem('dzdp:region', 'CN')
    const { useAppContext } = await import('./useAppContext')
    expect(useAppContext().state.region).toBe('CN')
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
