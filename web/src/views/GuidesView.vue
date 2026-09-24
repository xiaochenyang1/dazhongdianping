<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { guideStringsForRegion } from '@/core/web_guide_localizations'
import { fetchGuides } from '@/services/guide'
import type { GuideArticle } from '@/types/guide'

const { state } = useAppContext()
const copy = computed(() => guideStringsForRegion(state.region))
const guides = ref<GuideArticle[]>([])
const loading = ref(false)
const errorMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    guides.value = (await fetchGuides()).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section>
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="guides.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-else class="guide-list">
      <li v-for="guide in guides" :key="guide.id" :data-testid="`guide-${guide.id}`">
        <h2>{{ guide.title }}</h2>
        <p>{{ guide.summary }}</p>
        <RouterLink class="secondary-button" :to="`/guides/${guide.id}`">{{ copy.open }}</RouterLink>
      </li>
    </ul>
  </section>
</template>
