<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createAdminExperiment,
  fetchAdminExperiments,
  fetchAdminFlags,
  saveAdminFlag,
  type OpsExperiment,
  type OpsFlag,
} from '@/services/ops'

const { state } = useAdminSession()
const flags = ref<OpsFlag[]>([])
const experiments = ref<OpsExperiment[]>([])
const errorMessage = ref('')
const flagForm = reactive({ id: undefined as number | undefined, flagKey: '', description: '', enabled: true, rolloutPercent: 100 })
const experimentForm = reactive({ name: '', flagKey: '', status: 1 })
const canWrite = () => state.permissions.includes('operations:experiment:write')

async function load() {
  errorMessage.value = ''
  try {
    flags.value = await fetchAdminFlags()
    experiments.value = await fetchAdminExperiments()
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

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>实验开关</h1>
      <p class="page-desc">匿名开关按 flagKey 哈希分桶。实验分组按用户粘滞，再次分配不会改结果。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <table class="data-table">
      <tbody>
        <tr v-for="flag in flags" :key="flag.id">
          <td>{{ flag.flagKey }}</td>
          <td>{{ flag.enabled ? '开' : '关' }} {{ flag.rolloutPercent }}%</td>
          <td><button v-if="canWrite()" type="button" class="link" @click="editFlag(flag)">编辑</button></td>
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
