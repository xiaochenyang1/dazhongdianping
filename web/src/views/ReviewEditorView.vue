<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { localizeWebReviewError, reviewStringsForRegion } from '@/core/web_review_localizations'
import { fetchShopDetail } from '@/services/browse'
import { uploadImage } from '@/services/file'
import { createReview, fetchOwnedReviewDetail, updateReview } from '@/services/review'

const props = defineProps<{
  shopId?: number
  reviewId?: number
}>()

const router = useRouter()
const { state: appState } = useAppContext()

const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const uploading = ref(false)
const uploadMessage = ref('')
const uploadErrorMessage = ref('')

const shopMeta = ref<{
  id: number
  name: string
  cityName?: string
  areaName?: string
  coverUrl?: string
  summary?: string
} | null>(null)

const form = reactive({
  shopId: props.shopId ?? 0,
  content: '',
  scoreOverall: 4,
  scoreTaste: 4,
  scoreEnv: 4,
  scoreService: 4,
  cost: 0,
  currency: '',
  tagsInput: '',
  images: [] as string[],
})

const isEditing = computed(() => typeof props.reviewId === 'number' && !Number.isNaN(props.reviewId))
const copy = computed(() => reviewStringsForRegion(appState.region))
const pageTitle = computed(() => (isEditing.value ? copy.value.editor.editTitle : copy.value.editor.createTitle))
const pageSummary = computed(() =>
  isEditing.value ? copy.value.editor.editSummary : copy.value.editor.createSummary,
)

function fillEditorForm(detail: Awaited<ReturnType<typeof fetchOwnedReviewDetail>>) {
  form.shopId = detail.shopId
  form.content = detail.content
  form.scoreOverall = detail.scoreOverall
  form.scoreTaste = detail.scoreTaste
  form.scoreEnv = detail.scoreEnv
  form.scoreService = detail.scoreService
  form.cost = detail.cost
  form.currency = detail.currency
  form.tagsInput = detail.tags.join(', ')
  form.images = detail.images.map((item) => item.url)
  shopMeta.value = {
    id: detail.shopId,
    name: detail.shopName,
  }
}

async function loadEditor() {
  loading.value = true
  errorMessage.value = ''

  try {
    if (isEditing.value && props.reviewId) {
      const detail = await fetchOwnedReviewDetail(props.reviewId)
      fillEditorForm(detail)
      return
    }

    if (!props.shopId || Number.isNaN(props.shopId)) {
      throw new Error(copy.value.editor.missingShop)
    }

    const shop = await fetchShopDetail(props.shopId)
    shopMeta.value = {
      id: shop.id,
      name: shop.name,
      cityName: shop.cityName,
      areaName: shop.areaName,
      coverUrl: shop.coverUrl,
      summary: shop.summary,
    }
    form.shopId = shop.id
    form.currency = shop.currency
  } catch (error) {
    errorMessage.value = localizeWebReviewError(copy.value, error, copy.value.editor.loadFailed)
  } finally {
    loading.value = false
  }
}

function removeImageField(index: number) {
  form.images.splice(index, 1)
}

function normalizeTags() {
  return form.tagsInput
    .split(/[，,]/)
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, 10)
}

function normalizeImages() {
  return form.images
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, 9)
}

function clearUploadFeedback() {
  uploadMessage.value = ''
  uploadErrorMessage.value = ''
}

async function handleImageSelection(event: Event) {
  const input = event.target as HTMLInputElement | null
  const selectedFiles = Array.from(input?.files ?? [])
  if (selectedFiles.length === 0) {
    return
  }

  clearUploadFeedback()

  if (form.images.length >= 9) {
    uploadErrorMessage.value = copy.value.editor.maxImages
    if (input) {
      input.value = ''
    }
    return
  }

  const availableSlots = 9 - form.images.length
  const filesToUpload = selectedFiles.slice(0, availableSlots)

  if (filesToUpload.length < selectedFiles.length) {
    uploadErrorMessage.value = copy.value.editor.remainingImages(availableSlots)
  }

  uploading.value = true

  try {
    let uploadedCount = 0
    for (const file of filesToUpload) {
      const result = await uploadImage(file)
      form.images.push(result.url)
      uploadedCount += 1
    }
    if (uploadedCount > 0) {
      uploadMessage.value = copy.value.editor.uploadedImages(uploadedCount)
    }
  } catch (error) {
    uploadErrorMessage.value = localizeWebReviewError(copy.value, error, copy.value.editor.uploadFailed)
  } finally {
    uploading.value = false
    if (input) {
      input.value = ''
    }
  }
}

async function submitReview() {
  saving.value = true
  errorMessage.value = ''

  try {
    const payload = {
      shopId: form.shopId,
      content: form.content.trim(),
      scoreOverall: Number(form.scoreOverall),
      scoreTaste: Number(form.scoreTaste),
      scoreEnv: Number(form.scoreEnv),
      scoreService: Number(form.scoreService),
      cost: Number(form.cost),
      currency: form.currency.trim().toUpperCase(),
      tags: normalizeTags(),
      images: normalizeImages(),
    }

    const detail =
      isEditing.value && props.reviewId
        ? await updateReview(props.reviewId, payload)
        : await createReview(payload)

    await router.push(`/user/reviews/${detail.id}`)
  } catch (error) {
    errorMessage.value = localizeWebReviewError(copy.value, error, copy.value.editor.submitFailed)
  } finally {
    saving.value = false
  }
}

watch(
  () => [props.shopId, props.reviewId, appState.region],
  () => {
    void loadEditor()
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--single">
      <div class="hero-panel__content">
        <p class="eyebrow">{{ pageTitle }}</p>
        <h1>{{ shopMeta?.name ?? copy.editor.formFallback }}</h1>
        <p class="hero-panel__summary">{{ pageSummary }}</p>
        <p v-if="shopMeta?.cityName || shopMeta?.areaName" class="support-copy">
          {{ appState.region }} · {{ shopMeta?.cityName }} <span v-if="shopMeta?.areaName">· {{ shopMeta?.areaName }}</span>
        </p>
      </div>
    </section>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.editor.loading }}</p>

    <form v-else class="content-section review-form" @submit.prevent="submitReview">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.editor.ratingsEyebrow }}</p>
          <h2>{{ copy.editor.ratingsTitle }}</h2>
        </div>
      </div>

      <div class="field-row">
        <label class="field">
          <span>{{ copy.editor.overallScore }}</span>
          <select v-model="form.scoreOverall">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`overall-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ copy.editor.tasteScore }}</span>
          <select v-model="form.scoreTaste">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`taste-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ copy.editor.ambienceScore }}</span>
          <select v-model="form.scoreEnv">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`env-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ copy.editor.serviceScore }}</span>
          <select v-model="form.scoreService">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`service-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
      </div>

      <div class="field-row field-row--two">
        <label class="field">
          <span>{{ copy.editor.spend }}</span>
          <input v-model="form.cost" type="number" min="0" step="0.01" :placeholder="copy.editor.spendPlaceholder" />
        </label>
        <label class="field">
          <span>{{ copy.editor.currency }}</span>
          <select v-model="form.currency">
            <option value="CNY">CNY</option>
            <option value="EUR">EUR</option>
            <option value="GBP">GBP</option>
          </select>
        </label>
      </div>

      <label class="field">
        <span>{{ copy.editor.tags }}</span>
        <input v-model="form.tagsInput" type="text" :placeholder="copy.editor.tagsPlaceholder" />
      </label>

      <label class="field field--full">
        <span>{{ copy.editor.body }}</span>
        <textarea
          v-model="form.content"
          rows="7"
          maxlength="500"
          spellcheck="false"
          :placeholder="copy.editor.bodyPlaceholder"
        />
      </label>

      <div class="section-header section-header--compact">
        <div>
          <p class="eyebrow">{{ copy.editor.uploadEyebrow }}</p>
          <h2>{{ copy.editor.uploadTitle }}</h2>
        </div>
        <span class="support-copy">{{ uploading ? copy.editor.uploading : copy.editor.uploadedCount(form.images.length) }}</span>
      </div>

      <label class="field field--full">
        <span>{{ copy.editor.selectImages }}</span>
        <input
          class="file-input"
          type="file"
          accept="image/png,image/jpeg,image/gif"
          multiple
          :disabled="uploading || form.images.length >= 9"
          @change="handleImageSelection"
        />
      </label>

      <p class="support-copy">{{ copy.editor.uploadSupport }}</p>
      <p v-if="uploadMessage" class="feedback is-success">{{ uploadMessage }}</p>
      <p v-if="uploadErrorMessage" class="feedback is-error">{{ uploadErrorMessage }}</p>

      <div v-if="form.images.length > 0" class="photo-grid">
        <article v-for="(image, index) in form.images" :key="`${image}-${index}`" class="uploaded-image-card">
          <img :src="image" :alt="copy.editor.imageAlt(index + 1)" />
          <div class="uploaded-image-card__footer">
            <span>{{ copy.editor.imageLabel(index + 1) }}</span>
            <button type="button" class="ghost-button" @click="removeImageField(index)">{{ copy.editor.remove }}</button>
          </div>
        </article>
      </div>
      <p v-else class="feedback">{{ copy.editor.noImages }}</p>

      <div class="hero-actions">
        <button type="submit" class="primary-button" :disabled="saving || uploading">
          {{ saving ? copy.editor.submitting : isEditing ? copy.editor.saveAndResubmit : copy.editor.submitReview }}
        </button>
        <RouterLink class="secondary-button" :to="shopMeta ? `/shops/${shopMeta.id}` : '/shops'">{{ copy.editor.backToShop }}</RouterLink>
      </div>
    </form>
  </div>
</template>
