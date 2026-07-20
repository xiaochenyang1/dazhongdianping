<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchShops } from '@/services/merchant'
const loading = ref(true); const error = ref(''); const items = ref<Record<string, unknown>[]>([])
async function load() { loading.value = true; try { items.value = (await fetchShops({ page: 1, pageSize: 50 })).list } catch (e) { error.value = e instanceof Error ? e.message : '加载失败' } finally { loading.value = false } }
onMounted(load)
</script>
<template><div class="toolbar"><button @click="load">刷新</button></div><p v-if="loading" class="muted">加载中...</p><p v-if="error" class="error">{{ error }}</p><table v-if="!loading" class="table"><thead><tr><th>门店</th><th>区域</th><th>城市</th><th>评分</th><th>状态</th></tr></thead><tbody><tr v-for="item in items" :key="String(item.id)"><td>{{ item.name }}</td><td>{{ item.region }}</td><td>{{ item.cityName }}</td><td>{{ item.score ?? '-' }}</td><td>{{ item.statusText ?? item.status }}</td></tr></tbody></table></template>
