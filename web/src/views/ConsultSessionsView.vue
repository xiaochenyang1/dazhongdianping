<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { consultStringsForRegion } from '@/core/web_consult_localizations'
import { fetchConsultSessions } from '@/services/consult'
import type { ConsultSession } from '@/types/consult'

const { state: appState } = useAppContext()
const copy = computed(() => consultStringsForRegion(appState.region).sessions)

const sessions = ref<ConsultSession[]>([])
const loading = ref(false)
const errorMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    sessions.value = await fetchConsultSessions()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

watch(() => appState.region, load, { immediate: true })
</script>

<template>
  <section class="consult-sessions">
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="sessions.length === 0" class="feedback">{{ copy.empty }}</p>

    <ul v-else class="session-list">
      <li v-for="s in sessions" :key="s.id" class="session-card">
        <div class="session-card__head">
          <strong>{{ s.shopName }}</strong>
          <span v-if="s.unread > 0" class="badge">{{ copy.unread(s.unread) }}</span>
        </div>
        <p class="session-card__preview">{{ s.lastMessage }}</p>
        <RouterLink class="session-card__link" :to="`/user/consult/${s.id}`">{{ copy.open }}</RouterLink>
      </li>
    </ul>
  </section>
</template>
