<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { waitlistStringsForRegion } from '@/core/web_waitlist_localizations'
import { joinWaitlist } from '@/services/waitlist'

const props = defineProps<{ shopId?: number }>()

const router = useRouter()
const { state: appState } = useAppContext()
const copy = computed(() => waitlistStringsForRegion(appState.region).join)

const form = reactive({ tableType: 1, partySize: 2 })
const submitting = ref(false)
const errorMessage = ref('')
const hasShop = computed(() => !!props.shopId && props.shopId > 0)

async function submit() {
  if (!hasShop.value || submitting.value) return
  submitting.value = true
  errorMessage.value = ''
  try {
    await joinWaitlist(Number(props.shopId), { tableType: form.tableType, partySize: form.partySize })
    router.push('/user/waitlist')
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <section class="waitlist-join">
    <h1>{{ copy.title }}</h1>
    <p v-if="!hasShop" class="feedback is-error">{{ copy.missingShop }}</p>
    <p v-else-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <form v-if="hasShop" class="waitlist-form" @submit.prevent="submit">
      <label>
        <span>{{ copy.tableType }}</span>
        <select v-model.number="form.tableType">
          <option :value="1">{{ copy.small }}</option>
          <option :value="2">{{ copy.medium }}</option>
          <option :value="3">{{ copy.large }}</option>
        </select>
      </label>
      <label>
        <span>{{ copy.partySize }}</span>
        <input v-model.number="form.partySize" type="number" min="1" max="50" />
      </label>
      <button type="submit" :disabled="submitting">
        {{ submitting ? copy.submitting : copy.submit }}
      </button>
    </form>
  </section>
</template>
