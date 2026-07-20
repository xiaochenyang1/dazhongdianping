<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { auditRefund, fetchOrders } from '@/services/merchant'
const loading = ref(true); const error = ref(''); const items = ref<Record<string, unknown>[]>([])
async function load() { loading.value = true; try { items.value = (await fetchOrders({ page: 1, pageSize: 50 })).list } catch (e) { error.value = e instanceof Error ? e.message : '加载失败' } finally { loading.value = false } }
async function audit(id: number, approved: boolean) { try { await auditRefund(id, approved, approved ? undefined : '暂不符合退款条件'); await load() } catch (e) { error.value = e instanceof Error ? e.message : '操作失败' } }
onMounted(load)
</script>
<template><div class="toolbar"><button @click="load">刷新</button></div><p v-if="loading" class="muted">加载中...</p><p v-if="error" class="error">{{ error }}</p><table v-if="!loading" class="table"><thead><tr><th>订单号</th><th>门店</th><th>金额</th><th>支付</th><th>退款</th><th>操作</th></tr></thead><tbody><tr v-for="item in items" :key="String(item.id)"><td>{{ item.orderNo ?? item.id }}</td><td>{{ item.shopName }}</td><td>{{ item.payAmount ?? item.amount ?? '-' }}</td><td>{{ item.payStatusText ?? item.payStatus }}</td><td>{{ item.refundStatusText ?? item.refundStatus }}</td><td><button @click="audit(Number(item.id), true)">通过退款</button><button @click="audit(Number(item.id), false)">驳回</button></td></tr></tbody></table></template>
