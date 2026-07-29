<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { fetchGrowthConfig, updateGrowthRule, updateLevelConfig } from '@/services/admin'
import type { GrowthRule, LevelConfig } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:growth:write'))
const rules = ref<GrowthRule[]>([])
const levels = ref<LevelConfig[]>([])
const errorMessage = ref('')
const successMessage = ref('')

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
