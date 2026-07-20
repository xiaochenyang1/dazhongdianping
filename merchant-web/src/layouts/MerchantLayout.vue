<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { useMerchantSession, type MerchantRegion } from '@/composables/useMerchantSession'
import { fetchAccount } from '@/services/merchant'

const route = useRoute(); const router = useRouter(); const { state, clearSession, setRegion } = useMerchantSession()
const title = computed(() => String(route.meta.title ?? '商户工作台'))
const permissions = ref<string[]>([])
const baseLinks = [{ path: '/dashboard', label: '经营概览' }, { path: '/shops', label: '门店管理' }, { path: '/reservations', label: '预订处理' }, { path: '/deals', label: '团购管理' }, { path: '/orders', label: '订单退款' }, { path: '/reviews', label: '点评经营' }]
const links = computed(() => permissions.value.includes('staff:manage') ? [...baseLinks, { path: '/staffs', label: '员工管理' }] : baseLinks)
function logout() { clearSession(); void router.replace('/login') }
onMounted(async () => { try { permissions.value = (await fetchAccount()).permissions } catch { permissions.value = [] } })
</script>
<template>
  <div class="shell"><aside class="sidebar"><p class="eyebrow">商户工作台</p><h1>大众点评</h1><nav><RouterLink v-for="link in links" :key="link.path" :to="link.path" :class="{active: route.path === link.path}">{{ link.label }}</RouterLink></nav></aside><section class="main"><header><div><p class="eyebrow">当前页面</p><h2>{{ title }}</h2></div><div class="actions"><select :value="state.region" @change="setRegion(($event.target as HTMLSelectElement).value as MerchantRegion)"><option value="CN">CN</option><option value="EU">EU</option></select><span>{{ state.account }}</span><button class="ghost" @click="logout">退出</button></div></header><main class="page"><RouterView /></main></section></div>
</template>
