<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { addDaysToDateInput, toLocalDateInputValue } from '@/lib/local-date'
import { createReservation, fetchReservationSlots } from '@/services/reservation'
import type { ReservationSlot } from '@/types/reservation'

const props = defineProps<{ shopId: number }>()
const router = useRouter()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))
const minimumDate = toLocalDateInputValue()
const date = ref(addDaysToDateInput(minimumDate, 1))
const people = ref(2)
const slots = ref<ReservationSlot[]>([])
const selected = ref<ReservationSlot | null>(null)
const contactName = ref('')
const contactPhone = ref('')
const remark = ref('')
const errorMessage = ref('')

async function search() {
  errorMessage.value = ''
  try {
    slots.value = (await fetchReservationSlots(props.shopId, date.value, people.value)).list
    selected.value = null
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationCreate.slotLoadFailed)
  }
}

async function submit() {
  if (!selected.value) {
    errorMessage.value = copy.value.reservationCreate.selectSlotFirst
    return
  }
  try {
    const reservation = await createReservation({
      shopId: props.shopId,
      slotId: selected.value.slotId,
      reserveTime: `${date.value} ${selected.value.startTime}`,
      peopleCount: people.value,
      contactName: contactName.value,
      contactPhone: contactPhone.value,
      remark: remark.value,
    })
    await router.push(`/user/reservations/${reservation.id}`)
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationCreate.submitFailed)
  }
}

watch(
  () => state.region,
  () => {
    slots.value = []
    selected.value = null
    errorMessage.value = ''
  },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div><p class="eyebrow">{{ copy.reservationCreate.eyebrow }}</p><h1>{{ copy.reservationCreate.title }}</h1></div>
    </div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <section class="content-card">
      <div class="form-grid form-grid--two">
        <label class="field"><span>{{ copy.reservationCreate.date }}</span><input v-model="date" type="date" :min="minimumDate" /></label>
        <label class="field"><span>{{ copy.reservationCreate.people }}</span><input v-model.number="people" type="number" min="1" max="50" /></label>
      </div>
      <button class="primary-button" @click="search">{{ copy.reservationCreate.searchSlots }}</button>
      <div class="tag-row">
        <button
          v-for="slot in slots"
          :key="slot.slotId"
          type="button"
          class="secondary-button"
          :class="{ 'is-active': selected?.slotId === slot.slotId }"
          :disabled="!slot.available"
          @click="selected = slot"
        >
          {{ slot.startTime }}-{{ slot.endTime }} · {{ copy.common.remaining(slot.remainingCount) }} ·
          {{ copy.statuses.confirmMode(slot.confirmMode, slot.confirmModeText) }}
        </button>
      </div>
      <div class="form-grid form-grid--two">
        <label class="field"><span>{{ copy.reservationCreate.contactName }}</span><input v-model="contactName" /></label>
        <label class="field"><span>{{ copy.reservationCreate.contactPhone }}</span><input v-model="contactPhone" :placeholder="copy.reservationCreate.phonePlaceholder" /></label>
        <label class="field field--full"><span>{{ copy.reservationCreate.remark }}</span><input v-model="remark" :placeholder="copy.reservationCreate.remarkPlaceholder" /></label>
      </div>
      <button class="primary-button" @click="submit">{{ copy.reservationCreate.submit }}</button>
    </section>
  </section>
</template>
