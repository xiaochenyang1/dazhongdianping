<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
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

const reservation = ref<Reservation | null>(null)
const minimumDate = toLocalDateInputValue()
const date = ref(addDaysToDateInput(minimumDate, 1))
const slots = ref<ReservationSlot[]>([])
const errorMessage = ref('')
const successMessage = ref('')

const statusBanner = computed(() => {
  const marker = String(route.query.status || '')
  if (marker === 'confirmed') return '商户已确认你的预订。'
  if (marker === 'arrived') return '商户已确认你到店。'
  if (marker === 'rejected') return '商户已拒绝本次预订。'
  if (marker === 'no_show') return '商户已将本次预订标记为爽约。'
  return ''
})

async function load() {
  reservation.value = await fetchReservation(props.reservationId)
  const suggestedDate = addDaysToDateInput(reservation.value.reserveTime, 1)
  date.value = suggestedDate < minimumDate ? minimumDate : suggestedDate
}

async function cancel() {
  try {
    reservation.value = await cancelReservation(props.reservationId)
    successMessage.value = '预订已取消。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '取消失败'
  }
}

async function findSlots() {
  if (!reservation.value) return
  slots.value = (
    await fetchReservationSlots(reservation.value.shop.id, date.value, reservation.value.peopleCount)
  ).list
}

async function reschedule(slot: ReservationSlot) {
  try {
    reservation.value = await rescheduleReservation(
      props.reservationId,
      slot.slotId,
      `${date.value} ${slot.startTime}`,
      '用户在线改期',
    )
    slots.value = []
    successMessage.value = '改期申请已提交。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '改期失败'
  }
}

onMounted(() => {
  void load().catch((error) => {
    errorMessage.value = error instanceof Error ? error.message : '预订加载失败'
  })
})
</script>

<template>
  <section v-if="reservation" class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">预订 {{ reservation.reservationNo }}</p>
        <h1>{{ reservation.shop.name }}</h1>
        <p>{{ reservation.reserveTime }} · {{ reservation.peopleCount }} 人 · {{ reservation.statusText }}</p>
      </div>
    </div>

    <p v-if="statusBanner" class="feedback is-success" data-testid="reservation-status-banner">{{ statusBanner }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <div class="hero-actions">
      <button v-if="reservation.canCancel" class="secondary-button" type="button" @click="cancel">取消预订</button>
      <template v-if="reservation.canReschedule">
        <input v-model="date" type="date" :min="minimumDate" />
        <button class="secondary-button" type="button" @click="findSlots">查询改期时段</button>
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
        {{ slot.startTime }} · {{ slot.confirmModeText }} · 余 {{ slot.remainingCount }}
      </button>
    </div>

    <section class="content-card">
      <h2>变更时间线</h2>
      <div class="review-list">
        <article
          v-for="item in reservation.timeline"
          :key="item.createdAt + '-' + item.actionType + '-' + (item.remark || '')"
          class="review-card"
        >
          <strong>{{ item.actionText }}</strong>
          <p>{{ item.remark || '—' }}</p>
          <span>{{ item.operatorText }} · {{ item.createdAt }}</span>
        </article>
      </div>
    </section>
  </section>
</template>
