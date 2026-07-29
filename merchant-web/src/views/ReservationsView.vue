<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  arriveReservation,
  confirmReservation,
  fetchReservations,
  markReservationNoShow,
  rejectReservation,
  type MerchantReservation,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const loading = ref(true)
const actingId = ref<number | null>(null)
const error = ref('')
const success = ref('')
const items = ref<MerchantReservation[]>([])
const rejectReasons = reactive<Record<number, string>>({})
const canManageReservations = computed(() => props.permissions.includes('reservation:confirm'))
const canArriveReservations = computed(
  () => props.permissions.includes('reservation:arrive') || props.permissions.includes('reservation:confirm'),
)
const filters = reactive({
  status: '0',
})
const statusOptions = computed(() => [
  { value: '', label: strings.value.reservations.statusOptions.all },
  { value: '0', label: strings.value.reservations.statusOptions.pending },
  { value: '1', label: strings.value.reservations.statusOptions.confirmed },
  { value: '2', label: strings.value.reservations.statusOptions.arrived },
  { value: '3', label: strings.value.reservations.statusOptions.userCancelled },
  { value: '4', label: strings.value.reservations.statusOptions.merchantRejected },
  { value: '5', label: strings.value.reservations.statusOptions.noShow },
])

async function load() {
  loading.value = true
  error.value = ''
  try {
    items.value = (
      await fetchReservations({
        page: 1,
        pageSize: 50,
        status: filters.status === '' ? undefined : Number(filters.status),
      })
    ).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.reservations.loadError
  } finally {
    loading.value = false
  }
}

function canAct(item: MerchantReservation) {
  return Boolean(
    (canManageReservations.value && (item.canConfirm || item.canReject)) ||
      (canArriveReservations.value && (item.canArrive || item.canNoShow)),
  )
}

async function act(
  item: MerchantReservation,
  type: 'confirm' | 'reject' | 'arrive' | 'no-show',
) {
  if (type === 'confirm' || type === 'reject') {
    if (!canManageReservations.value) return
  } else if (!canArriveReservations.value) {
    return
  }

  actingId.value = item.id
  error.value = ''
  success.value = ''
  try {
    if (type === 'reject') {
      const reason = (rejectReasons[item.id] ?? '').trim()
      if (!reason) {
        error.value = strings.value.reservations.rejectReasonRequired
        return
      }
      await rejectReservation(item.id, reason)
      success.value = strings.value.reservations.successRejected(item.reservationNo)
    } else if (type === 'confirm') {
      await confirmReservation(item.id)
      success.value = strings.value.reservations.successConfirmed(item.reservationNo)
    } else if (type === 'arrive') {
      await arriveReservation(item.id)
      success.value = strings.value.reservations.successArrived(item.reservationNo)
    } else {
      await markReservationNoShow(item.id)
      success.value = strings.value.reservations.successNoShow(item.reservationNo)
    }
    delete rejectReasons[item.id]
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.reservations.actionError
  } finally {
    actingId.value = null
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div class="row-actions">
        <label>
          <span class="muted">{{ strings.reservations.statusLabel }}</span>
          <select
            v-model="filters.status"
            name="reservation-status-filter"
            data-testid="reservation-status-filter"
            @change="load"
          >
            <option v-for="option in statusOptions" :key="option.value || 'all'" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>
      <button type="button" @click="load">{{ strings.common.refresh }}</button>
    </div>
    <p class="muted">{{ strings.reservations.summary }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="success" class="muted" data-testid="reservation-success">{{ success }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.reservations.headers.reservationNo }}</th>
            <th>{{ strings.reservations.headers.shop }}</th>
            <th>{{ strings.reservations.headers.time }}</th>
            <th>{{ strings.reservations.headers.contact }}</th>
            <th>{{ strings.reservations.headers.status }}</th>
            <th>{{ strings.reservations.headers.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.reservationNo }}</td>
            <td>{{ item.shop.name }}</td>
            <td>
              {{ item.reserveTime }}
              <div v-if="item.peopleCount" class="muted">{{ strings.reservations.peopleCount(item.peopleCount) }}</div>
            </td>
            <td>
              <template v-if="item.contactName || item.contactPhone">
                {{ item.contactName || '—' }}
                <div class="muted">{{ item.contactPhone || '' }}</div>
              </template>
              <span v-else class="muted">—</span>
            </td>
            <td>{{ item.statusText }}</td>
            <td>
              <div
                v-if="canAct(item)"
                class="row-actions"
                :data-testid="`reservation-actions-${item.id}`"
              >
                <input
                  v-if="canManageReservations && item.canReject"
                  v-model="rejectReasons[item.id]"
                  :name="`reservation-reason-${item.id}`"
                  maxlength="255"
                  :placeholder="strings.reservations.rejectPlaceholder"
                />
                <button
                  v-if="canManageReservations && item.canConfirm"
                  type="button"
                  :data-testid="`confirm-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'confirm')"
                >
                  {{ strings.reservations.confirm }}
                </button>
                <button
                  v-if="canManageReservations && item.canReject"
                  type="button"
                  class="danger-action"
                  :data-testid="`reject-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'reject')"
                >
                  {{ strings.reservations.reject }}
                </button>
                <button
                  v-if="canArriveReservations && item.canArrive"
                  type="button"
                  :data-testid="`arrive-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'arrive')"
                >
                  {{ strings.reservations.arrive }}
                </button>
                <button
                  v-if="canArriveReservations && item.canNoShow"
                  type="button"
                  class="danger-action"
                  :data-testid="`noshow-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'no-show')"
                >
                  {{ strings.reservations.noShow }}
                </button>
              </div>
              <span v-else class="muted">{{ strings.reservations.noAction }}</span>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td colspan="6" class="feedback">{{ strings.reservations.empty }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
