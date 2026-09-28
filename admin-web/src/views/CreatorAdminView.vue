<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { fetchAdminCreatorTasks, saveAdminCreatorTask, type OpsCreatorTask } from '@/services/ops'

const { state } = useAdminSession()
const tasks = ref<OpsCreatorTask[]>([])
const errorMessage = ref('')
const editingId = ref<number | undefined>()
const form = reactive({ title: '', description: '', rewardPoints: 20, status: 1 })
const canWrite = () => state.permissions.includes('operations:creator:write')

async function load() {
  errorMessage.value = ''
  try {
    tasks.value = (await fetchAdminCreatorTasks()).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

function edit(task: OpsCreatorTask) {
  editingId.value = task.id
  form.title = task.title
  form.description = task.description
  form.rewardPoints = task.rewardPoints
  form.status = task.status
}

async function submit() {
  await saveAdminCreatorTask({
    title: form.title.trim(),
    description: form.description.trim(),
    rewardPoints: Number(form.rewardPoints),
    status: Number(form.status),
  }, editingId.value)
  editingId.value = undefined
  form.title = ''
  form.description = ''
  await load()
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>创作者任务</h1>
      <p class="page-desc">完成后积分写入用户积分流水，同一领取只发一次。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <table class="data-table">
      <tbody>
        <tr v-for="task in tasks" :key="task.id">
          <td>{{ task.title }}</td>
          <td>{{ task.rewardPoints }}</td>
          <td>{{ task.status === 1 ? '进行中' : '下线' }}</td>
          <td><button v-if="canWrite()" type="button" class="link" @click="edit(task)">编辑</button></td>
        </tr>
      </tbody>
    </table>
    <form v-if="canWrite()" @submit.prevent="submit">
      <input v-model="form.title" required maxlength="128" placeholder="标题" />
      <textarea v-model="form.description" rows="3" placeholder="说明" />
      <input v-model.number="form.rewardPoints" type="number" min="0" />
      <select v-model.number="form.status">
        <option :value="1">进行中</option>
        <option :value="0">下线</option>
      </select>
      <button type="submit">保存</button>
    </form>
  </section>
</template>
