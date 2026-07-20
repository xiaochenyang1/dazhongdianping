<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { createRankConfig, listRankConfigs, publishRankConfig, rollbackRankConfig } from '@/services/admin'
import type { RankConfig } from '@/types/admin'

const { state } = useAdminSession()
const configs = ref<RankConfig[]>([])
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const form = reactive({
  rankType: 1,
  cityId: state.region === 'EU' ? 101 : 1,
  categoryId: state.region === 'EU' ? 201 : 102,
  calcCycle: 4,
  scoreWeight: 0.7,
  reviewWeight: 0.2,
  dealWeight: 0.1,
  minReviewCount: 1,
  minScore: 4,
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try { configs.value = await listRankConfigs() }
  catch (error) { errorMessage.value = error instanceof Error ? error.message : '榜单规则加载失败' }
  finally { loading.value = false }
}

async function createDraft() {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const total = form.scoreWeight + form.reviewWeight + form.dealWeight
    if (Math.abs(total - 1) > 0.000001) throw new Error('三个权重之和必须等于 1。')
    await createRankConfig({
      rankType: form.rankType, region: state.region, cityId: form.cityId, categoryId: form.categoryId,
      calcCycle: form.calcCycle,
      weight: { score: form.scoreWeight, reviewCount: form.reviewWeight, hasDeal: form.dealWeight },
      minReviewCount: form.minReviewCount, minScore: form.minScore, manualIntervene: true,
    })
    successMessage.value = '新规则草稿已创建，未发布前不会影响线上榜单。'
    await load()
  } catch (error) { errorMessage.value = error instanceof Error ? error.message : '规则创建失败' }
  finally { saving.value = false }
}

async function publish(configId: number) {
  try {
    const result = await publishRankConfig(configId)
    successMessage.value = `发布成功：榜单 #${result.rankId}，共 ${result.itemCount} 家门店。`
    await load()
  } catch (error) { errorMessage.value = error instanceof Error ? error.message : '发布失败' }
}

async function rollback(configId: number) {
  try {
    const result = await rollbackRankConfig(configId)
    successMessage.value = `已按历史规则生成新版本并发布，榜单 #${result.rankId}。`
    await load()
  } catch (error) { errorMessage.value = error instanceof Error ? error.message : '回滚失败' }
}

watch(() => state.region, () => {
  form.cityId = state.region === 'EU' ? 101 : 1
  form.categoryId = state.region === 'EU' ? 201 : 102
  void load()
}, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header"><div><p class="eyebrow">榜单运营</p><h1>规则先存草稿，发布成功后再切榜单快照。</h1><p>重算翻车会保留旧榜单，不能让运营手一抖前台就黑屏。</p></div></div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline"><div><p class="eyebrow">规则版本</p><h2>区域 {{ state.region }} 的历史版本</h2></div></div>
        <p v-if="loading" class="feedback">加载中...</p>
        <div v-else class="table-shell"><table class="data-table"><thead><tr><th>类型</th><th>作用域</th><th>版本</th><th>状态</th><th>操作</th></tr></thead><tbody>
          <tr v-for="config in configs" :key="config.id"><td>{{ config.rankTypeText }}</td><td>城市 {{ config.cityId }} / 分类 {{ config.categoryId }}</td><td>v{{ config.version }}</td><td><span class="status-pill">{{ config.statusText }}</span></td><td class="table-actions"><button v-if="config.status === 0" class="table-action" @click="publish(config.id)">发布</button><button v-else class="table-action" @click="rollback(config.id)">回滚到此规则</button></td></tr>
        </tbody></table></div>
      </section>
      <section class="content-card editor-card">
        <div class="section-headline"><div><p class="eyebrow">新草稿</p><h2>创建下一版本</h2></div></div>
        <form class="editor-form" @submit.prevent="createDraft"><div class="form-grid form-grid--two">
          <label class="field"><span>榜单类型</span><select v-model.number="form.rankType"><option :value="1">必吃榜</option><option :value="2">好评榜</option><option :value="3">热门榜</option></select></label>
          <label class="field"><span>计算周期</span><select v-model.number="form.calcCycle"><option :value="1">日</option><option :value="2">周</option><option :value="3">月</option><option :value="4">季</option></select></label>
          <label class="field"><span>城市 ID</span><input v-model.number="form.cityId" type="number" min="1" /></label>
          <label class="field"><span>分类 ID</span><input v-model.number="form.categoryId" type="number" min="1" /></label>
          <label class="field"><span>评分权重</span><input v-model.number="form.scoreWeight" type="number" min="0" max="1" step="0.05" /></label>
          <label class="field"><span>点评量权重</span><input v-model.number="form.reviewWeight" type="number" min="0" max="1" step="0.05" /></label>
          <label class="field"><span>优惠权重</span><input v-model.number="form.dealWeight" type="number" min="0" max="1" step="0.05" /></label>
          <label class="field"><span>最低评分</span><input v-model.number="form.minScore" type="number" min="0" max="5" step="0.1" /></label>
          <label class="field"><span>最低点评量</span><input v-model.number="form.minReviewCount" type="number" min="0" /></label>
        </div><div class="form-actions"><button class="primary-button" type="submit" :disabled="saving">{{ saving ? '创建中...' : '保存草稿' }}</button></div></form>
      </section>
    </div>
  </section>
</template>
