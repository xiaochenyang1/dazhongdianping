<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { confirmReservation, fetchReservations, rejectReservation, type MerchantReservation } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const loading = ref(true)
const error = ref('')
const items = ref<MerchantReservation[]>([])
const rejectReasons = reactive<Record<number, string>>({})
const canManageReservations = computed(() => props.permissions.includes('reservation:confirm'))

async function load() {
  loading.value = true
  error.value = ''
  try {
    items.value = (await fetchReservations({ page: 1, pageSize: 50 })).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '预订加载失败'
  } finally {
    loading.value = false
  }
}

async function act(item: MerchantReservation, type: 'confirm' | 'reject') {
  if (!canManageReservations.value) return
  if (type === 'reject') {
    const reason = (rejectReasons[item.id] ?? '').trim()
    if (!reason) {
      error.value = '请填写拒绝原因'
      return
    }
    try {
      await rejectReservation(item.id, reason)
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : '拒绝预订失败'
      return
    }
  } else {
    try {
      await confirmReservation(item.id)
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : '确认预订失败'
      return
    }
  }
  delete rejectReasons[item.id]
  await load()
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">只对后端标记可操作的预订显示处理按钮。</span>
      <button type="button" @click="load">刷新</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="muted">加载中...</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead><tr><th>预订号</th><th>门店</th><th>时间</th><th>状态</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.reservationNo }}</td>
            <td>{{ item.shop.name }}</td>
            <td>{{ item.reserveTime }}</td>
            <td>{{ item.statusText }}</td>
            <td>
              <div v-if="canManageReservations && (item.canConfirm || item.canReject)" class="row-actions" :data-testid="`reservation-actions-${item.id}`">
                <input
                  v-if="item.canReject"
                  v-model="rejectReasons[item.id]"
                  :name="`reservation-reason-${item.id}`"
                  maxlength="255"
                  placeholder="填写拒绝原因"
                />
                <button v-if="item.canConfirm" type="button" :data-testid="`confirm-reservation-${item.id}`" @click="act(item, 'confirm')">确认</button>
                <button v-if="item.canReject" type="button" class="danger-action" :data-testid="`reject-reservation-${item.id}`" @click="act(item, 'reject')">拒绝</button>
              </div>
              <span v-else class="muted">无需处理</span>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="5" class="feedback">当前没有预订。</td></tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
