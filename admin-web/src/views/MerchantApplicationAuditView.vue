<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { auditMerchantApplication, listMerchantApplications } from '@/services/admin'
import type { AdminMerchantApplication, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminMerchantApplication> | null>(null)
const selectedMerchantId = ref<number | null>(null)
const rejectMode = ref(false)
const rejectReason = ref('')
const filters = reactive({ status: '0', page: 1, pageSize: 20 })

const selected = computed(
  () => pageState.value?.list.find((item) => item.merchantId === selectedMerchantId.value) ?? null,
)
const canWrite = computed(() => state.permissions.includes('audit:merchant_application:write'))

function statusText(application: AdminMerchantApplication) {
  return strings.value.merchantApplicationAudit.statusText(application.status, application.statusText)
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listMerchantApplications({
      status: filters.status === '' ? undefined : Number(filters.status),
      page: filters.page,
      pageSize: filters.pageSize,
    })
  } catch (cause) {
    errorMessage.value =
      cause instanceof Error ? cause.message : strings.value.merchantApplicationAudit.loadError
  } finally {
    loading.value = false
  }
}

async function decide(application: AdminMerchantApplication, status: 1 | 2) {
  if (!canWrite.value || application.status !== 0) return

  const reason = rejectReason.value.trim()
  if (status === 2 && !reason) {
    errorMessage.value = strings.value.merchantApplicationAudit.rejectReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await auditMerchantApplication(application.merchantId, {
      status,
      reason: status === 2 ? reason : '',
    })
    successMessage.value =
      status === 1
        ? strings.value.merchantApplicationAudit.approvedMessage(application.companyName)
        : strings.value.merchantApplicationAudit.rejectedMessage(application.companyName)
    selectedMerchantId.value = null
    rejectMode.value = false
    rejectReason.value = ''
    await load()
  } catch (cause) {
    errorMessage.value =
      cause instanceof Error ? cause.message : strings.value.merchantApplicationAudit.actionError
  } finally {
    acting.value = false
  }
}

function openReject(application: AdminMerchantApplication) {
  if (!canWrite.value || application.status !== 0) return
  selectedMerchantId.value = application.merchantId
  rejectMode.value = true
  rejectReason.value = ''
  errorMessage.value = ''
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedMerchantId.value = null
    rejectMode.value = false
    rejectReason.value = ''
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.merchantApplicationAudit.eyebrow }}</p>
        <h1>{{ strings.merchantApplicationAudit.heading }}</h1>
        <p>{{ strings.merchantApplicationAudit.description(state.region) }}</p>
      </div>
      <button class="secondary-button" type="button" @click="load">
        {{ strings.merchantApplicationAudit.refresh }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.merchantApplicationAudit.listEyebrow }}</p>
          <h2>{{ strings.merchantApplicationAudit.listHeading }}</h2>
        </div>
        <span class="inline-note">
          {{ strings.merchantApplicationAudit.listSummary(pageState?.total ?? 0) }}
        </span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.merchantApplicationAudit.filters.status }}</span>
          <select v-model="filters.status">
            <option value="">{{ strings.merchantApplicationAudit.statusOptions.all }}</option>
            <option value="0">{{ strings.merchantApplicationAudit.statusOptions.pending }}</option>
            <option value="1">{{ strings.merchantApplicationAudit.statusOptions.approved }}</option>
            <option value="2">{{ strings.merchantApplicationAudit.statusOptions.rejected }}</option>
          </select>
        </label>
        <div class="toolbar-actions">
          <button class="primary-button" type="button" @click="filters.page = 1; load()">
            {{ strings.merchantApplicationAudit.applyFilters }}
          </button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.merchantApplicationAudit.tableHeaders.merchant }}</th>
              <th>{{ strings.merchantApplicationAudit.tableHeaders.legal }}</th>
              <th>{{ strings.merchantApplicationAudit.tableHeaders.shopPhotos }}</th>
              <th>{{ strings.merchantApplicationAudit.tableHeaders.status }}</th>
              <th>{{ strings.merchantApplicationAudit.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="5" class="table-empty">{{ strings.merchantApplicationAudit.loading }}</td>
            </tr>
            <tr v-else-if="!pageState?.list.length">
              <td colspan="5" class="table-empty">{{ strings.merchantApplicationAudit.empty }}</td>
            </tr>
            <tr v-for="application in pageState?.list" :key="application.merchantId">
              <td>
                <strong>{{ application.companyName }}</strong>
                <p>{{ application.merchantAccount }} · {{ application.region }}</p>
              </td>
              <td>
                <strong>{{ application.legalPerson }}</strong>
                <p>
                  <a :href="application.licenseUrl" target="_blank" rel="noreferrer">
                    {{ strings.merchantApplicationAudit.licenseLink }}
                  </a>
                </p>
              </td>
              <td>
                <div class="application-photos">
                  <a
                    v-for="(photo, index) in application.shopPhotoUrls"
                    :key="photo"
                    :href="photo"
                    target="_blank"
                    rel="noreferrer"
                  >
                    <img :src="photo" :alt="strings.merchantApplicationAudit.shopPhotoAlt(index)" />
                  </a>
                </div>
              </td>
              <td>
                <span
                  class="status-pill"
                  :class="
                    application.status === 0
                      ? 'status-pill--warn'
                      : application.status === 1
                        ? 'status-pill--good'
                        : 'status-pill--muted'
                  "
                >
                  {{ statusText(application) }}
                </span>
                <p v-if="application.rejectReason">{{ application.rejectReason }}</p>
              </td>
              <td>
                <div v-if="application.status === 0 && canWrite" class="table-actions">
                  <button
                    class="table-action"
                    type="button"
                    :disabled="acting"
                    @click="decide(application, 1)"
                  >
                    {{ strings.merchantApplicationAudit.approve }}
                  </button>
                  <button
                    class="table-action table-action--danger"
                    type="button"
                    :disabled="acting"
                    @click="openReject(application)"
                  >
                    {{ strings.merchantApplicationAudit.reject }}
                  </button>
                </div>
                <span v-else-if="application.status === 0" class="inline-note">
                  {{ strings.merchantApplicationAudit.readOnly }}
                </span>
                <span v-else class="inline-note">{{ strings.merchantApplicationAudit.handled }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button
          class="ghost-button"
          type="button"
          :disabled="filters.page <= 1"
          @click="filters.page--; load()"
        >
          {{ strings.merchantApplicationAudit.previousPage }}
        </button>
        <span>{{ strings.merchantApplicationAudit.page(filters.page) }}</span>
        <button
          class="ghost-button"
          type="button"
          :disabled="!pageState?.hasMore"
          @click="filters.page++; load()"
        >
          {{ strings.merchantApplicationAudit.nextPage }}
        </button>
      </div>
    </section>

    <div v-if="rejectMode && selected && canWrite && selected.status === 0" class="audit-drawer">
      <div>
        <p class="eyebrow">{{ strings.merchantApplicationAudit.rejectEyebrow }}</p>
        <h2>{{ selected.companyName }}</h2>
        <p>{{ strings.merchantApplicationAudit.rejectDescription }}</p>
      </div>
      <label class="field field--full">
        <span>{{ strings.merchantApplicationAudit.rejectReasonLabel }}</span>
        <textarea
          v-model="rejectReason"
          name="rejectReason"
          rows="4"
          :placeholder="strings.merchantApplicationAudit.rejectReasonPlaceholder"
        />
      </label>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="rejectMode = false">
          {{ strings.common.cancel }}
        </button>
        <button
          class="secondary-button"
          type="button"
          :disabled="acting"
          @click="decide(selected, 2)"
        >
          {{ strings.merchantApplicationAudit.confirmReject }}
        </button>
      </div>
    </div>
  </section>
</template>
