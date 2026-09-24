<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { creatorStringsForRegion } from '@/core/web_creator_localizations'
import { claimCreatorTask, completeCreatorTask, fetchCreatorTasks } from '@/services/creator'
import type { CreatorTask } from '@/types/creator'

const { state } = useAppContext()
const copy = computed(() => creatorStringsForRegion(state.region))
const tasks = ref<CreatorTask[]>([])
const loading = ref(false)
const errorMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    tasks.value = (await fetchCreatorTasks()).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function act(task: CreatorTask) {
  errorMessage.value = ''
  try {
    if (task.claimStatus === 0) await claimCreatorTask(task.id)
    else if (task.claimStatus === 1) await completeCreatorTask(task.id)
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
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
    <p v-else-if="tasks.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-else>
      <li v-for="task in tasks" :key="task.id" :data-testid="`creator-task-${task.id}`">
        <h2>{{ task.title }}</h2>
        <p>{{ task.description }}</p>
        <p>{{ task.rewardPoints }} {{ copy.points }}</p>
        <button v-if="task.claimStatus !== 2" type="button" class="primary-button" @click="act(task)">
          {{ task.claimStatus === 0 ? copy.claim : copy.complete }}
        </button>
        <span v-else>{{ copy.done }}</span>
      </li>
    </ul>
  </section>
</template>
