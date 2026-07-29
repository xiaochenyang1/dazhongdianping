<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { fetchSettlementStatus, submitSettlement, type SettlementStatus } from '@/services/merchant'

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const status = ref<SettlementStatus | null>(null)
const form = reactive({ licenseUrl: '', legalPerson: '', photoLines: '' })

const editable = computed(() => status.value?.status === -1 || status.value?.status === 2)

function fillForm(next: SettlementStatus) {
  form.licenseUrl = next.licenseUrl ?? ''
  form.legalPerson = next.legalPerson ?? ''
  form.photoLines = (next.shopPhotoUrls ?? []).join('\n')
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    status.value = await fetchSettlementStatus()
    fillForm(status.value)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.settlement.loadError
  } finally {
    loading.value = false
  }
}

async function submit() {
  saving.value = true
  error.value = ''
  const payload = {
    licenseUrl: form.licenseUrl.trim(),
    legalPerson: form.legalPerson.trim(),
    shopPhotoUrls: form.photoLines.split(/\r?\n/).map((item) => item.trim()).filter(Boolean),
  }
  try {
    const result = await submitSettlement(payload)
    status.value = {
      ...(status.value ?? { merchantId: 0 }),
      ...payload,
      ...result,
      statusText: result.statusText || strings.value.settlement.fallbackPendingStatusText,
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.settlement.submitError
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <main class="settlement-page">
    <section class="settlement-header">
      <div>
        <p class="eyebrow">{{ strings.settlement.eyebrow }}</p>
        <h1>{{ strings.settlement.heading }}</h1>
        <p>{{ strings.settlement.description }}</p>
      </div>
      <span v-if="status" class="status-pill" :class="`status-${status.status}`">{{ status.statusText }}</span>
    </section>

    <p v-if="loading" class="card feedback">{{ strings.settlement.loadingStatus }}</p>
    <p v-else-if="error && !status" class="card error" role="alert">{{ error }}</p>

    <template v-else-if="status">
      <article v-if="status.status === 0" class="card status-card">
        <p class="eyebrow">{{ strings.settlement.pendingEyebrow }}</p>
        <h2>{{ strings.settlement.pendingHeading }}</h2>
        <p>{{ strings.settlement.pendingSubmittedAt(status.submittedAt) }}</p>
      </article>

      <article v-else-if="status.status === 1" class="card status-card status-card--success">
        <p class="eyebrow">{{ strings.settlement.approvedEyebrow }}</p>
        <h2>{{ strings.settlement.approvedHeading }}</h2>
        <p>{{ strings.settlement.approvedDescription }}</p>
        <RouterLink class="primary-link" to="/dashboard">{{ strings.settlement.openWorkbench }}</RouterLink>
      </article>

      <form v-if="editable" class="card settlement-form" @submit.prevent="submit">
        <div>
          <p class="eyebrow">
            {{ status.status === 2 ? strings.settlement.resubmitEyebrow : strings.settlement.firstSubmitEyebrow }}
          </p>
          <h2>
            {{ status.status === 2 ? strings.settlement.resubmitHeading : strings.settlement.firstSubmitHeading }}
          </h2>
          <p v-if="status.status === 2" class="rejection-note">
            <strong>{{ strings.settlement.rejectReasonLabel }}</strong>{{ status.rejectReason }}
          </p>
        </div>
        <label>
          {{ strings.settlement.licenseUrlLabel }}
          <input v-model.trim="form.licenseUrl" name="licenseUrl" required type="url" />
        </label>
        <label>
          {{ strings.settlement.legalPersonLabel }}
          <input v-model.trim="form.legalPerson" name="legalPerson" required />
        </label>
        <label>
          {{ strings.settlement.shopPhotoUrlsLabel }}
          <textarea v-model="form.photoLines" name="shopPhotoUrls" required rows="6" />
        </label>
        <p v-if="error" class="error" role="alert">{{ error }}</p>
        <button class="primary-action" :disabled="saving">
          {{ saving ? strings.settlement.submitting : strings.settlement.submitReview }}
        </button>
      </form>
    </template>
  </main>
</template>
