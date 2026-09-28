<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { guideStringsForRegion } from '@/core/web_guide_localizations'
import { fetchGuide } from '@/services/guide'
import type { GuideArticle } from '@/types/guide'

const props = defineProps<{ guideId: number }>()
const { state } = useAppContext()
const copy = computed(() => guideStringsForRegion(state.region))
const guide = ref<GuideArticle | null>(null)
const errorMessage = ref('')

async function load() {
  errorMessage.value = ''
  guide.value = null
  try {
    guide.value = await fetchGuide(props.guideId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

watch(() => [props.guideId, state.region], load, { immediate: true })
</script>

<template>
  <section v-if="guide">
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ guide.title }}</h1>
      <p class="summary">{{ guide.summary }}</p>
    </header>
    <article v-for="section in guide.sections ?? []" :key="section.id">
      <h2>{{ section.heading }}</h2>
      <p>{{ section.body }}</p>
      <RouterLink v-if="section.shopId" :to="`/shops/${section.shopId}`">{{ copy.shop }} #{{ section.shopId }}</RouterLink>
    </article>
  </section>
  <p v-else-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
  <p v-else class="feedback">{{ copy.loading }}</p>
</template>
