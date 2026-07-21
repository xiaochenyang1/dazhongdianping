<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { auditRefund, fetchOrders, type MerchantOrder } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const loading = ref(true)
const error = ref('')
const auditingId = ref<number | null>(null)
const items = ref<MerchantOrder[]>([])
const refundReasons = reactive<Record<number, string>>({})
const canAuditRefund = computed(() => props.permissions.includes('order:refund'))

async function load() {
  loading.value = true
  error.value = ''
  try {
    items.value = (await fetchOrders({ page: 1, pageSize: 50 })).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '订单加载失败'
  } finally {
    loading.value = false
  }
}

async function audit(item: MerchantOrder, decision: 'approve' | 'reject') {
  if (!canAuditRefund.value) return
  const reason = (refundReasons[item.id] ?? '').trim()
  if (!reason) {
    error.value = '请填写退款审核原因'
    return
  }
  auditingId.value = item.id
  error.value = ''
  try {
    await auditRefund(item.id, decision, reason)
    delete refundReasons[item.id]
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '退款审核失败'
  } finally {
    auditingId.value = null
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">仅“申请中”的退款可审核，历史决定只读展示。</span>
      <button type="button" @click="load">刷新</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="muted">加载中...</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead><tr><th>订单号</th><th>门店</th><th>金额</th><th>支付</th><th>退款</th><th>审核</th></tr></thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.orderNo }}</td>
            <td>{{ item.shopName }}</td>
            <td>{{ item.amount }} {{ item.currency }}</td>
            <td>{{ item.payStatusText }}</td>
            <td>{{ item.refund?.statusText ?? '无退款申请' }}</td>
            <td>
              <div v-if="canAuditRefund && item.refund?.status === 0" class="refund-audit" :data-testid="`refund-actions-${item.id}`">
                <input
                  v-model="refundReasons[item.id]"
                  :name="`refund-reason-${item.id}`"
                  maxlength="255"
                  placeholder="填写审核原因"
                />
                <div class="row-actions">
                  <button
                    type="button"
                    :data-testid="`approve-refund-${item.id}`"
                    :disabled="auditingId === item.id"
                    @click="audit(item, 'approve')"
                  >通过退款</button>
                  <button
                    type="button"
                    class="danger-action"
                    :data-testid="`reject-refund-${item.id}`"
                    :disabled="auditingId === item.id"
                    @click="audit(item, 'reject')"
                  >驳回</button>
                </div>
              </div>
              <span v-else class="muted">无需处理</span>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="6" class="feedback">当前筛选下没有订单。</td></tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
