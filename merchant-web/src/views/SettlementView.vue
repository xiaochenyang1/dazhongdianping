<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchSettlementStatus, submitSettlement, type SettlementStatus } from '@/services/merchant'

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const status = ref<SettlementStatus | null>(null)
const form = reactive({ licenseUrl: '', legalPerson: '', photoLines: '' })

const editable = computed(() => status.value?.status === -1 || status.value?.status === 2)

function fillForm(next: SettlementStatus) {
  form.licenseUrl = next.licenseUrl ?? ''
  form.legalPerson = next.legalPerson ?? ''
  form.photoLines = (next.shopPhotoUrls ?? []).join('\n')
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    status.value = await fetchSettlementStatus()
    fillForm(status.value)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '资质状态加载失败'
  } finally {
    loading.value = false
  }
}

async function submit() {
  saving.value = true
  error.value = ''
  const payload = {
    licenseUrl: form.licenseUrl.trim(),
    legalPerson: form.legalPerson.trim(),
    shopPhotoUrls: form.photoLines.split(/\r?\n/).map((item) => item.trim()).filter(Boolean),
  }
  try {
    const result = await submitSettlement(payload)
    status.value = {
      ...(status.value ?? { merchantId: 0 }),
      ...payload,
      ...result,
      statusText: result.statusText || '待审核',
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '资质提交失败'
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <main class="settlement-page">
    <section class="settlement-header">
      <div>
        <p class="eyebrow">Business verification</p>
        <h1>经营资质档案</h1>
        <p>审核通过前，公开业务数据不会被新账号修改。先把材料交齐，再进经营台狠狠干活。</p>
      </div>
      <span v-if="status" class="status-pill" :class="`status-${status.status}`">{{ status.statusText }}</span>
    </section>

    <p v-if="loading" class="card feedback">资质状态加载中...</p>
    <p v-else-if="error && !status" class="card error" role="alert">{{ error }}</p>

    <template v-else-if="status">
      <article v-if="status.status === 0" class="card status-card">
        <p class="eyebrow">审核中</p>
        <h2>资料已经进入审核队列</h2>
        <p>提交时间：{{ status.submittedAt || '刚刚提交' }}。审核完成后重新进入此页即可查看结果。</p>
      </article>

      <article v-else-if="status.status === 1" class="card status-card status-card--success">
        <p class="eyebrow">审核通过</p>
        <h2>经营工作台已经开放</h2>
        <p>现在可以维护门店、团购、预订、员工和点评经营。</p>
        <RouterLink class="primary-link" to="/dashboard">进入经营工作台</RouterLink>
      </article>

      <form v-if="editable" class="card settlement-form" @submit.prevent="submit">
        <div>
          <p class="eyebrow">{{ status.status === 2 ? '重新提交' : '首次提交' }}</p>
          <h2>{{ status.status === 2 ? '根据驳回意见更新材料' : '填写经营资质' }}</h2>
          <p v-if="status.status === 2" class="rejection-note"><strong>驳回原因：</strong>{{ status.rejectReason }}</p>
        </div>
        <label>营业执照图片 URL<input v-model.trim="form.licenseUrl" name="licenseUrl" required type="url" /></label>
        <label>法人或经营者姓名<input v-model.trim="form.legalPerson" name="legalPerson" required /></label>
        <label>门店照片 URL（每行一张，最多 12 张）<textarea v-model="form.photoLines" name="shopPhotoUrls" required rows="6" /></label>
        <p v-if="error" class="error" role="alert">{{ error }}</p>
        <button class="primary-action" :disabled="saving">{{ saving ? '提交中...' : '提交审核' }}</button>
      </form>
    </template>
  </main>
</template>
