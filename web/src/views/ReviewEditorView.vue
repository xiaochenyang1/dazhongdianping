<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
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
const pageTitle = computed(() => (isEditing.value ? '编辑点评' : '写点评'))
const pageSummary = computed(() =>
  isEditing.value ? '改完会重新进入审核，图片现在可以直接本地上传。' : '本地版本已经接了图片上传，别再手填 URL 了。',
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
      throw new Error('门店信息不完整，没法写点评。')
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
    errorMessage.value = error instanceof Error ? error.message : '点评编辑页加载失败'
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
    uploadErrorMessage.value = '最多只能上传 9 张图片'
    if (input) {
      input.value = ''
    }
    return
  }

  const availableSlots = 9 - form.images.length
  const filesToUpload = selectedFiles.slice(0, availableSlots)

  if (filesToUpload.length < selectedFiles.length) {
    uploadErrorMessage.value = `最多还能上传 ${availableSlots} 张图片，多出来的这批先别硬塞。`
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
      uploadMessage.value = `已上传 ${uploadedCount} 张图片。`
    }
  } catch (error) {
    uploadErrorMessage.value = error instanceof Error ? error.message : '图片上传失败'
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
    errorMessage.value = error instanceof Error ? error.message : '点评提交失败'
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
        <h1>{{ shopMeta?.name ?? '点评表单' }}</h1>
        <p class="hero-panel__summary">{{ pageSummary }}</p>
        <p v-if="shopMeta?.cityName || shopMeta?.areaName" class="support-copy">
          {{ appState.region }} · {{ shopMeta?.cityName }} <span v-if="shopMeta?.areaName">· {{ shopMeta?.areaName }}</span>
        </p>
      </div>
    </section>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">点评表单加载中...</p>

    <form v-else class="content-section review-form" @submit.prevent="submitReview">
      <div class="section-header">
        <div>
          <p class="eyebrow">评分与正文</p>
          <h2>把关键体验填完整，审核和聚合才有意义。</h2>
        </div>
      </div>

      <div class="field-row">
        <label class="field">
          <span>综合评分</span>
          <select v-model="form.scoreOverall">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`overall-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
        <label class="field">
          <span>口味评分</span>
          <select v-model="form.scoreTaste">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`taste-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
        <label class="field">
          <span>环境评分</span>
          <select v-model="form.scoreEnv">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`env-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
        <label class="field">
          <span>服务评分</span>
          <select v-model="form.scoreService">
            <option v-for="value in [5, 4, 3, 2, 1]" :key="`service-${value}`" :value="value">{{ value }}</option>
          </select>
        </label>
      </div>

      <div class="field-row field-row--two">
        <label class="field">
          <span>消费金额</span>
          <input v-model="form.cost" type="number" min="0" step="0.01" placeholder="本次消费金额" />
        </label>
        <label class="field">
          <span>货币</span>
          <select v-model="form.currency">
            <option value="CNY">CNY</option>
            <option value="EUR">EUR</option>
            <option value="GBP">GBP</option>
          </select>
        </label>
      </div>

      <label class="field">
        <span>标签</span>
        <input v-model="form.tagsInput" type="text" placeholder="用逗号分隔，比如：适合聚餐, 出锅稳, 回头率高" />
      </label>

      <label class="field field--full">
        <span>点评正文</span>
        <textarea
          v-model="form.content"
          rows="7"
          maxlength="500"
          spellcheck="false"
          placeholder="把真实体验说清楚，别整五个字就想糊过去。"
        />
      </label>

      <div class="section-header section-header--compact">
        <div>
          <p class="eyebrow">图片上传</p>
          <h2>现在直接传本地图片，别再靠手填 URL 硬顶了。</h2>
        </div>
        <span class="support-copy">{{ uploading ? '图片上传中...' : `当前已上传 ${form.images.length} / 9 张` }}</span>
      </div>

      <label class="field field--full">
        <span>选择图片</span>
        <input
          class="file-input"
          type="file"
          accept="image/png,image/jpeg,image/gif"
          multiple
          :disabled="uploading || form.images.length >= 9"
          @change="handleImageSelection"
        />
      </label>

      <p class="support-copy">支持 jpg / png / gif，单张最多 5MB，最多 9 张。</p>
      <p v-if="uploadMessage" class="feedback is-success">{{ uploadMessage }}</p>
      <p v-if="uploadErrorMessage" class="feedback is-error">{{ uploadErrorMessage }}</p>

      <div v-if="form.images.length > 0" class="photo-grid">
        <article v-for="(image, index) in form.images" :key="`${image}-${index}`" class="uploaded-image-card">
          <img :src="image" :alt="`点评图片 ${index + 1}`" />
          <div class="uploaded-image-card__footer">
            <span>图片 {{ index + 1 }}</span>
            <button type="button" class="ghost-button" @click="removeImageField(index)">移除</button>
          </div>
        </article>
      </div>
      <p v-else class="feedback">还没上传图片，当前已经能直接从本地选图了。</p>

      <div class="hero-actions">
        <button type="submit" class="primary-button" :disabled="saving || uploading">
          {{ saving ? '提交中...' : isEditing ? '保存并重新提审' : '提交点评' }}
        </button>
        <RouterLink class="secondary-button" :to="shopMeta ? `/shops/${shopMeta.id}` : '/shops'">返回门店</RouterLink>
      </div>
    </form>
  </div>
</template>
