<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { createShop, getShop, listShops, removeShop, updateShop } from '@/services/admin'
import { fetchAreas, fetchCategories, fetchCities } from '@/services/meta'
import type {
  AdminShopDetail,
  AdminShopSavePayload,
  AdminShopSummary,
  Area,
  CategoryNode,
  City,
  PageResult,
  Region,
} from '@/types/admin'

interface ShopFilters {
  keyword: string
  categoryId: string
  cityId: string
  areaId: string
  page: number
  pageSize: number
}

interface ShopFormState {
  merchantId: string
  categoryId: string
  cityId: string
  areaId: string
  name: string
  coverUrl: string
  phone: string
  pricePerCapita: string
  currency: string
  address: string
  latitude: string
  longitude: string
  businessHours: string
  summary: string
  score: string
  tasteScore: string
  envScore: string
  serviceScore: string
  hasDeal: boolean
  openNow: boolean
  status: string
  tags: string
}

interface CategoryOption {
  id: number
  label: string
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))

const categories = ref<CategoryNode[]>([])
const cities = ref<City[]>([])
const filterAreas = ref<Area[]>([])
const formAreas = ref<Area[]>([])
const pageState = ref<PageResult<AdminShopSummary> | null>(null)
const selectedDetail = ref<AdminShopDetail | null>(null)
const selectedShopId = ref<number | null>(null)

const listLoading = ref(false)
const detailLoading = ref(false)
const saving = ref(false)
const removingShopId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')

const filters = reactive<ShopFilters>({
  keyword: '',
  categoryId: '',
  cityId: '',
  areaId: '',
  page: 1,
  pageSize: 10,
})

const form = reactive<ShopFormState>(createEmptyShopForm(state.region))

const categoryOptions = computed<CategoryOption[]>(() =>
  categories.value.flatMap((group) => {
    if (group.children.length === 0) {
      return [{ id: group.id, label: group.name }]
    }

    return group.children.map((child) => ({
      id: child.id,
      label: `${group.name} / ${child.name}`,
    }))
  }),
)

const canWrite = computed(() => state.permissions.includes('data:shop:write'))
const editorTitle = computed(() => strings.value.shopManagement.editor.heading(selectedShopId.value))
const listCountText = computed(() => {
  if (!pageState.value || pageState.value.list.length === 0) {
    return strings.value.shopManagement.filters.emptyCount
  }

  const start = (pageState.value.page - 1) * pageState.value.pageSize + 1
  const end = start + pageState.value.list.length - 1
  return strings.value.shopManagement.filters.count(start, end, pageState.value.total)
})
const coverPreviewUrl = computed(() => form.coverUrl.trim() || defaultCoverUrl(state.region))

function defaultCurrency(region: Region) {
  return region === 'EU' ? 'EUR' : 'CNY'
}

function defaultCoverUrl(region: Region) {
  return region === 'EU'
    ? 'https://placehold.co/1200x720/1d4ed8/f8fafc?text=EU+Shop'
    : 'https://placehold.co/1200x720/f97316/f8fafc?text=CN+Shop'
}

function createEmptyShopForm(region: Region): ShopFormState {
  return {
    merchantId: '',
    categoryId: '',
    cityId: '',
    areaId: '',
    name: '',
    coverUrl: defaultCoverUrl(region),
    phone: '',
    pricePerCapita: region === 'EU' ? '22' : '88',
    currency: defaultCurrency(region),
    address: '',
    latitude: '',
    longitude: '',
    businessHours: '10:00-21:00',
    summary: '',
    score: '4.2',
    tasteScore: '4.1',
    envScore: '4.2',
    serviceScore: '4.2',
    hasDeal: false,
    openNow: true,
    status: '1',
    tags: '',
  }
}

function shopStatusText(shop: AdminShopSummary | AdminShopDetail) {
  return strings.value.shopManagement.statusText(shop.status, shop.statusText)
}

function merchantLabel(shop: AdminShopSummary) {
  return shop.merchantName || strings.value.shopManagement.merchantFallback
}

function actionLabel() {
  return canWrite.value ? strings.value.shopManagement.edit : strings.value.shopManagement.view
}

async function loadMeta() {
  const [nextCategories, nextCities] = await Promise.all([fetchCategories(), fetchCities()])
  categories.value = nextCategories
  cities.value = nextCities
}

async function loadFilterAreas() {
  if (!filters.cityId) {
    filterAreas.value = []
    return
  }
  filterAreas.value = await fetchAreas(Number(filters.cityId))
}

async function loadFormAreas() {
  if (!form.cityId) {
    formAreas.value = []
    return
  }
  formAreas.value = await fetchAreas(Number(form.cityId))
}

async function prepareCreateForm() {
  selectedShopId.value = null
  selectedDetail.value = null
  Object.assign(form, createEmptyShopForm(state.region))

  if (cities.value.length > 0) {
    form.cityId = String(cities.value[0].id)
    await loadFormAreas()
    form.areaId = formAreas.value[0] ? String(formAreas.value[0].id) : ''
  } else {
    formAreas.value = []
  }

  if (categoryOptions.value.length > 0) {
    form.categoryId = String(categoryOptions.value[0].id)
  }
}

async function openCreateForm() {
  if (!canWrite.value) return
  await prepareCreateForm()
}

async function applyDetail(detail: AdminShopDetail) {
  selectedShopId.value = detail.id
  selectedDetail.value = detail

  Object.assign(form, {
    merchantId: detail.merchantId > 0 ? String(detail.merchantId) : '',
    categoryId: String(detail.categoryId),
    cityId: String(detail.cityId),
    areaId: String(detail.areaId),
    name: detail.name,
    coverUrl: detail.coverUrl,
    phone: detail.phone,
    pricePerCapita: String(detail.pricePerCapita),
    currency: detail.currency,
    address: detail.address,
    latitude: detail.latitude == null ? '' : String(detail.latitude),
    longitude: detail.longitude == null ? '' : String(detail.longitude),
    businessHours: detail.businessHours,
    summary: detail.summary,
    score: String(detail.score),
    tasteScore: String(detail.tasteScore),
    envScore: String(detail.envScore),
    serviceScore: String(detail.serviceScore),
    hasDeal: detail.hasDeal,
    openNow: detail.openNow,
    status: String(detail.status),
    tags: detail.tags.join(', '),
  })

  await loadFormAreas()
  form.areaId = String(detail.areaId)
}

async function loadShops() {
  listLoading.value = true
  errorMessage.value = ''

  try {
    pageState.value = await listShops({
      region: state.region,
      keyword: filters.keyword.trim() || undefined,
      categoryId: filters.categoryId ? Number(filters.categoryId) : undefined,
      cityId: filters.cityId ? Number(filters.cityId) : undefined,
      areaId: filters.areaId ? Number(filters.areaId) : undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.shopManagement.loadError
  } finally {
    listLoading.value = false
  }
}

async function bootstrapPage() {
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await loadMeta()
    await loadFilterAreas()
    await prepareCreateForm()
    await loadShops()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.shopManagement.initError
  }
}

async function onFilterCityChange(value: string) {
  filters.cityId = value
  filters.areaId = ''
  await loadFilterAreas()
}

async function onFormCityChange(value: string) {
  form.cityId = value
  form.areaId = ''
  await loadFormAreas()
  form.areaId = formAreas.value[0] ? String(formAreas.value[0].id) : ''
}

async function handleEdit(shopId: number) {
  detailLoading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const detail = await getShop(shopId)
    await applyDetail(detail)
  } catch (error) {
    errorMessage.value =
      error instanceof Error ? error.message : strings.value.shopManagement.detailLoadError
  } finally {
    detailLoading.value = false
  }
}

function parseTags(rawValue: string) {
  return rawValue
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
}

function buildPayload(): AdminShopSavePayload {
  if (!form.categoryId || !form.cityId || !form.areaId) {
    throw new Error(strings.value.shopManagement.validationErrors.categoryCityAreaRequired)
  }
  if (!form.name.trim() || !form.coverUrl.trim() || !form.address.trim() || !form.summary.trim()) {
    throw new Error(strings.value.shopManagement.validationErrors.basicsRequired)
  }

  const latitude = form.latitude.trim() === '' ? null : Number(form.latitude)
  const longitude = form.longitude.trim() === '' ? null : Number(form.longitude)
  if ((latitude == null) !== (longitude == null)) {
    throw new Error(strings.value.shopManagement.validationErrors.coordinatesPairRequired)
  }
  if (latitude != null && (!Number.isFinite(latitude) || latitude < -90 || latitude > 90)) {
    throw new Error(strings.value.shopManagement.validationErrors.latitudeRange)
  }
  if (longitude != null && (!Number.isFinite(longitude) || longitude < -180 || longitude > 180)) {
    throw new Error(strings.value.shopManagement.validationErrors.longitudeRange)
  }

  return {
    merchantId: form.merchantId ? Number(form.merchantId) : 0,
    region: state.region,
    categoryId: Number(form.categoryId),
    cityId: Number(form.cityId),
    areaId: Number(form.areaId),
    name: form.name.trim(),
    coverUrl: form.coverUrl.trim(),
    phone: form.phone.trim(),
    pricePerCapita: Number(form.pricePerCapita),
    currency: form.currency.trim() || defaultCurrency(state.region),
    address: form.address.trim(),
    latitude,
    longitude,
    businessHours: form.businessHours.trim(),
    summary: form.summary.trim(),
    score: Number(form.score),
    tasteScore: Number(form.tasteScore),
    envScore: Number(form.envScore),
    serviceScore: Number(form.serviceScore),
    hasDeal: form.hasDeal,
    openNow: form.openNow,
    status: Number(form.status),
    tags: parseTags(form.tags),
  }
}

async function saveShop() {
  if (!canWrite.value || saving.value) return

  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''
  const isEditing = selectedShopId.value != null

  try {
    const payload = buildPayload()
    const detail =
      isEditing && selectedShopId.value
        ? await updateShop(selectedShopId.value, payload)
        : await createShop(payload)

    await applyDetail(detail)
    await loadShops()
    successMessage.value = isEditing
      ? strings.value.shopManagement.updateSuccess
      : strings.value.shopManagement.createSuccess
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : strings.value.shopManagement.saveError
  } finally {
    saving.value = false
  }
}

async function handleDelete(shopId: number) {
  if (!canWrite.value || removingShopId.value != null) return

  const target = pageState.value?.list.find((item) => item.id === shopId)
  const confirmed = window.confirm(
    strings.value.shopManagement.deleteConfirm(target?.name ?? `#${shopId}`),
  )
  if (!confirmed || !canWrite.value) return

  removingShopId.value = shopId
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await removeShop(shopId)

    if (selectedShopId.value === shopId) {
      await prepareCreateForm()
    }

    if (pageState.value && pageState.value.list.length === 1 && filters.page > 1) {
      filters.page -= 1
    }

    await loadShops()
    successMessage.value = strings.value.shopManagement.deleteSuccess
  } catch (error) {
    errorMessage.value =
      error instanceof Error ? error.message : strings.value.shopManagement.deleteError
  } finally {
    removingShopId.value = null
  }
}

function applyFilters() {
  filters.page = 1
  void loadShops()
}

function resetFilters() {
  filters.keyword = ''
  filters.categoryId = ''
  filters.cityId = ''
  filters.areaId = ''
  filters.page = 1
  filterAreas.value = []
  void loadShops()
}

function goPrevPage() {
  if (!pageState.value || pageState.value.page <= 1) return
  filters.page -= 1
  void loadShops()
}

function goNextPage() {
  if (!pageState.value?.hasMore) return
  filters.page += 1
  void loadShops()
}

watch(
  () => state.region,
  () => {
    filters.keyword = ''
    filters.categoryId = ''
    filters.cityId = ''
    filters.areaId = ''
    filters.page = 1
    void bootstrapPage()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.shopManagement.eyebrow }}</p>
        <h1>{{ strings.shopManagement.heading(state.region) }}</h1>
        <p>{{ strings.shopManagement.description }}</p>
      </div>

      <div class="header-actions">
        <button type="button" class="secondary-button" @click="loadShops">
          {{ strings.shopManagement.refresh }}
        </button>
        <button
          v-if="canWrite"
          type="button"
          class="primary-button"
          data-testid="create-shop"
          @click="openCreateForm"
        >
          {{ strings.shopManagement.create }}
        </button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">{{ strings.shopManagement.filters.eyebrow }}</p>
            <h2>{{ strings.shopManagement.filters.heading }}</h2>
          </div>
          <span class="inline-note">{{ listCountText }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>{{ strings.shopManagement.filters.labels.keyword }}</span>
            <input
              v-model="filters.keyword"
              type="text"
              :placeholder="strings.shopManagement.filters.placeholders.keyword"
            />
          </label>

          <label class="field">
            <span>{{ strings.shopManagement.filters.labels.city }}</span>
            <select :value="filters.cityId" @change="onFilterCityChange(($event.target as HTMLSelectElement).value)">
              <option value="">{{ strings.shopManagement.filters.options.allCities }}</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">
                {{ city.name }}
              </option>
            </select>
          </label>

          <label class="field">
            <span>{{ strings.shopManagement.filters.labels.area }}</span>
            <select v-model="filters.areaId">
              <option value="">{{ strings.shopManagement.filters.options.allAreas }}</option>
              <option v-for="area in filterAreas" :key="area.id" :value="area.id">
                {{ area.name }}
              </option>
            </select>
          </label>

          <label class="field">
            <span>{{ strings.shopManagement.filters.labels.category }}</span>
            <select v-model="filters.categoryId">
              <option value="">{{ strings.shopManagement.filters.options.allCategories }}</option>
              <option v-for="category in categoryOptions" :key="category.id" :value="category.id">
                {{ category.label }}
              </option>
            </select>
          </label>
        </div>

        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">
            {{ strings.shopManagement.filters.apply }}
          </button>
          <button type="button" class="ghost-button" @click="resetFilters">
            {{ strings.shopManagement.filters.reset }}
          </button>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>{{ strings.shopManagement.tableHeaders.shop }}</th>
                <th>{{ strings.shopManagement.tableHeaders.merchant }}</th>
                <th>{{ strings.shopManagement.tableHeaders.categoryRegion }}</th>
                <th>{{ strings.shopManagement.tableHeaders.cityArea }}</th>
                <th>{{ strings.shopManagement.tableHeaders.price }}</th>
                <th>{{ strings.shopManagement.tableHeaders.status }}</th>
                <th>{{ strings.shopManagement.tableHeaders.actions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="listLoading">
                <td colspan="7" class="table-empty">{{ strings.shopManagement.listLoading }}</td>
              </tr>
              <tr v-else-if="!pageState || pageState.list.length === 0">
                <td colspan="7" class="table-empty">{{ strings.shopManagement.listEmpty }}</td>
              </tr>
              <tr v-for="shop in pageState?.list" :key="shop.id">
                <td>
                  <strong>{{ shop.name }}</strong>
                  <p>#{{ shop.id }} · {{ shop.createdAt }}</p>
                </td>
                <td>{{ merchantLabel(shop) }}</td>
                <td>{{ shop.categoryName }} · {{ shop.region }}</td>
                <td>{{ shop.cityName }} · {{ shop.areaName }}</td>
                <td>{{ shop.pricePerCapita }} {{ state.region === 'EU' ? 'EUR' : 'CNY' }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="
                      shop.status === 1
                        ? 'status-pill--good'
                        : shop.status === 2
                          ? 'status-pill--warn'
                          : 'status-pill--muted'
                    "
                  >
                    {{ shopStatusText(shop) }}
                  </span>
                </td>
                <td class="table-actions">
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`open-shop-${shop.id}`"
                    @click="handleEdit(shop.id)"
                  >
                    {{ actionLabel() }}
                  </button>
                  <button
                    v-if="canWrite"
                    type="button"
                    class="table-action table-action--danger"
                    :data-testid="`delete-shop-${shop.id}`"
                    :disabled="removingShopId === shop.id"
                    @click="handleDelete(shop.id)"
                  >
                    {{
                      removingShopId === shop.id
                        ? strings.shopManagement.deleting
                        : strings.shopManagement.delete
                    }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button
            type="button"
            class="ghost-button"
            :disabled="(pageState?.page ?? 1) <= 1"
            @click="goPrevPage"
          >
            {{ strings.shopManagement.previousPage }}
          </button>
          <span>{{ strings.shopManagement.page(pageState?.page ?? 1) }}</span>
          <button
            type="button"
            class="ghost-button"
            :disabled="!pageState?.hasMore"
            @click="goNextPage"
          >
            {{ strings.shopManagement.nextPage }}
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <div class="editor-header">
          <div>
            <p class="eyebrow">{{ strings.shopManagement.editor.eyebrow }}</p>
            <h2>{{ editorTitle }}</h2>
          </div>
          <span class="inline-note">
            {{
              detailLoading
                ? strings.shopManagement.editor.loading
                : canWrite
                  ? strings.shopManagement.editor.regionNote(state.region)
                  : strings.shopManagement.editor.readOnly
            }}
          </span>
        </div>

        <form class="editor-form" data-testid="shop-editor" @submit.prevent="saveShop">
          <fieldset class="editor-fieldset" data-testid="shop-editor-fields" :disabled="!canWrite">
            <div class="form-grid form-grid--two">
              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.merchantId }}</span>
                <input
                  v-model="form.merchantId"
                  type="number"
                  min="0"
                  :placeholder="strings.shopManagement.editor.placeholders.merchantId"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.category }}</span>
                <select v-model="form.categoryId">
                  <option value="">{{ strings.shopManagement.editor.placeholders.category }}</option>
                  <option v-for="category in categoryOptions" :key="category.id" :value="category.id">
                    {{ category.label }}
                  </option>
                </select>
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.city }}</span>
                <select :value="form.cityId" @change="onFormCityChange(($event.target as HTMLSelectElement).value)">
                  <option value="">{{ strings.shopManagement.editor.placeholders.city }}</option>
                  <option v-for="city in cities" :key="city.id" :value="city.id">
                    {{ city.name }}
                  </option>
                </select>
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.area }}</span>
                <select v-model="form.areaId">
                  <option value="">{{ strings.shopManagement.editor.placeholders.area }}</option>
                  <option v-for="area in formAreas" :key="area.id" :value="area.id">
                    {{ area.name }}
                  </option>
                </select>
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.name }}</span>
                <input
                  v-model="form.name"
                  name="shop-name"
                  type="text"
                  :placeholder="strings.shopManagement.editor.placeholders.name"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.phone }}</span>
                <input
                  v-model="form.phone"
                  type="text"
                  :placeholder="strings.shopManagement.editor.placeholders.phone"
                />
              </label>

              <label class="field field--full">
                <span>{{ strings.shopManagement.editor.labels.coverUrl }}</span>
                <input
                  v-model="form.coverUrl"
                  type="url"
                  :placeholder="strings.shopManagement.editor.placeholders.coverUrl"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.pricePerCapita }}</span>
                <input v-model="form.pricePerCapita" type="number" min="0" step="0.1" />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.currency }}</span>
                <input v-model="form.currency" type="text" maxlength="3" />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.businessHours }}</span>
                <input
                  v-model="form.businessHours"
                  type="text"
                  :placeholder="strings.shopManagement.editor.placeholders.businessHours"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.status }}</span>
                <select v-model="form.status">
                  <option value="1">{{ strings.shopManagement.editor.statusOptions.open }}</option>
                  <option value="2">{{ strings.shopManagement.editor.statusOptions.closed }}</option>
                  <option value="0">{{ strings.shopManagement.editor.statusOptions.offline }}</option>
                </select>
              </label>

              <label class="field field--full">
                <span>{{ strings.shopManagement.editor.labels.address }}</span>
                <input
                  v-model="form.address"
                  name="shop-address"
                  type="text"
                  :placeholder="strings.shopManagement.editor.placeholders.address"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.latitude }}</span>
                <input
                  v-model="form.latitude"
                  type="number"
                  min="-90"
                  max="90"
                  step="0.000001"
                  :placeholder="strings.shopManagement.editor.placeholders.latitude"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.longitude }}</span>
                <input
                  v-model="form.longitude"
                  type="number"
                  min="-180"
                  max="180"
                  step="0.000001"
                  :placeholder="strings.shopManagement.editor.placeholders.longitude"
                />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.score }}</span>
                <input v-model="form.score" type="number" min="0" step="0.1" />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.tasteScore }}</span>
                <input v-model="form.tasteScore" type="number" min="0" step="0.1" />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.envScore }}</span>
                <input v-model="form.envScore" type="number" min="0" step="0.1" />
              </label>

              <label class="field">
                <span>{{ strings.shopManagement.editor.labels.serviceScore }}</span>
                <input v-model="form.serviceScore" type="number" min="0" step="0.1" />
              </label>

              <label class="field field--full">
                <span>{{ strings.shopManagement.editor.labels.tags }}</span>
                <input
                  v-model="form.tags"
                  type="text"
                  :placeholder="strings.shopManagement.editor.placeholders.tags"
                />
              </label>

              <label class="field field--full">
                <span>{{ strings.shopManagement.editor.labels.summary }}</span>
                <textarea
                  v-model="form.summary"
                  name="shop-summary"
                  rows="4"
                  :placeholder="strings.shopManagement.editor.placeholders.summary"
                />
              </label>
            </div>

            <div class="toggle-grid">
              <label class="toggle-card">
                <input v-model="form.hasDeal" type="checkbox" />
                <span>{{ strings.shopManagement.editor.toggles.hasDeal }}</span>
              </label>
              <label class="toggle-card">
                <input v-model="form.openNow" type="checkbox" />
                <span>{{ strings.shopManagement.editor.toggles.openNow }}</span>
              </label>
            </div>
          </fieldset>

          <div class="image-preview">
            <img :src="coverPreviewUrl" :alt="form.name || strings.shopManagement.editor.previewFallbacks.alt" />
            <div class="image-preview__body">
              <strong>{{ form.name || strings.shopManagement.editor.previewFallbacks.title }}</strong>
              <p>{{ form.address || strings.shopManagement.editor.previewFallbacks.address }}</p>
              <span>{{ form.businessHours || strings.shopManagement.editor.previewFallbacks.businessHours }}</span>
            </div>
          </div>

          <div class="meta-grid">
            <div>
              <span>{{ strings.shopManagement.editor.labels.createdAt }}</span>
              <strong>{{ selectedDetail?.createdAt ?? '--' }}</strong>
            </div>
            <div>
              <span>{{ strings.shopManagement.editor.labels.updatedAt }}</span>
              <strong>{{ selectedDetail?.updatedAt ?? '--' }}</strong>
            </div>
          </div>

          <div v-if="canWrite" class="form-actions">
            <button type="button" class="ghost-button" @click="openCreateForm">
              {{ strings.shopManagement.editor.reset }}
            </button>
            <button type="submit" class="primary-button" data-testid="save-shop" :disabled="saving">
              {{
                saving
                  ? strings.shopManagement.editor.saving
                  : selectedShopId
                    ? strings.shopManagement.editor.saveUpdate
                    : strings.shopManagement.editor.create
              }}
            </button>
          </div>
          <p v-else class="inline-note">{{ strings.shopManagement.editor.readOnlyMessage }}</p>

          <p class="inline-note">{{ strings.shopManagement.editor.demoMerchantIds }}</p>
        </form>
      </section>
    </div>
  </section>
</template>

<style scoped>
.editor-fieldset {
  min-width: 0;
  margin: 0;
  padding: 0;
  border: 0;
}
</style>
