<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { createAdminBanner, listAdminBanners, removeAdminBanner, updateAdminBanner, updateAdminBannerStatus } from '@/services/admin'
import { fetchCities } from '@/services/meta'
import type { AdminBanner, AdminBannerPayload, City } from '@/types/admin'

type BannerEditor = Omit<AdminBannerPayload, 'cityId'> & {
  id?: number
  cityId: number | ''
}

const { state } = useAdminSession()
const canWrite = computed(() => state.permissions.includes('operations:banner:write'))

const cities = ref<City[]>([])
const banners = ref<AdminBanner[]>([])
const filterCityId = ref<number | ''>('')
const editor = ref<BannerEditor | null>(null)
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let requestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : '请求失败'
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function scopeText(item: AdminBanner) {
  if (item.cityId == null) {
    return '区域通用'
  }
  return item.cityName || `城市 #${item.cityId}`
}

async function load() {
  const currentRequestId = ++requestId
  loading.value = true
  resetMessages()
  try {
    const [nextCities, nextBanners] = await Promise.all([
      fetchCities(),
      listAdminBanners(filterCityId.value === '' ? undefined : { cityId: Number(filterCityId.value) }),
    ])
    if (currentRequestId !== requestId) return
    cities.value = nextCities
    banners.value = nextBanners
    if (filterCityId.value !== '' && !nextCities.some((item) => item.id === filterCityId.value)) {
      filterCityId.value = ''
    }
  } catch (error) {
    if (currentRequestId === requestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

function openEditor(item?: AdminBanner) {
  if (!canWrite.value) return
  resetMessages()
  editor.value = item
    ? {
        id: item.id,
        cityId: item.cityId ?? '',
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        linkUrl: item.linkUrl,
        sortNo: item.sortNo,
      }
    : {
        cityId: '',
        title: '',
        subtitle: '',
        imageUrl: '',
        linkUrl: '/',
        sortNo: 0,
      }
}

async function submitEditor() {
  if (!editor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const current = editor.value
  const payload: AdminBannerPayload = {
    cityId: current.cityId === '' ? null : Number(current.cityId),
    title: current.title.trim(),
    subtitle: current.subtitle.trim(),
    imageUrl: current.imageUrl.trim(),
    linkUrl: current.linkUrl.trim(),
    sortNo: Number(current.sortNo),
  }
  try {
    if (current.id) {
      await updateAdminBanner(current.id, payload)
      successMessage.value = 'Banner 已更新'
    } else {
      await createAdminBanner(payload)
      successMessage.value = 'Banner 已创建'
    }
    editor.value = null
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleBanner(item: AdminBanner) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminBannerStatus(item.id, !item.enabled)
    successMessage.value = item.enabled ? 'Banner 已停用' : 'Banner 已启用'
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteBanner(item: AdminBanner) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(`确认删除 Banner「${item.title}」？删除后首页会立即下线。`)
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminBanner(item.id)
    successMessage.value = 'Banner 已删除'
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

watch(
  () => state.region,
  () => {
    filterCityId.value = ''
    editor.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">首页运营</p>
        <h1>Banner 走真表，别再改种子 SQL 冒充运营配置。</h1>
        <p>当前区域 {{ state.region }}。不筛城市时展示当前区域全部 Banner；按城市筛选时会同时展示区域通用和城市专属 Banner，便于对照 C 端首页结果。</p>
      </div>
      <button v-if="canWrite" data-testid="create-banner" class="secondary-button" type="button" @click="openEditor()">新建 Banner</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">展示范围</p>
          <h2>先按城市看当前首页会吃到哪些 Banner</h2>
        </div>
      </div>

      <form class="editor-form" @submit.prevent="load">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>城市筛选</span>
            <select v-model="filterCityId" name="banner-city-filter">
              <option :value="''">全部 Banner（含区域通用和城市专属）</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <div class="field">
            <span>说明</span>
            <p class="muted">`linkUrl` 当前只支持站内相对路径，例如 `/shops?cityId=101`。</p>
          </div>
        </div>
        <div class="form-actions">
          <button data-testid="apply-filter" class="primary-button" type="submit" :disabled="loading">
            {{ loading ? '加载中...' : '查看当前城市效果' }}
          </button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">Banner 列表</p>
          <h2>排序越小越靠前，停用后公开首页立即不再返回</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>范围</th>
              <th>标题</th>
              <th>落点</th>
              <th>排序</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">加载中...</td>
            </tr>
            <tr v-else-if="!banners.length">
              <td :colspan="canWrite ? 6 : 5" class="table-empty">当前没有 Banner。</td>
            </tr>
            <tr v-for="item in banners" :key="item.id">
              <td>{{ scopeText(item) }}</td>
              <td>
                <strong>{{ item.title }}</strong>
                <p>{{ item.subtitle || '无副标题' }}</p>
                <p class="muted">{{ item.imageUrl }}</p>
              </td>
              <td><code>{{ item.linkUrl }}</code></td>
              <td>{{ item.sortNo }}</td>
              <td><span class="status-pill">{{ item.enabled ? '启用' : '停用' }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`edit-banner-${item.id}`" class="table-action" type="button" @click="openEditor(item)">编辑</button>
                <button :data-testid="`toggle-banner-${item.id}`" class="table-action" type="button" @click="toggleBanner(item)">
                  {{ item.enabled ? '停用' : '启用' }}
                </button>
                <button :data-testid="`delete-banner-${item.id}`" class="table-action danger-action" type="button" @click="deleteBanner(item)">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="editor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ editor.id ? '编辑 Banner' : '新建 Banner' }}</p>
          <h2>{{ editor.id ? '改完立即影响后续返回结果' : '新建后按排序插入首页返回序列' }}</h2>
        </div>
      </div>

      <form data-testid="banner-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field">
            <span>城市范围</span>
            <select v-model="editor.cityId" name="banner-city">
              <option :value="''">区域通用</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
          </label>
          <label class="field">
            <span>排序</span>
            <input v-model.number="editor.sortNo" name="banner-sort-no" type="number" min="0" />
          </label>
          <label class="field field--full">
            <span>标题</span>
            <input v-model="editor.title" name="banner-title" type="text" maxlength="128" required />
          </label>
          <label class="field field--full">
            <span>副标题</span>
            <input v-model="editor.subtitle" name="banner-subtitle" type="text" maxlength="255" />
          </label>
          <label class="field field--full">
            <span>图片 URL</span>
            <input v-model="editor.imageUrl" name="banner-image-url" type="text" maxlength="255" required />
          </label>
          <label class="field field--full">
            <span>站内落点</span>
            <input v-model="editor.linkUrl" name="banner-link-url" type="text" maxlength="255" required />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存 Banner' }}</button>
          <button class="secondary-button" type="button" @click="editor = null">取消</button>
        </div>
      </form>
    </section>
  </section>
</template>
