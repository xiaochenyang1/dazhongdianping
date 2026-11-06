<script setup lang="ts">
import { computed, onUnmounted, reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { creatorStringsForRegion } from '@/core/web_creator_localizations'
import { claimCreatorTask, submitCreatorTask, fetchCreatorTasks, fetchCreatorEvidence } from '@/services/creator'
import type { CreatorTask, CreatorEvidence } from '@/types/creator'

const { state } = useAppContext()
const { state: session } = useUserSession()
const copy = computed(() => creatorStringsForRegion(state.region))
const tasks = ref<CreatorTask[]>([])
const loading = ref(false), busy = ref(false), errorMessage = ref('')
const page = ref(1), hasMore = ref(false), editingId = ref<number | null>(null)
const evidence = ref<CreatorEvidence[]>([]), evidenceLoading = ref(false), evidenceMore = ref(false), evidenceError = ref('')
const form = reactive({ evidenceType: 'review' as 'review' | 'post', evidenceId: 0, note: '' })
let scope = 0, listRevision = 0, evidenceRevision = 0, evidencePage = 1, evidenceTarget = 1

async function load(target = page.value) {
  const revision = ++listRevision
  loading.value = true; errorMessage.value = ''
  try {
    const result = await fetchCreatorTasks(target)
    if (revision !== listRevision) return
    tasks.value = result.list; page.value = target; hasMore.value = result.hasMore
  } catch (error) {
    if (revision === listRevision) errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally { if (revision === listRevision) loading.value = false }
}
async function loadEvidence(target = 1) {
  const revision = ++evidenceRevision
  evidenceTarget = target
  evidenceLoading.value = true; evidenceError.value = ''
  if (target === 1) { evidence.value = []; form.evidenceId = 0; evidenceMore.value = false }
  try {
    const result = await fetchCreatorEvidence(form.evidenceType, target)
    if (revision !== evidenceRevision) return
    evidence.value = target === 1 ? result.list : [...evidence.value, ...result.list.filter(row => !evidence.value.some(old => old.id === row.id))]
    evidenceMore.value = result.hasMore; evidencePage = target
  } catch (error) {
    if (revision === evidenceRevision) evidenceError.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally { if (revision === evidenceRevision) evidenceLoading.value = false }
}
function open(task: CreatorTask) {
  if (busy.value || loading.value || ![1, 4].includes(task.claimStatus)) return
  editingId.value = task.id; form.evidenceType = task.evidenceType ?? 'review'; form.note = task.submissionNote ?? ''
  void loadEvidence()
}
function close() {
  editingId.value = null; evidenceRevision++
  evidence.value = []; evidenceError.value = ''; evidenceLoading.value = false; evidenceMore.value = false
  form.evidenceId = 0; form.note = ''
}
async function act(task: CreatorTask) {
  if (busy.value || loading.value || ![0, 1, 4].includes(task.claimStatus)) return
  if (task.claimStatus !== 0 && (editingId.value !== task.id || evidenceLoading.value)) return
  if (task.claimStatus !== 0 && !evidence.value.some(item => item.id === form.evidenceId)) { errorMessage.value = copy.value.chooseRequired; return }
  const current = scope
  busy.value = true; errorMessage.value = ''
  try {
    const result = task.claimStatus === 0 ? await claimCreatorTask(task.id) : await submitCreatorTask(task.id, { ...form })
    if (current !== scope) return
    task.claimStatus = result.claimStatus
    close()
    await load()
  } catch (error) {
    if (current === scope) errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally { if (current === scope) busy.value = false }
}
watch(() => [state.region, session.currentUser?.id, session.accessToken], () => {
  scope++; close(); tasks.value = []; page.value = 1; hasMore.value = false; busy.value = false
  void load(1)
}, { immediate: true, flush: 'sync' })
onUnmounted(() => { scope++; listRevision++; evidenceRevision++ })
</script>

<template>
  <section class="creator-page">
    <header><p class="eyebrow">{{ copy.eyebrow }}</p><h1>{{ copy.title }}</h1><p class="summary">{{ copy.summary }}</p></header>
    <button class="secondary-button" type="button" :disabled="loading || busy" data-testid="creator-refresh" @click="close(); load()">{{ copy.refresh }}</button>
    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="loading">{{ copy.loading }}</p>
    <p v-if="!loading && !errorMessage && tasks.length === 0">{{ copy.empty }}</p>
    <ul class="task-list" :aria-busy="loading">
      <li v-for="task in tasks" :key="task.id" :data-testid="`creator-task-${task.id}`" class="task-card">
        <h2>{{ task.title }}</h2><p class="task-description">{{ task.description }}</p><strong>{{ task.rewardPoints }} {{ copy.points }}</strong>
        <p v-if="task.claimStatus === 2">{{ copy.done }}</p>
        <p v-else-if="task.claimStatus === 3">{{ copy.pending }}</p>
        <p v-else-if="task.claimStatus === 4">{{ copy.rejected }}<br />{{ task.reviewNote }}</p>
        <p v-else-if="task.claimStatus === 1">{{ copy.claimed }}</p>
        <button v-if="task.claimStatus === 0" class="primary-button task-action" type="button" :disabled="busy || loading" @click="act(task)">{{ copy.claim }}</button>
        <button v-else-if="[1,4].includes(task.claimStatus) && editingId !== task.id" class="primary-button" type="button" :disabled="busy || loading" @click="open(task)">{{ copy.submit }}</button>
        <form v-if="editingId === task.id" @submit.prevent="act(task)">
          <label class="field"><span>{{ copy.evidenceType }}</span><select v-model="form.evidenceType" :disabled="busy" data-testid="evidence-type" @change="loadEvidence()"><option value="review">{{ copy.review }}</option><option value="post">{{ copy.post }}</option></select></label>
          <label class="field"><span>{{ copy.evidence }}</span><select v-model.number="form.evidenceId" required :disabled="busy || evidenceLoading" data-testid="evidence-select"><option :value="0">{{ copy.choose }}</option><option v-for="item in evidence" :key="item.id" :value="item.id">{{ item.title }}</option></select></label>
          <p v-if="evidenceLoading">{{ copy.loading }}</p>
          <p v-if="evidenceError" role="alert">{{ evidenceError }} <button class="ghost-button" type="button" :disabled="busy || evidenceLoading" data-testid="evidence-retry" @click="loadEvidence(evidenceTarget)">{{ copy.refresh }}</button></p>
          <p v-if="!evidenceLoading && !evidenceError && !evidence.length">{{ copy.noEvidence }}</p>
          <button v-if="evidenceMore" class="secondary-button" type="button" :disabled="busy || evidenceLoading" data-testid="evidence-more" @click="loadEvidence(evidencePage + 1)">{{ copy.more }}</button>
          <label class="field"><span>{{ copy.note }}</span><textarea v-model="form.note" maxlength="1000" rows="3" :disabled="busy" data-testid="submission-note" /></label>
          <div class="actions"><button class="primary-button" type="submit" :disabled="busy || evidenceLoading || !form.evidenceId" data-testid="submit-work">{{ copy.submit }}</button><button class="secondary-button" type="button" :disabled="busy" @click="close">{{ copy.cancel }}</button></div>
        </form>
      </li>
    </ul>
    <nav class="actions"><button class="ghost-button" :disabled="loading || busy || page === 1" data-testid="creator-previous" @click="close(); load(page - 1)">{{ copy.previous }}</button><span>{{ page }}</span><button class="ghost-button" :disabled="loading || busy || !hasMore" data-testid="creator-next" @click="close(); load(page + 1)">{{ copy.next }}</button></nav>
  </section>
</template>
<style scoped>
.creator-page { max-width: 860px; margin: auto; }
.task-list { list-style: none; padding: 0; display: grid; gap: 18px; }
.task-card { padding: 24px; border: 1px solid var(--line); border-radius: 18px; background: var(--surface-strong); overflow-wrap: anywhere; }
.task-card h2 { margin-top: 0; }
.task-description { white-space: pre-wrap; }
.task-action { display: flex; margin-top: 16px; }
form { display: grid; gap: 12px; margin-top: 16px; }
.field { margin-bottom: 0; }
select, textarea { width: 100%; min-width: 0; }
.actions { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; }
</style>
