<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import {
  applyVerifiedCertification,
  fetchVerifiedCertification,
  type MerchantVerifiedCertificationStatus,
} from '@/services/merchant'

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const status = ref<MerchantVerifiedCertificationStatus | null>(null)
const form = reactive({ reason: '', evidenceLines: '' })

const canApply = computed(() => {
  if (!status.value) return false
  return status.value.status === 0 || status.value.status === 3
})

function fillForm(next: MerchantVerifiedCertificationStatus) {
  form.reason = next.reason || ''
  form.evidenceLines = (next.evidenceUrls || []).join('\n')
}

async function load() {
  loading.value = true
  error.value = ''
  success.value = ''
  try {
    status.value = await fetchVerifiedCertification()
    fillForm(status.value)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '认证商户状态加载失败'
  } finally {
    loading.value = false
  }
}

async function submit() {
  const reason = form.reason.trim()
  if (!reason) {
    error.value = '请填写认证申请理由'
    return
  }
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    status.value = await applyVerifiedCertification({
      reason,
      evidenceUrls: form.evidenceLines
        .split(/\r?\n/)
        .map((item) => item.trim())
        .filter(Boolean),
    })
    fillForm(status.value)
    success.value = '认证商户申请已提交，等待管理端审核。'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '认证商户申请提交失败'
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">Verified merchant</p>
        <h1>认证商户</h1>
        <p>资质审核通过后，可额外申请公开“认证商户”标识。待审或已通过时不可重复提交，驳回后可重提。</p>
      </div>
      <span v-if="status" class="status-pill" :class="`status-${status.status}`">{{ status.statusText }}</span>
    </div>

    <p v-if="loading" class="feedback">认证状态加载中...</p>
    <p v-else-if="error" class="feedback is-error" role="alert">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <template v-if="status && !loading">
      <article v-if="status.status === 2 && status.badge" class="card status-card status-card--success">
        <p class="eyebrow">已认证</p>
        <h2>
          当前门店可展示
          <span class="verified-badge">{{ status.badge.label }}</span>
        </h2>
        <p>通过时间：{{ status.auditedAt || '—' }}。公开门店详情会同步挂标。</p>
      </article>

      <article v-else-if="status.status === 1" class="card status-card">
        <p class="eyebrow">审核中</p>
        <h2>认证申请已进入审核队列</h2>
        <p>提交时间：{{ status.submittedAt || '刚刚提交' }}。通过后会在门店详情公开挂标。</p>
        <p v-if="status.reason"><strong>申请理由：</strong>{{ status.reason }}</p>
      </article>

      <article v-else-if="status.status === 3" class="card status-card">
        <p class="eyebrow">已驳回</p>
        <h2>可修改材料后重新提交</h2>
        <p><strong>驳回原因：</strong>{{ status.rejectReason || '未填写' }}</p>
      </article>

      <article v-if="canApply" class="card">
        <h2>{{ status.status === 3 ? '重新提交认证申请' : '提交认证申请' }}</h2>
        <form class="settlement-form" @submit.prevent="submit">
          <label>
            <span>申请理由</span>
            <textarea v-model="form.reason" rows="4" maxlength="500" placeholder="说明经营合规、服务承诺或可核验材料" required />
          </label>
          <label>
            <span>证明材料链接（可选，每行一个）</span>
            <textarea v-model="form.evidenceLines" rows="4" placeholder="https://..." />
          </label>
          <button type="submit" class="primary-button" :disabled="saving">
            {{ saving ? '提交中...' : '提交认证申请' }}
          </button>
        </form>
      </article>
    </template>
  </section>
</template>
