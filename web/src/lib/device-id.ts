const DEVICE_ID_STORAGE_KEY = 'dzdp:device-id'
const DEVICE_ID_PATTERN = /^web-[a-z0-9-]{16,60}$/

function createRandomToken() {
  if (typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID().toLowerCase()
  }

  const bytes = new Uint8Array(16)
  crypto.getRandomValues(bytes)
  return Array.from(bytes, (value) => value.toString(16).padStart(2, '0')).join('')
}

export function getBrowserDeviceId() {
  const existing = localStorage.getItem(DEVICE_ID_STORAGE_KEY)
  if (existing && DEVICE_ID_PATTERN.test(existing)) {
    return existing
  }

  const deviceId = `web-${createRandomToken()}`
  localStorage.setItem(DEVICE_ID_STORAGE_KEY, deviceId)
  return deviceId
}
