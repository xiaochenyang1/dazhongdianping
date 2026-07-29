<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  createNewShopDraft,
  createUpdateShopDraft,
  fetchAreas,
  fetchCategories,
  fetchCities,
  fetchShopChange,
  fetchShopChanges,
  fetchShops,
  saveShopChange,
  saveShopChangeDishes,
  saveShopChangePhotos,
  submitShopChange,
  type GeoArea,
  type GeoCategoryNode,
  type GeoCity,
  type MerchantShopChange,
  type MerchantShopChangeDish,
  type MerchantShopChangePayload,
  type MerchantShopChangePhoto,
  type MerchantShopOption,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const notice = ref('')
const shops = ref<Array<MerchantShopOption & Record<string, unknown>>>([])
const drafts = ref<MerchantShopChange[]>([])
const categories = ref<GeoCategoryNode[]>([])
const cities = ref<GeoCity[]>([])
const areas = ref<GeoArea[]>([])
const editorOpen = ref(false)
const activeDraft = ref<MerchantShopChange | null>(null)
const canEdit = computed(() => props.permissions.includes('shop:edit'))
const defaultCurrency = computed(() => (state.region === 'EU' ? 'EUR' : 'CNY'))
const flatCategories = computed(() => flattenCategories(categories.value))
const draftFilterOptions = computed(() => [
  { value: 'pending_or_rejected', label: strings.value.shopDrafts.filterOptions.pendingOrRejected },
  { value: '', label: strings.value.shopDrafts.filterOptions.all },
  { value: '0', label: strings.value.shopDrafts.filterOptions.draft },
  { value: '1', label: strings.value.shopDrafts.filterOptions.pending },
  { value: '2', label: strings.value.shopDrafts.filterOptions.approved },
  { value: '3', label: strings.value.shopDrafts.filterOptions.rejected },
])
const filters = reactive({
  draftStatus: 'pending_or_rejected',
})

const form = reactive({
  categoryId: '',
  cityId: '',
  areaId: '',
  name: '',
  coverUrl: '',
  phone: '',
  pricePerCapita: '',
  currency: defaultCurrency.value,
  address: '',
  latitude: '',
  longitude: '',
  businessHours: '',
  summary: '',
  openNow: true,
  tagsText: '',
  photos: [{ imageUrl: '', photoType: '1', sort: '1' }] as Array<{ imageUrl: string; photoType: string; sort: string }>,
  dishes: [{ name: '', price: '', recommendReason: '', sort: '1' }] as Array<{
    name: string
    price: string
    recommendReason: string
    sort: string
  }>,
})

defineExpose({
  form,
  submit,
  saveAll,
  activeDraft,
})

function flattenCategories(nodes: GeoCategoryNode[], prefix = ''): Array<{ id: number; name: string }> {
  const result: Array<{ id: number; name: string }> = []
  for (const node of nodes) {
    const label = prefix ? `${prefix} / ${node.name}` : node.name
    if (node.children?.length) {
      result.push(...flattenCategories(node.children, label))
    } else {
      result.push({ id: node.id, name: label })
    }
  }
  return result
}

function fillForm(draft: MerchantShopChange) {
  activeDraft.value = draft
  form.categoryId = draft.categoryId ? String(draft.categoryId) : ''
  form.cityId = draft.cityId ? String(draft.cityId) : ''
  form.areaId = draft.areaId ? String(draft.areaId) : ''
  form.name = draft.name || ''
  form.coverUrl = draft.coverUrl || ''
  form.phone = draft.phone || ''
  form.pricePerCapita = draft.pricePerCapita != null ? String(draft.pricePerCapita) : ''
  form.currency = draft.currency || defaultCurrency.value
  form.address = draft.address || ''
  form.latitude = draft.latitude != null ? String(draft.latitude) : ''
  form.longitude = draft.longitude != null ? String(draft.longitude) : ''
  form.businessHours = draft.businessHours || ''
  form.summary = draft.summary || ''
  form.openNow = draft.openNow !== false
  form.tagsText = (draft.tags ?? []).join(',')
  form.photos = (draft.photos?.length ? draft.photos : [{ imageUrl: draft.coverUrl || '', photoType: 1, sort: 1 }]).map(
    (photo: MerchantShopChangePhoto, index: number) => ({
      imageUrl: photo.imageUrl || '',
      photoType: String(photo.photoType ?? 1),
      sort: String(photo.sort ?? index + 1),
    }),
  )
  form.dishes = (draft.dishes?.length ? draft.dishes : [{ name: '', price: 0, recommendReason: '', sort: 1 }]).map(
    (dish: MerchantShopChangeDish, index: number) => ({
      name: dish.name || '',
      price: String(dish.price ?? ''),
      recommendReason: dish.recommendReason || '',
      sort: String(dish.sort ?? index + 1),
    }),
  )
}

function draftStatusText(status: number, fallback?: string) {
  return strings.value.shopDrafts.draftStatusText(status, fallback)
}

function liveShopStatus(item: Record<string, unknown>) {
  return strings.value.shopDrafts.liveShopStatusText(
    typeof item.openNow === 'boolean' ? item.openNow : null,
    typeof item.statusText === 'string' ? item.statusText : undefined,
  )
}

function draftName(draft: MerchantShopChange) {
  return draft.name || strings.value.shopDrafts.draftFallbackName(draft.id)
}

async function loadAreas(cityId: number) {
  if (!cityId) {
    areas.value = []
    return
  }
  areas.value = await fetchAreas(cityId)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [shopPage, draftPage, categoryList, cityList] = await Promise.all([
      fetchShops({ page: 1, pageSize: 50 }),
      fetchShopChanges({
        page: 1,
        pageSize: 50,
        status:
          filters.draftStatus === 'pending_or_rejected' || filters.draftStatus === ''
            ? undefined
            : Number(filters.draftStatus),
      }),
      fetchCategories(),
      fetchCities(),
    ])
    shops.value = shopPage.list
    const draftList = draftPage.list
    drafts.value =
      filters.draftStatus === 'pending_or_rejected'
        ? draftList.filter((item) => item.status === 1 || item.status === 3)
        : draftList
    categories.value = categoryList
    cities.value = cityList
    if (form.cityId) {
      await loadAreas(Number(form.cityId))
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.loadError
  } finally {
    loading.value = false
  }
}

async function openDraft(draftId: number) {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const detail = await fetchShopChange(draftId)
    fillForm(detail)
    if (detail.cityId) {
      await loadAreas(detail.cityId)
    }
    editorOpen.value = true
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.draftLoadError
  } finally {
    saving.value = false
  }
}

async function createNewDraft() {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const draft = await createNewShopDraft()
    fillForm(draft)
    editorOpen.value = true
    notice.value = strings.value.shopDrafts.newDraftNotice
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.newDraftError
  } finally {
    saving.value = false
  }
}

async function createShopDraft(shopId: number) {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const draft = await createUpdateShopDraft(shopId)
    fillForm(draft)
    if (draft.cityId) {
      await loadAreas(draft.cityId)
    }
    editorOpen.value = true
    notice.value = draft.status === 0
      ? strings.value.shopDrafts.updateDraftOpened
      : strings.value.shopDrafts.currentDraftStatus(draftStatusText(draft.status, draft.statusText))
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.updateDraftError
  } finally {
    saving.value = false
  }
}

function addPhoto() {
  form.photos.push({ imageUrl: '', photoType: '2', sort: String(form.photos.length + 1) })
}
function removePhoto(index: number) {
  if (form.photos.length <= 1) return
  form.photos.splice(index, 1)
}
function addDish() {
  form.dishes.push({ name: '', price: '', recommendReason: '', sort: String(form.dishes.length + 1) })
}
function removeDish(index: number) {
  form.dishes.splice(index, 1)
}

function buildBasePayload(): MerchantShopChangePayload {
  const categoryId = Number(form.categoryId)
  const cityId = Number(form.cityId)
  const areaId = Number(form.areaId)
  const pricePerCapita = Number(form.pricePerCapita)
  if (!Number.isFinite(categoryId) || categoryId <= 0) throw new Error(strings.value.shopDrafts.validations.categoryRequired)
  if (!Number.isFinite(cityId) || cityId <= 0) throw new Error(strings.value.shopDrafts.validations.cityRequired)
  if (!Number.isFinite(areaId) || areaId <= 0) throw new Error(strings.value.shopDrafts.validations.areaRequired)
  if (!form.name.trim()) throw new Error(strings.value.shopDrafts.validations.nameRequired)
  if (!form.coverUrl.trim()) throw new Error(strings.value.shopDrafts.validations.coverUrlRequired)
  if (!Number.isFinite(pricePerCapita) || pricePerCapita < 0) throw new Error(strings.value.shopDrafts.validations.priceInvalid)
  if (!form.address.trim()) throw new Error(strings.value.shopDrafts.validations.addressRequired)
  if (!form.businessHours.trim()) throw new Error(strings.value.shopDrafts.validations.businessHoursRequired)
  if (!form.summary.trim()) throw new Error(strings.value.shopDrafts.validations.summaryRequired)
  const latitude = form.latitude.trim() ? Number(form.latitude) : null
  const longitude = form.longitude.trim() ? Number(form.longitude) : null
  if (latitude != null && !Number.isFinite(latitude)) throw new Error(strings.value.shopDrafts.validations.latitudeInvalid)
  if (longitude != null && !Number.isFinite(longitude)) throw new Error(strings.value.shopDrafts.validations.longitudeInvalid)
  return {
    categoryId,
    cityId,
    areaId,
    name: form.name.trim(),
    coverUrl: form.coverUrl.trim(),
    phone: form.phone.trim(),
    pricePerCapita,
    currency: form.currency.trim().toUpperCase() || defaultCurrency.value,
    address: form.address.trim(),
    latitude,
    longitude,
    businessHours: form.businessHours.trim(),
    summary: form.summary.trim(),
    openNow: form.openNow,
    tags: form.tagsText
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean),
  }
}

function buildPhotos(): MerchantShopChangePhoto[] {
  const photos = form.photos.map((photo, index) => {
    if (!photo.imageUrl.trim()) throw new Error(strings.value.shopDrafts.validations.photoUrlRequired(index + 1))
    return {
      imageUrl: photo.imageUrl.trim(),
      photoType: Number(photo.photoType) || 1,
      sort: Number(photo.sort) || index + 1,
    }
  })
  if (!photos.length) throw new Error(strings.value.shopDrafts.validations.photoRequired)
  if (!photos.some((photo) => photo.photoType === 1 && photo.imageUrl === form.coverUrl.trim())) {
    throw new Error(strings.value.shopDrafts.validations.coverPhotoMismatch)
  }
  return photos
}

function buildDishes(): MerchantShopChangeDish[] {
  return form.dishes
    .filter((dish) => dish.name.trim() || dish.price.trim())
    .map((dish, index) => {
      const price = Number(dish.price)
      if (!dish.name.trim()) throw new Error(strings.value.shopDrafts.validations.dishNameRequired(index + 1))
      if (!Number.isFinite(price) || price < 0) throw new Error(strings.value.shopDrafts.validations.dishPriceInvalid(index + 1))
      return {
        name: dish.name.trim(),
        price,
        recommendReason: dish.recommendReason.trim(),
        sort: Number(dish.sort) || index + 1,
      }
    })
}

async function persistDraft() {
  if (!activeDraft.value) throw new Error(strings.value.shopDrafts.validations.noActiveDraft)
  const base = buildBasePayload()
  const photos = buildPhotos()
  const dishes = buildDishes()
  await saveShopChange(activeDraft.value.id, base)
  await saveShopChangePhotos(activeDraft.value.id, photos)
  const saved = await saveShopChangeDishes(activeDraft.value.id, dishes)
  fillForm(saved)
  return saved
}

async function saveAll() {
  if (!canEdit.value || !activeDraft.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    await persistDraft()
    notice.value = strings.value.shopDrafts.saveNotice
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.saveError
  } finally {
    saving.value = false
  }
}

async function submit() {
  if (!canEdit.value || !activeDraft.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    await persistDraft()
    const submitted = await submitShopChange(activeDraft.value.id)
    fillForm(submitted)
    notice.value = strings.value.shopDrafts.submitNotice
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.submitError
  } finally {
    saving.value = false
  }
}

watch(
  () => form.cityId,
  async (value, oldValue) => {
    if (value === oldValue) return
    const cityId = Number(value)
    if (!Number.isFinite(cityId) || cityId <= 0) {
      areas.value = []
      form.areaId = ''
      return
    }
    const keepArea = form.areaId
    try {
      await loadAreas(cityId)
      if (!areas.value.some((area) => String(area.id) === keepArea)) {
        form.areaId = ''
      }
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : strings.value.shopDrafts.areasLoadError
    }
  },
)

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">{{ strings.shopDrafts.eyebrow }}</p>
        <strong>{{ strings.shopDrafts.heading }}</strong>
        <p class="muted">{{ strings.shopDrafts.description }}</p>
      </div>
      <div class="row-actions">
        <label>
          <span class="muted">{{ strings.shopDrafts.filterLabel }}</span>
          <select
            v-model="filters.draftStatus"
            name="shop-draft-status-filter"
            data-testid="shop-draft-status-filter"
            @change="load"
          >
            <option v-for="option in draftFilterOptions" :key="option.value || 'all'" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
        <button type="button" class="secondary-action" @click="load">{{ strings.common.refresh }}</button>
        <button v-if="canEdit" type="button" class="primary-action" data-testid="shop-draft-create-new" :disabled="saving" @click="createNewDraft">
          {{ strings.shopDrafts.create }}
        </button>
      </div>
    </div>

    <p v-if="!canEdit" class="error" role="alert">{{ strings.shopDrafts.missingPermission('shop:edit') }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text">{{ notice }}</p>
    <p v-if="loading" class="muted">{{ strings.shopDrafts.loading }}</p>

    <div v-if="!loading" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.shopDrafts.liveTableHeaders.shop }}</th>
            <th>{{ strings.shopDrafts.liveTableHeaders.region }}</th>
            <th>{{ strings.shopDrafts.liveTableHeaders.city }}</th>
            <th>{{ strings.shopDrafts.liveTableHeaders.score }}</th>
            <th>{{ strings.shopDrafts.liveTableHeaders.status }}</th>
            <th>{{ strings.shopDrafts.liveTableHeaders.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in shops" :key="String(item.id)">
            <td>{{ item.name }}</td>
            <td>{{ item.region }}</td>
            <td>{{ item.cityName ?? '-' }}</td>
            <td>{{ item.score ?? '-' }}</td>
            <td>{{ liveShopStatus(item) }}</td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                class="secondary-action"
                :data-testid="`shop-draft-from-${item.id}`"
                :disabled="saving"
                @click="createShopDraft(Number(item.id))"
              >
                {{ strings.shopDrafts.createUpdateDraft }}
              </button>
              <span v-else class="muted">{{ strings.shopDrafts.readOnly }}</span>
            </td>
          </tr>
          <tr v-if="shops.length === 0">
            <td colspan="6" class="feedback">{{ strings.shopDrafts.noLiveShops }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <article v-if="drafts.length" class="card table-wrap" style="margin-top: 18px">
      <div class="toolbar">
        <strong>{{ strings.shopDrafts.draftListHeading }}</strong>
      </div>
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.shopDrafts.draftTableHeaders.draft }}</th>
            <th>{{ strings.shopDrafts.draftTableHeaders.type }}</th>
            <th>{{ strings.shopDrafts.draftTableHeaders.targetShop }}</th>
            <th>{{ strings.shopDrafts.draftTableHeaders.status }}</th>
            <th>{{ strings.shopDrafts.draftTableHeaders.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="draft in drafts" :key="draft.id">
            <td>
              <strong>{{ draftName(draft) }}</strong>
              <span class="table-subtext">#{{ draft.id }}</span>
            </td>
            <td>{{ strings.shopDrafts.changeTypeText(draft.changeType) }}</td>
            <td>{{ draft.targetShopId || '-' }}</td>
            <td>
              {{ draftStatusText(draft.status, draft.statusText) }}
              <span v-if="draft.rejectReason" class="table-subtext">
                {{ strings.shopDrafts.rejectReasonLabel }}{{ draft.rejectReason }}
              </span>
            </td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                class="secondary-action"
                :data-testid="`shop-draft-open-${draft.id}`"
                :disabled="saving"
                @click="openDraft(draft.id)"
              >
                {{ strings.shopDrafts.open }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </article>

    <article v-if="editorOpen && activeDraft" class="card deal-form-card" data-testid="shop-draft-editor" style="margin-top: 18px">
      <div class="toolbar">
        <div>
          <h3>{{ strings.shopDrafts.editorTitle(activeDraft.id) }}</h3>
          <p class="muted">
            {{
              strings.shopDrafts.editorSubtitle(
                activeDraft.changeType,
                activeDraft.targetShopId,
                draftStatusText(activeDraft.status, activeDraft.statusText),
              )
            }}
          </p>
          <p
            v-if="activeDraft.status === 3 && activeDraft.rejectReason"
            class="error"
            data-testid="shop-draft-reject-reason"
          >
            {{ strings.shopDrafts.editorRejectSummary(activeDraft.rejectReason) }}
          </p>
        </div>
        <button type="button" class="secondary-action" @click="editorOpen = false">
          {{ strings.shopDrafts.collapseEditor }}
        </button>
      </div>

      <form class="form-grid deal-form" @submit.prevent="saveAll">
        <label>
          <span>{{ strings.shopDrafts.labels.category }}</span>
          <select v-model="form.categoryId" name="shop-category-id" data-testid="shop-category-id">
            <option value="">{{ strings.shopDrafts.placeholders.selectCategory }}</option>
            <option v-for="item in flatCategories" :key="item.id" :value="String(item.id)">{{ item.name }}</option>
          </select>
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.city }}</span>
          <select v-model="form.cityId" name="shop-city-id" data-testid="shop-city-id">
            <option value="">{{ strings.shopDrafts.placeholders.selectCity }}</option>
            <option v-for="city in cities" :key="city.id" :value="String(city.id)">{{ city.name }}</option>
          </select>
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.area }}</span>
          <select v-model="form.areaId" name="shop-area-id" data-testid="shop-area-id">
            <option value="">{{ strings.shopDrafts.placeholders.selectArea }}</option>
            <option v-for="area in areas" :key="area.id" :value="String(area.id)">{{ area.name }}</option>
          </select>
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.openStatus }}</span>
          <select v-model="form.openNow" name="shop-open-now">
            <option :value="true">{{ strings.shopDrafts.openStatusOptions.open }}</option>
            <option :value="false">{{ strings.shopDrafts.openStatusOptions.closed }}</option>
          </select>
        </label>
        <label class="full-span">
          <span>{{ strings.shopDrafts.labels.name }}</span>
          <input v-model="form.name" name="shop-name" data-testid="shop-name" maxlength="128" />
        </label>
        <label class="full-span">
          <span>{{ strings.shopDrafts.labels.coverUrl }}</span>
          <input v-model="form.coverUrl" name="shop-cover-url" data-testid="shop-cover-url" maxlength="255" />
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.phone }}</span>
          <input v-model="form.phone" name="shop-phone" maxlength="64" />
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.pricePerCapita }}</span>
          <input v-model="form.pricePerCapita" name="shop-price" data-testid="shop-price" inputmode="decimal" />
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.currency }}</span>
          <input v-model="form.currency" name="shop-currency" maxlength="3" />
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.businessHours }}</span>
          <input v-model="form.businessHours" name="shop-hours" data-testid="shop-hours" maxlength="128" />
        </label>
        <label class="full-span">
          <span>{{ strings.shopDrafts.labels.address }}</span>
          <input v-model="form.address" name="shop-address" data-testid="shop-address" maxlength="255" />
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.latitude }}</span>
          <input v-model="form.latitude" name="shop-latitude" inputmode="decimal" />
        </label>
        <label>
          <span>{{ strings.shopDrafts.labels.longitude }}</span>
          <input v-model="form.longitude" name="shop-longitude" inputmode="decimal" />
        </label>
        <label class="full-span">
          <span>{{ strings.shopDrafts.labels.tags }}</span>
          <input
            v-model="form.tagsText"
            name="shop-tags"
            data-testid="shop-tags"
            :placeholder="strings.shopDrafts.placeholders.tags"
          />
        </label>
        <label class="full-span">
          <span>{{ strings.shopDrafts.labels.summary }}</span>
          <textarea v-model="form.summary" name="shop-summary" data-testid="shop-summary" rows="3" maxlength="255" />
        </label>

        <div class="full-span deal-items">
          <div class="toolbar">
            <strong>{{ strings.shopDrafts.photoSectionHeading }}</strong>
            <button type="button" class="secondary-action" data-testid="shop-photo-add" @click="addPhoto">
              {{ strings.shopDrafts.addPhoto }}
            </button>
          </div>
          <div v-for="(photo, index) in form.photos" :key="`photo-${index}`" class="deal-item-row">
            <input
              v-model="photo.imageUrl"
              :name="`shop-photo-url-${index}`"
              :data-testid="`shop-photo-url-${index}`"
              :placeholder="strings.shopDrafts.placeholders.photoUrl"
            />
            <select v-model="photo.photoType" :name="`shop-photo-type-${index}`">
              <option value="1">{{ strings.shopDrafts.photoTypeOptions.cover }}</option>
              <option value="2">{{ strings.shopDrafts.photoTypeOptions.environment }}</option>
              <option value="3">{{ strings.shopDrafts.photoTypeOptions.dish }}</option>
            </select>
            <input
              v-model="photo.sort"
              :name="`shop-photo-sort-${index}`"
              inputmode="numeric"
              :placeholder="strings.shopDrafts.placeholders.sort"
            />
            <button type="button" class="danger-action" :disabled="form.photos.length <= 1" @click="removePhoto(index)">
              {{ strings.shopDrafts.delete }}
            </button>
          </div>
        </div>

        <div class="full-span deal-items">
          <div class="toolbar">
            <strong>{{ strings.shopDrafts.dishSectionHeading }}</strong>
            <button type="button" class="secondary-action" data-testid="shop-dish-add" @click="addDish">
              {{ strings.shopDrafts.addDish }}
            </button>
          </div>
          <div v-for="(dish, index) in form.dishes" :key="`dish-${index}`" class="deal-item-row">
            <input
              v-model="dish.name"
              :name="`shop-dish-name-${index}`"
              :data-testid="`shop-dish-name-${index}`"
              :placeholder="strings.shopDrafts.placeholders.dishName"
            />
            <input
              v-model="dish.price"
              :name="`shop-dish-price-${index}`"
              :data-testid="`shop-dish-price-${index}`"
              inputmode="decimal"
              :placeholder="strings.shopDrafts.placeholders.dishPrice"
            />
            <input
              v-model="dish.recommendReason"
              :name="`shop-dish-reason-${index}`"
              :placeholder="strings.shopDrafts.placeholders.dishReason"
            />
            <input
              v-model="dish.sort"
              :name="`shop-dish-sort-${index}`"
              inputmode="numeric"
              :placeholder="strings.shopDrafts.placeholders.sort"
            />
            <button type="button" class="danger-action" @click="removeDish(index)">{{ strings.shopDrafts.delete }}</button>
          </div>
        </div>

        <div class="full-span row-actions">
          <button type="submit" class="primary-action" data-testid="shop-draft-save" :disabled="saving">
            {{ saving ? strings.shopDrafts.saving : strings.shopDrafts.saveDraft }}
          </button>
          <button type="button" class="primary-action" data-testid="shop-draft-submit" :disabled="saving" @click="submit">
            {{ strings.shopDrafts.submitReview }}
          </button>
          <button type="button" class="secondary-action" :disabled="saving" @click="editorOpen = false">
            {{ strings.common.cancel }}
          </button>
        </div>
      </form>
    </article>
  </section>
</template>
