<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import {
  arriveReservation,
  confirmReservation,
  fetchReservations,
  markReservationNoShow,
  rejectReservation,
  type MerchantReservation,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const loading = ref(true)
const actingId = ref<number | null>(null)
const error = ref('')
const success = ref('')
const items = ref<MerchantReservation[]>([])
const rejectReasons = reactive<Record<number, string>>({})
const canManageReservations = computed(() => props.permissions.includes('reservation:confirm'))
const canArriveReservations = computed(
  () => props.permissions.includes('reservation:arrive') || props.permissions.includes('reservation:confirm'),
)
const filters = reactive({
  status: '0',
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    items.value = (
      await fetchReservations({
        page: 1,
        pageSize: 50,
        status: filters.status === '' ? undefined : Number(filters.status),
      })
    ).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '预订加载失败'
  } finally {
    loading.value = false
  }
}

function canAct(item: MerchantReservation) {
  return Boolean(
    (canManageReservations.value && (item.canConfirm || item.canReject)) ||
      (canArriveReservations.value && (item.canArrive || item.canNoShow)),
  )
}

async function act(
  item: MerchantReservation,
  type: 'confirm' | 'reject' | 'arrive' | 'no-show',
) {
  if (type === 'confirm' || type === 'reject') {
    if (!canManageReservations.value) return
  } else if (!canArriveReservations.value) {
    return
  }

  actingId.value = item.id
  error.value = ''
  success.value = ''
  try {
    if (type === 'reject') {
      const reason = (rejectReasons[item.id] ?? '').trim()
      if (!reason) {
        error.value = '请填写拒绝原因'
        return
      }
      await rejectReservation(item.id, reason)
      success.value = `预订 ${item.reservationNo} 已拒绝`
    } else if (type === 'confirm') {
      await confirmReservation(item.id)
      success.value = `预订 ${item.reservationNo} 已确认`
    } else if (type === 'arrive') {
      await arriveReservation(item.id)
      success.value = `预订 ${item.reservationNo} 已确认到店`
    } else {
      await markReservationNoShow(item.id)
      success.value = `预订 ${item.reservationNo} 已标记爽约`
    }
    delete rejectReasons[item.id]
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '预订操作失败'
  } finally {
    actingId.value = null
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div class="row-actions">
        <label>
          <span class="muted">状态</span>
          <select
            v-model="filters.status"
            name="reservation-status-filter"
            data-testid="reservation-status-filter"
            @change="load"
          >
            <option value="">全部</option>
            <option value="0">待确认</option>
            <option value="1">已确认</option>
            <option value="2">已到店</option>
            <option value="3">用户取消</option>
            <option value="4">商户拒绝</option>
            <option value="5">爽约</option>
          </select>
        </label>
      </div>
      <button type="button" @click="load">刷新</button>
    </div>
    <p class="muted">默认看待确认；已确认预订可继续做到店确认或标记爽约。</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="success" class="muted" data-testid="reservation-success">{{ success }}</p>
    <p v-if="loading" class="muted">加载中...</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>预订号</th>
            <th>门店</th>
            <th>时间</th>
            <th>联系人</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.reservationNo }}</td>
            <td>{{ item.shop.name }}</td>
            <td>
              {{ item.reserveTime }}
              <div v-if="item.peopleCount" class="muted">{{ item.peopleCount }} 人</div>
            </td>
            <td>
              <template v-if="item.contactName || item.contactPhone">
                {{ item.contactName || '—' }}
                <div class="muted">{{ item.contactPhone || '' }}</div>
              </template>
              <span v-else class="muted">—</span>
            </td>
            <td>{{ item.statusText }}</td>
            <td>
              <div
                v-if="canAct(item)"
                class="row-actions"
                :data-testid="`reservation-actions-${item.id}`"
              >
                <input
                  v-if="canManageReservations && item.canReject"
                  v-model="rejectReasons[item.id]"
                  :name="`reservation-reason-${item.id}`"
                  maxlength="255"
                  placeholder="填写拒绝原因"
                />
                <button
                  v-if="canManageReservations && item.canConfirm"
                  type="button"
                  :data-testid="`confirm-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'confirm')"
                >
                  确认
                </button>
                <button
                  v-if="canManageReservations && item.canReject"
                  type="button"
                  class="danger-action"
                  :data-testid="`reject-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'reject')"
                >
                  拒绝
                </button>
                <button
                  v-if="canArriveReservations && item.canArrive"
                  type="button"
                  :data-testid="`arrive-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'arrive')"
                >
                  确认到店
                </button>
                <button
                  v-if="canArriveReservations && item.canNoShow"
                  type="button"
                  class="danger-action"
                  :data-testid="`noshow-reservation-${item.id}`"
                  :disabled="actingId === item.id"
                  @click="act(item, 'no-show')"
                >
                  标记爽约
                </button>
              </div>
              <span v-else class="muted">无需处理</span>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td colspan="6" class="feedback">当前筛选下没有预订。</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
