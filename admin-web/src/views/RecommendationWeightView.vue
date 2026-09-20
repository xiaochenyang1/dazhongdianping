<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { fetchRecommendationWeight, updateRecommendationWeight } from '@/services/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const copy = computed(() => strings.value.recommendationWeight)
const canWrite = computed(() => state.permissions.includes('operations:recommendation:write'))

const form = reactive({
  affinityWeight: 40,
  qualityWeight: 25,
  popularityWeight: 20,
  distanceWeight: 15,
})
const errorMessage = ref('')
const successMessage = ref('')
const saving = ref(false)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

async function load() {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const data = await fetchRecommendationWeight()
    form.affinityWeight = data.affinityWeight
    form.qualityWeight = data.qualityWeight
    form.popularityWeight = data.popularityWeight
    form.distanceWeight = data.distanceWeight
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

async function save() {
  if (!canWrite.value) return
  errorMessage.value = ''
  successMessage.value = ''
  saving.value = true
  try {
    const data = await updateRecommendationWeight({
      affinityWeight: form.affinityWeight,
      qualityWeight: form.qualityWeight,
      popularityWeight: form.popularityWeight,
      distanceWeight: form.distanceWeight,
    })
    form.affinityWeight = data.affinityWeight
    form.qualityWeight = data.qualityWeight
    form.popularityWeight = data.popularityWeight
    form.distanceWeight = data.distanceWeight
    successMessage.value = copy.value.saved
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.saveError)
  } finally {
    saving.value = false
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>{{ copy.title }}</h1>
      <p class="page-desc">{{ copy.description }}</p>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <form class="weight-form" @submit.prevent="save">
      <label>
        <span>{{ copy.affinity }}</span>
        <input v-model.number="form.affinityWeight" type="number" min="0" max="100" step="0.01" :disabled="!canWrite" />
      </label>
      <label>
        <span>{{ copy.quality }}</span>
        <input v-model.number="form.qualityWeight" type="number" min="0" max="100" step="0.01" :disabled="!canWrite" />
      </label>
      <label>
        <span>{{ copy.popularity }}</span>
        <input v-model.number="form.popularityWeight" type="number" min="0" max="100" step="0.01" :disabled="!canWrite" />
      </label>
      <label>
        <span>{{ copy.distance }}</span>
        <input v-model.number="form.distanceWeight" type="number" min="0" max="100" step="0.01" :disabled="!canWrite" />
      </label>
      <button type="submit" :disabled="!canWrite || saving">{{ copy.save }}</button>
      <p v-if="!canWrite" class="feedback">{{ copy.readOnly }}</p>
    </form>
  </section>
</template>
