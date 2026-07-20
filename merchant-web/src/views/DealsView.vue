<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchDeals, updateDealStatus } from '@/services/merchant'
const loading = ref(true); const error = ref(''); const items = ref<Record<string, unknown>[]>([])
async function load() { loading.value = true; try { items.value = (await fetchDeals({ page: 1, pageSize: 50 })).list } catch (e) { error.value = e instanceof Error ? e.message : '加载失败' } finally { loading.value = false } }
async function toggle(item: Record<string, unknown>) { try { await updateDealStatus(Number(item.id), Number(item.status) === 1 ? 0 : 1); await load() } catch (e) { error.value = e instanceof Error ? e.message : '操作失败' } }
onMounted(load)
</script>
<template><div class="toolbar"><button @click="load">刷新</button></div><p v-if="loading" class="muted">加载中...</p><p v-if="error" class="error">{{ error }}</p><table v-if="!loading" class="table"><thead><tr><th>套餐</th><th>门店</th><th>价格</th><th>审核</th><th>上下架</th></tr></thead><tbody><tr v-for="item in items" :key="String(item.id)"><td>{{ item.title ?? item.name }}</td><td>{{ item.shopName }}</td><td>{{ item.price ?? '-' }}</td><td>{{ item.auditStatusText ?? item.auditStatus }}</td><td><button @click="toggle(item)">{{ Number(item.status) === 1 ? '下架' : '上架' }}</button></td></tr></tbody></table></template>
