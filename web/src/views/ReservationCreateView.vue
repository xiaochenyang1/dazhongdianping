<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { localizeWebTradeError, tradeStringsForRegion } from '@/core/web_trade_localizations'
import { createReservation, fetchReservationSlots } from '@/services/reservation'
import type { ReservationSlot } from '@/types/reservation'

const props = defineProps<{ shopId: number }>()
const router = useRouter()
const { state } = useAppContext()
const copy = computed(() => tradeStringsForRegion(state.region))
const minimumDate = ref('')
const date = ref('')
const timeZone = ref('')
const loading = ref(false)
let searchVersion = 0
const people = ref(2)
const slots = ref<ReservationSlot[]>([])
const selected = ref<ReservationSlot | null>(null)
const contactName = ref('')
const contactPhone = ref('')
const remark = ref('')
const errorMessage = ref('')

async function search() {
  const version = ++searchVersion
  errorMessage.value = ''
  slots.value = []
  selected.value = null
  loading.value = true
  try {
    const result = await fetchReservationSlots(props.shopId, date.value || undefined, people.value)
    if (version !== searchVersion) return
    date.value = result.date
    minimumDate.value = result.today || ''
    timeZone.value = result.timeZone || ''
    slots.value = result.list
  } catch (error) {
    if (version === searchVersion) {
      errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.reservationCreate.slotLoadFailed)
    }
  } finally {
    if (version === searchVersion) loading.value = false
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

watch([date, people], () => {
  slots.value = []
  selected.value = null
}, { flush: 'sync' })

watch(
  [() => state.region, () => props.shopId],
  () => {
    date.value = ''
    timeZone.value = ''
    void search()
  },
  { immediate: true },
)
onUnmounted(() => { searchVersion++ })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div><p class="eyebrow">{{ copy.reservationCreate.eyebrow }}</p><h1>{{ copy.reservationCreate.title }}</h1></div>
    </div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <section class="content-card">
      <div class="form-grid form-grid--two">
        <label class="field"><span>{{ copy.reservationCreate.date }}</span><input v-model="date" type="date" :min="minimumDate" :disabled="loading" /></label>
        <label class="field"><span>{{ copy.reservationCreate.people }}</span><input v-model.number="people" type="number" min="1" max="50" :disabled="loading" /></label>
      </div>
      <p v-if="timeZone" class="muted" data-testid="reservation-time-zone">{{ timeZone }}</p>
      <button class="primary-button" :disabled="loading" @click="search">{{ copy.reservationCreate.searchSlots }}</button>
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
