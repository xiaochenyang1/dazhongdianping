<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { fetchAdminGuides, saveAdminGuide, updateAdminGuideStatus, type OpsGuide } from '@/services/ops'

const { state } = useAdminSession()
const guides = ref<OpsGuide[]>([])
const errorMessage = ref('')
const editingId = ref<number | undefined>()
const form = reactive({
  title: '',
  summary: '',
  coverUrl: '',
  cityId: 0,
  status: 1,
  heading: '',
  body: '',
  shopId: 0,
})
const canWrite = () => state.permissions.includes('operations:guide:write')

async function load() {
  errorMessage.value = ''
  try {
    guides.value = (await fetchAdminGuides()).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

async function submit() {
  const saved = await saveAdminGuide({
    title: form.title.trim(),
    summary: form.summary.trim(),
    coverUrl: form.coverUrl.trim(),
    cityId: Number(form.cityId),
    status: Number(form.status),
    sections: [{ heading: form.heading.trim(), body: form.body.trim(), shopId: Number(form.shopId), sortNo: 1 }],
  }, editingId.value)
  editingId.value = saved.id
  await load()
}

async function publish(guide: OpsGuide, status: number) {
  await updateAdminGuideStatus(guide.id, status)
  await load()
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>攻略专题</h1>
      <p class="page-desc">保存时会整表替换章节。C 端只展示已发布攻略。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <table class="data-table">
      <tbody>
        <tr v-for="guide in guides" :key="guide.id">
          <td>{{ guide.title }}</td>
          <td>{{ guide.status === 2 ? '已发布' : '草稿' }}</td>
          <td v-if="canWrite()">
            <button type="button" class="link" @click="publish(guide, guide.status === 2 ? 1 : 2)">
              {{ guide.status === 2 ? '改为草稿' : '发布' }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>
    <form v-if="canWrite()" @submit.prevent="submit">
      <input v-model="form.title" required maxlength="128" placeholder="标题" />
      <input v-model="form.summary" maxlength="500" placeholder="摘要" />
      <input v-model="form.coverUrl" maxlength="255" placeholder="封面" />
      <input v-model.number="form.cityId" type="number" min="0" placeholder="城市" />
      <select v-model.number="form.status">
        <option :value="1">草稿</option>
        <option :value="2">发布</option>
      </select>
      <input v-model="form.heading" placeholder="章节标题" />
      <textarea v-model="form.body" rows="4" placeholder="章节正文" />
      <input v-model.number="form.shopId" type="number" min="0" placeholder="门店" />
      <button type="submit">保存</button>
    </form>
  </section>
</template>
