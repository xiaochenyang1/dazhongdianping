<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { cameraScanError, CouponCameraScanner, normalizeScannedCoupon } from '@/core/coupon_camera_scanner'
import { verifyCoupon, type MerchantCoupon } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const code = ref('')
const loading = ref(false)
const error = ref('')
const notice = ref('')
const result = ref<MerchantCoupon | null>(null)
const history = ref<MerchantCoupon[]>([])
const canVerify = computed(() => props.permissions.includes('coupon:verify'))
const cameraOpen = ref(false)
const cameraStarting = ref(false)
const cameraVideo = ref<HTMLVideoElement | null>(null)
let scanner: CouponCameraScanner | null = null
let cameraRequest = 0

function stopCamera() {
  cameraRequest++
  scanner?.stop()
  scanner = null
  cameraOpen.value = false
  cameraStarting.value = false
}

async function startCamera() {
  if (!canVerify.value || loading.value || cameraOpen.value) return
  const request = ++cameraRequest
  error.value = ''
  notice.value = ''
  result.value = null
  cameraOpen.value = true
  cameraStarting.value = true
  await nextTick()
  if (request !== cameraRequest || !cameraVideo.value) return
  const current = new CouponCameraScanner(cameraVideo.value, (payload) => {
    const normalized = normalizeScannedCoupon(payload)
    stopCamera()
    if (normalized) {
      code.value = normalized
      notice.value = strings.value.coupons.scanned
    } else {
      error.value = strings.value.coupons.scanInvalid
    }
  }, (cause) => {
    stopCamera()
    error.value = strings.value.coupons.cameraErrors[cameraScanError(cause)]
  })
  scanner = current
  try {
    await current.start()
    if (request === cameraRequest) cameraStarting.value = false
  } catch (cause) {
    if (request !== cameraRequest) return
    stopCamera()
    error.value = strings.value.coupons.cameraErrors[cameraScanError(cause)]
  }
}

function stopWhenHidden() {
  if (document.visibilityState === 'hidden') stopCamera()
}

onMounted(() => {
  document.addEventListener('visibilitychange', stopWhenHidden)
  window.addEventListener('pagehide', stopCamera)
})
onBeforeUnmount(() => {
  document.removeEventListener('visibilitychange', stopWhenHidden)
  window.removeEventListener('pagehide', stopCamera)
  stopCamera()
})
watch(canVerify, (allowed) => { if (!allowed) stopCamera() })

function couponStatusText(coupon: MerchantCoupon) {
  return strings.value.coupons.statusText(coupon.status, coupon.statusText)
}

function dealLabel(coupon: MerchantCoupon) {
  return coupon.dealTitle || strings.value.coupons.dealFallback(coupon.dealId)
}

function shopLabel(coupon: MerchantCoupon) {
  return coupon.shopName || strings.value.coupons.shopFallback(coupon.shopId)
}

async function submit() {
  if (loading.value) return
  if (!canVerify.value) {
    error.value = strings.value.coupons.missingPermission('coupon:verify')
    return
  }
  const normalized = code.value.trim()
  if (!normalized) {
    error.value = strings.value.coupons.codeRequired
    return
  }
  if (!normalizeScannedCoupon(normalized)) {
    error.value = strings.value.coupons.codeInvalid
    return
  }
  stopCamera()
  loading.value = true
  error.value = ''
  notice.value = ''
  try {
    const coupon = await verifyCoupon(normalized)
    result.value = coupon
    history.value = [coupon, ...history.value.filter((item) => item.code !== coupon.code)].slice(0, 8)
    notice.value = strings.value.coupons.verifySuccess(coupon.code)
    code.value = ''
  } catch (cause) {
    result.value = null
    error.value = cause instanceof Error ? cause.message : strings.value.coupons.verifyError
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">{{ strings.coupons.eyebrow }}</p>
        <strong>{{ strings.coupons.heading }}</strong>
        <p class="muted">{{ strings.coupons.description }}</p>
      </div>
    </div>

    <p v-if="!canVerify" class="error" role="alert">{{ strings.coupons.missingPermission('coupon:verify') }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text" role="status">{{ notice }}</p>

    <article class="card verify-card">
      <form class="verify-form" @submit.prevent="submit">
        <label>
          <span>{{ strings.coupons.codeLabel }}</span>
          <input
            v-model="code"
            name="coupon-code"
            data-testid="coupon-code-input"
            maxlength="64"
            autocomplete="off"
            :placeholder="strings.coupons.codePlaceholder"
            :disabled="!canVerify || loading"
          />
        </label>
        <button
          type="submit"
          class="primary-action"
          data-testid="coupon-verify-submit"
          :disabled="!canVerify || loading"
        >
          {{ loading ? strings.coupons.verifying : strings.coupons.verify }}
        </button>
        <button
          type="button"
          data-testid="coupon-scan-start"
          :disabled="!canVerify || loading || cameraOpen"
          @click="startCamera"
        >
          {{ strings.coupons.scan }}
        </button>
      </form>
      <div v-if="cameraOpen" class="camera-panel" data-testid="coupon-camera-panel">
        <video ref="cameraVideo" data-testid="coupon-camera-video" autoplay muted playsinline :aria-label="strings.coupons.scan" />
        <p v-if="cameraStarting" role="status">{{ strings.coupons.cameraStarting }}</p>
        <p class="muted">{{ strings.coupons.cameraHint }}</p>
        <button type="button" data-testid="coupon-scan-stop" @click="stopCamera">{{ strings.coupons.stopScan }}</button>
      </div>
    </article>

    <article v-if="result" class="card result-card" data-testid="coupon-verify-result">
      <p class="eyebrow">{{ strings.coupons.latestResultHeading }}</p>
      <h3>{{ dealLabel(result) }}</h3>
      <p><strong>{{ strings.coupons.fieldLabels.code }}</strong>{{ result.code }}</p>
      <p><strong>{{ strings.coupons.fieldLabels.shop }}</strong>{{ shopLabel(result) }}</p>
      <p><strong>{{ strings.coupons.fieldLabels.status }}</strong>{{ couponStatusText(result) }}</p>
      <p v-if="result.verifyAt"><strong>{{ strings.coupons.fieldLabels.verifiedAt }}</strong>{{ result.verifyAt }}</p>
      <p v-if="result.expireAt"><strong>{{ strings.coupons.fieldLabels.expireAt }}</strong>{{ result.expireAt }}</p>
    </article>

    <article v-if="history.length" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.coupons.historyHeaders.code }}</th>
            <th>{{ strings.coupons.historyHeaders.deal }}</th>
            <th>{{ strings.coupons.historyHeaders.shop }}</th>
            <th>{{ strings.coupons.historyHeaders.status }}</th>
            <th>{{ strings.coupons.historyHeaders.verifiedAt }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in history" :key="`${item.id}-${item.code}`">
            <td>{{ item.code }}</td>
            <td>{{ dealLabel(item) }}</td>
            <td>{{ shopLabel(item) }}</td>
            <td>{{ couponStatusText(item) }}</td>
            <td>{{ item.verifyAt || '--' }}</td>
          </tr>
        </tbody>
      </table>
    </article>
  </section>
</template>

<style scoped>
.camera-panel { margin-top: 18px; max-width: 560px; }
.camera-panel video { display: block; width: 100%; max-height: 360px; border-radius: 12px; background: #151515; object-fit: contain; }
</style>
