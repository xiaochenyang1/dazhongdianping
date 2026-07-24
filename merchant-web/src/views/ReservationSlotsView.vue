<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  createReservationSlot,
  fetchReservationSlots,
  fetchShops,
  updateReservationSlot,
  updateReservationSlotStatus,
  type MerchantReservationSlot,
  type MerchantReservationSlotPayload,
  type MerchantShopOption,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const canView = computed(() => props.permissions.includes('reservation:view'))
const canEdit = computed(() => props.permissions.includes('reservation:confirm'))

const loading = ref(false)
const saving = ref(false)
const error = ref('')
const success = ref('')
const shops = ref<MerchantShopOption[]>([])
const items = ref<MerchantReservationSlot[]>([])

const filters = reactive({
  shopId: '' as string | number,
  dateFrom: '',
  dateTo: '',
  enabled: '' as '' | 'true' | 'false',
})

const editor = ref<(MerchantReservationSlotPayload & { id?: number }) | null>(null)

function messageOf(cause: unknown) {
  return cause instanceof Error ? cause.message : '请求失败'
}

async function loadShops() {
  const page = await fetchShops({ page: 1, pageSize: 100 })
  shops.value = page.list.map((item) => ({ id: Number(item.id), name: String(item.name) }))
  if (!filters.shopId && shops.value[0]) {
    filters.shopId = shops.value[0].id
  }
}

async function load() {
  if (!canView.value) return
  loading.value = true
  error.value = ''
  try {
    const page = await fetchReservationSlots({
      page: 1,
      pageSize: 100,
      shopId: filters.shopId === '' ? undefined : Number(filters.shopId),
      dateFrom: filters.dateFrom || undefined,
      dateTo: filters.dateTo || undefined,
      enabled: filters.enabled === '' ? undefined : filters.enabled === 'true',
    })
    items.value = page.list
  } catch (cause) {
    error.value = messageOf(cause)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  if (!canEdit.value) return
  const shopId = filters.shopId === '' ? Number(shops.value[0]?.id || 0) : Number(filters.shopId)
  editor.value = {
    shopId,
    bizDate: filters.dateFrom || new Date().toISOString().slice(0, 10),
    startTime: '18:00:00',
    endTime: '20:00:00',
    capacity: 10,
    confirmMode: 2,
    cancelBeforeMinutes: 120,
    enabled: true,
  }
  success.value = ''
  error.value = ''
}

function openEdit(item: MerchantReservationSlot) {
  if (!canEdit.value) return
  editor.value = {
    id: item.id,
    shopId: item.shopId,
    bizDate: String(item.bizDate).slice(0, 10),
    startTime: normalizeTime(item.startTime),
    endTime: normalizeTime(item.endTime),
    capacity: item.capacity,
    confirmMode: item.confirmMode,
    cancelBeforeMinutes: item.cancelBeforeMinutes,
    enabled: item.enabled,
  }
  success.value = ''
  error.value = ''
}

function normalizeTime(value: string) {
  if (!value) return '00:00:00'
  return value.length === 5 ? `${value}:00` : value
}

async function submitEditor() {
  if (!editor.value || !canEdit.value) return
  saving.value = true
  error.value = ''
  success.value = ''
  const payload: MerchantReservationSlotPayload = {
    shopId: Number(editor.value.shopId),
    bizDate: editor.value.bizDate,
    startTime: normalizeTime(editor.value.startTime),
    endTime: normalizeTime(editor.value.endTime),
    capacity: Number(editor.value.capacity),
    confirmMode: Number(editor.value.confirmMode),
    cancelBeforeMinutes: Number(editor.value.cancelBeforeMinutes),
    enabled: editor.value.enabled !== false,
  }
  try {
    if (editor.value.id) {
      await updateReservationSlot(editor.value.id, payload)
      success.value = '时段已更新'
    } else {
      await createReservationSlot(payload)
      success.value = '时段已创建'
    }
    editor.value = null
    await load()
  } catch (cause) {
    error.value = messageOf(cause)
  } finally {
    saving.value = false
  }
}

async function toggleEnabled(item: MerchantReservationSlot) {
  if (!canEdit.value || saving.value) return
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    await updateReservationSlotStatus(item.id, !item.enabled)
    success.value = item.enabled ? '时段已停用' : '时段已启用'
    await load()
  } catch (cause) {
    error.value = messageOf(cause)
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    await loadShops()
    await load()
  } catch (cause) {
    error.value = messageOf(cause)
  }
})

watch(
  () => [filters.shopId, filters.dateFrom, filters.dateTo, filters.enabled],
  () => {
    void load()
  },
)
</script>

<template>
  <section>
    <div class="toolbar">
      <div class="row-actions">
        <label>
          <span class="muted">门店</span>
          <select v-model="filters.shopId" data-testid="slot-shop-filter">
            <option value="">全部门店</option>
            <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
          </select>
        </label>
        <label>
          <span class="muted">开始日期</span>
          <input v-model="filters.dateFrom" type="date" data-testid="slot-date-from" />
        </label>
        <label>
          <span class="muted">结束日期</span>
          <input v-model="filters.dateTo" type="date" data-testid="slot-date-to" />
        </label>
        <label>
          <span class="muted">状态</span>
          <select v-model="filters.enabled" data-testid="slot-enabled-filter">
            <option value="">全部</option>
            <option value="true">启用</option>
            <option value="false">停用</option>
          </select>
        </label>
      </div>
      <div class="row-actions">
        <button type="button" @click="load">刷新</button>
        <button v-if="canEdit" type="button" data-testid="create-slot" @click="openCreate">新建时段</button>
      </div>
    </div>

    <p class="muted">配置门店可订时段：容量、自动/人工确认、取消截止分钟数。停用后 C 端不可再订该时段。</p>
    <p v-if="!canView" class="error" role="alert">当前账号缺少 `reservation:view` 权限。</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="success" class="muted" data-testid="slot-success">{{ success }}</p>
    <p v-if="loading" class="muted">加载中...</p>

    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>门店</th>
            <th>日期</th>
            <th>时段</th>
            <th>容量</th>
            <th>确认方式</th>
            <th>状态</th>
            <th v-if="canEdit">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.shopName || item.shopId }}</td>
            <td>{{ item.bizDate }}</td>
            <td>{{ item.startTime }} - {{ item.endTime }}</td>
            <td>{{ item.reservedCount }}/{{ item.capacity }}（余 {{ item.remainingCount }}）</td>
            <td>{{ item.confirmModeText }} · 取消前 {{ item.cancelBeforeMinutes }} 分</td>
            <td>{{ item.enabled ? '启用' : '停用' }}</td>
            <td v-if="canEdit" class="row-actions">
              <button type="button" :data-testid="`edit-slot-${item.id}`" @click="openEdit(item)">编辑</button>
              <button type="button" :data-testid="`toggle-slot-${item.id}`" @click="toggleEnabled(item)">
                {{ item.enabled ? '停用' : '启用' }}
              </button>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td :colspan="canEdit ? 7 : 6" class="feedback">当前筛选下没有时段。</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="editor && canEdit" class="card" style="margin-top: 16px">
      <h3>{{ editor.id ? '编辑时段' : '新建时段' }}</h3>
      <form class="row-actions" style="flex-wrap: wrap; gap: 12px" data-testid="slot-editor" @submit.prevent="submitEditor">
        <label>
          <span class="muted">门店</span>
          <select v-model.number="editor.shopId" name="slot-shop" required :disabled="!!editor.id">
            <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
          </select>
        </label>
        <label>
          <span class="muted">日期</span>
          <input v-model="editor.bizDate" name="slot-date" type="date" required />
        </label>
        <label>
          <span class="muted">开始</span>
          <input v-model="editor.startTime" name="slot-start" type="time" step="1" required />
        </label>
        <label>
          <span class="muted">结束</span>
          <input v-model="editor.endTime" name="slot-end" type="time" step="1" required />
        </label>
        <label>
          <span class="muted">容量</span>
          <input v-model.number="editor.capacity" name="slot-capacity" type="number" min="1" max="500" required />
        </label>
        <label>
          <span class="muted">确认方式</span>
          <select v-model.number="editor.confirmMode" name="slot-confirm-mode">
            <option :value="1">自动确认</option>
            <option :value="2">人工确认</option>
          </select>
        </label>
        <label>
          <span class="muted">取消截止(分钟)</span>
          <input
            v-model.number="editor.cancelBeforeMinutes"
            name="slot-cancel-before"
            type="number"
            min="0"
            max="1440"
            required
          />
        </label>
        <label>
          <span class="muted">启用</span>
          <input v-model="editor.enabled" name="slot-enabled" type="checkbox" />
        </label>
        <button type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存时段' }}</button>
        <button type="button" class="ghost" @click="editor = null">取消</button>
      </form>
    </div>
  </section>
</template>
