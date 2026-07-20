<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { auditMerchantApplication, listMerchantApplications } from '@/services/admin'
import type { AdminMerchantApplication, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminMerchantApplication> | null>(null)
const selectedMerchantId = ref<number | null>(null)
const rejectMode = ref(false)
const rejectReason = ref('')
const filters = reactive({ status: '0', page: 1, pageSize: 20 })

const selected = computed(() => pageState.value?.list.find((item) => item.merchantId === selectedMerchantId.value) ?? null)

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listMerchantApplications({
      status: filters.status === '' ? undefined : Number(filters.status),
      page: filters.page,
      pageSize: filters.pageSize,
    })
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '商户资质申请加载失败'
  } finally {
    loading.value = false
  }
}

async function decide(application: AdminMerchantApplication, status: 1 | 2) {
  const reason = rejectReason.value.trim()
  if (status === 2 && !reason) {
    errorMessage.value = '驳回原因不能为空'
    return
  }
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await auditMerchantApplication(application.merchantId, { status, reason: status === 2 ? reason : '' })
    successMessage.value = `${application.companyName} 已${status === 1 ? '通过' : '驳回'}。`
    selectedMerchantId.value = null
    rejectMode.value = false
    rejectReason.value = ''
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '资质审核失败'
  } finally {
    acting.value = false
  }
}

function openReject(application: AdminMerchantApplication) {
  selectedMerchantId.value = application.merchantId
  rejectMode.value = true
  rejectReason.value = ''
  errorMessage.value = ''
}

watch(() => state.region, () => { filters.page = 1; void load() }, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div><p class="eyebrow">商户准入</p><h1>先看清资质，再放行经营权限。</h1><p>当前区域 {{ state.region }}。审核动作会同步商户状态并记录审计日志。</p></div>
      <button class="secondary-button" type="button" @click="load">刷新申请</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline"><div><p class="eyebrow">申请列表</p><h2>材料、主体和区域放在一张桌上看。</h2></div><span class="inline-note">共 {{ pageState?.total ?? 0 }} 条</span></div>
      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field"><span>状态</span><select v-model="filters.status"><option value="">全部</option><option value="0">待审核</option><option value="1">已通过</option><option value="2">已驳回</option></select></label>
        <div class="toolbar-actions"><button class="primary-button" type="button" @click="filters.page = 1; load()">应用筛选</button></div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead><tr><th>商户主体</th><th>法人/执照</th><th>门店照片</th><th>状态</th><th>操作</th></tr></thead>
          <tbody>
            <tr v-if="loading"><td colspan="5" class="table-empty">申请加载中...</td></tr>
            <tr v-else-if="!pageState?.list.length"><td colspan="5" class="table-empty">当前没有资质申请。</td></tr>
            <tr v-for="application in pageState?.list" :key="application.merchantId">
              <td><strong>{{ application.companyName }}</strong><p>{{ application.merchantAccount }} · {{ application.region }}</p></td>
              <td><strong>{{ application.legalPerson }}</strong><p><a :href="application.licenseUrl" target="_blank" rel="noreferrer">查看营业执照</a></p></td>
              <td><div class="application-photos"><a v-for="photo in application.shopPhotoUrls" :key="photo" :href="photo" target="_blank" rel="noreferrer"><img :src="photo" alt="门店资质照片" /></a></div></td>
              <td><span class="status-pill" :class="application.status === 0 ? 'status-pill--warn' : application.status === 1 ? 'status-pill--good' : 'status-pill--muted'">{{ application.statusText }}</span><p v-if="application.rejectReason">{{ application.rejectReason }}</p></td>
              <td><div v-if="application.status === 0" class="table-actions"><button class="table-action" type="button" :disabled="acting" @click="decide(application, 1)">通过申请</button><button class="table-action table-action--danger" type="button" :disabled="acting" @click="openReject(application)">驳回申请</button></div><span v-else class="inline-note">已处理</span></td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager"><button class="ghost-button" type="button" :disabled="filters.page <= 1" @click="filters.page--; load()">上一页</button><span>第 {{ filters.page }} 页</span><button class="ghost-button" type="button" :disabled="!pageState?.hasMore" @click="filters.page++; load()">下一页</button></div>
    </section>

    <div v-if="rejectMode && selected" class="audit-drawer">
      <div><p class="eyebrow">驳回申请</p><h2>{{ selected.companyName }}</h2><p>原因会原样返回商户端，写人话，别写“资料不符”四个字就跑路。</p></div>
      <label class="field field--full"><span>驳回原因</span><textarea v-model="rejectReason" name="rejectReason" rows="4" /></label>
      <div class="form-actions"><button class="ghost-button" type="button" @click="rejectMode = false">取消</button><button class="secondary-button" type="button" :disabled="acting" @click="decide(selected, 2)">确认驳回</button></div>
    </div>
  </section>
</template>
