<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { createAdminBanner, listAdminBanners, removeAdminBanner, updateAdminBanner, updateAdminBannerStatus } from '@/services/admin'
import { fetchCities } from '@/services/meta'
import type { AdminBanner, AdminBannerPayload, City } from '@/types/admin'

type BannerEditor = Omit<AdminBannerPayload, 'cityId'> & {
  id?: number
  cityId: number | ''
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:banner:write'))

const cities = ref<City[]>([])
const banners = ref<AdminBanner[]>([])
const filterCityId = ref<number | ''>('')
const editor = ref<BannerEditor | null>(null)
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let requestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : strings.value.common.requestFailed
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function scopeText(item: AdminBanner) {
  return strings.value.banners.scopeText(item.cityId, item.cityName)
}

async function load() {
  const currentRequestId = ++requestId
  loading.value = true
  resetMessages()
  try {
    const [nextCities, nextBanners] = await Promise.all([
      fetchCities(),
      listAdminBanners(filterCityId.value === '' ? undefined : { cityId: Number(filterCityId.value) }),
    ])
    if (currentRequestId !== requestId) return
    cities.value = nextCities
    banners.value = nextBanners
    if (filterCityId.value !== '' && !nextCities.some((item) => item.id === filterCityId.value)) {
      filterCityId.value = ''
    }
  } catch (error) {
    if (currentRequestId === requestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

function openEditor(item?: AdminBanner) {
  if (!canWrite.value) return
  resetMessages()
  editor.value = item
    ? {
        id: item.id,
        cityId: item.cityId ?? '',
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        linkUrl: item.linkUrl,
        sortNo: item.sortNo,
      }
    : {
        cityId: '',
        title: '',
        subtitle: '',
        imageUrl: '',
        linkUrl: '/',
        sortNo: 0,
      }
}

async function submitEditor() {
  if (!editor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const current = editor.value
  const payload: AdminBannerPayload = {
    cityId: current.cityId === '' ? null : Number(current.cityId),
    title: current.title.trim(),
    subtitle: current.subtitle.trim(),
    imageUrl: current.imageUrl.trim(),
    linkUrl: current.linkUrl.trim(),
    sortNo: Number(current.sortNo),
  }
  try {
    if (current.id) {
      await updateAdminBanner(current.id, payload)
      successMessage.value = strings.value.banners.updated
    } else {
      await createAdminBanner(payload)
      successMessage.value = strings.value.banners.created
    }
    editor.value = null
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleBanner(item: AdminBanner) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminBannerStatus(item.id, !item.enabled)
    successMessage.value = item.enabled ? strings.value.banners.disabled : strings.value.banners.enabled
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteBanner(item: AdminBanner) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(strings.value.banners.deleteConfirm(item.title))
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminBanner(item.id)
    successMessage.value = strings.value.banners.deleted
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

watch(
  () => state.region,
  () => {
    filterCityId.value = ''
    editor.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.banners.eyebrow }}</p>
        <h1>{{ strings.banners.heading }}</h1>
        <p>{{ strings.banners.description(state.region) }}</p>
      </div>
      <button v-if="canWrite" data-testid="create-banner" class="secondary-button" type="button" @click="openEditor()">{{ strings.banners.create }}</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.banners.filterEyebrow }}</p>
          <h2>{{ strings.banners.filterHeading }}</h2>
        </div>
      </div>

      <form class="editor-form" @submit.prevent="load">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.banners.filterCityLabel }}</span>
            <select v-model="filterCityId" name="banner-city-filter">
              <option :value="''">{{ strings.banners.filterCityAll }}</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <div class="field">
            <span>{{ strings.banners.filterHelpLabel }}</span>
            <p class="muted">{{ strings.banners.filterHelpText }}</p>
          </div>
        </div>
        <div class="form-actions">
          <button data-testid="apply-filter" class="primary-button" type="submit" :disabled="loading">
            {{ loading ? strings.banners.loading : strings.banners.applyFilter }}
          </button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.banners.listEyebrow }}</p>
          <h2>{{ strings.banners.listHeading }}</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.banners.tableHeaders.scope }}</th>
              <th>{{ strings.banners.tableHeaders.title }}</th>
              <th>{{ strings.banners.tableHeaders.link }}</th>
              <th>{{ strings.banners.tableHeaders.sort }}</th>
              <th>{{ strings.banners.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.banners.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">{{ strings.banners.loading }}</td>
            </tr>
            <tr v-else-if="!banners.length">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">{{ strings.banners.empty }}</td>
            </tr>
            <tr v-for="item in banners" :key="item.id">
              <td>{{ scopeText(item) }}</td>
              <td>
                <strong>{{ item.title }}</strong>
                <p>{{ item.subtitle || strings.banners.subtitleFallback }}</p>
                <p class="muted">{{ item.imageUrl }}</p>
              </td>
              <td><code>{{ item.linkUrl }}</code></td>
              <td>{{ item.sortNo }}</td>
              <td><span class="status-pill">{{ strings.banners.statusText(item.enabled) }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`edit-banner-${item.id}`" class="table-action" type="button" @click="openEditor(item)">{{ strings.banners.edit }}</button>
                <button :data-testid="`toggle-banner-${item.id}`" class="table-action" type="button" @click="toggleBanner(item)">
                  {{ item.enabled ? strings.banners.disable : strings.banners.enable }}
                </button>
                <button :data-testid="`delete-banner-${item.id}`" class="table-action danger-action" type="button" @click="deleteBanner(item)">{{ strings.banners.delete }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="editor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.banners.editorEyebrow(Boolean(editor.id)) }}</p>
          <h2>{{ strings.banners.editorHeading(Boolean(editor.id)) }}</h2>
        </div>
      </div>

      <form data-testid="banner-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.banners.labels.cityScope }}</span>
            <select v-model="editor.cityId" name="banner-city">
              <option :value="''">{{ strings.banners.cityScopeAll }}</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.banners.labels.sort }}</span>
            <input v-model.number="editor.sortNo" name="banner-sort-no" type="number" min="0" />
          </label>
          <label class="field field--full">
            <span>{{ strings.banners.labels.title }}</span>
            <input v-model="editor.title" name="banner-title" type="text" maxlength="128" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.banners.labels.subtitle }}</span>
            <input v-model="editor.subtitle" name="banner-subtitle" type="text" maxlength="255" />
          </label>
          <label class="field field--full">
            <span>{{ strings.banners.labels.imageUrl }}</span>
            <input v-model="editor.imageUrl" name="banner-image-url" type="text" maxlength="255" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.banners.labels.linkUrl }}</span>
            <input v-model="editor.linkUrl" name="banner-link-url" type="text" maxlength="255" required />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? strings.banners.saving : strings.banners.save }}</button>
          <button class="secondary-button" type="button" @click="editor = null">{{ strings.common.cancel }}</button>
        </div>
      </form>
    </section>
  </section>
</template>
