<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  createGeoArea,
  createGeoCategory,
  createGeoCity,
  listGeoAreas,
  listGeoCategories,
  listGeoCities,
  removeGeoArea,
  removeGeoCategory,
  removeGeoCity,
  updateGeoArea,
  updateGeoAreaStatus,
  updateGeoCategory,
  updateGeoCategoryStatus,
  updateGeoCity,
  updateGeoCityStatus,
} from '@/services/geodata'
import type {
  AdminGeoArea,
  AdminGeoCategory,
  AdminGeoCity,
  GeoAreaPayload,
  GeoCategoryPayload,
  GeoCityPayload,
} from '@/types/admin'

type Tab = 'categories' | 'cities' | 'areas'
type CategoryEditor = GeoCategoryPayload & { id?: number }
type CityEditor = GeoCityPayload & { id?: number }
type AreaEditor = GeoAreaPayload & { id?: number }

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const activeTab = ref<Tab>('categories')
const categories = ref<AdminGeoCategory[]>([])
const cities = ref<AdminGeoCity[]>([])
const areas = ref<AdminGeoArea[]>([])
const selectedCityId = ref<number | ''>('')
const categoryEditor = ref<CategoryEditor | null>(null)
const cityEditor = ref<CityEditor | null>(null)
const areaEditor = ref<AreaEditor | null>(null)
const loading = ref(false)
const areaLoading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let regionRequestId = 0
let areaRequestId = 0

const canWrite = computed(() => state.permissions.includes('data:geo:write'))
const activeCities = computed(() => cities.value.filter((city) => city.status === 1))

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : strings.value.common.requestFailed
}

function geoStatusText(status: number) {
  return strings.value.basicDataManagement.statusText(status)
}

function categoryParentLabel(item: AdminGeoCategory) {
  return item.parentId === 0
    ? strings.value.basicDataManagement.category.root
    : categories.value.find((parent) => parent.id === item.parentId)?.name ?? `#${item.parentId}`
}

function areaCityOptionLabel(city: AdminGeoCity) {
  return `${city.name}${city.status === 0 ? strings.value.basicDataManagement.area.disabledSuffix : ''}`
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function closeEditors() {
  categoryEditor.value = null
  cityEditor.value = null
  areaEditor.value = null
}

async function reloadRegion() {
  const requestId = ++regionRequestId
  ++areaRequestId
  areaLoading.value = false
  resetMessages()
  closeEditors()
  categories.value = []
  cities.value = []
  areas.value = []
  selectedCityId.value = ''
  loading.value = true

  try {
    const [nextCategories, nextCities] = await Promise.all([listGeoCategories(), listGeoCities()])
    if (requestId !== regionRequestId) return
    categories.value = nextCategories
    cities.value = nextCities
  } catch (error) {
    if (requestId === regionRequestId) errorMessage.value = messageOf(error)
  } finally {
    if (requestId === regionRequestId) loading.value = false
  }
}

async function loadAreas(cityId: number | '') {
  const requestId = ++areaRequestId
  areas.value = []
  areaEditor.value = null
  areaLoading.value = false
  resetMessages()
  if (cityId === '') return
  areaLoading.value = true

  try {
    const nextAreas = await listGeoAreas(cityId)
    if (requestId === areaRequestId && selectedCityId.value === cityId) {
      areas.value = nextAreas
    }
  } catch (error) {
    if (requestId === areaRequestId) errorMessage.value = messageOf(error)
  } finally {
    if (requestId === areaRequestId) areaLoading.value = false
  }
}

function handleAreaCityChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value
  selectedCityId.value = value ? Number(value) : ''
  void loadAreas(selectedCityId.value)
}

function openCategoryEditor(item?: AdminGeoCategory) {
  if (!canWrite.value) return
  resetMessages()
  categoryEditor.value = item
    ? { id: item.id, parentId: item.parentId, name: item.name, sortNo: item.sortNo }
    : { parentId: 0, name: '', sortNo: 0 }
}

function openCityEditor(item?: AdminGeoCity) {
  if (!canWrite.value) return
  resetMessages()
  cityEditor.value = item
    ? { id: item.id, code: item.code, name: item.name, sortNo: item.sortNo }
    : { code: '', name: '', sortNo: 0 }
}

function openAreaEditor(item?: AdminGeoArea) {
  if (!canWrite.value || selectedCityId.value === '') return
  resetMessages()
  areaEditor.value = item
    ? { id: item.id, cityId: item.cityId, name: item.name, sortNo: item.sortNo }
    : { cityId: selectedCityId.value, name: '', sortNo: 0 }
}

async function submitCategory() {
  if (!categoryEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const editor = categoryEditor.value
  const payload: GeoCategoryPayload = {
    parentId: Number(editor.parentId),
    name: editor.name.trim(),
    sortNo: Number(editor.sortNo),
  }
  try {
    if (editor.id) await updateGeoCategory(editor.id, payload)
    else await createGeoCategory(payload)
    categoryEditor.value = null
    await reloadRegion()
    successMessage.value = editor.id
      ? strings.value.basicDataManagement.category.updateSuccess
      : strings.value.basicDataManagement.category.createSuccess
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function submitCity() {
  if (!cityEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const editor = cityEditor.value
  const payload: GeoCityPayload = {
    code: editor.code.trim().toUpperCase(),
    name: editor.name.trim(),
    sortNo: Number(editor.sortNo),
  }
  try {
    if (editor.id) await updateGeoCity(editor.id, payload)
    else await createGeoCity(payload)
    cityEditor.value = null
    await reloadRegion()
    successMessage.value = editor.id
      ? strings.value.basicDataManagement.city.updateSuccess
      : strings.value.basicDataManagement.city.createSuccess
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function submitArea() {
  if (!areaEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const editor = areaEditor.value
  const payload: GeoAreaPayload = {
    cityId: Number(editor.cityId),
    name: editor.name.trim(),
    sortNo: Number(editor.sortNo),
  }
  try {
    if (editor.id) await updateGeoArea(editor.id, payload)
    else await createGeoArea(payload)
    areaEditor.value = null
    await loadAreas(selectedCityId.value)
    successMessage.value = editor.id
      ? strings.value.basicDataManagement.area.updateSuccess
      : strings.value.basicDataManagement.area.createSuccess
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleCategory(item: AdminGeoCategory) {
  await runMutation(
    () => updateGeoCategoryStatus(item.id, item.status === 1 ? 0 : 1),
    reloadRegion,
    item.status === 1
      ? strings.value.basicDataManagement.category.disableSuccess
      : strings.value.basicDataManagement.category.enableSuccess,
  )
}

async function toggleCity(item: AdminGeoCity) {
  await runMutation(
    () => updateGeoCityStatus(item.id, item.status === 1 ? 0 : 1),
    reloadRegion,
    item.status === 1
      ? strings.value.basicDataManagement.city.disableSuccess
      : strings.value.basicDataManagement.city.enableSuccess,
  )
}

async function toggleArea(item: AdminGeoArea) {
  await runMutation(
    () => updateGeoAreaStatus(item.id, item.status === 1 ? 0 : 1),
    () => loadAreas(selectedCityId.value),
    item.status === 1
      ? strings.value.basicDataManagement.area.disableSuccess
      : strings.value.basicDataManagement.area.enableSuccess,
  )
}

async function deleteCategory(item: AdminGeoCategory) {
  if (!window.confirm(strings.value.basicDataManagement.category.deleteConfirm(item.name))) return
  await runMutation(
    () => removeGeoCategory(item.id),
    reloadRegion,
    strings.value.basicDataManagement.category.deleteSuccess,
  )
}

async function deleteCity(item: AdminGeoCity) {
  if (!window.confirm(strings.value.basicDataManagement.city.deleteConfirm(item.name))) return
  await runMutation(
    () => removeGeoCity(item.id),
    reloadRegion,
    strings.value.basicDataManagement.city.deleteSuccess,
  )
}

async function deleteArea(item: AdminGeoArea) {
  if (!window.confirm(strings.value.basicDataManagement.area.deleteConfirm(item.name))) return
  await runMutation(
    () => removeGeoArea(item.id),
    () => loadAreas(selectedCityId.value),
    strings.value.basicDataManagement.area.deleteSuccess,
  )
}

async function runMutation(action: () => Promise<unknown>, reload: () => Promise<void>, success: string) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await action()
    await reload()
    successMessage.value = success
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

watch(
  () => state.region,
  () => void reloadRegion(),
  { immediate: true },
)
</script>

<template>
  <section class="page-section geo-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.basicDataManagement.eyebrow(state.region) }}</p>
        <h1>{{ strings.basicDataManagement.heading }}</h1>
        <p>{{ strings.basicDataManagement.description }}</p>
      </div>
      <span class="status-pill" :class="canWrite ? 'status-pill--good' : 'status-pill--muted'">
        {{ canWrite ? strings.basicDataManagement.writable : strings.basicDataManagement.readOnly }}
      </span>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success" role="status">{{ successMessage }}</p>

    <div class="geo-tabs" role="tablist" :aria-label="strings.basicDataManagement.tabsAriaLabel">
      <button
        type="button"
        :class="{ 'is-active': activeTab === 'categories' }"
        data-testid="tab-categories"
        @click="activeTab = 'categories'"
      >
        {{ strings.basicDataManagement.tabs.categories }}
      </button>
      <button
        type="button"
        :class="{ 'is-active': activeTab === 'cities' }"
        data-testid="tab-cities"
        @click="activeTab = 'cities'"
      >
        {{ strings.basicDataManagement.tabs.cities }}
      </button>
      <button
        type="button"
        :class="{ 'is-active': activeTab === 'areas' }"
        data-testid="tab-areas"
        @click="activeTab = 'areas'"
      >
        {{ strings.basicDataManagement.tabs.areas }}
      </button>
    </div>

    <p v-if="loading" class="feedback">{{ strings.basicDataManagement.loading(state.region) }}</p>

    <section
      v-else-if="activeTab === 'categories'"
      class="geo-workspace"
      aria-labelledby="category-heading"
    >
      <div class="geo-workspace__toolbar">
        <div>
          <h2 id="category-heading">{{ strings.basicDataManagement.category.heading }}</h2>
          <p>{{ strings.basicDataManagement.category.summary(categories.length) }}</p>
        </div>
        <button
          v-if="canWrite"
          type="button"
          class="primary-button"
          data-testid="create-category"
          @click="openCategoryEditor()"
        >
          {{ strings.basicDataManagement.category.create }}
        </button>
      </div>

      <form
        v-if="categoryEditor"
        class="geo-editor"
        data-testid="category-form"
        @submit.prevent="submitCategory"
      >
        <label class="field">
          <span>{{ strings.basicDataManagement.category.labels.parent }}</span>
          <select
            v-model.number="categoryEditor.parentId"
            name="category-parent"
            :disabled="saving"
          >
            <option :value="0">{{ strings.basicDataManagement.category.root }}</option>
            <option
              v-for="item in categories.filter((entry) => entry.id !== categoryEditor?.id)"
              :key="item.id"
              :value="item.id"
            >
              {{ item.name }}
            </option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.basicDataManagement.category.labels.name }}</span>
          <input
            v-model="categoryEditor.name"
            name="category-name"
            maxlength="64"
            required
            :disabled="saving"
          />
        </label>
        <label class="field">
          <span>{{ strings.basicDataManagement.category.labels.sort }}</span>
          <input
            v-model.number="categoryEditor.sortNo"
            name="category-sort"
            type="number"
            min="0"
            max="999999"
            required
            :disabled="saving"
          />
        </label>
        <div class="form-actions">
          <button type="submit" class="primary-button" :disabled="saving">
            {{ strings.basicDataManagement.actions.save }}
          </button>
          <button
            type="button"
            class="ghost-button"
            :disabled="saving"
            @click="categoryEditor = null"
          >
            {{ strings.common.cancel }}
          </button>
        </div>
      </form>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.basicDataManagement.category.tableHeaders.name }}</th>
              <th>{{ strings.basicDataManagement.category.tableHeaders.parent }}</th>
              <th>{{ strings.basicDataManagement.category.tableHeaders.sort }}</th>
              <th>{{ strings.basicDataManagement.category.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.basicDataManagement.category.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in categories" :key="item.id">
              <td>
                <strong>{{ item.name }}</strong>
                <p>#{{ item.id }}</p>
              </td>
              <td>{{ categoryParentLabel(item) }}</td>
              <td class="numeric-cell">{{ item.sortNo }}</td>
              <td>
                <span
                  class="status-pill"
                  :class="item.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                >
                  {{ geoStatusText(item.status) }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`edit-category-${item.id}`"
                    :title="strings.basicDataManagement.category.editTitle"
                    @click="openCategoryEditor(item)"
                  >
                    {{ strings.basicDataManagement.actions.edit }}
                  </button>
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`status-category-${item.id}`"
                    :disabled="saving"
                    @click="toggleCategory(item)"
                  >
                    {{
                      item.status === 1
                        ? strings.basicDataManagement.actions.disable
                        : strings.basicDataManagement.actions.enable
                    }}
                  </button>
                  <button
                    type="button"
                    class="table-action table-action--danger"
                    :data-testid="`delete-category-${item.id}`"
                    :disabled="saving"
                    @click="deleteCategory(item)"
                  >
                    {{ strings.basicDataManagement.actions.delete }}
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="categories.length === 0">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">
                {{ strings.basicDataManagement.category.empty }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-else-if="activeTab === 'cities'" class="geo-workspace" aria-labelledby="city-heading">
      <div class="geo-workspace__toolbar">
        <div>
          <h2 id="city-heading">{{ strings.basicDataManagement.city.heading }}</h2>
          <p>{{ strings.basicDataManagement.city.summary(cities.length) }}</p>
        </div>
        <button
          v-if="canWrite"
          type="button"
          class="primary-button"
          data-testid="create-city"
          @click="openCityEditor()"
        >
          {{ strings.basicDataManagement.city.create }}
        </button>
      </div>

      <form
        v-if="cityEditor"
        class="geo-editor"
        data-testid="city-form"
        @submit.prevent="submitCity"
      >
        <label class="field">
          <span>{{ strings.basicDataManagement.city.labels.code }}</span>
          <input
            v-model="cityEditor.code"
            name="city-code"
            maxlength="32"
            required
            :disabled="saving"
          />
        </label>
        <label class="field">
          <span>{{ strings.basicDataManagement.city.labels.name }}</span>
          <input
            v-model="cityEditor.name"
            name="city-name"
            maxlength="64"
            required
            :disabled="saving"
          />
        </label>
        <label class="field">
          <span>{{ strings.basicDataManagement.city.labels.sort }}</span>
          <input
            v-model.number="cityEditor.sortNo"
            name="city-sort"
            type="number"
            min="0"
            max="999999"
            required
            :disabled="saving"
          />
        </label>
        <div class="form-actions">
          <button type="submit" class="primary-button" :disabled="saving">
            {{ strings.basicDataManagement.actions.save }}
          </button>
          <button
            type="button"
            class="ghost-button"
            :disabled="saving"
            @click="cityEditor = null"
          >
            {{ strings.common.cancel }}
          </button>
        </div>
      </form>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.basicDataManagement.city.tableHeaders.city }}</th>
              <th>{{ strings.basicDataManagement.city.tableHeaders.code }}</th>
              <th>{{ strings.basicDataManagement.city.tableHeaders.sort }}</th>
              <th>{{ strings.basicDataManagement.city.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.basicDataManagement.city.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in cities" :key="item.id">
              <td>
                <strong>{{ item.name }}</strong>
                <p>#{{ item.id }}</p>
              </td>
              <td><span class="code-box">{{ item.code }}</span></td>
              <td class="numeric-cell">{{ item.sortNo }}</td>
              <td>
                <span
                  class="status-pill"
                  :class="item.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                >
                  {{ geoStatusText(item.status) }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`edit-city-${item.id}`"
                    @click="openCityEditor(item)"
                  >
                    {{ strings.basicDataManagement.actions.edit }}
                  </button>
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`status-city-${item.id}`"
                    :disabled="saving"
                    @click="toggleCity(item)"
                  >
                    {{
                      item.status === 1
                        ? strings.basicDataManagement.actions.disable
                        : strings.basicDataManagement.actions.enable
                    }}
                  </button>
                  <button
                    type="button"
                    class="table-action table-action--danger"
                    :data-testid="`delete-city-${item.id}`"
                    :disabled="saving"
                    @click="deleteCity(item)"
                  >
                    {{ strings.basicDataManagement.actions.delete }}
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="cities.length === 0">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">
                {{ strings.basicDataManagement.city.empty }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-else class="geo-workspace" aria-labelledby="area-heading">
      <div class="geo-workspace__toolbar">
        <div>
          <h2 id="area-heading">{{ strings.basicDataManagement.area.heading }}</h2>
          <p>{{ strings.basicDataManagement.area.summary }}</p>
        </div>
        <button
          v-if="canWrite && selectedCityId !== ''"
          type="button"
          class="primary-button"
          data-testid="create-area"
          @click="openAreaEditor()"
        >
          {{ strings.basicDataManagement.area.create }}
        </button>
      </div>

      <label class="field geo-city-filter">
        <span>{{ strings.basicDataManagement.area.cityFilterLabel }}</span>
        <select
          :value="selectedCityId"
          data-testid="area-city-select"
          @change="handleAreaCityChange"
        >
          <option value="">{{ strings.basicDataManagement.area.selectCity }}</option>
          <option v-for="city in cities" :key="city.id" :value="city.id">
            {{ areaCityOptionLabel(city) }}
          </option>
        </select>
      </label>

      <form
        v-if="areaEditor"
        class="geo-editor"
        data-testid="area-form"
        @submit.prevent="submitArea"
      >
        <label class="field">
          <span>{{ strings.basicDataManagement.area.labels.city }}</span>
          <select v-model.number="areaEditor.cityId" name="area-city" required :disabled="saving">
            <option v-for="city in activeCities" :key="city.id" :value="city.id">
              {{ city.name }}
            </option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.basicDataManagement.area.labels.name }}</span>
          <input
            v-model="areaEditor.name"
            name="area-name"
            maxlength="64"
            required
            :disabled="saving"
          />
        </label>
        <label class="field">
          <span>{{ strings.basicDataManagement.area.labels.sort }}</span>
          <input
            v-model.number="areaEditor.sortNo"
            name="area-sort"
            type="number"
            min="0"
            max="999999"
            required
            :disabled="saving"
          />
        </label>
        <div class="form-actions">
          <button type="submit" class="primary-button" :disabled="saving">
            {{ strings.basicDataManagement.actions.save }}
          </button>
          <button
            type="button"
            class="ghost-button"
            :disabled="saving"
            @click="areaEditor = null"
          >
            {{ strings.common.cancel }}
          </button>
        </div>
      </form>

      <p v-if="areaLoading" class="feedback">{{ strings.basicDataManagement.area.loading }}</p>
      <div v-else class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.basicDataManagement.area.tableHeaders.area }}</th>
              <th>{{ strings.basicDataManagement.area.tableHeaders.city }}</th>
              <th>{{ strings.basicDataManagement.area.tableHeaders.sort }}</th>
              <th>{{ strings.basicDataManagement.area.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.basicDataManagement.area.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in areas" :key="item.id">
              <td>
                <strong>{{ item.name }}</strong>
                <p>#{{ item.id }}</p>
              </td>
              <td>{{ cities.find((city) => city.id === item.cityId)?.name ?? `#${item.cityId}` }}</td>
              <td class="numeric-cell">{{ item.sortNo }}</td>
              <td>
                <span
                  class="status-pill"
                  :class="item.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                >
                  {{ geoStatusText(item.status) }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`edit-area-${item.id}`"
                    @click="openAreaEditor(item)"
                  >
                    {{ strings.basicDataManagement.actions.edit }}
                  </button>
                  <button
                    type="button"
                    class="table-action"
                    :data-testid="`status-area-${item.id}`"
                    :disabled="saving"
                    @click="toggleArea(item)"
                  >
                    {{
                      item.status === 1
                        ? strings.basicDataManagement.actions.disable
                        : strings.basicDataManagement.actions.enable
                    }}
                  </button>
                  <button
                    type="button"
                    class="table-action table-action--danger"
                    :data-testid="`delete-area-${item.id}`"
                    :disabled="saving"
                    @click="deleteArea(item)"
                  >
                    {{ strings.basicDataManagement.actions.delete }}
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="selectedCityId === ''">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">
                {{ strings.basicDataManagement.area.emptySelectCity }}
              </td>
            </tr>
            <tr v-else-if="areas.length === 0">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">
                {{ strings.basicDataManagement.area.empty }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </section>
</template>
