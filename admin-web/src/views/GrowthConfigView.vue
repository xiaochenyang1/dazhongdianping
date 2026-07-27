<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { fetchGrowthConfig, updateGrowthRule, updateLevelConfig } from '@/services/admin'
import type { GrowthRule, LevelConfig } from '@/types/admin'

const { state } = useAdminSession()
const canWrite = computed(() => state.permissions.includes('operations:growth:write'))
const rules = ref<GrowthRule[]>([])
const levels = ref<LevelConfig[]>([])
const errorMessage = ref('')
const successMessage = ref('')

async function load() {
  try {
    const data = await fetchGrowthConfig()
    rules.value = data.rules
    levels.value = data.levels
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '配置加载失败'
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
    successMessage.value = `${rule.actionName} 已更新`
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '规则更新失败'
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
    successMessage.value = `Lv${level.level} 已更新`
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '等级更新失败'
  }
}

onMounted(load)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">成长体系</p>
        <h1>奖励权重和等级门槛都从数据库读取。</h1>
        <p>改完只影响之后的行为，历史流水不回写，账不能越改越玄学。</p>
      </div>
    </div>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div><p class="eyebrow">行为奖励</p><h2>成长值 / 积分 / 每日上限</h2></div>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead><tr><th>行为</th><th>成长值</th><th>积分</th><th>每日上限</th><th>启用</th><th v-if="canWrite">操作</th></tr></thead>
          <tbody>
            <tr v-for="rule in rules" :key="rule.id">
              <td><strong>{{ rule.actionName }}</strong><p>{{ rule.action }}</p></td>
              <td><input v-model.number="rule.growthValue" :name="`rule-growth-value-${rule.id}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model.number="rule.points" :name="`rule-points-${rule.id}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model.number="rule.dailyLimit" :name="`rule-daily-limit-${rule.id}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model="rule.enabled" :name="`rule-enabled-${rule.id}`" type="checkbox" :disabled="!canWrite"></td>
              <td v-if="canWrite"><button class="table-action" type="button" :data-testid="`save-growth-rule-${rule.id}`" @click="saveRule(rule)">保存</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div><p class="eyebrow">等级阈值</p><h2>Lv1-Lv8 配置</h2></div>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead><tr><th>等级</th><th>名称</th><th>最低成长值</th><th>启用</th><th v-if="canWrite">操作</th></tr></thead>
          <tbody>
            <tr v-for="level in levels" :key="level.level">
              <td>Lv{{ level.level }}</td>
              <td><input v-model="level.levelName" :name="`level-name-${level.level}`" type="text" :disabled="!canWrite"></td>
              <td><input v-model.number="level.minGrowth" :name="`level-min-growth-${level.level}`" type="number" min="0" :disabled="!canWrite"></td>
              <td><input v-model="level.enabled" :name="`level-enabled-${level.level}`" type="checkbox" :disabled="!canWrite"></td>
              <td v-if="canWrite"><button class="table-action" type="button" :data-testid="`save-growth-level-${level.level}`" @click="saveLevel(level)">保存</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </section>
</template>
