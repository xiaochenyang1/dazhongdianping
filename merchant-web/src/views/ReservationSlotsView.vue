<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  createReservationSlot,
  fetchReservationSlots,
  fetchShops,
  updateReservationSlot,
  updateReservationSlotStatus,
  type MerchantReservationSlot,
  type MerchantReservationSlotPayload,
  type MerchantShopOption,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const canView = computed(() => props.permissions.includes('reservation:view'))
const canEdit = computed(() => props.permissions.includes('reservation:confirm'))

const loading = ref(false)
const saving = ref(false)
const error = ref('')
const success = ref('')
const shops = ref<MerchantShopOption[]>([])
const items = ref<MerchantReservationSlot[]>([])

const filters = reactive({
  shopId: '' as string | number,
  dateFrom: '',
  dateTo: '',
  enabled: '' as '' | 'true' | 'false',
})
const enabledOptions = computed(() => [
  { value: '', label: strings.value.reservationSlots.filters.all },
  { value: 'true', label: strings.value.reservationSlots.filters.enabled },
  { value: 'false', label: strings.value.reservationSlots.filters.disabled },
])

const editor = ref<(MerchantReservationSlotPayload & { id?: number }) | null>(null)

function messageOf(cause: unknown) {
  return cause instanceof Error ? cause.message : strings.value.common.requestFailed
}

async function loadShops() {
  const page = await fetchShops({ page: 1, pageSize: 100 })
  shops.value = page.list.map((item) => ({ id: Number(item.id), name: String(item.name) }))
  if (!filters.shopId && shops.value[0]) {
    filters.shopId = shops.value[0].id
  }
}

async function load() {
  if (!canView.value) return
  loading.value = true
  error.value = ''
  try {
    const page = await fetchReservationSlots({
      page: 1,
      pageSize: 100,
      shopId: filters.shopId === '' ? undefined : Number(filters.shopId),
      dateFrom: filters.dateFrom || undefined,
      dateTo: filters.dateTo || undefined,
      enabled: filters.enabled === '' ? undefined : filters.enabled === 'true',
    })
    items.value = page.list
  } catch (cause) {
    error.value = messageOf(cause)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  if (!canEdit.value) return
  const shopId = filters.shopId === '' ? Number(shops.value[0]?.id || 0) : Number(filters.shopId)
  editor.value = {
    shopId,
    bizDate: filters.dateFrom || new Date().toISOString().slice(0, 10),
    startTime: '18:00:00',
    endTime: '20:00:00',
    capacity: 10,
    confirmMode: 2,
    cancelBeforeMinutes: 120,
    enabled: true,
  }
  success.value = ''
  error.value = ''
}

function openEdit(item: MerchantReservationSlot) {
  if (!canEdit.value) return
  editor.value = {
    id: item.id,
    shopId: item.shopId,
    bizDate: String(item.bizDate).slice(0, 10),
    startTime: normalizeTime(item.startTime),
    endTime: normalizeTime(item.endTime),
    capacity: item.capacity,
    confirmMode: item.confirmMode,
    cancelBeforeMinutes: item.cancelBeforeMinutes,
    enabled: item.enabled,
  }
  success.value = ''
  error.value = ''
}

function normalizeTime(value: string) {
  if (!value) return '00:00:00'
  return value.length === 5 ? `${value}:00` : value
}

async function submitEditor() {
  if (!editor.value || !canEdit.value) return
  saving.value = true
  error.value = ''
  success.value = ''
  const payload: MerchantReservationSlotPayload = {
    shopId: Number(editor.value.shopId),
    bizDate: editor.value.bizDate,
    startTime: normalizeTime(editor.value.startTime),
    endTime: normalizeTime(editor.value.endTime),
    capacity: Number(editor.value.capacity),
    confirmMode: Number(editor.value.confirmMode),
    cancelBeforeMinutes: Number(editor.value.cancelBeforeMinutes),
    enabled: editor.value.enabled !== false,
  }
  try {
    if (editor.value.id) {
      await updateReservationSlot(editor.value.id, payload)
      success.value = strings.value.reservationSlots.successUpdated
    } else {
      await createReservationSlot(payload)
      success.value = strings.value.reservationSlots.successCreated
    }
    editor.value = null
    await load()
  } catch (cause) {
    error.value = messageOf(cause)
  } finally {
    saving.value = false
  }
}

async function toggleEnabled(item: MerchantReservationSlot) {
  if (!canEdit.value || saving.value) return
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    await updateReservationSlotStatus(item.id, !item.enabled)
    success.value = item.enabled
      ? strings.value.reservationSlots.successDisabled
      : strings.value.reservationSlots.successEnabled
    await load()
  } catch (cause) {
    error.value = messageOf(cause)
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    await loadShops()
    await load()
  } catch (cause) {
    error.value = messageOf(cause)
  }
})

watch(
  () => [filters.shopId, filters.dateFrom, filters.dateTo, filters.enabled],
  () => {
    void load()
  },
)
</script>

<template>
  <section>
    <div class="toolbar">
      <div class="row-actions">
        <label>
          <span class="muted">{{ strings.reservationSlots.filters.shop }}</span>
          <select v-model="filters.shopId" data-testid="slot-shop-filter">
            <option value="">{{ strings.reservationSlots.filters.allShops }}</option>
            <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
          </select>
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.filters.startDate }}</span>
          <input v-model="filters.dateFrom" type="date" data-testid="slot-date-from" />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.filters.endDate }}</span>
          <input v-model="filters.dateTo" type="date" data-testid="slot-date-to" />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.filters.status }}</span>
          <select v-model="filters.enabled" data-testid="slot-enabled-filter">
            <option v-for="option in enabledOptions" :key="option.value || 'all'" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>
      <div class="row-actions">
        <button type="button" @click="load">{{ strings.common.refresh }}</button>
        <button v-if="canEdit" type="button" data-testid="create-slot" @click="openCreate">
          {{ strings.reservationSlots.create }}
        </button>
      </div>
    </div>

    <p class="muted">{{ strings.reservationSlots.summary }}</p>
    <p v-if="!canView" class="error" role="alert">{{ strings.reservationSlots.missingPermission('reservation:view') }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="success" class="muted" data-testid="slot-success">{{ success }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>

    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.reservationSlots.tableHeaders.shop }}</th>
            <th>{{ strings.reservationSlots.tableHeaders.date }}</th>
            <th>{{ strings.reservationSlots.tableHeaders.slot }}</th>
            <th>{{ strings.reservationSlots.tableHeaders.capacity }}</th>
            <th>{{ strings.reservationSlots.tableHeaders.confirmMode }}</th>
            <th>{{ strings.reservationSlots.tableHeaders.status }}</th>
            <th v-if="canEdit">{{ strings.reservationSlots.tableHeaders.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.shopName || item.shopId }}</td>
            <td>{{ item.bizDate }}</td>
            <td>{{ item.startTime }} - {{ item.endTime }}</td>
            <td>{{ strings.reservationSlots.capacitySummary(item.reservedCount, item.capacity, item.remainingCount) }}</td>
            <td>{{ strings.reservationSlots.confirmModeSummary(item.confirmMode, item.cancelBeforeMinutes) }}</td>
            <td>{{ strings.reservationSlots.statusText(item.enabled) }}</td>
            <td v-if="canEdit" class="row-actions">
              <button type="button" :data-testid="`edit-slot-${item.id}`" @click="openEdit(item)">
                {{ strings.reservationSlots.edit }}
              </button>
              <button type="button" :data-testid="`toggle-slot-${item.id}`" @click="toggleEnabled(item)">
                {{ item.enabled ? strings.reservationSlots.disable : strings.reservationSlots.enable }}
              </button>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td :colspan="canEdit ? 7 : 6" class="feedback">{{ strings.reservationSlots.empty }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="editor && canEdit" class="card" style="margin-top: 16px">
      <h3>{{ editor.id ? strings.reservationSlots.editorTitles.edit : strings.reservationSlots.editorTitles.create }}</h3>
      <form class="row-actions" style="flex-wrap: wrap; gap: 12px" data-testid="slot-editor" @submit.prevent="submitEditor">
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.shop }}</span>
          <select v-model.number="editor.shopId" name="slot-shop" required :disabled="!!editor.id">
            <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
          </select>
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.date }}</span>
          <input v-model="editor.bizDate" name="slot-date" type="date" required />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.start }}</span>
          <input v-model="editor.startTime" name="slot-start" type="time" step="1" required />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.end }}</span>
          <input v-model="editor.endTime" name="slot-end" type="time" step="1" required />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.capacity }}</span>
          <input v-model.number="editor.capacity" name="slot-capacity" type="number" min="1" max="500" required />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.confirmMode }}</span>
          <select v-model.number="editor.confirmMode" name="slot-confirm-mode">
            <option :value="1">{{ strings.reservationSlots.confirmModeLabel(1) }}</option>
            <option :value="2">{{ strings.reservationSlots.confirmModeLabel(2) }}</option>
          </select>
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.cancelBefore }}</span>
          <input
            v-model.number="editor.cancelBeforeMinutes"
            name="slot-cancel-before"
            type="number"
            min="0"
            max="1440"
            required
          />
        </label>
        <label>
          <span class="muted">{{ strings.reservationSlots.editorLabels.enabled }}</span>
          <input v-model="editor.enabled" name="slot-enabled" type="checkbox" />
        </label>
        <button type="submit" :disabled="saving">{{ saving ? strings.reservationSlots.saving : strings.reservationSlots.save }}</button>
        <button type="button" class="ghost" @click="editor = null">{{ strings.common.cancel }}</button>
      </form>
    </div>
  </section>
</template>
