<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { confirmReservation, fetchReservations, rejectReservation } from '@/services/merchant'
const loading = ref(true); const error = ref(''); const items = ref<Record<string, unknown>[]>([])
async function load() { loading.value = true; try { items.value = (await fetchReservations({ page: 1, pageSize: 50 })).list } catch (e) { error.value = e instanceof Error ? e.message : '加载失败' } finally { loading.value = false } }
async function act(id: number, type: 'confirm' | 'reject') { try { if (type === 'confirm') await confirmReservation(id); else await rejectReservation(id, '商户暂时无法接待'); await load() } catch (e) { error.value = e instanceof Error ? e.message : '操作失败' } }
onMounted(load)
</script>
<template><div class="toolbar"><button @click="load">刷新</button></div><p v-if="loading" class="muted">加载中...</p><p v-if="error" class="error">{{ error }}</p><table v-if="!loading" class="table"><thead><tr><th>预订号</th><th>门店</th><th>时间</th><th>状态</th><th>操作</th></tr></thead><tbody><tr v-for="item in items" :key="String(item.id)"><td>{{ item.reservationNo ?? item.id }}</td><td>{{ item.shopName }}</td><td>{{ item.reservationDate }} {{ item.reservationTime }}</td><td>{{ item.statusText ?? item.status }}</td><td><button @click="act(Number(item.id), 'confirm')">确认</button><button @click="act(Number(item.id), 'reject')">拒绝</button></td></tr></tbody></table></template>
