<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { fetchSettlementStatus, loginMerchant } from '@/services/merchant'
import { useMerchantSession, type MerchantRegion } from '@/composables/useMerchantSession'

const route = useRoute(); const router = useRouter(); const { setSession, setRegion } = useMerchantSession()
const account = ref(''); const password = ref(''); const region = ref<MerchantRegion>('EU'); const error = ref(''); const loading = ref(false)
async function submit() {
  loading.value = true; error.value = ''
  try {
    setRegion(region.value)
    setSession(await loginMerchant({ account: account.value, password: password.value }))
    const settlement = await fetchSettlementStatus()
    await router.replace(settlement.status === 1 ? String(route.query.redirect || '/dashboard') : '/settlement')
  }
  catch (e) { error.value = e instanceof Error ? e.message : '登录失败' }
  finally { loading.value = false }
}
</script>
<template>
  <main class="auth-page"><form class="card auth-card" @submit.prevent="submit"><p class="eyebrow">商户工作台</p><h1>登录经营后台</h1><label>经营区域<select v-model="region" name="region"><option value="EU">欧洲区 EU</option><option value="CN">国内区 CN</option></select></label><label>账号<input v-model="account" required autocomplete="username" /></label><label>密码<input v-model="password" required type="password" autocomplete="current-password" /></label><p v-if="error" class="error">{{ error }}</p><button :disabled="loading">{{ loading ? '登录中...' : '登录' }}</button><p class="auth-switch">还没有商户账号？<RouterLink to="/register">开始入驻</RouterLink></p></form></main>
</template>
