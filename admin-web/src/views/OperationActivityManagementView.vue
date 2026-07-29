<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  createAdminOperationActivity,
  createAdminOperationActivityItem,
  listAdminOperationActivities,
  listAdminOperationActivityItems,
  removeAdminOperationActivity,
  removeAdminOperationActivityItem,
  updateAdminOperationActivity,
  updateAdminOperationActivityItem,
  updateAdminOperationActivityItemStatus,
  updateAdminOperationActivityStatus,
} from '@/services/admin'
import { fetchCities } from '@/services/meta'
import type {
  AdminOperationActivity,
  AdminOperationActivityItem,
  AdminOperationActivityItemPayload,
  AdminOperationActivityPayload,
  City,
} from '@/types/admin'

type ActivityEditor = Omit<AdminOperationActivityPayload, 'cityId' | 'rule' | 'startAt' | 'endAt'> & {
  id?: number
  cityId: number | ''
  ruleText: string
  startAt: string
  endAt: string
}

type ItemEditor = Omit<AdminOperationActivityItemPayload, 'extra'> & {
  id?: number
  badge: string
  trackCode: string
  url: string
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:activity:write'))
const currentActivity = computed(() => activities.value.find((item) => item.id === selectedActivityId.value) ?? null)
const activityStatusOptions = computed(() => [
  { value: 0, label: strings.value.operationActivities.statusOptions.draft },
  { value: 1, label: strings.value.operationActivities.statusOptions.scheduled },
  { value: 2, label: strings.value.operationActivities.statusOptions.live },
  { value: 3, label: strings.value.operationActivities.statusOptions.offline },
  { value: 4, label: strings.value.operationActivities.statusOptions.ended },
])
const channelOptions = computed(() => [
  { value: 1, label: strings.value.operationActivities.channelOptions.home },
  { value: 2, label: strings.value.operationActivities.channelOptions.search },
  { value: 3, label: strings.value.operationActivities.channelOptions.channel },
  { value: 4, label: strings.value.operationActivities.channelOptions.activityPage },
  { value: 5, label: strings.value.operationActivities.channelOptions.community },
])
const typeOptions = computed(() => [
  { value: 1, label: strings.value.operationActivities.typeOptions.campaign },
  { value: 2, label: strings.value.operationActivities.typeOptions.festival },
  { value: 3, label: strings.value.operationActivities.typeOptions.newcomer },
  { value: 4, label: strings.value.operationActivities.typeOptions.merchantSupport },
  { value: 5, label: strings.value.operationActivities.typeOptions.contentTopic },
])
const targetTypeOptions = computed(() => [
  { value: 1, label: strings.value.operationActivities.targetTypeOptions.shop },
  { value: 2, label: strings.value.operationActivities.targetTypeOptions.deal },
  { value: 3, label: strings.value.operationActivities.targetTypeOptions.post },
  { value: 4, label: strings.value.operationActivities.targetTypeOptions.rank },
  { value: 5, label: strings.value.operationActivities.targetTypeOptions.topic },
  { value: 6, label: strings.value.operationActivities.targetTypeOptions.external },
])

const cities = ref<City[]>([])
const activities = ref<AdminOperationActivity[]>([])
const items = ref<AdminOperationActivityItem[]>([])
const filterCityId = ref<number | ''>('')
const filterStatus = ref<number | ''>('')
const selectedActivityId = ref<number | null>(null)
const activityEditor = ref<ActivityEditor | null>(null)
const itemEditor = ref<ItemEditor | null>(null)
const activityStatusDrafts = ref<Record<number, number>>({})
const loading = ref(false)
const itemLoading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let activityRequestId = 0
let itemRequestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : strings.value.common.requestFailed
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function scopeText(item: AdminOperationActivity) {
  return strings.value.operationActivities.scopeText(item.cityId, item.cityName)
}

function textOf(record: Record<string, unknown>, key: string) {
  const value = record[key]
  return typeof value === 'string' ? value : ''
}

function prettyJson(value: Record<string, unknown>) {
  return value && Object.keys(value).length ? JSON.stringify(value, null, 2) : ''
}

function extraUrl(item: AdminOperationActivityItem) {
  return item.extra ? textOf(item.extra, 'url') : ''
}

function activityChannelText(channel: number, fallback?: string) {
  return strings.value.operationActivities.channelText(channel, fallback)
}

function activityTypeText(type: number, fallback?: string) {
  return strings.value.operationActivities.typeText(type, fallback)
}

function activityStatusText(status: number, fallback?: string) {
  return strings.value.operationActivities.activityStatusText(status, fallback)
}

function itemStatusText(status: number, fallback?: string) {
  return strings.value.operationActivities.itemStatusText(status, fallback)
}

function targetTypeText(targetType: number, fallback?: string) {
  return strings.value.operationActivities.targetTypeText(targetType, fallback)
}

async function loadActivities() {
  const currentRequestId = ++activityRequestId
  loading.value = true
  resetMessages()
  try {
    const query = {
      cityId: filterCityId.value === '' ? undefined : Number(filterCityId.value),
      status: filterStatus.value === '' ? undefined : Number(filterStatus.value),
    }
    const [nextCities, nextActivities] = await Promise.all([
      fetchCities(),
      listAdminOperationActivities(query.cityId == null && query.status == null ? undefined : query),
    ])
    if (currentRequestId !== activityRequestId) return
    cities.value = nextCities
    activities.value = nextActivities
    activityStatusDrafts.value = Object.fromEntries(nextActivities.map((item) => [item.id, item.status]))
    if (filterCityId.value !== '' && !nextCities.some((item) => item.id === filterCityId.value)) {
      filterCityId.value = ''
    }
    const nextSelectedId = selectedActivityId.value != null && nextActivities.some((item) => item.id === selectedActivityId.value)
      ? selectedActivityId.value
      : (nextActivities[0]?.id ?? null)
    selectedActivityId.value = nextSelectedId
    itemEditor.value = null
    if (nextSelectedId == null) {
      items.value = []
      return
    }
    void loadItems(nextSelectedId)
  } catch (error) {
    if (currentRequestId === activityRequestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === activityRequestId) {
      loading.value = false
    }
  }
}

async function loadItems(activityId = selectedActivityId.value) {
  if (activityId == null) {
    items.value = []
    return
  }
  const currentRequestId = ++itemRequestId
  itemLoading.value = true
  try {
    const nextItems = await listAdminOperationActivityItems(activityId)
    if (currentRequestId !== itemRequestId) return
    items.value = nextItems
  } catch (error) {
    if (currentRequestId === itemRequestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === itemRequestId) {
      itemLoading.value = false
    }
  }
}

function selectActivity(item: AdminOperationActivity) {
  selectedActivityId.value = item.id
  itemEditor.value = null
  void loadItems(item.id)
}

function openActivityEditor(item?: AdminOperationActivity) {
  if (!canWrite.value) return
  resetMessages()
  activityEditor.value = item
    ? {
        id: item.id,
        name: item.name,
        code: item.code,
        cityId: item.cityId === 0 ? '' : item.cityId,
        channel: item.channel,
        type: item.type,
        cover: item.cover,
        landingUrl: item.landingUrl,
        ruleText: prettyJson(item.rule),
        startAt: item.startAt,
        endAt: item.endAt,
      }
    : {
        name: '',
        code: '',
        cityId: '',
        channel: 4,
        type: 1,
        cover: '',
        landingUrl: '',
        ruleText: '',
        startAt: '',
        endAt: '',
      }
}

function parseObjectText(value: string, label: string) {
  const source = value.trim()
  if (!source) return null
  let parsed: unknown
  try {
    parsed = JSON.parse(source)
  } catch {
    throw new Error(strings.value.operationActivities.jsonParseError(label))
  }
  if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') {
    throw new Error(strings.value.operationActivities.jsonObjectError(label))
  }
  return parsed as Record<string, unknown>
}

function buildActivityPayload(current: ActivityEditor): AdminOperationActivityPayload {
  return {
    name: current.name.trim(),
    code: current.code.trim(),
    cityId: current.cityId === '' ? 0 : Number(current.cityId),
    channel: Number(current.channel),
    type: Number(current.type),
    cover: current.cover.trim(),
    landingUrl: current.landingUrl.trim(),
    rule: parseObjectText(current.ruleText, strings.value.operationActivities.activityLabels.rule),
    startAt: current.startAt.trim() || null,
    endAt: current.endAt.trim() || null,
  }
}

async function submitActivityEditor() {
  if (!activityEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  try {
    const current = activityEditor.value
    const payload = buildActivityPayload(current)
    if (current.id) {
      await updateAdminOperationActivity(current.id, payload)
      successMessage.value = strings.value.operationActivities.updated
    } else {
      await createAdminOperationActivity(payload)
      successMessage.value = strings.value.operationActivities.created
    }
    activityEditor.value = null
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function applyActivityStatus(item: AdminOperationActivity) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminOperationActivityStatus(item.id, Number(activityStatusDrafts.value[item.id] ?? item.status))
    successMessage.value = strings.value.operationActivities.statusUpdated
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteActivity(item: AdminOperationActivity) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(strings.value.operationActivities.deleteActivityConfirm(item.name))
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminOperationActivity(item.id)
    successMessage.value = strings.value.operationActivities.deleted
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

function openItemEditor(item?: AdminOperationActivityItem) {
  if (!canWrite.value || !currentActivity.value) return
  resetMessages()
  itemEditor.value = item
    ? {
        id: item.id,
        targetType: item.targetType,
        targetId: item.targetId,
        title: item.title,
        subtitle: item.subtitle,
        image: item.image,
        sort: item.sort,
        badge: item.extra ? textOf(item.extra, 'badge') : '',
        trackCode: item.extra ? textOf(item.extra, 'trackCode') : '',
        url: item.extra ? textOf(item.extra, 'url') : '',
      }
    : {
        targetType: 1,
        targetId: 0,
        title: '',
        subtitle: '',
        image: '',
        sort: 0,
        badge: '',
        trackCode: '',
        url: '',
      }
}

function buildItemPayload(current: ItemEditor): AdminOperationActivityItemPayload {
  const extra: Record<string, unknown> = {}
  if (current.badge.trim()) extra.badge = current.badge.trim()
  if (current.trackCode.trim()) extra.trackCode = current.trackCode.trim()
  if (current.url.trim()) extra.url = current.url.trim()
  if (current.targetType === 6 && !current.url.trim()) {
    throw new Error(strings.value.operationActivities.externalUrlRequired)
  }
  return {
    targetType: Number(current.targetType),
    targetId: Number(current.targetType) === 6 ? 0 : Number(current.targetId),
    title: current.title.trim(),
    subtitle: current.subtitle.trim(),
    image: current.image.trim(),
    sort: Number(current.sort),
    extra: Object.keys(extra).length ? extra : null,
  }
}

async function submitItemEditor() {
  if (!itemEditor.value || !currentActivity.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  try {
    const current = itemEditor.value
    const payload = buildItemPayload(current)
    if (current.id) {
      await updateAdminOperationActivityItem(currentActivity.value.id, current.id, payload)
      successMessage.value = strings.value.operationActivities.itemUpdated
    } else {
      await createAdminOperationActivityItem(currentActivity.value.id, payload)
      successMessage.value = strings.value.operationActivities.itemCreated
    }
    itemEditor.value = null
    await loadItems(currentActivity.value.id)
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleItem(item: AdminOperationActivityItem) {
  if (!currentActivity.value || !canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminOperationActivityItemStatus(
      currentActivity.value.id,
      item.id,
      item.status === 1 ? 2 : 1,
    )
    successMessage.value = item.status === 1 ? strings.value.operationActivities.itemDisabled : strings.value.operationActivities.itemEnabled
    await loadItems(currentActivity.value.id)
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteItem(item: AdminOperationActivityItem) {
  if (!currentActivity.value || !canWrite.value || saving.value) return
  const confirmed = window.confirm(strings.value.operationActivities.deleteItemConfirm(item.title))
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminOperationActivityItem(currentActivity.value.id, item.id)
    successMessage.value = strings.value.operationActivities.itemDeleted
    await loadItems(currentActivity.value.id)
    await loadActivities()
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
    filterStatus.value = ''
    selectedActivityId.value = null
    activityEditor.value = null
    itemEditor.value = null
    void loadActivities()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.operationActivities.eyebrow }}</p>
        <h1>{{ strings.operationActivities.heading }}</h1>
        <p>{{ strings.operationActivities.description(state.region) }}</p>
      </div>
      <button v-if="canWrite" data-testid="create-activity" class="secondary-button" type="button" @click="openActivityEditor()">{{ strings.operationActivities.create }}</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.operationActivities.filtersEyebrow }}</p>
          <h2>{{ strings.operationActivities.filtersHeading }}</h2>
        </div>
      </div>

      <form class="editor-form" @submit.prevent="loadActivities">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.operationActivities.filterLabels.city }}</span>
            <select v-model="filterCityId" name="activity-city-filter">
              <option :value="''">{{ strings.operationActivities.filterOptions.allCities }}</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.filterLabels.status }}</span>
            <select v-model="filterStatus" name="activity-status-filter">
              <option :value="''">{{ strings.operationActivities.filterOptions.allStatuses }}</option>
              <option v-for="option in activityStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
        </div>
        <div class="form-actions">
          <button data-testid="apply-activity-filter" class="primary-button" type="submit" :disabled="loading">
            {{ loading ? strings.operationActivities.loading : strings.operationActivities.applyFilters }}
          </button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.operationActivities.listEyebrow }}</p>
          <h2>{{ strings.operationActivities.listHeading }}</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.operationActivities.tableHeaders.scopeCode }}</th>
              <th>{{ strings.operationActivities.tableHeaders.activity }}</th>
              <th>{{ strings.operationActivities.tableHeaders.delivery }}</th>
              <th>{{ strings.operationActivities.tableHeaders.items }}</th>
              <th>{{ strings.operationActivities.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.operationActivities.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">{{ strings.operationActivities.loading }}</td>
            </tr>
            <tr v-else-if="!activities.length">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">{{ strings.operationActivities.empty }}</td>
            </tr>
            <tr v-for="item in activities" :key="item.id">
              <td>
                <strong>{{ scopeText(item) }}</strong>
                <p><code>{{ item.code }}</code></p>
              </td>
              <td>
                <strong>{{ item.name }}</strong>
                <p>{{ activityTypeText(item.type, item.typeText) }}</p>
                <p class="muted">{{ item.cover }}</p>
              </td>
              <td>
                <p>{{ activityChannelText(item.channel, item.channelText) }}</p>
                <p>{{ item.startAt || strings.operationActivities.startFallback }}</p>
                <p>{{ item.endAt || strings.operationActivities.endFallback }}</p>
              </td>
              <td>{{ item.itemCount }}</td>
              <td><span class="status-pill">{{ activityStatusText(item.status, item.statusText) }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`select-activity-${item.id}`" class="table-action" type="button" @click="selectActivity(item)">{{ strings.operationActivities.manageItems }}</button>
                <button :data-testid="`edit-activity-${item.id}`" class="table-action" type="button" @click="openActivityEditor(item)">{{ strings.operationActivities.edit }}</button>
                <select v-model.number="activityStatusDrafts[item.id]" :name="`activity-status-${item.id}`">
                  <option v-for="option in activityStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <button :data-testid="`status-activity-${item.id}`" class="table-action" type="button" @click="applyActivityStatus(item)">{{ strings.operationActivities.changeStatus }}</button>
                <button :data-testid="`delete-activity-${item.id}`" class="table-action danger-action" type="button" @click="deleteActivity(item)">{{ strings.operationActivities.delete }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="activityEditor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.operationActivities.activityEditorEyebrow(Boolean(activityEditor.id)) }}</p>
          <h2>{{ strings.operationActivities.activityEditorHeading(Boolean(activityEditor.id)) }}</h2>
        </div>
      </div>

      <form data-testid="activity-editor" class="editor-form" @submit.prevent="submitActivityEditor">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.operationActivities.activityLabels.cityScope }}</span>
            <select v-model="activityEditor.cityId" name="activity-city">
              <option :value="''">{{ strings.operationActivities.scopeText(0, '') }}</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.activityLabels.channel }}</span>
            <select v-model.number="activityEditor.channel" name="activity-channel">
              <option v-for="option in channelOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.activityLabels.type }}</span>
            <select v-model.number="activityEditor.type" name="activity-type">
              <option v-for="option in typeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.activityLabels.startAt }}</span>
            <input v-model="activityEditor.startAt" name="activity-start-at" type="text" :placeholder="strings.operationActivities.activityPlaceholders.startAt" />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.activityLabels.name }}</span>
            <input v-model="activityEditor.name" name="activity-name" type="text" maxlength="128" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.activityLabels.code }}</span>
            <input v-model="activityEditor.code" name="activity-code" type="text" maxlength="64" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.activityLabels.cover }}</span>
            <input v-model="activityEditor.cover" name="activity-cover" type="text" maxlength="255" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.activityLabels.landingUrl }}</span>
            <input v-model="activityEditor.landingUrl" name="activity-landing-url" type="text" maxlength="255" required />
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.activityLabels.endAt }}</span>
            <input v-model="activityEditor.endAt" name="activity-end-at" type="text" :placeholder="strings.operationActivities.activityPlaceholders.endAt" />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.activityLabels.rule }}</span>
            <textarea v-model="activityEditor.ruleText" name="activity-rule" rows="6" :placeholder="strings.operationActivities.activityPlaceholders.rule"></textarea>
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? strings.operationActivities.saving : strings.operationActivities.saveActivity }}</button>
          <button class="secondary-button" type="button" @click="activityEditor = null">{{ strings.common.cancel }}</button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.operationActivities.itemsEyebrow }}</p>
          <h2>{{ strings.operationActivities.itemsHeading(currentActivity ? currentActivity.name : null) }}</h2>
          <p v-if="currentActivity">{{ strings.operationActivities.itemsDescription(scopeText(currentActivity), activityStatusText(currentActivity.status, currentActivity.statusText)) }}</p>
        </div>
        <button v-if="canWrite && currentActivity" data-testid="create-activity-item" class="secondary-button" type="button" @click="openItemEditor()">{{ strings.operationActivities.createItem }}</button>
      </div>

      <p v-if="!currentActivity" class="table-empty">{{ strings.operationActivities.noActivitySelected }}</p>

      <div v-else class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.operationActivities.itemTableHeaders.resource }}</th>
              <th>{{ strings.operationActivities.itemTableHeaders.copy }}</th>
              <th>{{ strings.operationActivities.itemTableHeaders.sort }}</th>
              <th>{{ strings.operationActivities.itemTableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.operationActivities.itemTableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="itemLoading">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">{{ strings.operationActivities.itemsLoading }}</td>
            </tr>
            <tr v-else-if="!items.length">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">{{ strings.operationActivities.itemEmpty }}</td>
            </tr>
            <tr v-for="item in items" :key="item.id">
              <td>
                <strong>{{ targetTypeText(item.targetType, item.targetTypeText) }}</strong>
                <p>{{ item.targetName || strings.operationActivities.targetFallback(item.targetId) }}</p>
                <p v-if="extraUrl(item)" class="muted">{{ extraUrl(item) }}</p>
              </td>
              <td>
                <strong>{{ item.title }}</strong>
                <p>{{ item.subtitle || strings.operationActivities.subtitleFallback }}</p>
                <p class="muted">{{ item.image }}</p>
              </td>
              <td>{{ item.sort }}</td>
              <td><span class="status-pill">{{ itemStatusText(item.status, item.statusText) }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`edit-activity-item-${item.id}`" class="table-action" type="button" @click="openItemEditor(item)">{{ strings.operationActivities.edit }}</button>
                <button :data-testid="`toggle-activity-item-${item.id}`" class="table-action" type="button" @click="toggleItem(item)">
                  {{ item.status === 1 ? strings.operationActivities.itemDisable : strings.operationActivities.itemEnable }}
                </button>
                <button :data-testid="`delete-activity-item-${item.id}`" class="table-action danger-action" type="button" @click="deleteItem(item)">{{ strings.operationActivities.delete }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="itemEditor && canWrite && currentActivity" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.operationActivities.itemEditorEyebrow(Boolean(itemEditor.id)) }}</p>
          <h2>{{ strings.operationActivities.itemEditorHeading(currentActivity.name, Boolean(itemEditor.id)) }}</h2>
        </div>
      </div>

      <form data-testid="activity-item-editor" class="editor-form" @submit.prevent="submitItemEditor">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.operationActivities.itemLabels.targetType }}</span>
            <select v-model.number="itemEditor.targetType" name="item-target-type">
              <option v-for="option in targetTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.itemLabels.targetId }}</span>
            <input v-model.number="itemEditor.targetId" name="item-target-id" type="number" min="0" :disabled="itemEditor.targetType === 6" />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.itemLabels.title }}</span>
            <input v-model="itemEditor.title" name="item-title" type="text" maxlength="128" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.itemLabels.subtitle }}</span>
            <input v-model="itemEditor.subtitle" name="item-subtitle" type="text" maxlength="255" />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.itemLabels.image }}</span>
            <input v-model="itemEditor.image" name="item-image" type="text" maxlength="255" required />
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.itemLabels.sort }}</span>
            <input v-model.number="itemEditor.sort" name="item-sort" type="number" min="0" />
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.itemLabels.badge }}</span>
            <input v-model="itemEditor.badge" name="item-badge" type="text" maxlength="32" />
          </label>
          <label class="field">
            <span>{{ strings.operationActivities.itemLabels.trackCode }}</span>
            <input v-model="itemEditor.trackCode" name="item-track-code" type="text" maxlength="64" />
          </label>
          <label class="field field--full">
            <span>{{ strings.operationActivities.itemLabels.url }}</span>
            <input v-model="itemEditor.url" name="item-url" type="text" maxlength="255" :placeholder="strings.operationActivities.itemUrlPlaceholder" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? strings.operationActivities.saving : strings.operationActivities.saveItem }}</button>
          <button class="secondary-button" type="button" @click="itemEditor = null">{{ strings.common.cancel }}</button>
        </div>
      </form>
    </section>
  </section>
</template>
