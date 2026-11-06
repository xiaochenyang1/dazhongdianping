<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { consultStringsForRegion } from '@/core/web_consult_localizations'
import { fetchConsultSessions } from '@/services/consult'
import type { ConsultSession, ConsultSessionQuery } from '@/types/consult'

const { state: appState } = useAppContext()
const copy = computed(() => consultStringsForRegion(appState.region).sessions)

const sessions = ref<ConsultSession[]>([])
const loading = ref(false)
const errorMessage = ref('')
const unreadOnly = ref(false)
const pageIndex = ref(0)
const hasMore = ref(false)
let cursors: ConsultSessionQuery[] = [{}]
let revision = 0

async function load(index = pageIndex.value) {
  const current = ++revision
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchConsultSessions({ ...cursors[index], unreadOnly: unreadOnly.value })
    if (current !== revision) return
    sessions.value = result.list
    pageIndex.value = index
    hasMore.value = result.hasMore
    cursors = cursors.slice(0, index + 1)
    if (result.hasMore && result.nextBeforeId != null && result.nextBeforeUpdatedAt != null) {
      cursors.push({ beforeId: result.nextBeforeId, beforeUpdatedAt: result.nextBeforeUpdatedAt })
    }
  } catch (error) {
    if (current === revision) errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    if (current === revision) loading.value = false
  }
}

watch([() => appState.region, unreadOnly], () => {
  cursors = [{}]
  pageIndex.value = 0
  hasMore.value = false
  sessions.value = []
  void load(0)
}, { immediate: true })
onUnmounted(() => { revision++ })
</script>

<template>
  <section class="consult-sessions">
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
      <p class="summary">{{ copy.summary }}</p>
    </header>

    <div class="list-controls">
      <label><input v-model="unreadOnly" type="checkbox" data-testid="sessions-unread" /> {{ copy.unreadOnly }}</label>
      <button type="button" class="secondary-button" :disabled="loading" @click="load(0)">{{ copy.refresh }}</button>
    </div>
    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-if="!loading && !errorMessage && sessions.length === 0" class="feedback">{{ unreadOnly ? copy.noUnread : copy.empty }}</p>

    <ul class="session-list" :aria-busy="loading">
      <li v-for="s in sessions" :key="s.id" class="session-card">
        <div class="session-card__head">
          <strong>{{ s.shopName }}</strong>
          <span v-if="s.unread > 0" class="badge">{{ copy.unread(s.unread) }}</span>
        </div>
        <p class="session-card__preview">{{ s.lastMessage }}</p>
        <RouterLink class="session-card__link" :to="`/user/consult/${s.id}`">{{ copy.open }}</RouterLink>
      </li>
    </ul>
    <div class="list-controls">
      <button type="button" class="secondary-button" :disabled="loading || pageIndex === 0" data-testid="sessions-previous" @click="load(pageIndex - 1)">{{ copy.previous }}</button>
      <span>{{ pageIndex + 1 }}</span>
      <button type="button" class="secondary-button" :disabled="loading || !hasMore" data-testid="sessions-next" @click="load(pageIndex + 1)">{{ copy.next }}</button>
    </div>
  </section>
</template>

<style scoped>
.consult-sessions { max-width: 900px; margin: 0 auto; }
.list-controls { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin: 20px 0; }
.session-list { list-style: none; padding: 0; display: grid; gap: 12px; }
.session-card { padding: 20px; background: var(--surface-strong); border: 1px solid var(--line); border-radius: 18px; }
.session-card__head { display: flex; gap: 12px; justify-content: space-between; }
.session-card__preview { color: var(--text-soft); overflow-wrap: anywhere; }
.session-card__link { color: var(--brand); font-weight: 700; }
.badge { flex-shrink: 0; color: var(--brand); }
</style>
