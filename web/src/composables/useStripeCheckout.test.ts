import { describe, expect, it, vi, beforeEach } from 'vitest'

const confirmCardPayment = vi.fn()
const mount = vi.fn()
const unmount = vi.fn()
const create = vi.fn(() => ({ mount, unmount }))
const elements = vi.fn(() => ({ create }))

vi.mock('@stripe/stripe-js', () => ({
  loadStripe: vi.fn(async () => ({ elements, confirmCardPayment })),
}))

import { useStripeCheckout } from './useStripeCheckout'

describe('useStripeCheckout', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    confirmCardPayment.mockReset()
  })

  it('mounts a card element and becomes ready', async () => {
    const checkout = useStripeCheckout('pk_test_key')
    const el = document.createElement('div')

    await checkout.mount(el, 'pi_1_secret_abc')

    expect(create).toHaveBeenCalledWith('card', expect.anything())
    expect(mount).toHaveBeenCalledWith(el)
    expect(checkout.ready.value).toBe(true)
    expect(checkout.error.value).toBe('')
  })

  it('returns true when Stripe confirms the payment', async () => {
    confirmCardPayment.mockResolvedValue({ paymentIntent: { status: 'succeeded' } })
    const checkout = useStripeCheckout('pk_test_key')
    await checkout.mount(document.createElement('div'), 'pi_1_secret_abc')

    const ok = await checkout.confirm()

    expect(ok).toBe(true)
    expect(checkout.processing.value).toBe(false)
  })

  it('surfaces the Stripe error message and returns false', async () => {
    confirmCardPayment.mockResolvedValue({ error: { message: 'Your card was declined.' } })
    const checkout = useStripeCheckout('pk_test_key')
    await checkout.mount(document.createElement('div'), 'pi_1_secret_abc')

    const ok = await checkout.confirm()

    expect(ok).toBe(false)
    expect(checkout.error.value).toBe('Your card was declined.')
    expect(checkout.processing.value).toBe(false)
  })

  it('refuses to confirm before mount', async () => {
    const checkout = useStripeCheckout('pk_test_key')

    const ok = await checkout.confirm()

    expect(ok).toBe(false)
    expect(confirmCardPayment).not.toHaveBeenCalled()
  })

  it('reports a missing publishable key instead of throwing', async () => {
    const checkout = useStripeCheckout('')

    await checkout.mount(document.createElement('div'), 'pi_1_secret_abc')

    expect(checkout.ready.value).toBe(false)
    expect(checkout.error.value).not.toBe('')
  })
})
