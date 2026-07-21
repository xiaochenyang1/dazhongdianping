<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createGeoArea,
  createGeoCategory,
  createGeoCity,
  listGeoAreas,
  listGeoCategories,
  listGeoCities,
  removeGeoArea,
  removeGeoCategory,
  removeGeoCity,
  updateGeoArea,
  updateGeoAreaStatus,
  updateGeoCategory,
  updateGeoCategoryStatus,
  updateGeoCity,
  updateGeoCityStatus,
} from '@/services/geodata'
import type {
  AdminGeoArea,
  AdminGeoCategory,
  AdminGeoCity,
  GeoAreaPayload,
  GeoCategoryPayload,
  GeoCityPayload,
} from '@/types/admin'

type Tab = 'categories' | 'cities' | 'areas'
type CategoryEditor = GeoCategoryPayload & { id?: number }
type CityEditor = GeoCityPayload & { id?: number }
type AreaEditor = GeoAreaPayload & { id?: number }

const { state } = useAdminSession()
const activeTab = ref<Tab>('categories')
const categories = ref<AdminGeoCategory[]>([])
const cities = ref<AdminGeoCity[]>([])
const areas = ref<AdminGeoArea[]>([])
const selectedCityId = ref<number | ''>('')
const categoryEditor = ref<CategoryEditor | null>(null)
const cityEditor = ref<CityEditor | null>(null)
const areaEditor = ref<AreaEditor | null>(null)
const loading = ref(false)
const areaLoading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let regionRequestId = 0
let areaRequestId = 0

const canWrite = computed(() => state.permissions.includes('data:geo:write'))
const activeCities = computed(() => cities.value.filter((city) => city.status === 1))

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : '请求失败'
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function closeEditors() {
  categoryEditor.value = null
  cityEditor.value = null
  areaEditor.value = null
}

async function reloadRegion() {
  const requestId = ++regionRequestId
  ++areaRequestId
  areaLoading.value = false
  resetMessages()
  closeEditors()
  categories.value = []
  cities.value = []
  areas.value = []
  selectedCityId.value = ''
  loading.value = true

  try {
    const [nextCategories, nextCities] = await Promise.all([
      listGeoCategories(),
      listGeoCities(),
    ])
    if (requestId !== regionRequestId) return
    categories.value = nextCategories
    cities.value = nextCities
  } catch (error) {
    if (requestId === regionRequestId) errorMessage.value = messageOf(error)
  } finally {
    if (requestId === regionRequestId) loading.value = false
  }
}

async function loadAreas(cityId: number | '') {
  const requestId = ++areaRequestId
  areas.value = []
  areaEditor.value = null
  areaLoading.value = false
  resetMessages()
  if (cityId === '') return
  areaLoading.value = true

  try {
    const nextAreas = await listGeoAreas(cityId)
    if (requestId === areaRequestId && selectedCityId.value === cityId) {
      areas.value = nextAreas
    }
  } catch (error) {
    if (requestId === areaRequestId) errorMessage.value = messageOf(error)
  } finally {
    if (requestId === areaRequestId) areaLoading.value = false
  }
}

function handleAreaCityChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value
  selectedCityId.value = value ? Number(value) : ''
  void loadAreas(selectedCityId.value)
}

function openCategoryEditor(item?: AdminGeoCategory) {
  if (!canWrite.value) return
  resetMessages()
  categoryEditor.value = item
    ? { id: item.id, parentId: item.parentId, name: item.name, sortNo: item.sortNo }
    : { parentId: 0, name: '', sortNo: 0 }
}

function openCityEditor(item?: AdminGeoCity) {
  if (!canWrite.value) return
  resetMessages()
  cityEditor.value = item
    ? { id: item.id, code: item.code, name: item.name, sortNo: item.sortNo }
    : { code: '', name: '', sortNo: 0 }
}

function openAreaEditor(item?: AdminGeoArea) {
  if (!canWrite.value || selectedCityId.value === '') return
  resetMessages()
  areaEditor.value = item
    ? { id: item.id, cityId: item.cityId, name: item.name, sortNo: item.sortNo }
    : { cityId: selectedCityId.value, name: '', sortNo: 0 }
}

async function submitCategory() {
  if (!categoryEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const editor = categoryEditor.value
  const payload: GeoCategoryPayload = {
    parentId: Number(editor.parentId),
    name: editor.name.trim(),
    sortNo: Number(editor.sortNo),
  }
  try {
    if (editor.id) await updateGeoCategory(editor.id, payload)
    else await createGeoCategory(payload)
    categoryEditor.value = null
    await reloadRegion()
    successMessage.value = editor.id ? '分类已更新' : '分类已创建'
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function submitCity() {
  if (!cityEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const editor = cityEditor.value
  const payload: GeoCityPayload = {
    code: editor.code.trim().toUpperCase(),
    name: editor.name.trim(),
    sortNo: Number(editor.sortNo),
  }
  try {
    if (editor.id) await updateGeoCity(editor.id, payload)
    else await createGeoCity(payload)
    cityEditor.value = null
    await reloadRegion()
    successMessage.value = editor.id ? '城市已更新' : '城市已创建'
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function submitArea() {
  if (!areaEditor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const editor = areaEditor.value
  const payload: GeoAreaPayload = {
    cityId: Number(editor.cityId),
    name: editor.name.trim(),
    sortNo: Number(editor.sortNo),
  }
  try {
    if (editor.id) await updateGeoArea(editor.id, payload)
    else await createGeoArea(payload)
    areaEditor.value = null
    await loadAreas(selectedCityId.value)
    successMessage.value = editor.id ? '商圈已更新' : '商圈已创建'
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleCategory(item: AdminGeoCategory) {
  await runMutation(
    () => updateGeoCategoryStatus(item.id, item.status === 1 ? 0 : 1),
    reloadRegion,
    item.status === 1 ? '分类已停用' : '分类已启用',
  )
}

async function toggleCity(item: AdminGeoCity) {
  await runMutation(
    () => updateGeoCityStatus(item.id, item.status === 1 ? 0 : 1),
    reloadRegion,
    item.status === 1 ? '城市已停用' : '城市已启用',
  )
}

async function toggleArea(item: AdminGeoArea) {
  await runMutation(
    () => updateGeoAreaStatus(item.id, item.status === 1 ? 0 : 1),
    () => loadAreas(selectedCityId.value),
    item.status === 1 ? '商圈已停用' : '商圈已启用',
  )
}

async function deleteCategory(item: AdminGeoCategory) {
  if (!window.confirm(`确认删除分类「${item.name}」？被业务引用时服务端会拒绝。`)) return
  await runMutation(() => removeGeoCategory(item.id), reloadRegion, '分类已删除')
}

async function deleteCity(item: AdminGeoCity) {
  if (!window.confirm(`确认删除城市「${item.name}」？被业务引用时服务端会拒绝。`)) return
  await runMutation(() => removeGeoCity(item.id), reloadRegion, '城市已删除')
}

async function deleteArea(item: AdminGeoArea) {
  if (!window.confirm(`确认删除商圈「${item.name}」？被业务引用时服务端会拒绝。`)) return
  await runMutation(() => removeGeoArea(item.id), () => loadAreas(selectedCityId.value), '商圈已删除')
}

async function runMutation(action: () => Promise<unknown>, reload: () => Promise<void>, success: string) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await action()
    await reload()
    successMessage.value = success
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

watch(() => state.region, () => void reloadRegion(), { immediate: true })
</script>

<template>
  <section class="page-section geo-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">当前区域 {{ state.region }}</p>
        <h1>基础数据</h1>
        <p>维护分类、城市和商圈。停用项不会继续出现在 C 端筛选中，历史门店信息仍会保留。</p>
      </div>
      <span class="status-pill" :class="canWrite ? 'status-pill--good' : 'status-pill--muted'">
        {{ canWrite ? '可维护' : '只读' }}
      </span>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success" role="status">{{ successMessage }}</p>

    <div class="geo-tabs" role="tablist" aria-label="基础数据类型">
      <button type="button" :class="{ 'is-active': activeTab === 'categories' }" data-testid="tab-categories" @click="activeTab = 'categories'">分类</button>
      <button type="button" :class="{ 'is-active': activeTab === 'cities' }" data-testid="tab-cities" @click="activeTab = 'cities'">城市</button>
      <button type="button" :class="{ 'is-active': activeTab === 'areas' }" data-testid="tab-areas" @click="activeTab = 'areas'">商圈</button>
    </div>

    <p v-if="loading" class="feedback">正在加载 {{ state.region }} 区域数据...</p>

    <section v-else-if="activeTab === 'categories'" class="geo-workspace" aria-labelledby="category-heading">
      <div class="geo-workspace__toolbar">
        <div><h2 id="category-heading">分类</h2><p>{{ categories.length }} 条，按父级与排序值展示</p></div>
        <button v-if="canWrite" type="button" class="primary-button" data-testid="create-category" @click="openCategoryEditor()">新增分类</button>
      </div>

      <form v-if="categoryEditor" class="geo-editor" data-testid="category-form" @submit.prevent="submitCategory">
        <label class="field"><span>父分类</span><select v-model.number="categoryEditor.parentId" name="category-parent" :disabled="saving"><option :value="0">根分类</option><option v-for="item in categories.filter((entry) => entry.id !== categoryEditor?.id)" :key="item.id" :value="item.id">{{ item.name }}</option></select></label>
        <label class="field"><span>名称</span><input v-model="categoryEditor.name" name="category-name" maxlength="64" required :disabled="saving"></label>
        <label class="field"><span>排序</span><input v-model.number="categoryEditor.sortNo" name="category-sort" type="number" min="0" max="999999" required :disabled="saving"></label>
        <div class="form-actions"><button type="submit" class="primary-button" :disabled="saving">保存</button><button type="button" class="ghost-button" :disabled="saving" @click="categoryEditor = null">取消</button></div>
      </form>

      <div class="table-shell"><table class="data-table"><thead><tr><th>名称</th><th>父级</th><th>排序</th><th>状态</th><th v-if="canWrite">操作</th></tr></thead><tbody>
        <tr v-for="item in categories" :key="item.id"><td><strong>{{ item.name }}</strong><p>#{{ item.id }}</p></td><td>{{ item.parentId === 0 ? '根分类' : categories.find((parent) => parent.id === item.parentId)?.name ?? `#${item.parentId}` }}</td><td class="numeric-cell">{{ item.sortNo }}</td><td><span class="status-pill" :class="item.status === 1 ? 'status-pill--good' : 'status-pill--muted'">{{ item.status === 1 ? '启用' : '停用' }}</span></td><td v-if="canWrite"><div class="table-actions"><button type="button" class="table-action" :data-testid="`edit-category-${item.id}`" title="编辑分类" @click="openCategoryEditor(item)">编辑</button><button type="button" class="table-action" :data-testid="`status-category-${item.id}`" :disabled="saving" @click="toggleCategory(item)">{{ item.status === 1 ? '停用' : '启用' }}</button><button type="button" class="table-action table-action--danger" :data-testid="`delete-category-${item.id}`" :disabled="saving" @click="deleteCategory(item)">删除</button></div></td></tr>
        <tr v-if="categories.length === 0"><td :colspan="canWrite ? 5 : 4" class="table-empty">当前区域暂无分类</td></tr>
      </tbody></table></div>
    </section>

    <section v-else-if="activeTab === 'cities'" class="geo-workspace" aria-labelledby="city-heading">
      <div class="geo-workspace__toolbar"><div><h2 id="city-heading">城市</h2><p>{{ cities.length }} 条，城市编码在区域内唯一</p></div><button v-if="canWrite" type="button" class="primary-button" data-testid="create-city" @click="openCityEditor()">新增城市</button></div>
      <form v-if="cityEditor" class="geo-editor" data-testid="city-form" @submit.prevent="submitCity"><label class="field"><span>编码</span><input v-model="cityEditor.code" name="city-code" maxlength="32" required :disabled="saving"></label><label class="field"><span>名称</span><input v-model="cityEditor.name" name="city-name" maxlength="64" required :disabled="saving"></label><label class="field"><span>排序</span><input v-model.number="cityEditor.sortNo" name="city-sort" type="number" min="0" max="999999" required :disabled="saving"></label><div class="form-actions"><button type="submit" class="primary-button" :disabled="saving">保存</button><button type="button" class="ghost-button" :disabled="saving" @click="cityEditor = null">取消</button></div></form>
      <div class="table-shell"><table class="data-table"><thead><tr><th>城市</th><th>编码</th><th>排序</th><th>状态</th><th v-if="canWrite">操作</th></tr></thead><tbody><tr v-for="item in cities" :key="item.id"><td><strong>{{ item.name }}</strong><p>#{{ item.id }}</p></td><td><span class="code-box">{{ item.code }}</span></td><td class="numeric-cell">{{ item.sortNo }}</td><td><span class="status-pill" :class="item.status === 1 ? 'status-pill--good' : 'status-pill--muted'">{{ item.status === 1 ? '启用' : '停用' }}</span></td><td v-if="canWrite"><div class="table-actions"><button type="button" class="table-action" :data-testid="`edit-city-${item.id}`" @click="openCityEditor(item)">编辑</button><button type="button" class="table-action" :data-testid="`status-city-${item.id}`" :disabled="saving" @click="toggleCity(item)">{{ item.status === 1 ? '停用' : '启用' }}</button><button type="button" class="table-action table-action--danger" :data-testid="`delete-city-${item.id}`" :disabled="saving" @click="deleteCity(item)">删除</button></div></td></tr><tr v-if="cities.length === 0"><td :colspan="canWrite ? 5 : 4" class="table-empty">当前区域暂无城市</td></tr></tbody></table></div>
    </section>

    <section v-else class="geo-workspace" aria-labelledby="area-heading">
      <div class="geo-workspace__toolbar"><div><h2 id="area-heading">商圈</h2><p>先选择城市，再维护其下商圈</p></div><button v-if="canWrite && selectedCityId !== ''" type="button" class="primary-button" data-testid="create-area" @click="openAreaEditor()">新增商圈</button></div>
      <label class="field geo-city-filter"><span>城市</span><select :value="selectedCityId" data-testid="area-city-select" @change="handleAreaCityChange"><option value="">请选择城市</option><option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}{{ city.status === 0 ? '（停用）' : '' }}</option></select></label>
      <form v-if="areaEditor" class="geo-editor" data-testid="area-form" @submit.prevent="submitArea"><label class="field"><span>城市</span><select v-model.number="areaEditor.cityId" name="area-city" required :disabled="saving"><option v-for="city in activeCities" :key="city.id" :value="city.id">{{ city.name }}</option></select></label><label class="field"><span>名称</span><input v-model="areaEditor.name" name="area-name" maxlength="64" required :disabled="saving"></label><label class="field"><span>排序</span><input v-model.number="areaEditor.sortNo" name="area-sort" type="number" min="0" max="999999" required :disabled="saving"></label><div class="form-actions"><button type="submit" class="primary-button" :disabled="saving">保存</button><button type="button" class="ghost-button" :disabled="saving" @click="areaEditor = null">取消</button></div></form>
      <p v-if="areaLoading" class="feedback">正在加载商圈...</p>
      <div v-else class="table-shell"><table class="data-table"><thead><tr><th>商圈</th><th>城市</th><th>排序</th><th>状态</th><th v-if="canWrite">操作</th></tr></thead><tbody><tr v-for="item in areas" :key="item.id"><td><strong>{{ item.name }}</strong><p>#{{ item.id }}</p></td><td>{{ cities.find((city) => city.id === item.cityId)?.name ?? `#${item.cityId}` }}</td><td class="numeric-cell">{{ item.sortNo }}</td><td><span class="status-pill" :class="item.status === 1 ? 'status-pill--good' : 'status-pill--muted'">{{ item.status === 1 ? '启用' : '停用' }}</span></td><td v-if="canWrite"><div class="table-actions"><button type="button" class="table-action" :data-testid="`edit-area-${item.id}`" @click="openAreaEditor(item)">编辑</button><button type="button" class="table-action" :data-testid="`status-area-${item.id}`" :disabled="saving" @click="toggleArea(item)">{{ item.status === 1 ? '停用' : '启用' }}</button><button type="button" class="table-action table-action--danger" :data-testid="`delete-area-${item.id}`" :disabled="saving" @click="deleteArea(item)">删除</button></div></td></tr><tr v-if="selectedCityId === ''"><td :colspan="canWrite ? 5 : 4" class="table-empty">请选择城市</td></tr><tr v-else-if="areas.length === 0"><td :colspan="canWrite ? 5 : 4" class="table-empty">当前城市暂无商圈</td></tr></tbody></table></div>
    </section>
  </section>
</template>
