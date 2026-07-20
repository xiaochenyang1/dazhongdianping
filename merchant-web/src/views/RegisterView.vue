<script setup lang="ts">
import { reactive, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { registerMerchant } from '@/services/merchant'
import { useMerchantSession, type MerchantRegion } from '@/composables/useMerchantSession'

const router = useRouter()
const { setSession } = useMerchantSession()
const loading = ref(false)
const error = ref('')
const form = reactive({
  account: '',
  password: '',
  companyName: '',
  contactName: '',
  contactPhone: '',
  region: 'EU' as MerchantRegion,
})

async function submit() {
  loading.value = true
  error.value = ''
  try {
    const result = await registerMerchant({ ...form })
    setSession({ ...result, region: form.region })
    await router.replace('/settlement')
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '注册失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="auth-page identity-auth-page">
    <section class="identity-intro">
      <p class="eyebrow">Merchant onboarding</p>
      <h1>把店开起来，别先被表格劝退。</h1>
      <p>注册主账号后直接提交经营资质。审核通过前不会开放经营数据，流程清楚，权限也不串门。</p>
      <ol>
        <li><strong>01</strong><span>创建商户主体</span></li>
        <li><strong>02</strong><span>提交执照与门店照片</span></li>
        <li><strong>03</strong><span>审核通过后配置员工</span></li>
      </ol>
    </section>

    <form class="card auth-card identity-form" @submit.prevent="submit">
      <div>
        <p class="eyebrow">商户入驻</p>
        <h2>创建主账号</h2>
        <p class="muted">这个账号拥有员工和门店权限管理能力，请使用长期可控的邮箱或手机号。</p>
      </div>

      <label>经营区域
        <select v-model="form.region" name="region">
          <option value="EU">欧洲区 EU</option>
          <option value="CN">国内区 CN</option>
        </select>
      </label>
      <label>登录账号<input v-model.trim="form.account" name="account" required autocomplete="username" /></label>
      <label>登录密码<input v-model="form.password" name="password" required minlength="8" type="password" autocomplete="new-password" /></label>
      <label>企业或个体名称<input v-model.trim="form.companyName" name="companyName" required /></label>
      <div class="form-grid">
        <label>联系人<input v-model.trim="form.contactName" name="contactName" required autocomplete="name" /></label>
        <label>联系电话<input v-model.trim="form.contactPhone" name="contactPhone" required autocomplete="tel" /></label>
      </div>

      <p v-if="error" class="error" role="alert">{{ error }}</p>
      <button class="primary-action" :disabled="loading">{{ loading ? '正在创建...' : '创建账号并提交资质' }}</button>
      <p class="auth-switch">已经有账号？<RouterLink to="/login">返回登录</RouterLink></p>
    </form>
  </main>
</template>
