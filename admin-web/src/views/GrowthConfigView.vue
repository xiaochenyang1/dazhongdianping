<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { createGrowthRule, fetchGrowthConfig, updateGrowthRule, updateLevelConfig } from '@/services/admin'
import type { GrowthRule, LevelConfig } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:growth:write'))
const rules = ref<GrowthRule[]>([])
const levels = ref<LevelConfig[]>([])
const errorMessage = ref('')
const successMessage = ref('')
const creating = ref(false)

const newRule = reactive({
  action: '',
  actionName: '',
  growthValue: 0,
  points: 0,
  dailyLimit: 0,
  enabled: true,
})

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function growthActionText(rule: GrowthRule) {
  return strings.value.growthConfigs.actionText(rule.action, rule.actionName)
}

async function load() {
  errorMessage.value = ''
  try {
    const data = await fetchGrowthConfig()
    rules.value = data.rules
    levels.value = data.levels
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.growthConfigs.loadError)
  }
}

async function saveRule(rule: GrowthRule) {
  if (!canWrite.value) return
  try {
    await updateGrowthRule(rule.id, {
      action: rule.action,
      actionName: rule.actionName,
      growthValue: rule.growthValue,
      points: rule.points,
      dailyLimit: rule.dailyLimit,
      enabled: rule.enabled,
    })
    successMessage.value = strings.value.growthConfigs.ruleUpdated(growthActionText(rule))
    await load()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.growthConfigs.ruleUpdateError)
  }
}

async function createRule() {
  if (!canWrite.value || creating.value) return
  errorMessage.value = ''
  successMessage.value = ''
  const action = newRule.action.trim()
  const actionName = newRule.actionName.trim()
  if (!action || !actionName) {
    errorMessage.value = strings.value.growthConfigs.ruleActionRequired
    return
  }
  creating.value = true
  try {
    await createGrowthRule({
      action,
      actionName,
      growthValue: newRule.growthValue,
      points: newRule.points,
      dailyLimit: newRule.dailyLimit,
      enabled: newRule.enabled,
    })
    successMessage.value = strings.value.growthConfigs.ruleCreated(action)
    newRule.action = ''
    newRule.actionName = ''
    newRule.growthValue = 0
    newRule.points = 0
    newRule.dailyLimit = 0
    newRule.enabled = true
    await load()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.growthConfigs.ruleCreateError)
  } finally {
    creating.value = false
  }
}

async function saveLevel(level: LevelConfig) {
  if (!canWrite.value) return
  try {
    await updateLevelConfig(level.level, {
      minGrowth: level.minGrowth,
      levelName: level.levelName,
      icon: level.icon,
      privilegeJson: level.privilegeJson,
      enabled: level.enabled,
    })
    successMessage.value = strings.value.growthConfigs.levelUpdated(level.level)
    await load()
  } catch (cause) {
    errorMessage.value = messageOf(cause, strings.value.growthConfigs.levelUpdateError)
  }
}

watch(() => state.region, () => { void load() }, { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.growthConfigs.eyebrow }}</p>
        <h1>{{ strings.growthConfigs.heading }}</h1>
        <p>{{ strings.growthConfigs.description }}</p>
      </div>
    </div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div><p class="eyebrow">{{ strings.growthConfigs.rulesEyebrow }}</p><h2>{{ strings.growthConfigs.rulesHeading }}</h2></div>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead><tr><th>{{ strings.growthConfigs.ruleHeaders.action }}</th><th>{{ strings.growthConfigs.ruleHeaders.growthValue }}</th><th>{{ strings.growthConfigs.ruleHeaders.points }}</th><th>{{ strings.growthConfigs.ruleHeaders.dailyLimit }}</th><th>{{ strings.growthConfigs.ruleHeaders.enabled }}</th><th v-if="canWrite">{{ strings.growthConfigs.ruleHeaders.actions }}</th></tr></thead>
          <tbody>
            <tr v-for="rule in rules" :key="rule.id">
              <td><strong>{{ growthActionText(rule) }}</strong><p>{{ rule.action }}</p></td>
              <td><input v-model.number="rule.growthValue" :name="`rule-growth-value-${rule.id}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model.number="rule.points" :name="`rule-points-${rule.id}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model.number="rule.dailyLimit" :name="`rule-daily-limit-${rule.id}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model="rule.enabled" :name="`rule-enabled-${rule.id}`" type="checkbox" :disabled="!canWrite"></td>
              <td v-if="canWrite"><button class="table-action" type="button" :data-testid="`save-growth-rule-${rule.id}`" @click="saveRule(rule)">{{ strings.growthConfigs.save }}</button></td>
            </tr>
          </tbody>
        </table>
      </div>
      <form v-if="canWrite" class="editor-form" data-testid="growth-rule-create-form" @submit.prevent="createRule">
        <div class="section-headline">
          <div><p class="eyebrow">{{ strings.growthConfigs.createEyebrow }}</p><h3>{{ strings.growthConfigs.createHeading }}</h3></div>
        </div>
        <div class="form-grid form-grid--two">
          <label class="field"><span>{{ strings.growthConfigs.newRuleLabels.action }}</span><input v-model="newRule.action" name="new-rule-action" type="text" :placeholder="strings.growthConfigs.actionPlaceholder"></label>
          <label class="field"><span>{{ strings.growthConfigs.newRuleLabels.actionName }}</span><input v-model="newRule.actionName" name="new-rule-action-name" type="text"></label>
          <label class="field"><span>{{ strings.growthConfigs.newRuleLabels.growthValue }}</span><input v-model.number="newRule.growthValue" name="new-rule-growth-value" type="number" min="0"></label>
          <label class="field"><span>{{ strings.growthConfigs.newRuleLabels.points }}</span><input v-model.number="newRule.points" name="new-rule-points" type="number" min="0"></label>
          <label class="field"><span>{{ strings.growthConfigs.newRuleLabels.dailyLimit }}</span><input v-model.number="newRule.dailyLimit" name="new-rule-daily-limit" type="number" min="0"></label>
          <label class="toggle-card"><input v-model="newRule.enabled" name="new-rule-enabled" type="checkbox"><span>{{ strings.growthConfigs.newRuleLabels.enabled }}</span></label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="creating">{{ creating ? strings.growthConfigs.creating : strings.growthConfigs.createRule }}</button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div><p class="eyebrow">{{ strings.growthConfigs.levelsEyebrow }}</p><h2>{{ strings.growthConfigs.levelsHeading }}</h2></div>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead><tr><th>{{ strings.growthConfigs.levelHeaders.level }}</th><th>{{ strings.growthConfigs.levelHeaders.name }}</th><th>{{ strings.growthConfigs.levelHeaders.minGrowth }}</th><th>{{ strings.growthConfigs.levelHeaders.enabled }}</th><th v-if="canWrite">{{ strings.growthConfigs.levelHeaders.actions }}</th></tr></thead>
          <tbody>
            <tr v-for="level in levels" :key="level.level">
              <td>{{ strings.growthConfigs.levelLabel(level.level) }}</td>
              <td><input v-model="level.levelName" :name="`level-name-${level.level}`" type="text" :disabled="!canWrite"></td>
              <td><input v-model.number="level.minGrowth" :name="`level-min-growth-${level.level}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model="level.enabled" :name="`level-enabled-${level.level}`" type="checkbox" :disabled="!canWrite"></td>
              <td v-if="canWrite"><button class="table-action" type="button" :data-testid="`save-growth-level-${level.level}`" @click="saveLevel(level)">{{ strings.growthConfigs.save }}</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </section>
</template>
