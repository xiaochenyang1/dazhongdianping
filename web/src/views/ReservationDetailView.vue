<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { addDaysToDateInput, toLocalDateInputValue } from '@/lib/local-date'
import {
  cancelReservation,
  fetchReservation,
  fetchReservationSlots,
  rescheduleReservation,
} from '@/services/reservation'
import type { Reservation, ReservationSlot } from '@/types/reservation'

const props = defineProps<{ reservationId: number }>()
const route = useRoute()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))

const reservation = ref<Reservation | null>(null)
const minimumDate = toLocalDateInputValue()
const date = ref(addDaysToDateInput(minimumDate, 1))
const slots = ref<ReservationSlot[]>([])
const errorMessage = ref('')
const successMessage = ref('')

const statusBanner = computed(() => {
  const marker = String(route.query.status || '')
  if (marker === 'confirmed') return copy.value.reservationDetail.confirmedBanner
  if (marker === 'arrived') return copy.value.reservationDetail.arrivedBanner
  if (marker === 'rejected') return copy.value.reservationDetail.rejectedBanner
  if (marker === 'no_show') return copy.value.reservationDetail.noShowBanner
  return ''
})

async function load() {
  errorMessage.value = ''
  reservation.value = await fetchReservation(props.reservationId)
  const suggestedDate = addDaysToDateInput(reservation.value.reserveTime, 1)
  date.value = suggestedDate < minimumDate ? minimumDate : suggestedDate
}

async function cancel() {
  try {
    reservation.value = await cancelReservation(props.reservationId)
    successMessage.value = copy.value.reservationDetail.cancelSuccess
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationDetail.cancelFailed)
  }
}

async function findSlots() {
  if (!reservation.value) return
  errorMessage.value = ''
  try {
    slots.value = (
      await fetchReservationSlots(reservation.value.shop.id, date.value, reservation.value.peopleCount)
    ).list
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationDetail.slotLoadFailed)
  }
}

async function reschedule(slot: ReservationSlot) {
  try {
    reservation.value = await rescheduleReservation(
      props.reservationId,
      slot.slotId,
      `${date.value} ${slot.startTime}`,
      copy.value.reservationDetail.rescheduleReason,
    )
    slots.value = []
    successMessage.value = copy.value.reservationDetail.rescheduleSuccess
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationDetail.rescheduleFailed)
  }
}

watch(
  [() => props.reservationId, () => state.region],
  () => {
    reservation.value = null
    slots.value = []
    successMessage.value = ''
    void load().catch((error) => {
      errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationDetail.loadFailed)
    })
  },
  { immediate: true },
)
</script>

<template>
  <section v-if="reservation" class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.reservationDetail.reservation }} {{ reservation.reservationNo }}</p>
        <h1>{{ reservation.shop.name }}</h1>
        <p>
          {{ formatWebDateTime(reservation.reserveTime, copy.tag) }} · {{ copy.common.people(reservation.peopleCount) }} ·
          {{ copy.statuses.reservation(reservation.status, reservation.statusText) }}
        </p>
      </div>
    </div>

    <p v-if="statusBanner" class="feedback is-success" data-testid="reservation-status-banner">{{ statusBanner }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <div class="hero-actions">
      <button v-if="reservation.canCancel" class="secondary-button" type="button" @click="cancel">{{ copy.reservationDetail.cancel }}</button>
      <template v-if="reservation.canReschedule">
        <input v-model="date" type="date" :min="minimumDate" />
        <button class="secondary-button" type="button" @click="findSlots">{{ copy.reservationDetail.findSlots }}</button>
      </template>
    </div>

    <div class="tag-row">
      <button
        v-for="slot in slots"
        :key="slot.slotId"
        class="secondary-button"
        type="button"
        :disabled="!slot.available"
        @click="reschedule(slot)"
      >
        {{ slot.startTime }} · {{ copy.statuses.confirmMode(slot.confirmMode, slot.confirmModeText) }} ·
        {{ copy.common.remaining(slot.remainingCount) }}
      </button>
    </div>

    <section class="content-card">
      <h2>{{ copy.reservationDetail.timeline }}</h2>
      <div class="review-list">
        <article
          v-for="item in reservation.timeline || []"
          :key="item.createdAt + '-' + item.actionType + '-' + (item.remark || '')"
          class="review-card"
        >
          <strong>{{ copy.statuses.timelineAction(item.actionType, item.actionText) }}</strong>
          <p>{{ copy.statuses.timelineRemark(item.actionType, item.remark) }}</p>
          <span>
            {{ copy.statuses.operator(item.operatorType, item.operatorText) }} ·
            {{ formatWebDateTime(item.createdAt, copy.tag) }}
          </span>
        </article>
      </div>
    </section>
  </section>
</template>
