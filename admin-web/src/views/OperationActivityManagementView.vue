<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createAdminOperationActivity,
  createAdminOperationActivityItem,
  listAdminOperationActivities,
  listAdminOperationActivityItems,
  removeAdminOperationActivity,
  removeAdminOperationActivityItem,
  updateAdminOperationActivity,
  updateAdminOperationActivityItem,
  updateAdminOperationActivityItemStatus,
  updateAdminOperationActivityStatus,
} from '@/services/admin'
import { fetchCities } from '@/services/meta'
import type {
  AdminOperationActivity,
  AdminOperationActivityItem,
  AdminOperationActivityItemPayload,
  AdminOperationActivityPayload,
  City,
} from '@/types/admin'

type ActivityEditor = Omit<AdminOperationActivityPayload, 'cityId' | 'rule' | 'startAt' | 'endAt'> & {
  id?: number
  cityId: number | ''
  ruleText: string
  startAt: string
  endAt: string
}

type ItemEditor = Omit<AdminOperationActivityItemPayload, 'extra'> & {
  id?: number
  badge: string
  trackCode: string
  url: string
}

const activityStatusOptions = [
  { value: 0, label: '草稿' },
  { value: 1, label: '待上线' },
  { value: 2, label: '上线中' },
  { value: 3, label: '已下线' },
  { value: 4, label: '已结束' },
]

const channelOptions = [
  { value: 1, label: '首页' },
  { value: 2, label: '搜索' },
  { value: 3, label: '频道' },
  { value: 4, label: '活动页' },
  { value: 5, label: '社区' },
]

const typeOptions = [
  { value: 1, label: '专题活动' },
  { value: 2, label: '节日活动' },
  { value: 3, label: '新客活动' },
  { value: 4, label: '商户扶持' },
  { value: 5, label: '内容话题' },
]

const targetTypeOptions = [
  { value: 1, label: '店铺' },
  { value: 2, label: '团购' },
  { value: 3, label: '帖子' },
  { value: 4, label: '榜单' },
  { value: 5, label: '话题' },
  { value: 6, label: '外链' },
]

const { state } = useAdminSession()
const canWrite = computed(() => state.permissions.includes('operations:activity:write'))
const currentActivity = computed(() => activities.value.find((item) => item.id === selectedActivityId.value) ?? null)

const cities = ref<City[]>([])
const activities = ref<AdminOperationActivity[]>([])
const items = ref<AdminOperationActivityItem[]>([])
const filterCityId = ref<number | ''>('')
const filterStatus = ref<number | ''>('')
const selectedActivityId = ref<number | null>(null)
const activityEditor = ref<ActivityEditor | null>(null)
const itemEditor = ref<ItemEditor | null>(null)
const activityStatusDrafts = ref<Record<number, number>>({})
const loading = ref(false)
const itemLoading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let activityRequestId = 0
let itemRequestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : '请求失败'
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function scopeText(item: AdminOperationActivity) {
  if (item.cityId === 0) {
    return '区域通用'
  }
  return item.cityName || `城市 #${item.cityId}`
}

function textOf(record: Record<string, unknown>, key: string) {
  const value = record[key]
  return typeof value === 'string' ? value : ''
}

function prettyJson(value: Record<string, unknown>) {
  return value && Object.keys(value).length ? JSON.stringify(value, null, 2) : ''
}

function extraUrl(item: AdminOperationActivityItem) {
  return item.extra ? textOf(item.extra, 'url') : ''
}

async function loadActivities() {
  const currentRequestId = ++activityRequestId
  loading.value = true
  resetMessages()
  try {
    const query = {
      cityId: filterCityId.value === '' ? undefined : Number(filterCityId.value),
      status: filterStatus.value === '' ? undefined : Number(filterStatus.value),
    }
    const [nextCities, nextActivities] = await Promise.all([
      fetchCities(),
      listAdminOperationActivities(query.cityId == null && query.status == null ? undefined : query),
    ])
    if (currentRequestId !== activityRequestId) return
    cities.value = nextCities
    activities.value = nextActivities
    activityStatusDrafts.value = Object.fromEntries(nextActivities.map((item) => [item.id, item.status]))
    if (filterCityId.value !== '' && !nextCities.some((item) => item.id === filterCityId.value)) {
      filterCityId.value = ''
    }
    const nextSelectedId = selectedActivityId.value != null && nextActivities.some((item) => item.id === selectedActivityId.value)
      ? selectedActivityId.value
      : (nextActivities[0]?.id ?? null)
    selectedActivityId.value = nextSelectedId
    itemEditor.value = null
    if (nextSelectedId == null) {
      items.value = []
      return
    }
    void loadItems(nextSelectedId)
  } catch (error) {
    if (currentRequestId === activityRequestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === activityRequestId) {
      loading.value = false
    }
  }
}

async function loadItems(activityId = selectedActivityId.value) {
  if (activityId == null) {
    items.value = []
    return
  }
  const currentRequestId = ++itemRequestId
  itemLoading.value = true
  try {
    const nextItems = await listAdminOperationActivityItems(activityId)
    if (currentRequestId !== itemRequestId) return
    items.value = nextItems
  } catch (error) {
    if (currentRequestId === itemRequestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === itemRequestId) {
      itemLoading.value = false
    }
  }
}

function selectActivity(item: AdminOperationActivity) {
  selectedActivityId.value = item.id
  itemEditor.value = null
  void loadItems(item.id)
}

function openActivityEditor(item?: AdminOperationActivity) {
  if (!canWrite.value) return
  resetMessages()
  activityEditor.value = item
    ? {
        id: item.id,
        name: item.name,
        code: item.code,
        cityId: item.cityId === 0 ? '' : item.cityId,
        channel: item.channel,
        type: item.type,
        cover: item.cover,
        landingUrl: item.landingUrl,
        ruleText: prettyJson(item.rule),
        startAt: item.startAt,
        endAt: item.endAt,
      }
    : {
        name: '',
        code: '',
        cityId: '',
        channel: 4,
        type: 1,
        cover: '',
        landingUrl: '',
        ruleText: '',
        startAt: '',
        endAt: '',
      }
}

function parseObjectText(value: string, label: string) {
  const source = value.trim()
  if (!source) return null
  let parsed: unknown
  try {
    parsed = JSON.parse(source)
  } catch {
    throw new Error(`${label} 必须是合法 JSON`)
  }
  if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') {
    throw new Error(`${label} 必须是 JSON 对象`)
  }
  return parsed as Record<string, unknown>
}

function buildActivityPayload(current: ActivityEditor): AdminOperationActivityPayload {
  return {
    name: current.name.trim(),
    code: current.code.trim(),
    cityId: current.cityId === '' ? 0 : Number(current.cityId),
    channel: Number(current.channel),
    type: Number(current.type),
    cover: current.cover.trim(),
    landingUrl: current.landingUrl.trim(),
    rule: parseObjectText(current.ruleText, '规则 JSON'),
    startAt: current.startAt.trim() || null,
    endAt: current.endAt.trim() || null,
  }
}

async function submitActivityEditor() {
  if (!activityEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  try {
    const current = activityEditor.value
    const payload = buildActivityPayload(current)
    if (current.id) {
      await updateAdminOperationActivity(current.id, payload)
      successMessage.value = '活动已更新'
    } else {
      await createAdminOperationActivity(payload)
      successMessage.value = '活动已创建'
    }
    activityEditor.value = null
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function applyActivityStatus(item: AdminOperationActivity) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminOperationActivityStatus(item.id, Number(activityStatusDrafts.value[item.id] ?? item.status))
    successMessage.value = '活动状态已更新'
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteActivity(item: AdminOperationActivity) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(`确认删除活动「${item.name}」？活动主体和资源项会一起删除。`)
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminOperationActivity(item.id)
    successMessage.value = '活动已删除'
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

function openItemEditor(item?: AdminOperationActivityItem) {
  if (!canWrite.value || !currentActivity.value) return
  resetMessages()
  itemEditor.value = item
    ? {
        id: item.id,
        targetType: item.targetType,
        targetId: item.targetId,
        title: item.title,
        subtitle: item.subtitle,
        image: item.image,
        sort: item.sort,
        badge: item.extra ? textOf(item.extra, 'badge') : '',
        trackCode: item.extra ? textOf(item.extra, 'trackCode') : '',
        url: item.extra ? textOf(item.extra, 'url') : '',
      }
    : {
        targetType: 1,
        targetId: 0,
        title: '',
        subtitle: '',
        image: '',
        sort: 0,
        badge: '',
        trackCode: '',
        url: '',
      }
}

function buildItemPayload(current: ItemEditor): AdminOperationActivityItemPayload {
  const extra: Record<string, unknown> = {}
  if (current.badge.trim()) extra.badge = current.badge.trim()
  if (current.trackCode.trim()) extra.trackCode = current.trackCode.trim()
  if (current.url.trim()) extra.url = current.url.trim()
  if (current.targetType === 6 && !current.url.trim()) {
    throw new Error('外链资源必须填写 URL')
  }
  return {
    targetType: Number(current.targetType),
    targetId: Number(current.targetType) === 6 ? 0 : Number(current.targetId),
    title: current.title.trim(),
    subtitle: current.subtitle.trim(),
    image: current.image.trim(),
    sort: Number(current.sort),
    extra: Object.keys(extra).length ? extra : null,
  }
}

async function submitItemEditor() {
  if (!itemEditor.value || !currentActivity.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  try {
    const current = itemEditor.value
    const payload = buildItemPayload(current)
    if (current.id) {
      await updateAdminOperationActivityItem(currentActivity.value.id, current.id, payload)
      successMessage.value = '资源项已更新'
    } else {
      await createAdminOperationActivityItem(currentActivity.value.id, payload)
      successMessage.value = '资源项已创建'
    }
    itemEditor.value = null
    await loadItems(currentActivity.value.id)
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleItem(item: AdminOperationActivityItem) {
  if (!currentActivity.value || !canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminOperationActivityItemStatus(
      currentActivity.value.id,
      item.id,
      item.status === 1 ? 2 : 1,
    )
    successMessage.value = item.status === 1 ? '资源项已停用' : '资源项已启用'
    await loadItems(currentActivity.value.id)
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteItem(item: AdminOperationActivityItem) {
  if (!currentActivity.value || !canWrite.value || saving.value) return
  const confirmed = window.confirm(`确认删除资源项「${item.title}」？删除后活动页会立刻少一块内容。`)
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminOperationActivityItem(currentActivity.value.id, item.id)
    successMessage.value = '资源项已删除'
    await loadItems(currentActivity.value.id)
    await loadActivities()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

watch(
  () => state.region,
  () => {
    filterCityId.value = ''
    filterStatus.value = ''
    selectedActivityId.value = null
    activityEditor.value = null
    itemEditor.value = null
    void loadActivities()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">活动运营</p>
        <h1>活动主体和挂载资源走真表，别再拿文档目标态当已上线。</h1>
        <p>当前区域 {{ state.region }}。活动主体负责范围、时间和投放规则；资源项负责挂店铺、团购、帖子、榜单、话题或外链，两个层面都在这里收口。</p>
      </div>
      <button v-if="canWrite" data-testid="create-activity" class="secondary-button" type="button" @click="openActivityEditor()">新建活动</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">筛选范围</p>
          <h2>先按城市和状态看当前活动池，再决定挂什么资源</h2>
        </div>
      </div>

      <form class="editor-form" @submit.prevent="loadActivities">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>城市筛选</span>
            <select v-model="filterCityId" name="activity-city-filter">
              <option :value="''">全部活动（含区域通用）</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <label class="field">
            <span>状态筛选</span>
            <select v-model="filterStatus" name="activity-status-filter">
              <option :value="''">全部状态</option>
              <option v-for="option in activityStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
        </div>
        <div class="form-actions">
          <button data-testid="apply-activity-filter" class="primary-button" type="submit" :disabled="loading">
            {{ loading ? '加载中...' : '应用筛选' }}
          </button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">活动列表</p>
          <h2>主体管范围和时间，资源项数量能直接看出这个活动是不是空壳</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>范围 / 编码</th>
              <th>活动信息</th>
              <th>投放</th>
              <th>资源项</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">加载中...</td>
            </tr>
            <tr v-else-if="!activities.length">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">当前筛选下没有活动。</td>
            </tr>
            <tr v-for="item in activities" :key="item.id">
              <td>
                <strong>{{ scopeText(item) }}</strong>
                <p><code>{{ item.code }}</code></p>
              </td>
              <td>
                <strong>{{ item.name }}</strong>
                <p>{{ item.typeText }}</p>
                <p class="muted">{{ item.cover }}</p>
              </td>
              <td>
                <p>{{ item.channelText }}</p>
                <p>{{ item.startAt || '未设开始时间' }}</p>
                <p>{{ item.endAt || '未设结束时间' }}</p>
              </td>
              <td>{{ item.itemCount }}</td>
              <td><span class="status-pill">{{ item.statusText }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`select-activity-${item.id}`" class="table-action" type="button" @click="selectActivity(item)">管资源</button>
                <button :data-testid="`edit-activity-${item.id}`" class="table-action" type="button" @click="openActivityEditor(item)">编辑</button>
                <select v-model.number="activityStatusDrafts[item.id]" :name="`activity-status-${item.id}`">
                  <option v-for="option in activityStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <button :data-testid="`status-activity-${item.id}`" class="table-action" type="button" @click="applyActivityStatus(item)">改状态</button>
                <button :data-testid="`delete-activity-${item.id}`" class="table-action danger-action" type="button" @click="deleteActivity(item)">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="activityEditor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ activityEditor.id ? '编辑活动主体' : '新建活动主体' }}</p>
          <h2>{{ activityEditor.id ? '改范围、时间和规则，资源项不会被重置' : '先建主体，再去挂店铺、团购、榜单或外链' }}</h2>
        </div>
      </div>

      <form data-testid="activity-editor" class="editor-form" @submit.prevent="submitActivityEditor">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>城市范围</span>
            <select v-model="activityEditor.cityId" name="activity-city">
              <option :value="''">区域通用</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <label class="field">
            <span>投放频道</span>
            <select v-model.number="activityEditor.channel" name="activity-channel">
              <option v-for="option in channelOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
          <label class="field">
            <span>活动类型</span>
            <select v-model.number="activityEditor.type" name="activity-type">
              <option v-for="option in typeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
          <label class="field">
            <span>开始时间</span>
            <input v-model="activityEditor.startAt" name="activity-start-at" type="text" placeholder="2026-09-01 00:00:00" />
          </label>
          <label class="field field--full">
            <span>活动名称</span>
            <input v-model="activityEditor.name" name="activity-name" type="text" maxlength="128" required />
          </label>
          <label class="field field--full">
            <span>活动编码</span>
            <input v-model="activityEditor.code" name="activity-code" type="text" maxlength="64" required />
          </label>
          <label class="field field--full">
            <span>封面 URL</span>
            <input v-model="activityEditor.cover" name="activity-cover" type="text" maxlength="255" required />
          </label>
          <label class="field field--full">
            <span>落地地址</span>
            <input v-model="activityEditor.landingUrl" name="activity-landing-url" type="text" maxlength="255" required />
          </label>
          <label class="field">
            <span>结束时间</span>
            <input v-model="activityEditor.endAt" name="activity-end-at" type="text" placeholder="2026-09-30 23:59:59" />
          </label>
          <label class="field field--full">
            <span>规则 JSON</span>
            <textarea v-model="activityEditor.ruleText" name="activity-rule" rows="6" placeholder='{"audience":["student"],"sort":"manual"}'></textarea>
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存活动' }}</button>
          <button class="secondary-button" type="button" @click="activityEditor = null">取消</button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">资源项管理</p>
          <h2>{{ currentActivity ? `给「${currentActivity.name}」挂资源` : '先选中一个活动，再管理资源项' }}</h2>
          <p v-if="currentActivity">当前范围 {{ scopeText(currentActivity) }}，状态 {{ currentActivity.statusText }}，可以混挂店铺、团购、帖子、榜单、话题和外链。</p>
        </div>
        <button v-if="canWrite && currentActivity" data-testid="create-activity-item" class="secondary-button" type="button" @click="openItemEditor()">新增资源项</button>
      </div>

      <p v-if="!currentActivity" class="table-empty">当前筛选下还没有活动可管理资源项。</p>

      <div v-else class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>资源</th>
              <th>展示文案</th>
              <th>排序</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="itemLoading">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">加载中...</td>
            </tr>
            <tr v-else-if="!items.length">
              <td :colspan="canWrite ? 5 : 4" class="table-empty">这个活动还没有资源项。</td>
            </tr>
            <tr v-for="item in items" :key="item.id">
              <td>
                <strong>{{ item.targetTypeText }}</strong>
                <p>{{ item.targetName || `目标 #${item.targetId}` }}</p>
                <p v-if="extraUrl(item)" class="muted">{{ extraUrl(item) }}</p>
              </td>
              <td>
                <strong>{{ item.title }}</strong>
                <p>{{ item.subtitle || '无副标题' }}</p>
                <p class="muted">{{ item.image }}</p>
              </td>
              <td>{{ item.sort }}</td>
              <td><span class="status-pill">{{ item.statusText }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`edit-activity-item-${item.id}`" class="table-action" type="button" @click="openItemEditor(item)">编辑</button>
                <button :data-testid="`toggle-activity-item-${item.id}`" class="table-action" type="button" @click="toggleItem(item)">
                  {{ item.status === 1 ? '停用' : '启用' }}
                </button>
                <button :data-testid="`delete-activity-item-${item.id}`" class="table-action danger-action" type="button" @click="deleteItem(item)">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="itemEditor && canWrite && currentActivity" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ itemEditor.id ? '编辑资源项' : '新建资源项' }}</p>
          <h2>{{ itemEditor.id ? '改目标或文案后，活动位展示会立即跟着变' : `把资源挂到「${currentActivity.name}」底下` }}</h2>
        </div>
      </div>

      <form data-testid="activity-item-editor" class="editor-form" @submit.prevent="submitItemEditor">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>资源类型</span>
            <select v-model.number="itemEditor.targetType" name="item-target-type">
              <option v-for="option in targetTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </label>
          <label class="field">
            <span>目标 ID</span>
            <input v-model.number="itemEditor.targetId" name="item-target-id" type="number" min="0" :disabled="itemEditor.targetType === 6" />
          </label>
          <label class="field field--full">
            <span>标题</span>
            <input v-model="itemEditor.title" name="item-title" type="text" maxlength="128" required />
          </label>
          <label class="field field--full">
            <span>副标题</span>
            <input v-model="itemEditor.subtitle" name="item-subtitle" type="text" maxlength="255" />
          </label>
          <label class="field field--full">
            <span>图片 URL</span>
            <input v-model="itemEditor.image" name="item-image" type="text" maxlength="255" required />
          </label>
          <label class="field">
            <span>排序</span>
            <input v-model.number="itemEditor.sort" name="item-sort" type="number" min="0" />
          </label>
          <label class="field">
            <span>角标</span>
            <input v-model="itemEditor.badge" name="item-badge" type="text" maxlength="32" />
          </label>
          <label class="field">
            <span>埋点编码</span>
            <input v-model="itemEditor.trackCode" name="item-track-code" type="text" maxlength="64" />
          </label>
          <label class="field field--full">
            <span>外链 URL</span>
            <input v-model="itemEditor.url" name="item-url" type="text" maxlength="255" placeholder="targetType=6 时必填" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存资源项' }}</button>
          <button class="secondary-button" type="button" @click="itemEditor = null">取消</button>
        </div>
      </form>
    </section>
  </section>
</template>
