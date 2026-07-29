<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { importShops, listImportBatches } from '@/services/admin'
import type {
  AdminImportBatch,
  AdminImportRecord,
  AdminImportResult,
  PageResult,
  Region,
} from '@/types/admin'

interface BatchFilters {
  status: string
  page: number
  pageSize: number
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))

const importing = ref(false)
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const lastResult = ref<AdminImportResult | null>(null)
const batchesPage = ref<PageResult<AdminImportBatch> | null>(null)

const form = reactive({
  fileName: defaultFileName(state.region),
  recordsText: buildExampleText(state.region),
})

const batchFilters = reactive<BatchFilters>({
  status: '',
  page: 1,
  pageSize: 10,
})

function defaultFileName(region: Region) {
  return `seed-${region.toLowerCase()}-shops.json`
}

function buildExampleRecord(region: Region): AdminImportRecord {
  if (region === 'EU') {
    return {
      merchantAccount: 'seed-eu-import-001@example.com',
      companyName: 'Paris Seed Import SARL',
      contactName: 'Lina',
      contactPhone: '+33111112222',
      shopName: 'Paris Seed Import Sichuan Bistro',
      categoryId: 201,
      cityId: 101,
      areaId: 1011,
      address: '18 Rue du Temple, Paris',
      latitude: 48.85837,
      longitude: 2.35717,
      phone: '+33155556666',
      businessHours: '11:30-22:00',
      pricePerCapita: 34,
      coverUrl: 'https://placehold.co/1200x720/1d4ed8/f8fafc?text=EU+Import',
      summary: 'Sample shop used to demonstrate the EU import flow.',
      score: 4.4,
      tasteScore: 4.5,
      envScore: 4.2,
      serviceScore: 4.3,
      currency: 'EUR',
      hasDeal: true,
      openNow: true,
      tags: ['Chinese', 'Import', 'Paris'],
    }
  }

  return {
    merchantAccount: 'seed-cn-import-001@example.com',
    companyName: '上海导入测试餐饮',
    contactName: '王磊',
    contactPhone: '13811112222',
    shopName: '上海导入测试火锅店',
    categoryId: 102,
    cityId: 1,
    areaId: 11,
    address: '上海市徐汇区测试导入路18号',
    latitude: 31.18826,
    longitude: 121.43687,
    phone: '021-61234567',
    businessHours: '10:00-22:00',
    pricePerCapita: 126,
    coverUrl: 'https://placehold.co/1200x720/f97316/f8fafc?text=CN+Import',
    summary: '给国内区演示导入链路用的样例门店。',
    score: 4.5,
    tasteScore: 4.6,
    envScore: 4.3,
    serviceScore: 4.4,
    currency: 'CNY',
    hasDeal: true,
    openNow: true,
    tags: ['导入', '火锅', '聚餐'],
  }
}

function buildExampleText(region: Region) {
  return JSON.stringify([buildExampleRecord(region)], null, 2)
}

function batchStatusText(batch: AdminImportBatch) {
  return strings.value.shopImport.statusText(batch.status, batch.statusText)
}

function resultStatusText(result: AdminImportResult) {
  return strings.value.shopImport.statusText(result.status, result.statusText)
}

function resetExample() {
  form.fileName = defaultFileName(state.region)
  form.recordsText = buildExampleText(state.region)
  lastResult.value = null
}

async function loadBatches() {
  loading.value = true
  errorMessage.value = ''

  try {
    batchesPage.value = await listImportBatches({
      region: state.region,
      status: batchFilters.status ? Number(batchFilters.status) : undefined,
      page: batchFilters.page,
      pageSize: batchFilters.pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.shopImport.loadError
  } finally {
    loading.value = false
  }
}

async function submitImport() {
  importing.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const parsed = JSON.parse(form.recordsText) as AdminImportRecord[]
    if (!Array.isArray(parsed) || parsed.length === 0) {
      throw new Error(strings.value.shopImport.invalidRecords)
    }

    const result = await importShops({
      fileName: form.fileName.trim() || defaultFileName(state.region),
      region: state.region,
      records: parsed,
    })

    lastResult.value = result
    successMessage.value = strings.value.shopImport.importSuccess(result.success, result.failed)
    batchFilters.page = 1
    await loadBatches()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.shopImport.importError
  } finally {
    importing.value = false
  }
}

function applyBatchFilter() {
  batchFilters.page = 1
  void loadBatches()
}

function goPrevPage() {
  if (!batchesPage.value || batchesPage.value.page <= 1) return
  batchFilters.page -= 1
  void loadBatches()
}

function goNextPage() {
  if (!batchesPage.value?.hasMore) return
  batchFilters.page += 1
  void loadBatches()
}

watch(
  () => state.region,
  () => {
    errorMessage.value = ''
    successMessage.value = ''
    batchFilters.status = ''
    batchFilters.page = 1
    resetExample()
    void loadBatches()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.shopImport.eyebrow }}</p>
        <h1>{{ strings.shopImport.heading }}</h1>
        <p>{{ strings.shopImport.description }}</p>
      </div>

      <div class="header-actions">
        <button type="button" class="secondary-button" @click="resetExample">
          {{ strings.shopImport.resetExample }}
        </button>
        <button
          type="button"
          class="primary-button"
          data-testid="import-submit"
          :disabled="importing"
          @click="submitImport"
        >
          {{ importing ? strings.shopImport.importing : strings.shopImport.startImport }}
        </button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.shopImport.requestEyebrow }}</p>
            <h2>{{ strings.shopImport.requestHeading(state.region) }}</h2>
          </div>
          <span class="inline-note">{{ strings.shopImport.requestNote }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.shopImport.labels.fileName }}</span>
            <input
              v-model="form.fileName"
              type="text"
              :placeholder="strings.shopImport.fileNamePlaceholder"
            />
          </label>

          <label class="field">
            <span>{{ strings.shopImport.labels.region }}</span>
            <input :value="state.region" type="text" readonly />
          </label>
        </div>

        <label class="field field--full">
          <span>{{ strings.shopImport.labels.records }}</span>
          <textarea
            v-model="form.recordsText"
            data-testid="import-records-textarea"
            rows="18"
            spellcheck="false"
            :placeholder="strings.shopImport.recordsPlaceholder"
          />
        </label>

        <div class="hint-card">
          <strong>{{ strings.shopImport.validIdsTitle }}</strong>
          <p>{{ strings.shopImport.validIds(state.region) }}</p>
        </div>

        <section v-if="lastResult" class="result-panel">
          <div class="section-headline">
            <div>
              <p class="eyebrow">{{ strings.shopImport.resultEyebrow }}</p>
              <h2>{{ strings.shopImport.resultHeading }}</h2>
            </div>
          </div>

          <div class="stat-grid stat-grid--compact">
            <article class="stat-card">
              <p>{{ strings.shopImport.resultCards.total }}</p>
              <strong>{{ lastResult.total }}</strong>
              <span>{{ strings.shopImport.resultCards.batch(lastResult.batchId) }}</span>
            </article>
            <article class="stat-card">
              <p>{{ strings.shopImport.resultCards.success }}</p>
              <strong>{{ lastResult.success }}</strong>
              <span>{{ resultStatusText(lastResult) }}</span>
            </article>
            <article class="stat-card">
              <p>{{ strings.shopImport.resultCards.failure }}</p>
              <strong>{{ lastResult.failed }}</strong>
              <span>{{ lastResult.errorFile || strings.shopImport.resultCards.noErrorFile }}</span>
            </article>
          </div>

          <ul v-if="lastResult.errorMessages.length > 0" class="error-list">
            <li v-for="message in lastResult.errorMessages" :key="message">{{ message }}</li>
          </ul>
        </section>
      </section>

      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.shopImport.batchesEyebrow }}</p>
            <h2>{{ strings.shopImport.batchesHeading }}</h2>
          </div>
          <span class="inline-note">{{ strings.shopImport.batchesSummary(batchesPage?.total ?? 0) }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.shopImport.filters.status }}</span>
            <select v-model="batchFilters.status">
              <option value="">{{ strings.shopImport.statusOptions.all }}</option>
              <option value="0">{{ strings.shopImport.statusOptions.processing }}</option>
              <option value="1">{{ strings.shopImport.statusOptions.completed }}</option>
              <option value="2">{{ strings.shopImport.statusOptions.failed }}</option>
            </select>
          </label>

          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyBatchFilter">
              {{ strings.shopImport.applyFilters }}
            </button>
            <button type="button" class="ghost-button" @click="loadBatches">
              {{ strings.shopImport.refresh }}
            </button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.shopImport.tableHeaders.batch }}</th>
                <th>{{ strings.shopImport.tableHeaders.fileName }}</th>
                <th>{{ strings.shopImport.tableHeaders.result }}</th>
                <th>{{ strings.shopImport.tableHeaders.status }}</th>
                <th>{{ strings.shopImport.tableHeaders.errorFile }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="5" class="table-empty">{{ strings.shopImport.loading }}</td>
              </tr>
              <tr v-else-if="!batchesPage || batchesPage.list.length === 0">
                <td colspan="5" class="table-empty">{{ strings.shopImport.empty }}</td>
              </tr>
              <tr v-for="batch in batchesPage?.list" :key="batch.id">
                <td>
                  #{{ batch.id }}
                  <p>{{ batch.createdAt }}</p>
                </td>
                <td>{{ batch.fileName }}</td>
                <td>{{ strings.shopImport.resultSummary(batch.success, batch.failed) }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="
                      batch.failed === 0
                        ? 'status-pill--good'
                        : batch.success > 0
                          ? 'status-pill--warn'
                          : 'status-pill--muted'
                    "
                  >
                    {{ batchStatusText(batch) }}
                  </span>
                </td>
                <td>
                  <code class="code-box">
                    {{ batch.errorFile || strings.shopImport.resultCards.noErrorFile }}
                  </code>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button
            type="button"
            class="ghost-button"
            :disabled="(batchesPage?.page ?? 1) <= 1"
            @click="goPrevPage"
          >
            {{ strings.shopImport.previousPage }}
          </button>
          <span>{{ strings.shopImport.page(batchesPage?.page ?? 1) }}</span>
          <button
            type="button"
            class="ghost-button"
            :disabled="!batchesPage?.hasMore"
            @click="goNextPage"
          >
            {{ strings.shopImport.nextPage }}
          </button>
        </div>
      </section>
    </div>
  </section>
</template>
