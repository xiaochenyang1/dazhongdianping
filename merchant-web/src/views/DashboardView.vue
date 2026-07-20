<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchAccount, fetchDashboard, type MerchantAccount } from '@/services/merchant'
const loading = ref(true); const error = ref(''); const account = ref<MerchantAccount | null>(null); const dashboard = ref<Record<string, unknown>>({})
onMounted(async () => { try { [account.value, dashboard.value] = await Promise.all([fetchAccount(), fetchDashboard()]) } catch (e) { error.value = e instanceof Error ? e.message : '加载失败' } finally { loading.value = false } })
function number(key: string) { const value = dashboard.value[key]; return typeof value === 'number' ? value : 0 }
</script>
<template><div class="toolbar"><span class="muted">{{ account?.merchant.companyName ?? '商户' }}<template v-if="account?.operator.name"> · {{ account.operator.name }}</template></span></div><p v-if="loading" class="muted">加载中...</p><p v-if="error" class="error">{{ error }}</p><div v-if="!loading" class="grid"><div class="card"><p class="muted">浏览量</p><div class="stat">{{ number('viewCount') }}</div></div><div class="card"><p class="muted">支付订单</p><div class="stat">{{ number('paidOrderCount') }}</div></div><div class="card"><p class="muted">核销券</p><div class="stat">{{ number('verifiedCouponCount') }}</div></div><div class="card"><p class="muted">点评数</p><div class="stat">{{ number('reviewCount') }}</div></div></div></template>
