<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  listTopics,
  mergeTopic,
  recalculateTopicHot,
  updateTopic,
  updateTopicRecommendation,
  updateTopicStatus,
  type AdminTopic,
} from '@/services/topic'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:topic:write'))
const rows = ref<AdminTopic[]>([])
const loading = ref(false)
const actionBusy = ref(false)
const error = ref('')
const notice = ref('')
const keyword = ref('')
const status = ref<number | undefined>(undefined)
const recommended = ref<boolean | undefined>(undefined)
const editingId = ref<number | null>(null)
const editingName = ref('')
const mergeSource = ref<AdminTopic | null>(null)
const mergeTargetId = ref<number | null>(null)
const pinDrafts = reactive<Record<number, number>>({})

const mergeTargets = computed(() =>
  rows.value.filter(
    (row) => row.id !== mergeSource.value?.id && row.status === 1 && row.mergedToId == null,
  ),
)

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function topicStatusText(topicStatus: number) {
  return strings.value.topics.statusChipText(topicStatus)
}

function calculatedAtText(value: string) {
  return strings.value.topics.calculatedAt(value || strings.value.topics.noSnapshot)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const page = await listTopics({
      status: status.value,
      recommended: recommended.value,
      keyword: keyword.value.trim(),
      page: 1,
      pageSize: 20,
    })
    rows.value = page.list
    for (const key of Object.keys(pinDrafts)) delete pinDrafts[Number(key)]
    for (const row of rows.value) pinDrafts[row.id] = row.pinnedSort
  } catch (cause) {
    error.value = messageOf(cause, strings.value.topics.loadError)
  } finally {
    loading.value = false
  }
}

function startRename(row: AdminTopic) {
  if (!canWrite.value) return
  editingId.value = row.id
  editingName.value = row.name
}

async function saveRename() {
  if (!canWrite.value || editingId.value == null || !editingName.value.trim()) return
  await runAction(async () => {
    await updateTopic(editingId.value!, { name: editingName.value.trim() })
    editingId.value = null
    editingName.value = ''
    notice.value = strings.value.topics.renamed
    await load()
  })
}

async function toggleRecommendation(row: AdminTopic) {
  if (!canWrite.value) return
  await runAction(async () => {
    await updateTopicRecommendation(row.id, {
      recommended: !row.recommended,
      pinnedSort: Math.max(0, Number(pinDrafts[row.id] ?? 0)),
    })
    notice.value = row.recommended ? strings.value.topics.recommendationDisabled : strings.value.topics.recommendationEnabled
    await load()
  })
}

async function toggleStatus(row: AdminTopic) {
  if (!canWrite.value) return
  await runAction(async () => {
    await updateTopicStatus(row.id, row.status === 1 ? 2 : 1)
    notice.value = row.status === 1 ? strings.value.topics.blocked : strings.value.topics.restored
    await load()
  })
}

function startMerge(row: AdminTopic) {
  if (!canWrite.value) return
  mergeSource.value = row
  mergeTargetId.value = null
}

async function confirmMerge() {
  if (!canWrite.value) return
  const source = mergeSource.value
  const target = rows.value.find((row) => row.id === mergeTargetId.value)
  if (!source || !target) {
    error.value = strings.value.topics.invalidMergeTarget
    return
  }
  const confirmed = window.confirm(strings.value.topics.mergeConfirmPrompt(source.name, target.name))
  if (!confirmed) return
  await runAction(async () => {
    await mergeTopic(source.id, target.id)
    mergeSource.value = null
    mergeTargetId.value = null
    notice.value = strings.value.topics.merged
    await load()
  })
}

async function recalculate() {
  if (!canWrite.value) return
  await runAction(async () => {
    const result = await recalculateTopicHot()
    notice.value = strings.value.topics.recalculated(result.region, result.calculatedAt)
    await load()
  })
}

async function runAction(action: () => Promise<void>) {
  if (!canWrite.value) return
  actionBusy.value = true
  error.value = ''
  notice.value = ''
  try {
    await action()
  } catch (cause) {
    error.value = messageOf(cause, strings.value.topics.actionError)
  } finally {
    actionBusy.value = false
  }
}

watch(
  () => state.region,
  () => {
    editingId.value = null
    editingName.value = ''
    mergeSource.value = null
    mergeTargetId.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="topic-console">
    <header class="command-header stage-item">
      <div>
        <p class="eyebrow">{{ strings.topics.headerEyebrow(state.region) }}</p>
        <h1>{{ strings.topics.heading }}</h1>
        <p class="lede">{{ strings.topics.description }}</p>
      </div>
      <button v-if="canWrite" class="recalculate-button" type="button" :disabled="actionBusy" @click="recalculate">
        <span>↻</span> {{ strings.topics.recalculate }}
      </button>
    </header>

    <form class="filter-deck stage-item" @submit.prevent="load">
      <label>
        <span>{{ strings.topics.filters.keyword }}</span>
        <input v-model="keyword" data-testid="topic-keyword" :placeholder="strings.topics.keywordPlaceholder" />
      </label>
      <label>
        <span>{{ strings.topics.filters.status }}</span>
        <select v-model="status" data-testid="topic-status">
          <option :value="undefined">{{ strings.topics.statusOptions.all }}</option>
          <option :value="1">{{ strings.topics.statusOptions.live }}</option>
          <option :value="2">{{ strings.topics.statusOptions.blocked }}</option>
        </select>
      </label>
      <label>
        <span>{{ strings.topics.filters.recommended }}</span>
        <select v-model="recommended" data-testid="topic-recommended">
          <option :value="undefined">{{ strings.topics.recommendationOptions.all }}</option>
          <option :value="true">{{ strings.topics.recommendationOptions.recommended }}</option>
          <option :value="false">{{ strings.topics.recommendationOptions.notRecommended }}</option>
        </select>
      </label>
      <button class="query-button" type="submit">{{ strings.topics.query }}</button>
    </form>

    <p v-if="error" class="signal signal-error" role="alert">{{ error }}</p>
    <p v-if="notice" class="signal signal-success">{{ notice }}</p>
    <p v-if="loading" class="loading-copy">{{ strings.topics.loading }}</p>

    <div v-else class="topic-grid stage-item">
      <article v-for="row in rows" :key="row.id" class="topic-card" :class="{ 'is-muted': row.status === 2 }">
        <div class="card-topline">
          <div class="status-stack">
            <span class="status-chip" :class="row.status === 1 ? 'is-live' : 'is-blocked'">
              {{ topicStatusText(row.status) }}
            </span>
            <span v-if="row.recommended" class="status-chip is-recommended">{{ strings.topics.recommendedChip }}</span>
          </div>
          <strong class="topic-id">#{{ row.id }}</strong>
        </div>

        <div class="topic-title-block">
          <h2>{{ row.name }}</h2>
          <p v-if="row.mergedToId" class="merged-note">{{ strings.topics.mergedTo(row.mergedToId) }}</p>
        </div>

        <dl class="metric-rack">
          <div><dt>{{ strings.topics.metricLabels.hotScore }}</dt><dd>{{ row.hotScore }}</dd></div>
          <div><dt>{{ strings.topics.metricLabels.posts }}</dt><dd>{{ row.postCount }}</dd></div>
          <div><dt>{{ strings.topics.metricLabels.followers }}</dt><dd>{{ row.followerCount }}</dd></div>
        </dl>

        <p class="formula-line">{{ strings.topics.activitySummary(row.postCount7d, row.likeCount7d, row.commentCount7d) }}</p>
        <p class="calculated-at">{{ calculatedAtText(row.calculatedAt) }}</p>

        <div v-if="canWrite" class="pin-control">
          <label :for="`pin-${row.id}`">{{ strings.topics.pinLabel }}</label>
          <input
            :id="`pin-${row.id}`"
            v-model.number="pinDrafts[row.id]"
            :name="`pin-${row.id}`"
            type="number"
            min="0"
          />
        </div>

        <div v-if="canWrite" class="card-actions">
          <button type="button" @click="startRename(row)">{{ strings.topics.rename }}</button>
          <button type="button" class="accent-action" @click="toggleRecommendation(row)">
            {{ row.recommended ? strings.topics.cancelRecommend : strings.topics.recommend }}
          </button>
          <button type="button" @click="toggleStatus(row)">{{ row.status === 1 ? strings.topics.block : strings.topics.restore }}</button>
          <button type="button" class="danger-action" :disabled="row.mergedToId != null" @click="startMerge(row)">{{ strings.topics.merge }}</button>
        </div>
      </article>
    </div>

    <aside v-if="editingId != null && canWrite" class="operation-drawer stage-item">
      <div>
        <p class="eyebrow">{{ strings.topics.renameEyebrow }}</p>
        <h2>{{ strings.topics.renameHeading }}</h2>
      </div>
      <form data-testid="rename-form" @submit.prevent="saveRename">
        <input v-model="editingName" name="topic-name" maxlength="64" required />
        <button type="submit" :disabled="actionBusy">{{ strings.topics.renameSave }}</button>
        <button type="button" @click="editingId = null">{{ strings.common.cancel }}</button>
      </form>
    </aside>

    <aside v-if="mergeSource && canWrite" class="operation-drawer merge-drawer stage-item">
      <div>
        <p class="eyebrow">{{ strings.topics.mergeEyebrow }}</p>
        <h2>{{ strings.topics.mergeHeading(mergeSource.name) }}</h2>
        <p>{{ strings.topics.mergeDescription }}</p>
      </div>
      <div class="merge-controls">
        <select v-model.number="mergeTargetId" name="merge-target">
          <option :value="null">{{ strings.topics.mergeTargetPlaceholder }}</option>
          <option v-for="target in mergeTargets" :key="target.id" :value="target.id">
            #{{ target.id }} {{ target.name }}
          </option>
        </select>
        <button class="danger-action" type="button" :disabled="actionBusy" @click="confirmMerge">{{ strings.topics.mergeConfirm }}</button>
        <button type="button" @click="mergeSource = null">{{ strings.common.cancel }}</button>
      </div>
    </aside>
  </section>
</template>

<style scoped>
.topic-console {
  --ink: #18211d;
  --paper: #f3efe4;
  --copper: #bd5a2f;
  --moss: #42634f;
  display: grid;
  gap: 18px;
  color: var(--ink);
  -webkit-font-smoothing: antialiased;
}

.command-header,
.filter-deck,
.operation-drawer {
  border-radius: 24px;
  background: var(--paper);
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.06), 0 1px 2px -1px rgba(0, 0, 0, 0.08), 0 18px 42px rgba(44, 36, 25, 0.08);
}

.command-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 28px;
  padding: 30px;
  background-image: linear-gradient(105deg, rgba(189, 90, 47, 0.13), transparent 52%), repeating-linear-gradient(90deg, transparent 0 47px, rgba(24, 33, 29, 0.035) 48px);
}

.command-header h1,
.operation-drawer h2,
.topic-title-block h2 {
  margin: 0;
  font-family: "Noto Serif SC", "Source Han Serif SC", serif;
  text-wrap: balance;
}

.command-header h1 { font-size: clamp(32px, 4vw, 52px); letter-spacing: -0.04em; }
.eyebrow { margin: 0 0 8px; color: var(--copper); font-size: 12px; font-weight: 900; letter-spacing: 0.16em; }
.lede { max-width: 680px; margin: 12px 0 0; color: #566159; text-wrap: pretty; }

button,
input,
select { min-height: 42px; font: inherit; }

button {
  border: 0;
  border-radius: 10px;
  padding: 0 15px;
  cursor: pointer;
  background: #fffdf7;
  color: var(--ink);
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.08), 0 2px 5px rgba(0, 0, 0, 0.05);
  transition-property: scale, box-shadow, background-color;
  transition-duration: 150ms;
  transition-timing-function: ease-out;
}

button:hover { box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.11), 0 5px 12px rgba(0, 0, 0, 0.08); }
button:active { scale: 0.96; }
button:disabled { cursor: not-allowed; opacity: 0.48; }
.recalculate-button, .query-button, .accent-action { background: var(--ink); color: #fff; }
.danger-action { background: #812f26; color: #fff; }

.filter-deck {
  display: grid;
  grid-template-columns: minmax(220px, 1fr) repeat(2, minmax(150px, 0.45fr)) auto;
  gap: 12px;
  padding: 14px;
}

.filter-deck label { display: grid; gap: 6px; font-size: 12px; font-weight: 800; }
input, select { border: 1px solid rgba(24, 33, 29, 0.18); border-radius: 10px; padding: 0 12px; background: #fffefa; color: var(--ink); }
input:focus, select:focus { outline: 2px solid rgba(189, 90, 47, 0.34); outline-offset: 1px; }

.topic-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(330px, 1fr)); gap: 16px; }
.topic-card { display: grid; gap: 16px; padding: 20px; border-radius: 20px; background: #fff; box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.055), 0 1px 2px -1px rgba(0, 0, 0, 0.08), 0 13px 30px rgba(31, 39, 34, 0.07); transition-property: transform, box-shadow, opacity; transition-duration: 180ms; transition-timing-function: ease-out; }
.topic-card:hover { transform: translateY(-3px); box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.08), 0 18px 38px rgba(31, 39, 34, 0.11); }
.topic-card.is-muted { opacity: 0.62; }
.card-topline, .status-stack, .card-actions, .pin-control, .merge-controls { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.card-topline { justify-content: space-between; }
.status-chip { padding: 5px 8px; border-radius: 999px; font-size: 11px; font-weight: 900; letter-spacing: 0.08em; }
.status-chip.is-live { background: #dceadd; color: #214b31; }
.status-chip.is-blocked { background: #f1d8d2; color: #742a23; }
.status-chip.is-recommended { background: #f5dfb5; color: #70420c; }
.topic-id, .metric-rack dd, .formula-line, .calculated-at { font-variant-numeric: tabular-nums; }
.topic-id { color: #879188; }
.topic-title-block h2 { font-size: 26px; }
.merged-note, .calculated-at { margin: 5px 0 0; color: #798178; font-size: 12px; }

.metric-rack { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin: 0; }
.metric-rack div { border-radius: 14px; padding: 12px; background: var(--paper); }
.metric-rack dt { font-size: 11px; color: #687269; }
.metric-rack dd { margin: 5px 0 0; font-size: 24px; font-weight: 900; }
.formula-line { margin: 0; color: var(--moss); font-weight: 800; }
.pin-control { justify-content: space-between; }
.pin-control label { font-size: 12px; font-weight: 800; }
.pin-control input { width: 96px; }
.card-actions button { flex: 1 1 120px; }

.operation-drawer { display: grid; grid-template-columns: minmax(220px, 0.7fr) minmax(300px, 1.3fr); gap: 24px; padding: 24px; }
.operation-drawer form, .merge-controls { align-content: center; }
.operation-drawer form { display: grid; grid-template-columns: 1fr auto auto; gap: 8px; }
.merge-drawer { background: #ead9d1; }
.merge-drawer p { text-wrap: pretty; }
.merge-controls select { flex: 1 1 260px; }

.signal { margin: 0; border-radius: 12px; padding: 12px 14px; font-weight: 800; }
.signal-error { background: #f5ddd8; color: #7c2d24; }
.signal-success { background: #dfeade; color: #285138; }
.loading-copy { color: #687269; }

.stage-item { animation: stage-in 360ms ease-out both; }
.stage-item:nth-of-type(2) { animation-delay: 80ms; }
.stage-item:nth-of-type(3) { animation-delay: 160ms; }
@keyframes stage-in { from { opacity: 0; transform: translateY(12px); filter: blur(4px); } to { opacity: 1; transform: translateY(0); filter: blur(0); } }

@media (max-width: 900px) {
  .command-header, .operation-drawer { grid-template-columns: 1fr; flex-direction: column; align-items: stretch; }
  .filter-deck { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 600px) {
  .filter-deck, .operation-drawer form { grid-template-columns: 1fr; }
  .topic-grid { grid-template-columns: 1fr; }
}
</style>
