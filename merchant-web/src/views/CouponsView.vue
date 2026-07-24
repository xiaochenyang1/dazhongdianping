<script setup lang="ts">
import { computed, ref } from 'vue'
import { verifyCoupon, type MerchantCoupon } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const code = ref('')
const loading = ref(false)
const error = ref('')
const notice = ref('')
const result = ref<MerchantCoupon | null>(null)
const history = ref<MerchantCoupon[]>([])
const canVerify = computed(() => props.permissions.includes('coupon:verify'))

async function submit() {
  if (!canVerify.value) {
    error.value = '当前账号没有券码核销权限'
    return
  }
  const normalized = code.value.trim()
  if (!normalized) {
    error.value = '请输入券码'
    return
  }
  loading.value = true
  error.value = ''
  notice.value = ''
  try {
    const coupon = await verifyCoupon(normalized)
    result.value = coupon
    history.value = [coupon, ...history.value.filter((item) => item.code !== coupon.code)].slice(0, 8)
    notice.value = `券码 ${coupon.code} 已核销成功`
    code.value = ''
  } catch (cause) {
    result.value = null
    error.value = cause instanceof Error ? cause.message : '券码核销失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">Coupon verify</p>
        <strong>到店券码核销</strong>
        <p class="muted">录入顾客出示的券码；成功后券状态变为已使用，重复核销会被拒绝。</p>
      </div>
    </div>

    <p v-if="!canVerify" class="error" role="alert">当前账号缺少 `coupon:verify` 权限，不能核销券码。</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text">{{ notice }}</p>

    <article class="card verify-card">
      <form class="verify-form" @submit.prevent="submit">
        <label>
          <span>券码</span>
          <input
            v-model="code"
            name="coupon-code"
            data-testid="coupon-code-input"
            maxlength="64"
            autocomplete="off"
            placeholder="例如 VERIFYME001"
            :disabled="!canVerify || loading"
          />
        </label>
        <button
          type="submit"
          class="primary-action"
          data-testid="coupon-verify-submit"
          :disabled="!canVerify || loading"
        >
          {{ loading ? '核销中...' : '确认核销' }}
        </button>
      </form>
    </article>

    <article v-if="result" class="card result-card" data-testid="coupon-verify-result">
      <p class="eyebrow">最近一次核销</p>
      <h3>{{ result.dealTitle || `deal:${result.dealId}` }}</h3>
      <p><strong>券码：</strong>{{ result.code }}</p>
      <p><strong>门店：</strong>{{ result.shopName || `shop:${result.shopId}` }}</p>
      <p><strong>状态：</strong>{{ result.statusText || (result.status === 2 ? '已使用' : `状态 ${result.status}`) }}</p>
      <p v-if="result.verifyAt"><strong>核销时间：</strong>{{ result.verifyAt }}</p>
      <p v-if="result.expireAt"><strong>有效期至：</strong>{{ result.expireAt }}</p>
    </article>

    <article v-if="history.length" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>券码</th>
            <th>团购</th>
            <th>门店</th>
            <th>状态</th>
            <th>核销时间</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in history" :key="`${item.id}-${item.code}`">
            <td>{{ item.code }}</td>
            <td>{{ item.dealTitle || `deal:${item.dealId}` }}</td>
            <td>{{ item.shopName || `shop:${item.shopId}` }}</td>
            <td>{{ item.statusText || (item.status === 2 ? '已使用' : item.status) }}</td>
            <td>{{ item.verifyAt || '--' }}</td>
          </tr>
        </tbody>
      </table>
    </article>
  </section>
</template>
