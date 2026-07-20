<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import {
  listTopics,
  mergeTopic,
  recalculateTopicHot,
  updateTopic,
  updateTopicRecommendation,
  updateTopicStatus,
  type AdminTopic,
} from '@/services/topic'

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
    for (const row of rows.value) pinDrafts[row.id] = row.pinnedSort
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '话题加载失败'
  } finally {
    loading.value = false
  }
}

function startRename(row: AdminTopic) {
  editingId.value = row.id
  editingName.value = row.name
}

async function saveRename() {
  if (editingId.value == null || !editingName.value.trim()) return
  await runAction(async () => {
    await updateTopic(editingId.value!, { name: editingName.value.trim() })
    editingId.value = null
    editingName.value = ''
    notice.value = '话题名称已更新'
    await load()
  })
}

async function toggleRecommendation(row: AdminTopic) {
  await runAction(async () => {
    await updateTopicRecommendation(row.id, {
      recommended: !row.recommended,
      pinnedSort: Math.max(0, Number(pinDrafts[row.id] ?? 0)),
    })
    notice.value = row.recommended ? '已取消推荐' : '推荐与置顶排序已更新'
    await load()
  })
}

async function toggleStatus(row: AdminTopic) {
  await runAction(async () => {
    await updateTopicStatus(row.id, row.status === 1 ? 2 : 1)
    notice.value = row.status === 1 ? '话题已屏蔽' : '话题已恢复'
    await load()
  })
}

function startMerge(row: AdminTopic) {
  mergeSource.value = row
  mergeTargetId.value = null
}

async function confirmMerge() {
  const source = mergeSource.value
  const target = rows.value.find((row) => row.id === mergeTargetId.value)
  if (!source || !target) {
    error.value = '请选择有效的合并目标'
    return
  }
  const confirmed = window.confirm(
    `将「${source.name}」合并到「${target.name}」。帖子与关注会迁移，源话题将被屏蔽；该操作不可逆。`,
  )
  if (!confirmed) return
  await runAction(async () => {
    await mergeTopic(source.id, target.id)
    mergeSource.value = null
    mergeTargetId.value = null
    notice.value = '话题合并完成，关系与热榜已重算'
    await load()
  })
}

async function recalculate() {
  await runAction(async () => {
    const result = await recalculateTopicHot()
    notice.value = `${result.region} 热榜已重算：${result.calculatedAt}`
    await load()
  })
}

async function runAction(action: () => Promise<void>) {
  actionBusy.value = true
  error.value = ''
  notice.value = ''
  try {
    await action()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '操作失败'
  } finally {
    actionBusy.value = false
  }
}

onMounted(load)
</script>

<template>
  <section class="topic-console">
    <header class="command-header stage-item">
      <div>
        <p class="eyebrow">TOPIC OPERATIONS · {{ rows[0]?.region ?? 'CURRENT REGION' }}</p>
        <h1>话题治理作战台</h1>
        <p class="lede">推荐负责发现，置顶负责秩序，合并负责收拾重复命名留下的烂摊子。</p>
      </div>
      <button class="recalculate-button" type="button" :disabled="actionBusy" @click="recalculate">
        <span>↻</span> 重算热榜
      </button>
    </header>

    <form class="filter-deck stage-item" @submit.prevent="load">
      <label>
        <span>关键词</span>
        <input v-model="keyword" data-testid="topic-keyword" placeholder="名称精确定位" />
      </label>
      <label>
        <span>状态</span>
        <select v-model="status" data-testid="topic-status">
          <option :value="undefined">全部状态</option>
          <option :value="1">正常</option>
          <option :value="2">屏蔽</option>
        </select>
      </label>
      <label>
        <span>运营推荐</span>
        <select v-model="recommended" data-testid="topic-recommended">
          <option :value="undefined">全部</option>
          <option :value="true">已推荐</option>
          <option :value="false">未推荐</option>
        </select>
      </label>
      <button class="query-button" type="submit">执行筛选</button>
    </form>

    <p v-if="error" class="signal signal-error" role="alert">{{ error }}</p>
    <p v-if="notice" class="signal signal-success">{{ notice }}</p>
    <p v-if="loading" class="loading-copy">正在读取区域话题...</p>

    <div v-else class="topic-grid stage-item">
      <article v-for="row in rows" :key="row.id" class="topic-card" :class="{ 'is-muted': row.status === 2 }">
        <div class="card-topline">
          <div class="status-stack">
            <span class="status-chip" :class="row.status === 1 ? 'is-live' : 'is-blocked'">
              {{ row.status === 1 ? 'LIVE' : 'BLOCKED' }}
            </span>
            <span v-if="row.recommended" class="status-chip is-recommended">推荐</span>
          </div>
          <strong class="topic-id">#{{ row.id }}</strong>
        </div>

        <div class="topic-title-block">
          <h2>{{ row.name }}</h2>
          <p v-if="row.mergedToId" class="merged-note">已合并至 #{{ row.mergedToId }}</p>
        </div>

        <dl class="metric-rack">
          <div><dt>热度</dt><dd>{{ row.hotScore }}</dd></div>
          <div><dt>帖子</dt><dd>{{ row.postCount }}</dd></div>
          <div><dt>关注</dt><dd>{{ row.followerCount }}</dd></div>
        </dl>

        <p class="formula-line">{{ row.postCount7d }} 帖 · {{ row.likeCount7d }} 赞 · {{ row.commentCount7d }} 评论</p>
        <p class="calculated-at">最近计算 {{ row.calculatedAt || '尚未生成快照' }}</p>

        <div class="pin-control">
          <label :for="`pin-${row.id}`">置顶排序</label>
          <input
            :id="`pin-${row.id}`"
            v-model.number="pinDrafts[row.id]"
            :name="`pin-${row.id}`"
            type="number"
            min="0"
          />
        </div>

        <div class="card-actions">
          <button type="button" @click="startRename(row)">编辑名称</button>
          <button type="button" class="accent-action" @click="toggleRecommendation(row)">
            {{ row.recommended ? '取消推荐' : '推荐并置顶' }}
          </button>
          <button type="button" @click="toggleStatus(row)">{{ row.status === 1 ? '屏蔽' : '恢复' }}</button>
          <button type="button" class="danger-action" :disabled="row.mergedToId != null" @click="startMerge(row)">
            合并话题
          </button>
        </div>
      </article>
    </div>

    <aside v-if="editingId != null" class="operation-drawer stage-item">
      <div>
        <p class="eyebrow">RENAME TOPIC</p>
        <h2>修改公开名称</h2>
      </div>
      <form data-testid="rename-form" @submit.prevent="saveRename">
        <input v-model="editingName" name="topic-name" maxlength="64" required />
        <button type="submit" :disabled="actionBusy">保存名称</button>
        <button type="button" @click="editingId = null">取消</button>
      </form>
    </aside>

    <aside v-if="mergeSource" class="operation-drawer merge-drawer stage-item">
      <div>
        <p class="eyebrow">IRREVERSIBLE MERGE</p>
        <h2>合并「{{ mergeSource.name }}」</h2>
        <p>源帖子与关注关系会去重迁移，源话题随后屏蔽。这个动作不可逆。</p>
      </div>
      <div class="merge-controls">
        <select v-model.number="mergeTargetId" name="merge-target">
          <option :value="null">选择目标话题</option>
          <option v-for="target in mergeTargets" :key="target.id" :value="target.id">
            #{{ target.id }} {{ target.name }}
          </option>
        </select>
        <button class="danger-action" type="button" :disabled="actionBusy" @click="confirmMerge">确认不可逆合并</button>
        <button type="button" @click="mergeSource = null">取消</button>
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
