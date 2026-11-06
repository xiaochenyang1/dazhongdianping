<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminCreatorStrings } from '@/core/admin_creator_localizations'
import { fetchAdminCreatorTasks, saveAdminCreatorTask, type OpsCreatorTask } from '@/services/ops'
import { fetchCreatorClaims, reviewCreatorClaim, type CreatorClaim } from '@/services/creator'

const { state } = useAdminSession()
const copy = computed(() => adminCreatorStrings(state.region))
const canWrite = computed(() => state.permissions.includes('operations:creator:write'))
const tab = ref<'reviews' | 'tasks'>('reviews')
const tasks = ref<OpsCreatorTask[]>([])
const claims = ref<CreatorClaim[]>([])
const selected = ref<CreatorClaim | null>(null)
const evidenceImages = computed(() => (selected.value?.evidence?.images ?? []).flatMap(value => {
  try {
    const url = new URL(value, window.location.href)
    return ['http:', 'https:'].includes(url.protocol) ? [url.href] : []
  } catch { return [] }
}))
const reviewNote = ref('')
const filter = ref(3)
const page = ref(1)
const hasMore = ref(false)
const loading = ref(false)
const acting = ref(false)
const busy = computed(() => loading.value || acting.value)
const errorMessage = ref('')
const successMessage = ref('')
const editingId = ref<number>()
const form = reactive({ title: '', description: '', rewardPoints: 20, status: 1 })
let scope = 0
let revision = 0

function resetForm() {
  editingId.value = undefined
  Object.assign(form, { title: '', description: '', rewardPoints: 20, status: 1 })
}

async function load(target = page.value, preserveSelection = false) {
  const current = ++revision
  loading.value = true
  errorMessage.value = ''
  try {
    if (tab.value === 'reviews') {
      const result = await fetchCreatorClaims(target, filter.value || undefined)
      if (current !== revision) return
      claims.value = result.list
      hasMore.value = result.hasMore
      if (!preserveSelection) { selected.value = null; reviewNote.value = '' }
    } else {
      const result = await fetchAdminCreatorTasks(target)
      if (current !== revision) return
      tasks.value = result.list
      hasMore.value = result.hasMore
    }
    page.value = target
  } catch (error) {
    if (current === revision) errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  } finally { if (current === revision) loading.value = false }
}

function changeTab(value: 'reviews' | 'tasks') {
  if (busy.value || tab.value === value) return
  tab.value = value
  selected.value = null
  successMessage.value = ''
  page.value = 1
  hasMore.value = false
  void load(1)
}

function select(claim: CreatorClaim) {
  if (busy.value) return
  selected.value = claim
  reviewNote.value = ''
  errorMessage.value = ''; successMessage.value = ''
}

async function review(approved: boolean) {
  const item = selected.value
  if (busy.value || !canWrite.value || !item || item.claimStatus !== 3) return
  const note = reviewNote.value.trim()
  if (!approved && !note) { errorMessage.value = copy.value.noteRequired; return }
  if (approved && (!item.evidence || !item.evidenceHash)) return
  const current = scope
  acting.value = true
  errorMessage.value = ''; successMessage.value = ''
  try {
    const result = await reviewCreatorClaim(item.id, {
      approved, submissionVersion: item.submissionVersion, evidenceHash: item.evidenceHash, note,
    })
    if (current !== scope) return
    selected.value = result
    reviewNote.value = ''
    successMessage.value = approved ? copy.value.approved : copy.value.rejected
    await load(page.value, true)
  } catch (error) {
    if (current === scope) errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  } finally { if (current === scope) acting.value = false }
}

function edit(task: OpsCreatorTask) {
  if (busy.value || !canWrite.value) return
  editingId.value = task.id
  Object.assign(form, { title: task.title, description: task.description, rewardPoints: task.rewardPoints, status: task.status })
}

async function save() {
  if (busy.value || !canWrite.value) return
  const reward = Number(form.rewardPoints)
  if (!form.title.trim() || !Number.isInteger(reward) || reward < 0 || reward > 2147483647) {
    errorMessage.value = copy.value.invalid; return
  }
  const current = scope
  acting.value = true
  errorMessage.value = ''; successMessage.value = ''
  try {
    await saveAdminCreatorTask({ ...form, title: form.title.trim(), description: form.description.trim(), rewardPoints: reward }, editingId.value)
    if (current !== scope) return
    resetForm()
    successMessage.value = copy.value.saved
    await load()
  } catch (error) {
    if (current === scope) errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  } finally { if (current === scope) acting.value = false }
}

watch(() => [state.region, state.profile?.id, state.token], () => {
  scope++; revision++
  tasks.value = []; claims.value = []; selected.value = null; reviewNote.value = ''
  errorMessage.value = ''; successMessage.value = ''; page.value = 1; hasMore.value = false
  loading.value = false; acting.value = false; resetForm()
  void load(1)
}, { immediate: true, flush: 'sync' })
onBeforeUnmount(() => { scope++; revision++ })
</script>

<template>
  <section class="page creator-admin">
    <header class="page-header"><h1>{{ copy.title }}</h1><p class="page-desc">{{ copy.summary }}</p></header>
    <nav class="actions">
      <button type="button" class="secondary-button" :aria-pressed="tab === 'reviews'" :disabled="busy" @click="changeTab('reviews')">{{ copy.reviews }}</button>
      <button type="button" class="secondary-button" :aria-pressed="tab === 'tasks'" :disabled="busy" data-testid="creator-tasks-tab" @click="changeTab('tasks')">{{ copy.tasks }}</button>
      <button type="button" class="ghost-button" :disabled="busy" @click="load()">{{ copy.refresh }}</button>
    </nav>
    <p v-if="errorMessage" role="alert" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" role="status" class="feedback">{{ successMessage }}</p>
    <p v-if="loading" role="status">{{ copy.loading }}</p>
    <template v-if="tab === 'reviews'">
      <label class="field status-filter">{{ copy.status }}<select v-model.number="filter" :disabled="acting" data-testid="creator-review-filter" @change="load(1)">
        <option :value="0">{{ copy.all }}</option><option v-for="status in [3,4,2,1]" :key="status" :value="status">{{ copy.statuses[status] }}</option>
      </select></label>
      <div class="review-layout">
        <div class="claim-list" :aria-busy="loading">
          <p v-if="!loading && !claims.length">{{ copy.emptyClaims }}</p>
          <article v-for="item in claims" :key="item.id" class="panel" :data-testid="`creator-claim-${item.id}`">
            <h2>{{ item.taskTitle }}</h2><p>{{ copy.customer }} #{{ item.userId }} · {{ item.rewardPoints }} {{ copy.points }}</p>
            <p>{{ copy.statuses[item.claimStatus] }}</p>
            <button type="button" class="secondary-button" :disabled="busy" @click="select(item)">{{ copy.select }}</button>
          </article>
        </div>
        <article v-if="selected" class="panel claim-detail" data-testid="creator-claim-detail">
          <h2>{{ selected.taskTitle }}</h2><h3>{{ copy.requirements }}</h3><p class="multiline">{{ selected.taskDescription }}</p>
          <strong>{{ selected.rewardPoints }} {{ copy.points }} · {{ copy.statuses[selected.claimStatus] }}</strong>
          <p v-if="selected.submittedAt">{{ copy.submittedAt }}: {{ selected.submittedAt.replace('T', ' ') }}</p>
          <h3>{{ copy.submission }}</h3><p class="multiline">{{ selected.submissionNote || '—' }}</p>
          <h3>{{ copy.work }}</h3>
          <template v-if="selected.evidence">
            <p>{{ selected.evidenceType === 'review' ? copy.review : copy.post }} #{{ selected.evidenceId }}</p>
            <h4>{{ selected.evidence.title }}</h4><p class="multiline">{{ selected.evidence.content }}</p>
            <p v-if="selected.evidence.shopId">{{ copy.shop }} #{{ selected.evidence.shopId }}</p>
            <p v-if="selected.evidence.score != null">{{ copy.score }}: {{ selected.evidence.score }}</p>
            <div class="work-images"><a v-for="(url, index) in evidenceImages" :key="index" :href="url" target="_blank" rel="noopener noreferrer"><img :src="url" :alt="`${copy.image} ${index + 1}`" loading="lazy" /></a></div>
          </template>
          <p v-else>{{ selected.claimStatus === 1 ? copy.notSubmitted : copy.unavailable }}</p>
          <p v-if="selected.reviewNote" class="multiline">{{ copy.result }}: {{ selected.reviewNote }}</p>
          <form v-if="canWrite && selected.claimStatus === 3" @submit.prevent="review(true)">
            <label class="field">{{ copy.note }}<textarea v-model="reviewNote" maxlength="1000" rows="3" :disabled="busy" data-testid="creator-review-note" /></label>
            <div class="actions">
              <button class="primary-button" type="submit" :disabled="busy || !selected.evidence || !selected.evidenceHash" data-testid="creator-approve">{{ copy.approve }}</button>
              <button class="secondary-button" type="button" :disabled="busy" data-testid="creator-reject" @click="review(false)">{{ copy.reject }}</button>
            </div>
          </form>
        </article>
        <p v-else class="selection-help">{{ copy.selectHelp }}</p>
      </div>
    </template>
    <template v-else>
      <p>{{ copy.frozen }}</p>
      <p v-if="!loading && !tasks.length">{{ copy.emptyTasks }}</p>
      <div v-else class="table-scroll"><table class="data-table" :aria-busy="loading">
        <thead><tr><th>{{ copy.taskTitle }}</th><th>{{ copy.reward }}</th><th>{{ copy.status }}</th><th>{{ copy.edit }}</th></tr></thead>
        <tbody><tr v-for="task in tasks" :key="task.id"><td>{{ task.title }}</td><td>{{ task.rewardPoints }}</td><td>{{ task.status === 1 ? copy.enabled : copy.disabled }}</td><td><button v-if="canWrite" class="link" :disabled="busy" @click="edit(task)">{{ copy.edit }}</button></td></tr></tbody>
      </table></div>
      <form v-if="canWrite" class="panel task-form" data-testid="creator-task-form" @submit.prevent="save">
        <div class="actions"><h2>{{ editingId ? copy.edit : copy.newTask }}</h2><button v-if="editingId" type="button" :disabled="busy" @click="resetForm">{{ copy.newTask }}</button></div>
        <label class="field">{{ copy.taskTitle }}<input v-model="form.title" required maxlength="128" :disabled="busy" /></label>
        <label class="field">{{ copy.description }}<textarea v-model="form.description" maxlength="1000" rows="3" :disabled="busy" /></label>
        <label class="field">{{ copy.reward }}<input v-model.number="form.rewardPoints" type="number" required min="0" max="2147483647" step="1" :disabled="busy" /></label>
        <label class="field">{{ copy.status }}<select v-model.number="form.status" :disabled="busy"><option :value="1">{{ copy.enabled }}</option><option :value="0">{{ copy.disabled }}</option></select></label>
        <button class="primary-button" type="submit" :disabled="busy">{{ copy.save }}</button>
      </form>
    </template>
    <nav class="actions"><button class="ghost-button" :disabled="busy || page <= 1" data-testid="creator-previous" @click="load(page - 1)">{{ copy.previous }}</button><span>{{ page }}</span><button class="ghost-button" :disabled="busy || !hasMore" data-testid="creator-next" @click="load(page + 1)">{{ copy.next }}</button></nav>
  </section>
</template>

<style scoped>
.creator-admin { display: grid; gap: 1rem; }
.actions { display: flex; gap: .75rem; align-items: center; flex-wrap: wrap; }
.status-filter { max-width: 260px; }
.review-layout { display: grid; grid-template-columns: minmax(220px, 1fr) minmax(0, 2fr); gap: 1.25rem; align-items: start; }
.claim-list { display: grid; gap: 1rem; }
.panel { background: var(--panel); border: 1px solid var(--border); padding: 1.25rem; border-radius: 1rem; overflow-wrap: anywhere; }
.panel h2 { margin-top: 0; font-size: 1.15rem; }
.panel h3 { margin-bottom: .5rem; }
.multiline { white-space: pre-wrap; }
.claim-detail form, .task-form { display: grid; gap: 1rem; }
.claim-detail form { margin-top: 1rem; }
.work-images { display: grid; grid-template-columns: repeat(auto-fill, minmax(100px, 1fr)); gap: .75rem; }
.work-images img { width: 100%; height: 130px; object-fit: cover; border-radius: .5rem; }
.table-scroll { overflow-x: auto; }
.task-form { max-width: 760px; }
@media (max-width: 800px) { .review-layout { grid-template-columns: 1fr; } }
</style>
