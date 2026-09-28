<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { createOpenApp, fetchOpenApps, updateOpenAppStatus, type OpsOpenApp } from '@/services/ops'

const { state } = useAdminSession()
const apps = ref<OpsOpenApp[]>([])
const created = ref<OpsOpenApp | null>(null)
const errorMessage = ref('')
const form = reactive({ name: '', ownerMerchantId: 0 })
const canWrite = () => state.permissions.includes('openapi:write')

async function load() {
  errorMessage.value = ''
  try {
    apps.value = await fetchOpenApps()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

async function submit() {
  created.value = await createOpenApp({ name: form.name.trim(), ownerMerchantId: Number(form.ownerMerchantId) })
  form.name = ''
  await load()
}

async function toggle(app: OpsOpenApp) {
  await updateOpenAppStatus(app.id, app.status === 1 ? 0 : 1)
  await load()
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>开放平台</h1>
      <p class="page-desc">密钥只在创建时返回一次。验签使用原始 secret，不要先做 hex 解码。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="created?.secret" class="feedback is-success" data-testid="openapi-secret">
      {{ created.keyId }} / {{ created.secret }}
    </p>
    <table class="data-table">
      <tbody>
        <tr v-for="app in apps" :key="app.id">
          <td>{{ app.name }}</td>
          <td>{{ app.ownerMerchantId }}</td>
          <td>{{ app.status === 1 ? '启用' : '停用' }}</td>
          <td>{{ (app.keyIds ?? []).join(', ') }}</td>
          <td><button v-if="canWrite()" type="button" class="link" @click="toggle(app)">{{ app.status === 1 ? '停用' : '启用' }}</button></td>
        </tr>
      </tbody>
    </table>
    <form v-if="canWrite()" @submit.prevent="submit">
      <input v-model="form.name" required maxlength="128" placeholder="应用名称" />
      <input v-model.number="form.ownerMerchantId" type="number" min="0" required placeholder="商户 id" />
      <button type="submit">创建</button>
    </form>
  </section>
</template>
