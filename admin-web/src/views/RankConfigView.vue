<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { createRankConfig, listRankConfigs, publishRankConfig, rollbackRankConfig } from '@/services/admin'
import type { RankConfig } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const configs = ref<RankConfig[]>([])
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const canWrite = computed(() => state.permissions.includes('operations:rank:write'))

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

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function rankTypeText(config: RankConfig) {
  return strings.value.rankConfigs.rankTypeText(config.rankType, config.rankTypeText)
}

function rankStatusText(config: RankConfig) {
  return strings.value.rankConfigs.statusText(config.status, config.statusText)
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try { configs.value = await listRankConfigs() }
  catch (error) { errorMessage.value = messageOf(error, strings.value.rankConfigs.loadError) }
  finally { loading.value = false }
}

async function createDraft() {
  if (!canWrite.value || saving.value) return
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const total = form.scoreWeight + form.reviewWeight + form.dealWeight
    if (Math.abs(total - 1) > 0.000001) throw new Error(strings.value.rankConfigs.weightSumError)
    await createRankConfig({
      rankType: form.rankType, region: state.region, cityId: form.cityId, categoryId: form.categoryId,
      calcCycle: form.calcCycle,
      weight: { score: form.scoreWeight, reviewCount: form.reviewWeight, hasDeal: form.dealWeight },
      minReviewCount: form.minReviewCount, minScore: form.minScore, manualIntervene: true,
    })
    successMessage.value = strings.value.rankConfigs.createSuccess
    await load()
  } catch (error) { errorMessage.value = messageOf(error, strings.value.rankConfigs.createError) }
  finally { saving.value = false }
}

async function publish(configId: number) {
  if (!canWrite.value) return
  try {
    const result = await publishRankConfig(configId)
    successMessage.value = strings.value.rankConfigs.publishSuccess(result.rankId, result.itemCount)
    await load()
  } catch (error) { errorMessage.value = messageOf(error, strings.value.rankConfigs.publishError) }
}

async function rollback(configId: number) {
  if (!canWrite.value) return
  try {
    const result = await rollbackRankConfig(configId)
    successMessage.value = strings.value.rankConfigs.rollbackSuccess(result.rankId)
    await load()
  } catch (error) { errorMessage.value = messageOf(error, strings.value.rankConfigs.rollbackError) }
}

watch(() => state.region, () => {
  form.cityId = state.region === 'EU' ? 101 : 1
  form.categoryId = state.region === 'EU' ? 201 : 102
  void load()
}, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header"><div><p class="eyebrow">{{ strings.rankConfigs.eyebrow }}</p><h1>{{ strings.rankConfigs.heading }}</h1><p>{{ strings.rankConfigs.description }}</p></div></div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline"><div><p class="eyebrow">{{ strings.rankConfigs.historyEyebrow }}</p><h2>{{ strings.rankConfigs.historyHeading(state.region) }}</h2></div></div>
        <p v-if="loading" class="feedback">{{ strings.rankConfigs.loading }}</p>
        <div v-else class="table-shell"><table class="data-table"><thead><tr><th>{{ strings.rankConfigs.tableHeaders.type }}</th><th>{{ strings.rankConfigs.tableHeaders.scope }}</th><th>{{ strings.rankConfigs.tableHeaders.version }}</th><th>{{ strings.rankConfigs.tableHeaders.status }}</th><th v-if="canWrite">{{ strings.rankConfigs.tableHeaders.actions }}</th></tr></thead><tbody>
          <tr v-for="config in configs" :key="config.id"><td>{{ rankTypeText(config) }}</td><td>{{ strings.rankConfigs.scopeSummary(config.cityId, config.categoryId) }}</td><td>v{{ config.version }}</td><td><span class="status-pill">{{ rankStatusText(config) }}</span></td><td v-if="canWrite" class="table-actions"><button v-if="config.status === 0" type="button" class="table-action" :data-testid="`rank-publish-${config.id}`" @click="publish(config.id)">{{ strings.rankConfigs.publish }}</button><button v-else type="button" class="table-action" :data-testid="`rank-rollback-${config.id}`" @click="rollback(config.id)">{{ strings.rankConfigs.rollback }}</button></td></tr>
        </tbody></table></div>
      </section>
      <section class="content-card editor-card">
        <div class="section-headline"><div><p class="eyebrow">{{ strings.rankConfigs.editorEyebrow }}</p><h2>{{ strings.rankConfigs.editorHeading }}</h2></div></div>
        <form v-if="canWrite" class="editor-form" data-testid="rank-draft-form" @submit.prevent="createDraft"><div class="form-grid form-grid--two">
          <label class="field"><span>{{ strings.rankConfigs.labels.rankType }}</span><select v-model.number="form.rankType"><option :value="1">{{ strings.rankConfigs.rankTypeOptions.mustEat }}</option><option :value="2">{{ strings.rankConfigs.rankTypeOptions.review }}</option><option :value="3">{{ strings.rankConfigs.rankTypeOptions.hot }}</option></select></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.calcCycle }}</span><select v-model.number="form.calcCycle"><option :value="1">{{ strings.rankConfigs.calcCycleOptions.day }}</option><option :value="2">{{ strings.rankConfigs.calcCycleOptions.week }}</option><option :value="3">{{ strings.rankConfigs.calcCycleOptions.month }}</option><option :value="4">{{ strings.rankConfigs.calcCycleOptions.quarter }}</option></select></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.cityId }}</span><input v-model.number="form.cityId" type="number" min="1" /></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.categoryId }}</span><input v-model.number="form.categoryId" type="number" min="1" /></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.scoreWeight }}</span><input v-model.number="form.scoreWeight" type="number" min="0" max="1" step="0.05" /></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.reviewWeight }}</span><input v-model.number="form.reviewWeight" type="number" min="0" max="1" step="0.05" /></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.dealWeight }}</span><input v-model.number="form.dealWeight" type="number" min="0" max="1" step="0.05" /></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.minScore }}</span><input v-model.number="form.minScore" type="number" min="0" max="5" step="0.1" /></label>
          <label class="field"><span>{{ strings.rankConfigs.labels.minReviewCount }}</span><input v-model.number="form.minReviewCount" type="number" min="0" /></label>
        </div><div class="form-actions"><button class="primary-button" type="submit" :disabled="saving">{{ saving ? strings.rankConfigs.saving : strings.rankConfigs.saveDraft }}</button></div></form>
        <p v-else class="inline-note">{{ strings.rankConfigs.readOnly }}</p>
      </section>
    </div>
  </section>
</template>
