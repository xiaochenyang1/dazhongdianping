<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  applyVerifiedCertification,
  fetchVerifiedCertification,
  type MerchantVerifiedCertificationStatus,
} from '@/services/merchant'

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const status = ref<MerchantVerifiedCertificationStatus | null>(null)
const form = reactive({ reason: '', evidenceLines: '' })

const canApply = computed(() => {
  if (!status.value) return false
  return status.value.status === 0 || status.value.status === 3
})

function fillForm(next: MerchantVerifiedCertificationStatus) {
  form.reason = next.reason || ''
  form.evidenceLines = (next.evidenceUrls || []).join('\n')
}

async function load() {
  loading.value = true
  error.value = ''
  success.value = ''
  try {
    status.value = await fetchVerifiedCertification()
    fillForm(status.value)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.verifiedMerchant.loadError
  } finally {
    loading.value = false
  }
}

async function submit() {
  const reason = form.reason.trim()
  if (!reason) {
    error.value = strings.value.verifiedMerchant.reasonRequired
    return
  }
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    status.value = await applyVerifiedCertification({
      reason,
      evidenceUrls: form.evidenceLines
        .split(/\r?\n/)
        .map((item) => item.trim())
        .filter(Boolean),
    })
    fillForm(status.value)
    success.value = strings.value.verifiedMerchant.submitSuccess
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.verifiedMerchant.submitError
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.verifiedMerchant.eyebrow }}</p>
        <h1>{{ strings.verifiedMerchant.heading }}</h1>
        <p>{{ strings.verifiedMerchant.description }}</p>
      </div>
      <span v-if="status" class="status-pill" :class="`status-${status.status}`">
        {{ strings.verifiedMerchant.statusText(status.status, status.statusText) }}
      </span>
    </div>

    <p v-if="loading" class="feedback">{{ strings.verifiedMerchant.loading }}</p>
    <p v-else-if="error" class="feedback is-error" role="alert">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <template v-if="status && !loading">
      <article v-if="status.status === 2 && status.badge" class="card status-card status-card--success" data-testid="verified-result-approved">
        <p class="eyebrow">{{ strings.verifiedMerchant.approvedEyebrow }}</p>
        <h2>
          {{ strings.verifiedMerchant.approvedHeading }}
          <span class="verified-badge">{{ strings.verifiedMerchant.badgeLabel }}</span>
        </h2>
        <p>{{ strings.verifiedMerchant.approvedDescription(status.auditedAt) }}</p>
        <p v-if="status.effectiveStartAt" class="muted">{{ strings.verifiedMerchant.effectiveStart(status.effectiveStartAt) }}</p>
      </article>

      <article v-else-if="status.status === 1" class="card status-card" data-testid="verified-result-pending">
        <p class="eyebrow">{{ strings.verifiedMerchant.pendingEyebrow }}</p>
        <h2>{{ strings.verifiedMerchant.pendingHeading }}</h2>
        <p>{{ strings.verifiedMerchant.pendingDescription(status.submittedAt) }}</p>
        <p v-if="status.reason"><strong>{{ strings.verifiedMerchant.reasonLabel }}</strong>{{ status.reason }}</p>
      </article>

      <article v-else-if="status.status === 3" class="card status-card" data-testid="verified-result-rejected">
        <p class="eyebrow">{{ strings.verifiedMerchant.rejectedEyebrow }}</p>
        <h2>{{ strings.verifiedMerchant.rejectedHeading }}</h2>
        <p>
          <strong>{{ strings.verifiedMerchant.rejectReasonLabel }}</strong>
          {{ status.rejectReason || strings.verifiedMerchant.missingReason }}
        </p>
        <p v-if="status.auditedAt" class="muted">{{ strings.verifiedMerchant.auditedAt(status.auditedAt) }}</p>
      </article>

      <article v-if="canApply" class="card">
        <h2>{{ status.status === 3 ? strings.verifiedMerchant.reapplyHeading : strings.verifiedMerchant.applyHeading }}</h2>
        <form class="settlement-form" @submit.prevent="submit">
          <label>
            <span>{{ strings.verifiedMerchant.labels.reason }}</span>
            <textarea
              v-model="form.reason"
              rows="4"
              maxlength="500"
              :placeholder="strings.verifiedMerchant.placeholders.reason"
              required
            />
          </label>
          <label>
            <span>{{ strings.verifiedMerchant.labels.evidenceUrls }}</span>
            <textarea
              v-model="form.evidenceLines"
              rows="4"
              :placeholder="strings.verifiedMerchant.placeholders.evidenceUrls"
            />
          </label>
          <button type="submit" class="primary-button" :disabled="saving">
            {{ saving ? strings.verifiedMerchant.submitting : strings.verifiedMerchant.submit }}
          </button>
        </form>
      </article>
    </template>
  </section>
</template>
