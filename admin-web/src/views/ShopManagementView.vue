<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createShop,
  getShop,
  listShops,
  removeShop,
  updateShop,
} from '@/services/admin'
import { fetchAreas, fetchCategories, fetchCities } from '@/services/meta'
import type {
  AdminShopDetail,
  AdminShopSavePayload,
  AdminShopSummary,
  Area,
  CategoryNode,
  City,
  PageResult,
  Region,
} from '@/types/admin'

interface ShopFilters {
  keyword: string
  categoryId: string
  cityId: string
  areaId: string
  page: number
  pageSize: number
}

interface ShopFormState {
  merchantId: string
  categoryId: string
  cityId: string
  areaId: string
  name: string
  coverUrl: string
  phone: string
  pricePerCapita: string
  currency: string
  address: string
  latitude: string
  longitude: string
  businessHours: string
  summary: string
  score: string
  tasteScore: string
  envScore: string
  serviceScore: string
  hasDeal: boolean
  openNow: boolean
  status: string
  tags: string
}

interface CategoryOption {
  id: number
  label: string
}

const { state } = useAdminSession()

const categories = ref<CategoryNode[]>([])
const cities = ref<City[]>([])
const filterAreas = ref<Area[]>([])
const formAreas = ref<Area[]>([])
const pageState = ref<PageResult<AdminShopSummary> | null>(null)
const selectedDetail = ref<AdminShopDetail | null>(null)
const selectedShopId = ref<number | null>(null)

const listLoading = ref(false)
const detailLoading = ref(false)
const saving = ref(false)
const removingShopId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')

const filters = reactive<ShopFilters>({
  keyword: '',
  categoryId: '',
  cityId: '',
  areaId: '',
  page: 1,
  pageSize: 10,
})

const form = reactive<ShopFormState>(createEmptyShopForm(state.region))

const categoryOptions = computed<CategoryOption[]>(() =>
  categories.value.flatMap((group) => {
    if (group.children.length === 0) {
      return [{ id: group.id, label: group.name }]
    }

    return group.children.map((child) => ({
      id: child.id,
      label: `${group.name} / ${child.name}`,
    }))
  }),
)

const editorTitle = computed(() => (selectedShopId.value ? `编辑门店 #${selectedShopId.value}` : '新建门店'))
const listCountText = computed(() => {
  if (!pageState.value || pageState.value.list.length === 0) {
    return '0 / 0'
  }

  const start = (pageState.value.page - 1) * pageState.value.pageSize + 1
  const end = start + pageState.value.list.length - 1
  return `${start}-${end} / ${pageState.value.total}`
})

const coverPreviewUrl = computed(() => form.coverUrl.trim() || defaultCoverUrl(state.region))

function defaultCurrency(region: Region) {
  return region === 'EU' ? 'EUR' : 'CNY'
}

function defaultCoverUrl(region: Region) {
  return region === 'EU'
    ? 'https://placehold.co/1200x720/1d4ed8/f8fafc?text=EU+Shop'
    : 'https://placehold.co/1200x720/f97316/f8fafc?text=CN+Shop'
}

function createEmptyShopForm(region: Region): ShopFormState {
  return {
    merchantId: '',
    categoryId: '',
    cityId: '',
    areaId: '',
    name: '',
    coverUrl: defaultCoverUrl(region),
    phone: '',
    pricePerCapita: region === 'EU' ? '22' : '88',
    currency: defaultCurrency(region),
    address: '',
    latitude: '',
    longitude: '',
    businessHours: '10:00-21:00',
    summary: '',
    score: '4.2',
    tasteScore: '4.1',
    envScore: '4.2',
    serviceScore: '4.2',
    hasDeal: false,
    openNow: true,
    status: '1',
    tags: '',
  }
}

async function loadMeta() {
  const [nextCategories, nextCities] = await Promise.all([fetchCategories(), fetchCities()])
  categories.value = nextCategories
  cities.value = nextCities
}

async function loadFilterAreas() {
  if (!filters.cityId) {
    filterAreas.value = []
    return
  }

  filterAreas.value = await fetchAreas(Number(filters.cityId))
}

async function loadFormAreas() {
  if (!form.cityId) {
    formAreas.value = []
    return
  }

  formAreas.value = await fetchAreas(Number(form.cityId))
}

async function openCreateForm() {
  selectedShopId.value = null
  selectedDetail.value = null
  Object.assign(form, createEmptyShopForm(state.region))

  if (cities.value.length > 0) {
    form.cityId = String(cities.value[0].id)
    await loadFormAreas()
    form.areaId = formAreas.value[0] ? String(formAreas.value[0].id) : ''
  } else {
    formAreas.value = []
  }

  if (categoryOptions.value.length > 0) {
    form.categoryId = String(categoryOptions.value[0].id)
  }
}

async function applyDetail(detail: AdminShopDetail) {
  selectedShopId.value = detail.id
  selectedDetail.value = detail

  Object.assign(form, {
    merchantId: detail.merchantId > 0 ? String(detail.merchantId) : '',
    categoryId: String(detail.categoryId),
    cityId: String(detail.cityId),
    areaId: String(detail.areaId),
    name: detail.name,
    coverUrl: detail.coverUrl,
    phone: detail.phone,
    pricePerCapita: String(detail.pricePerCapita),
    currency: detail.currency,
    address: detail.address,
    latitude: detail.latitude == null ? '' : String(detail.latitude),
    longitude: detail.longitude == null ? '' : String(detail.longitude),
    businessHours: detail.businessHours,
    summary: detail.summary,
    score: String(detail.score),
    tasteScore: String(detail.tasteScore),
    envScore: String(detail.envScore),
    serviceScore: String(detail.serviceScore),
    hasDeal: detail.hasDeal,
    openNow: detail.openNow,
    status: String(detail.status),
    tags: detail.tags.join(', '),
  })

  await loadFormAreas()
  form.areaId = String(detail.areaId)
}

async function loadShops() {
  listLoading.value = true
  errorMessage.value = ''

  try {
    pageState.value = await listShops({
      region: state.region,
      keyword: filters.keyword.trim() || undefined,
      categoryId: filters.categoryId ? Number(filters.categoryId) : undefined,
      cityId: filters.cityId ? Number(filters.cityId) : undefined,
      areaId: filters.areaId ? Number(filters.areaId) : undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店列表加载失败'
  } finally {
    listLoading.value = false
  }
}

async function bootstrapPage() {
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await loadMeta()
    await loadFilterAreas()
    await openCreateForm()
    await loadShops()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '商户管理初始化失败'
  }
}

async function onFilterCityChange(value: string) {
  filters.cityId = value
  filters.areaId = ''
  await loadFilterAreas()
}

async function onFormCityChange(value: string) {
  form.cityId = value
  form.areaId = ''
  await loadFormAreas()
  form.areaId = formAreas.value[0] ? String(formAreas.value[0].id) : ''
}

async function handleEdit(shopId: number) {
  detailLoading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const detail = await getShop(shopId)
    await applyDetail(detail)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店详情加载失败'
  } finally {
    detailLoading.value = false
  }
}

function parseTags(rawValue: string) {
  return rawValue
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
}

function buildPayload(): AdminShopSavePayload {
  if (!form.categoryId || !form.cityId || !form.areaId) {
    throw new Error('分类、城市、商圈得补齐，不然门店往哪儿挂？')
  }
  if (!form.name.trim() || !form.coverUrl.trim() || !form.address.trim() || !form.summary.trim()) {
    throw new Error('名称、封面、地址、摘要这些基础字段别留空。')
  }

  const latitude = form.latitude.trim() === '' ? null : Number(form.latitude)
  const longitude = form.longitude.trim() === '' ? null : Number(form.longitude)
  if ((latitude == null) !== (longitude == null)) {
    throw new Error('经纬度得成对填写，单独来一个没法定位。')
  }
  if (latitude != null && (!Number.isFinite(latitude) || latitude < -90 || latitude > 90)) {
    throw new Error('纬度必须在 -90 到 90 之间。')
  }
  if (longitude != null && (!Number.isFinite(longitude) || longitude < -180 || longitude > 180)) {
    throw new Error('经度必须在 -180 到 180 之间。')
  }

  return {
    merchantId: form.merchantId ? Number(form.merchantId) : 0,
    region: state.region,
    categoryId: Number(form.categoryId),
    cityId: Number(form.cityId),
    areaId: Number(form.areaId),
    name: form.name.trim(),
    coverUrl: form.coverUrl.trim(),
    phone: form.phone.trim(),
    pricePerCapita: Number(form.pricePerCapita),
    currency: form.currency.trim() || defaultCurrency(state.region),
    address: form.address.trim(),
    latitude,
    longitude,
    businessHours: form.businessHours.trim(),
    summary: form.summary.trim(),
    score: Number(form.score),
    tasteScore: Number(form.tasteScore),
    envScore: Number(form.envScore),
    serviceScore: Number(form.serviceScore),
    hasDeal: form.hasDeal,
    openNow: form.openNow,
    status: Number(form.status),
    tags: parseTags(form.tags),
  }
}

async function saveShop() {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const isEditing = selectedShopId.value != null

  try {
    const payload = buildPayload()
    const detail = isEditing && selectedShopId.value
      ? await updateShop(selectedShopId.value, payload)
      : await createShop(payload)

    await applyDetail(detail)
    await loadShops()
    successMessage.value = isEditing ? '门店更新成功。' : '门店创建成功。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店保存失败'
  } finally {
    saving.value = false
  }
}

async function handleDelete(shopId: number) {
  const target = pageState.value?.list.find((item) => item.id === shopId)
  const confirmed = window.confirm(`确认删除门店「${target?.name ?? `#${shopId}`}」？`)

  if (!confirmed) {
    return
  }

  removingShopId.value = shopId
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await removeShop(shopId)

    if (selectedShopId.value === shopId) {
      await openCreateForm()
    }

    if (pageState.value && pageState.value.list.length === 1 && filters.page > 1) {
      filters.page -= 1
    }

    await loadShops()
    successMessage.value = '门店已删除。'
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店删除失败'
  } finally {
    removingShopId.value = null
  }
}

function applyFilters() {
  filters.page = 1
  void loadShops()
}

function resetFilters() {
  filters.keyword = ''
  filters.categoryId = ''
  filters.cityId = ''
  filters.areaId = ''
  filters.page = 1
  filterAreas.value = []
  void loadShops()
}

function goPrevPage() {
  if (!pageState.value || pageState.value.page <= 1) {
    return
  }

  filters.page -= 1
  void loadShops()
}

function goNextPage() {
  if (!pageState.value?.hasMore) {
    return
  }

  filters.page += 1
  void loadShops()
}

watch(
  () => state.region,
  () => {
    filters.keyword = ''
    filters.categoryId = ''
    filters.cityId = ''
    filters.areaId = ''
    filters.page = 1
    void bootstrapPage()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">商户管理</p>
        <h1>区域 {{ state.region }} 的门店最小 CRUD 已经接上，先把数据盘清楚。</h1>
        <p>这里追求的是可操作、可验收，不是摆一堆按钮假装平台很大。</p>
      </div>

      <div class="header-actions">
        <button type="button" class="secondary-button" @click="loadShops">刷新列表</button>
        <button type="button" class="primary-button" @click="openCreateForm">新建门店</button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">列表筛选</p>
            <h2>先把门店找得到、改得到，再谈后面的运营玩法。</h2>
          </div>
          <span class="inline-note">当前显示 {{ listCountText }}</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>关键词</span>
            <input v-model="filters.keyword" type="text" placeholder="店名 / 地址 / 商户名" />
          </label>

          <label class="field">
            <span>城市</span>
            <select :value="filters.cityId" @change="onFilterCityChange(($event.target as HTMLSelectElement).value)">
              <option value="">全部城市</option>
              <option v-for="city in cities" :key="city.id" :value="city.id">
                {{ city.name }}
              </option>
            </select>
          </label>

          <label class="field">
            <span>商圈</span>
            <select v-model="filters.areaId">
              <option value="">全部商圈</option>
              <option v-for="area in filterAreas" :key="area.id" :value="area.id">
                {{ area.name }}
              </option>
            </select>
          </label>

          <label class="field">
            <span>分类</span>
            <select v-model="filters.categoryId">
              <option value="">全部分类</option>
              <option v-for="category in categoryOptions" :key="category.id" :value="category.id">
                {{ category.label }}
              </option>
            </select>
          </label>
        </div>

        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">应用筛选</button>
          <button type="button" class="ghost-button" @click="resetFilters">重置</button>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>门店</th>
                <th>商户</th>
                <th>分类 / 区域</th>
                <th>城市 / 商圈</th>
                <th>人均</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="listLoading">
                <td colspan="7" class="table-empty">门店列表加载中...</td>
              </tr>
              <tr v-else-if="!pageState || pageState.list.length === 0">
                <td colspan="7" class="table-empty">当前筛选下没有门店，条件别拧巴得太狠。</td>
              </tr>
              <tr v-for="shop in pageState?.list" :key="shop.id">
                <td>
                  <strong>{{ shop.name }}</strong>
                  <p>#{{ shop.id }} · {{ shop.createdAt }}</p>
                </td>
                <td>{{ shop.merchantName || '未绑定商户' }}</td>
                <td>{{ shop.categoryName }} · {{ shop.region }}</td>
                <td>{{ shop.cityName }} · {{ shop.areaName }}</td>
                <td>{{ shop.pricePerCapita }} {{ state.region === 'EU' ? 'EUR' : 'CNY' }}</td>
                <td>
                  <span class="status-pill" :class="shop.status === 1 ? 'status-pill--good' : shop.status === 2 ? 'status-pill--warn' : 'status-pill--muted'">
                    {{ shop.statusText }}
                  </span>
                </td>
                <td class="table-actions">
                  <button type="button" class="table-action" @click="handleEdit(shop.id)">编辑</button>
                  <button
                    type="button"
                    class="table-action table-action--danger"
                    :disabled="removingShopId === shop.id"
                    @click="handleDelete(shop.id)"
                  >
                    {{ removingShopId === shop.id ? '删除中...' : '删除' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
            上一页
          </button>
          <span>第 {{ pageState?.page ?? 1 }} 页</span>
          <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
            下一页
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <div class="editor-header">
          <div>
            <p class="eyebrow">编辑器</p>
            <h2>{{ editorTitle }}</h2>
          </div>
          <span class="inline-note">{{ detailLoading ? '详情加载中...' : `区域 ${state.region}` }}</span>
        </div>

        <form class="editor-form" @submit.prevent="saveShop">
          <div class="form-grid form-grid--two">
            <label class="field">
              <span>商户 ID</span>
              <input v-model="form.merchantId" type="number" min="0" placeholder="可为空或填现有商户 ID" />
            </label>

            <label class="field">
              <span>分类</span>
              <select v-model="form.categoryId">
                <option value="">请选择分类</option>
                <option v-for="category in categoryOptions" :key="category.id" :value="category.id">
                  {{ category.label }}
                </option>
              </select>
            </label>

            <label class="field">
              <span>城市</span>
              <select :value="form.cityId" @change="onFormCityChange(($event.target as HTMLSelectElement).value)">
                <option value="">请选择城市</option>
                <option v-for="city in cities" :key="city.id" :value="city.id">
                  {{ city.name }}
                </option>
              </select>
            </label>

            <label class="field">
              <span>商圈</span>
              <select v-model="form.areaId">
                <option value="">请选择商圈</option>
                <option v-for="area in formAreas" :key="area.id" :value="area.id">
                  {{ area.name }}
                </option>
              </select>
            </label>

            <label class="field">
              <span>门店名称</span>
              <input v-model="form.name" type="text" placeholder="例如：徐汇测试店" />
            </label>

            <label class="field">
              <span>联系电话</span>
              <input v-model="form.phone" type="text" placeholder="门店电话" />
            </label>

            <label class="field field--full">
              <span>封面图</span>
              <input v-model="form.coverUrl" type="url" placeholder="https://..." />
            </label>

            <label class="field">
              <span>人均</span>
              <input v-model="form.pricePerCapita" type="number" min="0" step="0.1" />
            </label>

            <label class="field">
              <span>币种</span>
              <input v-model="form.currency" type="text" maxlength="3" />
            </label>

            <label class="field">
              <span>营业时间</span>
              <input v-model="form.businessHours" type="text" placeholder="10:00-21:00" />
            </label>

            <label class="field">
              <span>状态</span>
              <select v-model="form.status">
                <option value="1">营业</option>
                <option value="2">停业</option>
                <option value="0">下线</option>
              </select>
            </label>

            <label class="field field--full">
              <span>地址</span>
              <input v-model="form.address" type="text" placeholder="请填写完整地址" />
            </label>

            <label class="field">
              <span>纬度</span>
              <input v-model="form.latitude" type="number" min="-90" max="90" step="0.000001" placeholder="例如 31.230416" />
            </label>

            <label class="field">
              <span>经度</span>
              <input v-model="form.longitude" type="number" min="-180" max="180" step="0.000001" placeholder="例如 121.473701" />
            </label>

            <label class="field">
              <span>综合评分</span>
              <input v-model="form.score" type="number" min="0" step="0.1" />
            </label>

            <label class="field">
              <span>口味</span>
              <input v-model="form.tasteScore" type="number" min="0" step="0.1" />
            </label>

            <label class="field">
              <span>环境</span>
              <input v-model="form.envScore" type="number" min="0" step="0.1" />
            </label>

            <label class="field">
              <span>服务</span>
              <input v-model="form.serviceScore" type="number" min="0" step="0.1" />
            </label>

            <label class="field field--full">
              <span>标签</span>
              <input v-model="form.tags" type="text" placeholder="火锅, 聚餐, 夜宵" />
            </label>

            <label class="field field--full">
              <span>摘要</span>
              <textarea
                v-model="form.summary"
                rows="4"
                placeholder="写清楚门店亮点，不要满屏废话。"
              />
            </label>
          </div>

          <div class="toggle-grid">
            <label class="toggle-card">
              <input v-model="form.hasDeal" type="checkbox" />
              <span>当前有优惠 / 团购</span>
            </label>
            <label class="toggle-card">
              <input v-model="form.openNow" type="checkbox" />
              <span>当前展示为营业中</span>
            </label>
          </div>

          <div class="image-preview">
            <img :src="coverPreviewUrl" :alt="form.name || '门店封面预览'" />
            <div class="image-preview__body">
              <strong>{{ form.name || '门店封面预览' }}</strong>
              <p>{{ form.address || '地址还没填，别急着说自己上线了。' }}</p>
              <span>{{ form.businessHours || '营业时间待填' }}</span>
            </div>
          </div>

          <div class="meta-grid">
            <div>
              <span>创建时间</span>
              <strong>{{ selectedDetail?.createdAt ?? '--' }}</strong>
            </div>
            <div>
              <span>更新时间</span>
              <strong>{{ selectedDetail?.updatedAt ?? '--' }}</strong>
            </div>
          </div>

          <div class="form-actions">
            <button type="button" class="ghost-button" @click="openCreateForm">重置表单</button>
            <button type="submit" class="primary-button" :disabled="saving">
              {{ saving ? '保存中...' : selectedShopId ? '保存修改' : '创建门店' }}
            </button>
          </div>

          <p class="inline-note">
            现成演示商户 ID：`CN` 可用 `1001 / 1002`，`EU` 可用 `2001 / 2002`。
          </p>
        </form>
      </section>
    </div>
  </section>
</template>
