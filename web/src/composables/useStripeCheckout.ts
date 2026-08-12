import { ref } from 'vue'
import { loadStripe, type Stripe, type StripeCardElement } from '@stripe/stripe-js'

export function useStripeCheckout(publishableKey: string) {
  const error = ref('')
  const processing = ref(false)
  const ready = ref(false)

  let stripe: Stripe | null = null
  let card: StripeCardElement | null = null
  let secret = ''

  async function mount(el: HTMLElement, clientSecret: string) {
    error.value = ''
    ready.value = false
    if (!publishableKey) {
      error.value = 'Stripe publishable key is not configured'
      return
    }
    try {
      stripe = await loadStripe(publishableKey)
      if (!stripe) {
        error.value = 'Stripe failed to load'
        return
      }
      secret = clientSecret
      card = stripe.elements().create('card', { hidePostalCode: true })
      card.mount(el)
      ready.value = true
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Stripe failed to load'
    }
  }

  async function confirm(): Promise<boolean> {
    if (!stripe || !card || !secret) return false
    processing.value = true
    error.value = ''
    try {
      const result = await stripe.confirmCardPayment(secret, { payment_method: { card } })
      if (result.error) {
        error.value = result.error.message || 'Card payment failed'
        return false
      }
      return result.paymentIntent?.status === 'succeeded'
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Card payment failed'
      return false
    } finally {
      processing.value = false
    }
  }

  function unmount() {
    card?.unmount()
    card = null
    ready.value = false
  }

  return { error, processing, ready, mount, confirm, unmount }
}
