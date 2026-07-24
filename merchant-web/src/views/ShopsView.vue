<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import {
  createNewShopDraft,
  createUpdateShopDraft,
  fetchAreas,
  fetchCategories,
  fetchCities,
  fetchShopChange,
  fetchShopChanges,
  fetchShops,
  saveShopChange,
  saveShopChangeDishes,
  saveShopChangePhotos,
  submitShopChange,
  type GeoArea,
  type GeoCategoryNode,
  type GeoCity,
  type MerchantShopChange,
  type MerchantShopChangeDish,
  type MerchantShopChangePayload,
  type MerchantShopChangePhoto,
  type MerchantShopOption,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const notice = ref('')
const shops = ref<Array<MerchantShopOption & Record<string, unknown>>>([])
const drafts = ref<MerchantShopChange[]>([])
const categories = ref<GeoCategoryNode[]>([])
const cities = ref<GeoCity[]>([])
const areas = ref<GeoArea[]>([])
const editorOpen = ref(false)
const activeDraft = ref<MerchantShopChange | null>(null)
const canEdit = computed(() => props.permissions.includes('shop:edit'))
const defaultCurrency = computed(() => (state.region === 'EU' ? 'EUR' : 'CNY'))
const flatCategories = computed(() => flattenCategories(categories.value))

const form = reactive({
  categoryId: '',
  cityId: '',
  areaId: '',
  name: '',
  coverUrl: '',
  phone: '',
  pricePerCapita: '',
  currency: defaultCurrency.value,
  address: '',
  latitude: '',
  longitude: '',
  businessHours: '',
  summary: '',
  openNow: true,
  tagsText: '',
  photos: [{ imageUrl: '', photoType: '1', sort: '1' }] as Array<{ imageUrl: string; photoType: string; sort: string }>,
  dishes: [{ name: '', price: '', recommendReason: '', sort: '1' }] as Array<{
    name: string
    price: string
    recommendReason: string
    sort: string
  }>,
})

defineExpose({
  form,
  submit,
  saveAll,
  activeDraft,
})

function flattenCategories(nodes: GeoCategoryNode[], prefix = ''): Array<{ id: number; name: string }> {
  const result: Array<{ id: number; name: string }> = []
  for (const node of nodes) {
    const label = prefix ? `${prefix} / ${node.name}` : node.name
    if (node.children?.length) {
      result.push(...flattenCategories(node.children, label))
    } else {
      result.push({ id: node.id, name: label })
    }
  }
  return result
}

function fillForm(draft: MerchantShopChange) {
  activeDraft.value = draft
  form.categoryId = draft.categoryId ? String(draft.categoryId) : ''
  form.cityId = draft.cityId ? String(draft.cityId) : ''
  form.areaId = draft.areaId ? String(draft.areaId) : ''
  form.name = draft.name || ''
  form.coverUrl = draft.coverUrl || ''
  form.phone = draft.phone || ''
  form.pricePerCapita = draft.pricePerCapita != null ? String(draft.pricePerCapita) : ''
  form.currency = draft.currency || defaultCurrency.value
  form.address = draft.address || ''
  form.latitude = draft.latitude != null ? String(draft.latitude) : ''
  form.longitude = draft.longitude != null ? String(draft.longitude) : ''
  form.businessHours = draft.businessHours || ''
  form.summary = draft.summary || ''
  form.openNow = draft.openNow !== false
  form.tagsText = (draft.tags ?? []).join(',')
  form.photos = (draft.photos?.length ? draft.photos : [{ imageUrl: draft.coverUrl || '', photoType: 1, sort: 1 }]).map(
    (photo: MerchantShopChangePhoto, index: number) => ({
      imageUrl: photo.imageUrl || '',
      photoType: String(photo.photoType ?? 1),
      sort: String(photo.sort ?? index + 1),
    }),
  )
  form.dishes = (draft.dishes?.length ? draft.dishes : [{ name: '', price: 0, recommendReason: '', sort: 1 }]).map(
    (dish: MerchantShopChangeDish, index: number) => ({
      name: dish.name || '',
      price: String(dish.price ?? ''),
      recommendReason: dish.recommendReason || '',
      sort: String(dish.sort ?? index + 1),
    }),
  )
}

async function loadAreas(cityId: number) {
  if (!cityId) {
    areas.value = []
    return
  }
  areas.value = await fetchAreas(cityId)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [shopPage, draftPage, categoryList, cityList] = await Promise.all([
      fetchShops({ page: 1, pageSize: 50 }),
      fetchShopChanges({ page: 1, pageSize: 50 }),
      fetchCategories(),
      fetchCities(),
    ])
    shops.value = shopPage.list
    drafts.value = draftPage.list
    categories.value = categoryList
    cities.value = cityList
    if (form.cityId) {
      await loadAreas(Number(form.cityId))
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '门店数据加载失败'
  } finally {
    loading.value = false
  }
}

async function openDraft(draftId: number) {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const detail = await fetchShopChange(draftId)
    fillForm(detail)
    if (detail.cityId) {
      await loadAreas(detail.cityId)
    }
    editorOpen.value = true
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '草稿加载失败'
  } finally {
    saving.value = false
  }
}

async function createNewDraft() {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const draft = await createNewShopDraft()
    fillForm(draft)
    editorOpen.value = true
    notice.value = '新门店草稿已创建'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '创建草稿失败'
  } finally {
    saving.value = false
  }
}

async function createShopDraft(shopId: number) {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const draft = await createUpdateShopDraft(shopId)
    fillForm(draft)
    if (draft.cityId) {
      await loadAreas(draft.cityId)
    }
    editorOpen.value = true
    notice.value = draft.status === 0 ? '已打开门店修改草稿' : `当前草稿状态：${draft.statusText || draft.status}`
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '创建修改草稿失败'
  } finally {
    saving.value = false
  }
}

function addPhoto() {
  form.photos.push({ imageUrl: '', photoType: '2', sort: String(form.photos.length + 1) })
}
function removePhoto(index: number) {
  if (form.photos.length <= 1) return
  form.photos.splice(index, 1)
}
function addDish() {
  form.dishes.push({ name: '', price: '', recommendReason: '', sort: String(form.dishes.length + 1) })
}
function removeDish(index: number) {
  form.dishes.splice(index, 1)
}

function buildBasePayload(): MerchantShopChangePayload {
  const categoryId = Number(form.categoryId)
  const cityId = Number(form.cityId)
  const areaId = Number(form.areaId)
  const pricePerCapita = Number(form.pricePerCapita)
  if (!Number.isFinite(categoryId) || categoryId <= 0) throw new Error('请选择分类')
  if (!Number.isFinite(cityId) || cityId <= 0) throw new Error('请选择城市')
  if (!Number.isFinite(areaId) || areaId <= 0) throw new Error('请选择商圈')
  if (!form.name.trim()) throw new Error('请填写门店名称')
  if (!form.coverUrl.trim()) throw new Error('请填写封面图 URL')
  if (!Number.isFinite(pricePerCapita) || pricePerCapita < 0) throw new Error('人均价格无效')
  if (!form.address.trim()) throw new Error('请填写地址')
  if (!form.businessHours.trim()) throw new Error('请填写营业时间')
  if (!form.summary.trim()) throw new Error('请填写门店简介')
  const latitude = form.latitude.trim() ? Number(form.latitude) : null
  const longitude = form.longitude.trim() ? Number(form.longitude) : null
  if (latitude != null && !Number.isFinite(latitude)) throw new Error('纬度无效')
  if (longitude != null && !Number.isFinite(longitude)) throw new Error('经度无效')
  return {
    categoryId,
    cityId,
    areaId,
    name: form.name.trim(),
    coverUrl: form.coverUrl.trim(),
    phone: form.phone.trim(),
    pricePerCapita,
    currency: form.currency.trim().toUpperCase() || defaultCurrency.value,
    address: form.address.trim(),
    latitude,
    longitude,
    businessHours: form.businessHours.trim(),
    summary: form.summary.trim(),
    openNow: form.openNow,
    tags: form.tagsText
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean),
  }
}

function buildPhotos(): MerchantShopChangePhoto[] {
  const photos = form.photos.map((photo, index) => {
    if (!photo.imageUrl.trim()) throw new Error(`第 ${index + 1} 张图片地址不能为空`)
    return {
      imageUrl: photo.imageUrl.trim(),
      photoType: Number(photo.photoType) || 1,
      sort: Number(photo.sort) || index + 1,
    }
  })
  if (!photos.length) throw new Error('至少上传 1 张门店图片')
  if (!photos.some((photo) => photo.photoType === 1 && photo.imageUrl === form.coverUrl.trim())) {
    throw new Error('封面图必须同时出现在相册中，且 photoType=1')
  }
  return photos
}

function buildDishes(): MerchantShopChangeDish[] {
  return form.dishes
    .filter((dish) => dish.name.trim() || dish.price.trim())
    .map((dish, index) => {
      const price = Number(dish.price)
      if (!dish.name.trim()) throw new Error(`第 ${index + 1} 个菜品名称不能为空`)
      if (!Number.isFinite(price) || price < 0) throw new Error(`第 ${index + 1} 个菜品价格无效`)
      return {
        name: dish.name.trim(),
        price,
        recommendReason: dish.recommendReason.trim(),
        sort: Number(dish.sort) || index + 1,
      }
    })
}

async function persistDraft() {
  if (!activeDraft.value) throw new Error('没有可保存的草稿')
  const base = buildBasePayload()
  const photos = buildPhotos()
  const dishes = buildDishes()
  await saveShopChange(activeDraft.value.id, base)
  await saveShopChangePhotos(activeDraft.value.id, photos)
  const saved = await saveShopChangeDishes(activeDraft.value.id, dishes)
  fillForm(saved)
  return saved
}

async function saveAll() {
  if (!canEdit.value || !activeDraft.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    await persistDraft()
    notice.value = '草稿已保存（基础资料 / 相册 / 菜单）'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '草稿保存失败'
  } finally {
    saving.value = false
  }
}

async function submit() {
  if (!canEdit.value || !activeDraft.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    await persistDraft()
    const submitted = await submitShopChange(activeDraft.value.id)
    fillForm(submitted)
    notice.value = '门店变更已提交审核，审核通过前不会改动线上门店'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '提交审核失败'
  } finally {
    saving.value = false
  }
}

watch(
  () => form.cityId,
  async (value, oldValue) => {
    if (value === oldValue) return
    const cityId = Number(value)
    if (!Number.isFinite(cityId) || cityId <= 0) {
      areas.value = []
      form.areaId = ''
      return
    }
    const keepArea = form.areaId
    try {
      await loadAreas(cityId)
      if (!areas.value.some((area) => String(area.id) === keepArea)) {
        form.areaId = ''
      }
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : '商圈加载失败'
    }
  },
)

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">Shop drafts</p>
        <strong>门店与草稿审核</strong>
        <p class="muted">先建草稿，再改基础资料/相册/菜单；提交审核前线上门店数据不会变。</p>
      </div>
      <div class="row-actions">
        <button type="button" class="secondary-action" @click="load">刷新</button>
        <button v-if="canEdit" type="button" class="primary-action" data-testid="shop-draft-create-new" :disabled="saving" @click="createNewDraft">
          新建门店草稿
        </button>
      </div>
    </div>

    <p v-if="!canEdit" class="error" role="alert">当前账号缺少 `shop:edit` 权限，只能查看线上门店。</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text">{{ notice }}</p>
    <p v-if="loading" class="muted">加载中...</p>

    <div v-if="!loading" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>门店</th>
            <th>区域</th>
            <th>城市</th>
            <th>评分</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in shops" :key="String(item.id)">
            <td>{{ item.name }}</td>
            <td>{{ item.region }}</td>
            <td>{{ item.cityName ?? '-' }}</td>
            <td>{{ item.score ?? '-' }}</td>
            <td>{{ item.statusText ?? item.status }}</td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                class="secondary-action"
                :data-testid="`shop-draft-from-${item.id}`"
                :disabled="saving"
                @click="createShopDraft(Number(item.id))"
              >
                修改草稿
              </button>
              <span v-else class="muted">只读</span>
            </td>
          </tr>
          <tr v-if="shops.length === 0">
            <td colspan="6" class="feedback">当前还没有线上门店，可先新建门店草稿。</td>
          </tr>
        </tbody>
      </table>
    </div>

    <article v-if="drafts.length" class="card table-wrap" style="margin-top: 18px">
      <div class="toolbar">
        <strong>草稿列表</strong>
      </div>
      <table class="table">
        <thead>
          <tr>
            <th>草稿</th>
            <th>类型</th>
            <th>目标门店</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="draft in drafts" :key="draft.id">
            <td>
              <strong>{{ draft.name || `草稿 #${draft.id}` }}</strong>
              <span class="table-subtext">#{{ draft.id }}</span>
            </td>
            <td>{{ draft.changeType === 1 ? '新门店' : '修改门店' }}</td>
            <td>{{ draft.targetShopId || '-' }}</td>
            <td>
              {{ draft.statusText || draft.status }}
              <span v-if="draft.rejectReason" class="table-subtext">驳回：{{ draft.rejectReason }}</span>
            </td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                class="secondary-action"
                :data-testid="`shop-draft-open-${draft.id}`"
                :disabled="saving"
                @click="openDraft(draft.id)"
              >
                打开
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </article>

    <article v-if="editorOpen && activeDraft" class="card deal-form-card" data-testid="shop-draft-editor" style="margin-top: 18px">
      <div class="toolbar">
        <div>
          <h3>编辑草稿 #{{ activeDraft.id }}</h3>
          <p class="muted">
            {{ activeDraft.changeType === 1 ? '新门店草稿' : `修改门店 #${activeDraft.targetShopId}` }}
            · {{ activeDraft.statusText || activeDraft.status }}
          </p>
        </div>
        <button type="button" class="secondary-action" @click="editorOpen = false">收起编辑器</button>
      </div>

      <form class="form-grid deal-form" @submit.prevent="saveAll">
        <label>
          <span>分类</span>
          <select v-model="form.categoryId" name="shop-category-id" data-testid="shop-category-id">
            <option value="">请选择分类</option>
            <option v-for="item in flatCategories" :key="item.id" :value="String(item.id)">{{ item.name }}</option>
          </select>
        </label>
        <label>
          <span>城市</span>
          <select v-model="form.cityId" name="shop-city-id" data-testid="shop-city-id">
            <option value="">请选择城市</option>
            <option v-for="city in cities" :key="city.id" :value="String(city.id)">{{ city.name }}</option>
          </select>
        </label>
        <label>
          <span>商圈</span>
          <select v-model="form.areaId" name="shop-area-id" data-testid="shop-area-id">
            <option value="">请选择商圈</option>
            <option v-for="area in areas" :key="area.id" :value="String(area.id)">{{ area.name }}</option>
          </select>
        </label>
        <label>
          <span>营业状态</span>
          <select v-model="form.openNow" name="shop-open-now">
            <option :value="true">营业中</option>
            <option :value="false">休息中</option>
          </select>
        </label>
        <label class="full-span">
          <span>门店名称</span>
          <input v-model="form.name" name="shop-name" data-testid="shop-name" maxlength="128" />
        </label>
        <label class="full-span">
          <span>封面图 URL</span>
          <input v-model="form.coverUrl" name="shop-cover-url" data-testid="shop-cover-url" maxlength="255" />
        </label>
        <label>
          <span>电话</span>
          <input v-model="form.phone" name="shop-phone" maxlength="64" />
        </label>
        <label>
          <span>人均价格</span>
          <input v-model="form.pricePerCapita" name="shop-price" data-testid="shop-price" inputmode="decimal" />
        </label>
        <label>
          <span>币种</span>
          <input v-model="form.currency" name="shop-currency" maxlength="3" />
        </label>
        <label>
          <span>营业时间</span>
          <input v-model="form.businessHours" name="shop-hours" data-testid="shop-hours" maxlength="128" />
        </label>
        <label class="full-span">
          <span>地址</span>
          <input v-model="form.address" name="shop-address" data-testid="shop-address" maxlength="255" />
        </label>
        <label>
          <span>纬度</span>
          <input v-model="form.latitude" name="shop-latitude" inputmode="decimal" />
        </label>
        <label>
          <span>经度</span>
          <input v-model="form.longitude" name="shop-longitude" inputmode="decimal" />
        </label>
        <label class="full-span">
          <span>标签（逗号分隔）</span>
          <input v-model="form.tagsText" name="shop-tags" data-testid="shop-tags" placeholder="Chinese,Spicy" />
        </label>
        <label class="full-span">
          <span>简介</span>
          <textarea v-model="form.summary" name="shop-summary" data-testid="shop-summary" rows="3" maxlength="255" />
        </label>

        <div class="full-span deal-items">
          <div class="toolbar">
            <strong>相册（1-20，封面必须 photoType=1）</strong>
            <button type="button" class="secondary-action" data-testid="shop-photo-add" @click="addPhoto">添加图片</button>
          </div>
          <div v-for="(photo, index) in form.photos" :key="`photo-${index}`" class="deal-item-row">
            <input v-model="photo.imageUrl" :name="`shop-photo-url-${index}`" :data-testid="`shop-photo-url-${index}`" placeholder="图片 URL" />
            <select v-model="photo.photoType" :name="`shop-photo-type-${index}`">
              <option value="1">封面</option>
              <option value="2">环境</option>
              <option value="3">菜品</option>
            </select>
            <input v-model="photo.sort" :name="`shop-photo-sort-${index}`" inputmode="numeric" placeholder="排序" />
            <button type="button" class="danger-action" :disabled="form.photos.length <= 1" @click="removePhoto(index)">删除</button>
          </div>
        </div>

        <div class="full-span deal-items">
          <div class="toolbar">
            <strong>菜单（最多 100）</strong>
            <button type="button" class="secondary-action" data-testid="shop-dish-add" @click="addDish">添加菜品</button>
          </div>
          <div v-for="(dish, index) in form.dishes" :key="`dish-${index}`" class="deal-item-row">
            <input v-model="dish.name" :name="`shop-dish-name-${index}`" :data-testid="`shop-dish-name-${index}`" placeholder="菜品名" />
            <input v-model="dish.price" :name="`shop-dish-price-${index}`" :data-testid="`shop-dish-price-${index}`" inputmode="decimal" placeholder="价格" />
            <input v-model="dish.recommendReason" :name="`shop-dish-reason-${index}`" placeholder="推荐理由" />
            <input v-model="dish.sort" :name="`shop-dish-sort-${index}`" inputmode="numeric" placeholder="排序" />
            <button type="button" class="danger-action" @click="removeDish(index)">删除</button>
          </div>
        </div>

        <div class="full-span row-actions">
          <button type="submit" class="primary-action" data-testid="shop-draft-save" :disabled="saving">
            {{ saving ? '保存中...' : '保存草稿' }}
          </button>
          <button type="button" class="primary-action" data-testid="shop-draft-submit" :disabled="saving" @click="submit">
            提交审核
          </button>
          <button type="button" class="secondary-action" :disabled="saving" @click="editorOpen = false">取消</button>
        </div>
      </form>
    </article>
  </section>
</template>
