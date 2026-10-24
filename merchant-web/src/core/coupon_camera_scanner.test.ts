import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { CameraScanError, cameraScanError, CouponCameraError, CouponCameraScanner, normalizeScannedCoupon } from './coupon_camera_scanner'
import fixture from './fixtures/coupon_qr.json'

function couponFrame(): ImageData {
  const scale = 6
  const size = fixture.rows.length * scale
  const data = new Uint8ClampedArray(size * size * 4)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const index = (y * size + x) * 4
      const color = fixture.rows[Math.floor(y / scale)][Math.floor(x / scale)] === '1' ? 0 : 255
      data.set([color, color, color, 255], index)
    }
  }
  return { data, width: size, height: size } as ImageData
}

describe('CouponCameraScanner', () => {
  const track = { stop: vi.fn() }
  const stream = { getTracks: () => [track] } as unknown as MediaStream
  const getUserMedia = vi.fn()
  let scanner: CouponCameraScanner | null = null

  beforeEach(() => {
    vi.useFakeTimers()
    track.stop.mockReset()
    getUserMedia.mockReset().mockResolvedValue(stream)
    vi.stubGlobal('isSecureContext', true)
    vi.stubGlobal('navigator', { mediaDevices: { getUserMedia } })
    vi.spyOn(HTMLMediaElement.prototype, 'play').mockResolvedValue()
    vi.spyOn(HTMLMediaElement.prototype, 'pause').mockImplementation(() => {})
  })

  afterEach(() => {
    scanner?.stop()
    scanner = null
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
    vi.useRealTimers()
  })

  it('decodes a QR produced with the backend ZXing format and closes the camera after one result', async () => {
    const frame = couponFrame()
    const video = document.createElement('video')
    Object.defineProperties(video, {
      readyState: { value: 2 }, videoWidth: { value: frame.width }, videoHeight: { value: frame.height },
    })
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue({
      drawImage: vi.fn(), getImageData: () => frame,
    } as unknown as CanvasRenderingContext2D)
    const payload = vi.fn()
    const error = vi.fn()
    scanner = new CouponCameraScanner(video, payload, error)
    await scanner.start()
    expect(getUserMedia).toHaveBeenCalledWith(expect.objectContaining({ audio: false, video: expect.any(Object) }))
    await vi.advanceTimersByTimeAsync(201)
    await vi.dynamicImportSettled()
    expect(payload).toHaveBeenCalledOnce()
    expect(payload).toHaveBeenCalledWith(fixture.payload)
    expect(error).not.toHaveBeenCalled()
    expect(track.stop).toHaveBeenCalledOnce()
    expect(video.srcObject).toBeNull()
    await vi.advanceTimersByTimeAsync(1000)
    expect(payload).toHaveBeenCalledOnce()
  })

  it('releases a stream granted after stop without reopening the camera', async () => {
    let grant!: (stream: MediaStream) => void
    getUserMedia.mockImplementation(() => new Promise<MediaStream>((resolve) => { grant = resolve }))
    const video = document.createElement('video')
    scanner = new CouponCameraScanner(video, vi.fn(), vi.fn())
    const starting = scanner.start()
    scanner.stop()
    grant(stream)
    await starting
    expect(track.stop).toHaveBeenCalledOnce()
    expect(video.srcObject).toBeNull()
    expect(video.play).not.toHaveBeenCalled()
  })

  it('releases the stream when video playback fails', async () => {
    vi.mocked(HTMLMediaElement.prototype.play).mockRejectedValue(new Error('synthetic playback failure'))
    const video = document.createElement('video')
    scanner = new CouponCameraScanner(video, vi.fn(), vi.fn())
    await expect(scanner.start()).rejects.toThrow('synthetic playback failure')
    expect(track.stop).toHaveBeenCalledOnce()
    expect(video.srcObject).toBeNull()
  })

  it('requires a secure context and available browser camera support before requesting permission', async () => {
    scanner = new CouponCameraScanner(document.createElement('video'), vi.fn(), vi.fn())
    vi.stubGlobal('isSecureContext', false)
    await expect(scanner.start()).rejects.toMatchObject({ code: 'secureContext' })
    vi.stubGlobal('isSecureContext', true)
    vi.stubGlobal('navigator', {})
    await expect(scanner.start()).rejects.toMatchObject({ code: 'unsupported' })
    expect(getUserMedia).not.toHaveBeenCalled()
  })

  it.each([
    ['NotAllowedError', 'denied'], ['NotFoundError', 'notFound'], ['NotReadableError', 'busy'], ['UnknownError', 'failed'],
  ] as const)('maps %s to useful camera feedback', (name, code) => {
    const cause = new Error('synthetic')
    cause.name = name
    expect(cameraScanError(cause)).toBe(code)
    expect(cameraScanError(new CouponCameraError(code as CameraScanError))).toBe(code)
  })

  it('accepts raw coupon codes and rejects links, control characters and oversized payloads', () => {
    expect(normalizeScannedCoupon(' CPQRACCEPTANCE001 ')).toBe('CPQRACCEPTANCE001')
    for (const payload of ['', 'https://example.invalid/coupon/CP001', 'CP 001', 'CP\n001', '<script>', 'A'.repeat(65)]) {
      expect(normalizeScannedCoupon(payload)).toBeNull()
    }
  })
})
