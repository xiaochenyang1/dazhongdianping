export type CameraScanError = 'secureContext' | 'unsupported' | 'denied' | 'notFound' | 'busy' | 'failed'

export class CouponCameraError extends Error {
  constructor(readonly code: CameraScanError) {
    super(code)
  }
}

// QR payloads are raw coupon codes, matching the backend's locally generated QR image.
export function normalizeScannedCoupon(payload: string): string | null {
  const code = payload.trim()
  return /^[A-Za-z0-9_-]{1,64}$/.test(code) ? code : null
}

export function cameraScanError(cause: unknown): CameraScanError {
  if (cause instanceof CouponCameraError) return cause.code
  const name = cause instanceof Error ? cause.name : ''
  if (name === 'NotAllowedError' || name === 'SecurityError') return 'denied'
  if (name === 'NotFoundError' || name === 'OverconstrainedError') return 'notFound'
  if (name === 'NotReadableError' || name === 'AbortError') return 'busy'
  return 'failed'
}

export class CouponCameraScanner {
  private version = 0
  private stream: MediaStream | null = null
  private timer: ReturnType<typeof setTimeout> | null = null
  private readonly canvas = document.createElement('canvas')

  constructor(
    private readonly video: HTMLVideoElement,
    private readonly onPayload: (payload: string) => void,
    private readonly onError: (cause: unknown) => void,
  ) {}

  async start(): Promise<void> {
    this.stop()
    if (!window.isSecureContext) throw new CouponCameraError('secureContext')
    if (!navigator.mediaDevices?.getUserMedia) throw new CouponCameraError('unsupported')
    const version = this.version
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: { facingMode: { ideal: 'environment' }, width: { ideal: 1280 }, height: { ideal: 720 } },
    })
    if (version !== this.version) {
      stream.getTracks().forEach((track) => track.stop())
      return
    }
    this.stream = stream
    this.video.srcObject = stream
    try {
      await this.video.play()
      if (version !== this.version) return
      this.schedule(version)
    } catch (cause) {
      if (version !== this.version) return
      this.stop()
      throw cause
    }
  }

  stop(): void {
    this.version++
    if (this.timer !== null) clearTimeout(this.timer)
    this.timer = null
    this.stream?.getTracks().forEach((track) => track.stop())
    this.stream = null
    this.video.pause()
    this.video.srcObject = null
    // Drop the last frame as soon as scanning ends. Frames stay in this browser.
    this.canvas.width = 0
    this.canvas.height = 0
  }

  private schedule(version: number): void {
    this.timer = setTimeout(() => { void this.scan(version) }, 200)
  }

  private async scan(version: number): Promise<void> {
    if (version !== this.version) return
    try {
      if (this.video.readyState >= 2 && this.video.videoWidth > 0 && this.video.videoHeight > 0) {
        const scale = Math.min(1, 720 / Math.max(this.video.videoWidth, this.video.videoHeight))
        this.canvas.width = Math.max(1, Math.round(this.video.videoWidth * scale))
        this.canvas.height = Math.max(1, Math.round(this.video.videoHeight * scale))
        const context = this.canvas.getContext('2d', { willReadFrequently: true })
        if (!context) throw new CouponCameraError('unsupported')
        context.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height)
        const frame = context.getImageData(0, 0, this.canvas.width, this.canvas.height)
        // Bundled decoder supports Safari / Firefox without sending camera frames to a service.
        const { default: decode } = await import('jsqr')
        if (version !== this.version) return
        const result = decode(frame.data, frame.width, frame.height, { inversionAttempts: 'attemptBoth' })
        if (result?.data) {
          this.stop()
          this.onPayload(result.data)
          return
        }
      }
      if (version === this.version) this.schedule(version)
    } catch (cause) {
      if (version !== this.version) return
      this.stop()
      this.onError(cause)
    }
  }
}
