<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createAdminExperiment,
  deleteAdminFlagScope,
  fetchAdminExperiments,
  fetchAdminFlagScopes,
  fetchAdminFlags,
  saveAdminFlag,
  saveAdminFlagScope,
  type OpsExperiment,
  type OpsFlag,
  type OpsFlagScope,
} from '@/services/ops'

const { state } = useAdminSession()
const flags = ref<OpsFlag[]>([])
const experiments = ref<OpsExperiment[]>([])
const flagScopes = ref<OpsFlagScope[]>([])
const selectedFlag = ref<OpsFlag | null>(null)
const errorMessage = ref('')
const flagForm = reactive({ id: undefined as number | undefined, flagKey: '', description: '', enabled: true, rolloutPercent: 100 })
const experimentForm = reactive({ name: '', flagKey: '', status: 1 })
const scopeForm = reactive({ scopeType: 'city' as 'city' | 'shop' | 'campaign', scopeId: 0, enabled: true, rolloutPercent: 100 })
const canWrite = () => state.permissions.includes('operations:experiment:write')

async function load() {
  errorMessage.value = ''
  try {
    flags.value = await fetchAdminFlags()
    experiments.value = await fetchAdminExperiments()
    if (selectedFlag.value) {
      const refreshed = flags.value.find((flag) => flag.id === selectedFlag.value?.id)
      selectedFlag.value = refreshed ?? null
      flagScopes.value = refreshed ? await fetchAdminFlagScopes(refreshed.id) : []
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

function editFlag(flag: OpsFlag) {
  flagForm.id = flag.id
  flagForm.flagKey = flag.flagKey
  flagForm.description = flag.description
  flagForm.enabled = flag.enabled
  flagForm.rolloutPercent = flag.rolloutPercent
}

async function manageScopes(flag: OpsFlag) {
  selectedFlag.value = flag
  flagScopes.value = await fetchAdminFlagScopes(flag.id)
}

async function saveFlag() {
  await saveAdminFlag({
    flagKey: flagForm.flagKey.trim(),
    description: flagForm.description.trim(),
    enabled: flagForm.enabled,
    rolloutPercent: Number(flagForm.rolloutPercent),
  }, flagForm.id)
  flagForm.id = undefined
  flagForm.flagKey = ''
  await load()
}

async function saveExperiment() {
  await createAdminExperiment({
    name: experimentForm.name.trim(),
    flagKey: experimentForm.flagKey.trim(),
    status: Number(experimentForm.status),
  })
  experimentForm.name = ''
  await load()
}

async function saveScope() {
  if (!selectedFlag.value) return
  await saveAdminFlagScope(selectedFlag.value.id, {
    scopeType: scopeForm.scopeType,
    scopeId: Number(scopeForm.scopeId),
    enabled: scopeForm.enabled,
    rolloutPercent: Number(scopeForm.rolloutPercent),
  })
  flagScopes.value = await fetchAdminFlagScopes(selectedFlag.value.id)
}

async function removeScope(scope: OpsFlagScope) {
  if (!selectedFlag.value) return
  await deleteAdminFlagScope(selectedFlag.value.id, scope.id)
  flagScopes.value = await fetchAdminFlagScopes(selectedFlag.value.id)
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>实验开关</h1>
      <p class="page-desc">开关支持总熔断、稳定用户比例以及活动 &gt; 门店 &gt; 城市三级灰度规则。实验分组按用户粘滞。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <table class="data-table">
      <tbody>
        <tr v-for="flag in flags" :key="flag.id">
          <td>{{ flag.flagKey }}</td>
          <td>{{ flag.enabled ? '开' : '关' }} {{ flag.rolloutPercent }}%</td>
          <td>
            <button v-if="canWrite()" type="button" class="link" @click="editFlag(flag)">编辑</button>
            <button type="button" class="link" @click="manageScopes(flag)">灰度规则</button>
          </td>
        </tr>
      </tbody>
    </table>
    <form v-if="canWrite()" @submit.prevent="saveFlag">
      <input v-model="flagForm.flagKey" required placeholder="flagKey" />
      <input v-model="flagForm.description" placeholder="说明" />
      <label><input v-model="flagForm.enabled" type="checkbox" /> 启用</label>
      <input v-model.number="flagForm.rolloutPercent" type="number" min="0" max="100" />
      <button type="submit">保存开关</button>
    </form>
    <section v-if="selectedFlag" class="panel">
      <h2>{{ selectedFlag.flagKey }} 灰度规则</h2>
      <p>规则优先级：活动 &gt; 门店 &gt; 城市；总开关关闭时所有规则立即失效。</p>
      <table class="data-table">
        <thead><tr><th>范围</th><th>ID</th><th>状态</th><th>比例</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-if="!flagScopes.length"><td colspan="5">暂无范围规则，使用总开关比例。</td></tr>
          <tr v-for="scope in flagScopes" :key="scope.id">
            <td>{{ scope.scopeType }}</td><td>{{ scope.scopeId }}</td>
            <td>{{ scope.enabled ? '启用' : '禁用' }}</td><td>{{ scope.rolloutPercent }}%</td>
            <td><button v-if="canWrite()" type="button" class="link" @click="removeScope(scope)">删除</button></td>
          </tr>
        </tbody>
      </table>
      <form v-if="canWrite()" @submit.prevent="saveScope">
        <select v-model="scopeForm.scopeType">
          <option value="city">城市</option><option value="shop">门店</option><option value="campaign">活动</option>
        </select>
        <input v-model.number="scopeForm.scopeId" type="number" min="1" required placeholder="范围 ID" />
        <label><input v-model="scopeForm.enabled" type="checkbox" /> 启用</label>
        <input v-model.number="scopeForm.rolloutPercent" type="number" min="0" max="100" required />
        <button type="submit">保存灰度规则</button>
      </form>
    </section>
    <h2>实验</h2>
    <ul>
      <li v-for="item in experiments" :key="item.id">{{ item.name }} · {{ item.flagKey }} · {{ item.status === 1 ? '进行中' : '关闭' }}</li>
    </ul>
    <form v-if="canWrite()" @submit.prevent="saveExperiment">
      <input v-model="experimentForm.name" required placeholder="名称" />
      <input v-model="experimentForm.flagKey" placeholder="flagKey" />
      <select v-model.number="experimentForm.status">
        <option :value="1">进行中</option>
        <option :value="0">关闭</option>
      </select>
      <button type="submit">创建实验</button>
    </form>
  </section>
</template>
