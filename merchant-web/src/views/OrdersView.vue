<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { auditRefund, fetchOrders, type MerchantOrder } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const loading = ref(true)
const error = ref('')
const auditingId = ref<number | null>(null)
const items = ref<MerchantOrder[]>([])
const refundReasons = reactive<Record<number, string>>({})
const canAuditRefund = computed(() => props.permissions.includes('order:refund'))
const filters = reactive({
  refundStatus: '0',
})
const refundStatusOptions = computed(() => [
  { value: '', label: strings.value.orders.refundStatusOptions.all },
  { value: '0', label: strings.value.orders.refundStatusOptions.pending },
  { value: '1', label: strings.value.orders.refundStatusOptions.success },
  { value: '2', label: strings.value.orders.refundStatusOptions.rejected },
  { value: '3', label: strings.value.orders.refundStatusOptions.processing },
  { value: '4', label: strings.value.orders.refundStatusOptions.failed },
])

async function load() {
  loading.value = true
  error.value = ''
  try {
    items.value = (
      await fetchOrders({
        page: 1,
        pageSize: 50,
        refundStatus: filters.refundStatus === '' ? undefined : Number(filters.refundStatus),
      })
    ).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.orders.loadError
  } finally {
    loading.value = false
  }
}

async function audit(item: MerchantOrder, decision: 'approve' | 'reject') {
  if (!canAuditRefund.value) return
  const reason = (refundReasons[item.id] ?? '').trim()
  if (!reason) {
    error.value = strings.value.orders.auditReasonRequired
    return
  }
  auditingId.value = item.id
  error.value = ''
  try {
    await auditRefund(item.id, decision, reason)
    delete refundReasons[item.id]
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.orders.auditError
  } finally {
    auditingId.value = null
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div class="row-actions">
        <label>
          <span class="muted">{{ strings.orders.refundStatusLabel }}</span>
          <select
            v-model="filters.refundStatus"
            name="order-refund-status-filter"
            data-testid="order-refund-status-filter"
            @change="load"
          >
            <option v-for="option in refundStatusOptions" :key="option.value || 'all'" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>
      <button type="button" @click="load">{{ strings.common.refresh }}</button>
    </div>
    <p class="muted">{{ strings.orders.summary }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.orders.headers.orderNo }}</th>
            <th>{{ strings.orders.headers.shop }}</th>
            <th>{{ strings.orders.headers.amount }}</th>
            <th>{{ strings.orders.headers.payment }}</th>
            <th>{{ strings.orders.headers.refund }}</th>
            <th>{{ strings.orders.headers.audit }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.orderNo }}</td>
            <td>{{ item.shopName }}</td>
            <td>{{ item.amount }} {{ item.currency }}</td>
            <td>{{ item.payStatusText }}</td>
            <td>
              {{ item.refund?.statusText ?? strings.orders.noRefund }}
              <p v-if="item.refund?.channelRefundTxn" class="code-box">
                {{ item.refund.channel || '-' }} / {{ item.refund.channelRefundTxn }}
              </p>
              <p v-if="item.refund?.channelFailureReason" class="error">
                {{ item.refund.channelFailureReason }}
              </p>
            </td>
            <td>
              <div v-if="canAuditRefund && item.refund?.status === 0" class="refund-audit" :data-testid="`refund-actions-${item.id}`">
                <input
                  v-model="refundReasons[item.id]"
                  :name="`refund-reason-${item.id}`"
                  maxlength="255"
                  :placeholder="strings.orders.auditPlaceholder"
                />
                <div class="row-actions">
                  <button
                    type="button"
                    :data-testid="`approve-refund-${item.id}`"
                    :disabled="auditingId === item.id"
                    @click="audit(item, 'approve')"
                  >{{ strings.orders.approve }}</button>
                  <button
                    type="button"
                    class="danger-action"
                    :data-testid="`reject-refund-${item.id}`"
                    :disabled="auditingId === item.id"
                    @click="audit(item, 'reject')"
                  >{{ strings.orders.reject }}</button>
                </div>
              </div>
              <span v-else class="muted">{{ strings.orders.noAction }}</span>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="6" class="feedback">{{ strings.orders.empty }}</td></tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
