<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import {
  createDeal,
  fetchDeal,
  fetchDeals,
  fetchShops,
  updateDeal,
  updateDealStatus,
  type MerchantDeal,
  type MerchantDealItem,
  type MerchantDealPayload,
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
const items = ref<MerchantDeal[]>([])
const shops = ref<MerchantShopOption[]>([])
const editingId = ref<number | null>(null)
const formOpen = ref(false)
const canEdit = computed(() => props.permissions.includes('deal:edit'))
const defaultCurrency = computed(() => (state.region === 'EU' ? 'EUR' : 'CNY'))

const form = reactive({
  shopId: '',
  type: '1',
  title: '',
  coverImage: '',
  price: '',
  originalPrice: '',
  currency: defaultCurrency.value,
  stock: '20',
  validStart: '',
  validEnd: '',
  rules: '',
  items: [{ name: '', quantity: '1', price: '', sort: '1' }] as Array<{
    name: string
    quantity: string
    price: string
    sort: string
  }>,
})

function resetForm() {
  editingId.value = null
  form.shopId = shops.value[0] ? String(shops.value[0].id) : ''
  form.type = '1'
  form.title = ''
  form.coverImage = 'https://placehold.co/1200x720/f97316/ffffff?text=Deal'
  form.price = ''
  form.originalPrice = ''
  form.currency = defaultCurrency.value
  form.stock = '20'
  form.validStart = ''
  form.validEnd = ''
  form.rules = ''
  form.items = [{ name: '', quantity: '1', price: '', sort: '1' }]
}

function openCreate() {
  if (!canEdit.value) return
  resetForm()
  formOpen.value = true
  error.value = ''
  notice.value = ''
}

async function openEdit(deal: MerchantDeal) {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const detail = await fetchDeal(deal.id)
    editingId.value = detail.id
    form.shopId = String(detail.shopId)
    form.type = String(detail.type || 1)
    form.title = detail.title || ''
    form.coverImage = detail.coverImage || ''
    form.price = String(detail.price ?? '')
    form.originalPrice = String(detail.originalPrice ?? '')
    form.currency = detail.currency || defaultCurrency.value
    form.stock = String(detail.stock ?? 0)
    form.validStart = detail.validStart || ''
    form.validEnd = detail.validEnd || ''
    form.rules = detail.rules || ''
    form.items = (detail.items?.length ? detail.items : [{ name: '', quantity: 1, price: 0, sort: 1 }]).map(
      (item: MerchantDealItem, index: number) => ({
        name: item.name || '',
        quantity: String(item.quantity ?? 1),
        price: String(item.price ?? 0),
        sort: String(item.sort ?? index + 1),
      }),
    )
    formOpen.value = true
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '团购详情加载失败'
  } finally {
    saving.value = false
  }
}

function addItem() {
  form.items.push({
    name: '',
    quantity: '1',
    price: '',
    sort: String(form.items.length + 1),
  })
}

function removeItem(index: number) {
  if (form.items.length <= 1) return
  form.items.splice(index, 1)
}

function buildPayload(): MerchantDealPayload {
  const shopId = Number(form.shopId)
  const price = Number(form.price)
  const originalPrice = Number(form.originalPrice)
  const stock = Number(form.stock)
  if (!Number.isFinite(shopId) || shopId <= 0) throw new Error('请选择门店')
  if (!form.title.trim()) throw new Error('请填写团购标题')
  if (!form.coverImage.trim()) throw new Error('请填写封面图 URL')
  if (!Number.isFinite(price) || price <= 0) throw new Error('售价必须大于 0')
  if (!Number.isFinite(originalPrice) || originalPrice <= 0) throw new Error('原价必须大于 0')
  if (!Number.isFinite(stock) || stock < -1) throw new Error('库存不能小于 -1')
  const itemsPayload = form.items.map((item, index) => {
    const quantity = Number(item.quantity)
    const itemPrice = Number(item.price)
    const sort = Number(item.sort)
    if (!item.name.trim()) throw new Error(`第 ${index + 1} 个套餐项名称不能为空`)
    if (!Number.isFinite(quantity) || quantity < 1) throw new Error(`第 ${index + 1} 个套餐项数量无效`)
    if (!Number.isFinite(itemPrice) || itemPrice < 0) throw new Error(`第 ${index + 1} 个套餐项价格无效`)
    return {
      name: item.name.trim(),
      quantity,
      price: itemPrice,
      sort: Number.isFinite(sort) ? sort : index + 1,
    }
  })
  return {
    shopId,
    type: Number(form.type) === 2 ? 2 : 1,
    title: form.title.trim(),
    coverImage: form.coverImage.trim(),
    price,
    originalPrice,
    currency: form.currency.trim().toUpperCase(),
    stock,
    validStart: form.validStart || null,
    validEnd: form.validEnd || null,
    rules: form.rules.trim(),
    items: itemsPayload,
  }
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [dealPage, shopPage] = await Promise.all([
      fetchDeals({ page: 1, pageSize: 50 }),
      fetchShops({ page: 1, pageSize: 100 }),
    ])
    items.value = dealPage.list
    shops.value = shopPage.list.map((shop) => ({ id: Number(shop.id), name: String(shop.name || `shop:${shop.id}`) }))
    if (!form.shopId && shops.value[0]) {
      form.shopId = String(shops.value[0].id)
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '团购加载失败'
  } finally {
    loading.value = false
  }
}

async function save() {
  if (!canEdit.value) return
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    const payload = buildPayload()
    if (editingId.value == null) {
      await createDeal(payload)
      notice.value = '团购已创建并提交审核'
    } else {
      await updateDeal(editingId.value, payload)
      notice.value = '团购已更新并重新提交审核'
    }
    formOpen.value = false
    resetForm()
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '团购保存失败'
  } finally {
    saving.value = false
  }
}

async function toggle(item: MerchantDeal) {
  if (!canEdit.value) return
  error.value = ''
  notice.value = ''
  try {
    await updateDealStatus(item.id, item.status === 1 ? 0 : 1)
    notice.value = item.status === 1 ? '团购已下架' : '团购已上架'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '上下架失败'
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">Deal management</p>
        <strong>团购创建与编辑</strong>
        <p class="muted">创建/编辑后会回到待审下架；审核通过后才能上架销售。</p>
      </div>
      <div class="row-actions">
        <button type="button" class="secondary-action" @click="load">刷新</button>
        <button v-if="canEdit" type="button" class="primary-action" data-testid="deal-create-open" @click="openCreate">
          新建团购
        </button>
      </div>
    </div>

    <p v-if="!canEdit" class="error" role="alert">当前账号缺少 `deal:edit` 权限，只能查看列表。</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text">{{ notice }}</p>
    <p v-if="loading" class="muted">加载中...</p>

    <article v-if="formOpen" class="card deal-form-card" data-testid="deal-form">
      <h3>{{ editingId == null ? '新建团购' : `编辑团购 #${editingId}` }}</h3>
      <form class="form-grid deal-form" @submit.prevent="save">
        <label>
          <span>门店</span>
          <select v-model="form.shopId" name="deal-shop-id" data-testid="deal-shop-id">
            <option value="">请选择门店</option>
            <option v-for="shop in shops" :key="shop.id" :value="String(shop.id)">{{ shop.name }}</option>
          </select>
        </label>
        <label>
          <span>类型</span>
          <select v-model="form.type" name="deal-type">
            <option value="1">团购套餐</option>
            <option value="2">代金券</option>
          </select>
        </label>
        <label class="full-span">
          <span>标题</span>
          <input v-model="form.title" name="deal-title" data-testid="deal-title" maxlength="128" placeholder="例如 双人午市套餐" />
        </label>
        <label class="full-span">
          <span>封面图 URL</span>
          <input v-model="form.coverImage" name="deal-cover" maxlength="255" placeholder="https://..." />
        </label>
        <label>
          <span>售价</span>
          <input v-model="form.price" name="deal-price" data-testid="deal-price" inputmode="decimal" />
        </label>
        <label>
          <span>原价</span>
          <input v-model="form.originalPrice" name="deal-original-price" data-testid="deal-original-price" inputmode="decimal" />
        </label>
        <label>
          <span>币种</span>
          <input v-model="form.currency" name="deal-currency" maxlength="3" />
        </label>
        <label>
          <span>库存（-1 不限）</span>
          <input v-model="form.stock" name="deal-stock" inputmode="numeric" />
        </label>
        <label>
          <span>有效开始</span>
          <input v-model="form.validStart" name="deal-valid-start" type="date" />
        </label>
        <label>
          <span>有效结束</span>
          <input v-model="form.validEnd" name="deal-valid-end" type="date" />
        </label>
        <label class="full-span">
          <span>使用规则</span>
          <textarea v-model="form.rules" name="deal-rules" rows="3" maxlength="2000" placeholder="周末通用；需提前预约..." />
        </label>

        <div class="full-span deal-items">
          <div class="toolbar">
            <strong>套餐明细</strong>
            <button type="button" class="secondary-action" data-testid="deal-item-add" @click="addItem">添加明细</button>
          </div>
          <div v-for="(item, index) in form.items" :key="index" class="deal-item-row">
            <input v-model="item.name" :name="`deal-item-name-${index}`" :data-testid="`deal-item-name-${index}`" placeholder="项目名称" />
            <input v-model="item.quantity" :name="`deal-item-quantity-${index}`" inputmode="numeric" placeholder="数量" />
            <input v-model="item.price" :name="`deal-item-price-${index}`" inputmode="decimal" placeholder="价格" />
            <input v-model="item.sort" :name="`deal-item-sort-${index}`" inputmode="numeric" placeholder="排序" />
            <button type="button" class="danger-action" :disabled="form.items.length <= 1" @click="removeItem(index)">删除</button>
          </div>
        </div>

        <div class="full-span row-actions">
          <button type="submit" class="primary-action" data-testid="deal-save" :disabled="saving">
            {{ saving ? '提交中...' : editingId == null ? '创建并提交审核' : '保存并重新提交' }}
          </button>
          <button type="button" class="secondary-action" :disabled="saving" @click="formOpen = false">取消</button>
        </div>
      </form>
    </article>

    <div v-if="!loading" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>套餐</th>
            <th>门店</th>
            <th>价格</th>
            <th>审核</th>
            <th>上下架</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>
              <strong>{{ item.title }}</strong>
              <span class="table-subtext">库存 {{ item.stock }} · 已售 {{ item.soldCount ?? 0 }}</span>
            </td>
            <td>{{ item.shopName || `shop:${item.shopId}` }}</td>
            <td>{{ item.price }} {{ item.currency }}</td>
            <td>{{ item.auditStatusText || item.auditStatus }}</td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                :data-testid="`deal-toggle-${item.id}`"
                @click="toggle(item)"
              >
                {{ item.status === 1 ? '下架' : '上架' }}
              </button>
              <span v-else class="muted">{{ item.statusText || item.status }}</span>
            </td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                class="secondary-action"
                :data-testid="`deal-edit-${item.id}`"
                :disabled="saving"
                @click="openEdit(item)"
              >
                编辑
              </button>
              <span v-else class="muted">只读</span>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td colspan="6" class="feedback">还没有团购，先建一个吧。</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
