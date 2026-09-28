<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { complaintStringsForRegion, localizeWebComplaintError } from '@/core/web_complaint_localizations'
import { createComplaint } from '@/services/complaint'

const props = defineProps<{ shopId?: number; orderId?: number }>()

const router = useRouter()
const { state: appState } = useAppContext()
const copy = computed(() => complaintStringsForRegion(appState.region))

const form = reactive({ type: 1, title: '', content: '' })
const submitting = ref(false)
const errorMessage = ref('')

const hasShop = computed(() => !!props.shopId && props.shopId > 0)

async function submit() {
  if (!hasShop.value) {
    errorMessage.value = copy.value.create.missingShop
    return
  }
  submitting.value = true
  errorMessage.value = ''
  try {
    await createComplaint({
      shopId: Number(props.shopId),
      orderId: props.orderId ? Number(props.orderId) : undefined,
      type: form.type,
      title: form.title,
      content: form.content,
    })
    router.push('/user/complaints')
  } catch (error) {
    errorMessage.value = localizeWebComplaintError(copy.value, error, copy.value.create.submitFailed)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <section class="complaint-create">
    <header>
      <p class="eyebrow">{{ copy.create.eyebrow }}</p>
      <h1>{{ copy.create.title }}</h1>
      <p class="summary">{{ copy.create.summary }}</p>
    </header>

    <p v-if="!hasShop" class="feedback is-error">{{ copy.create.missingShop }}</p>
    <p v-else-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <form v-if="hasShop" class="complaint-form" @submit.prevent="submit">
      <label>
        <span>{{ copy.create.typeLabel }}</span>
        <select v-model.number="form.type">
          <option :value="1">{{ copy.list.typeText(1) }}</option>
          <option :value="2">{{ copy.list.typeText(2) }}</option>
          <option :value="3">{{ copy.list.typeText(3) }}</option>
          <option :value="4">{{ copy.list.typeText(4) }}</option>
          <option :value="5">{{ copy.list.typeText(5) }}</option>
        </select>
      </label>
      <label>
        <span>{{ copy.create.titleLabel }}</span>
        <input v-model="form.title" type="text" maxlength="128" :placeholder="copy.create.titlePlaceholder" required />
      </label>
      <label>
        <span>{{ copy.create.contentLabel }}</span>
        <textarea v-model="form.content" rows="5" maxlength="2000" :placeholder="copy.create.contentPlaceholder" required></textarea>
      </label>
      <button type="submit" :disabled="submitting">
        {{ submitting ? copy.create.submitting : copy.create.submit }}
      </button>
    </form>
  </section>
</template>
