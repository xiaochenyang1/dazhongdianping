import { beforeEach, describe, expect, it } from 'vitest'
import { getBrowserDeviceId } from './device-id'

describe('getBrowserDeviceId', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('creates one browser-specific id and reuses it across calls', () => {
    const first = getBrowserDeviceId()
    const second = getBrowserDeviceId()

    expect(first).toMatch(/^web-[a-z0-9-]{16,}$/)
    expect(second).toBe(first)
    expect(localStorage.getItem('dzdp:device-id')).toBe(first)
  })

  it('reuses a valid id saved by an earlier browser session', () => {
    localStorage.setItem('dzdp:device-id', 'web-existing-browser-1234')

    expect(getBrowserDeviceId()).toBe('web-existing-browser-1234')
  })
})
