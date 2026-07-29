<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
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
const strings = computed(() => merchantStringsForRegion(state.region))
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
const filterOptions = computed(() => [
  { value: 'pending_or_rejected', label: strings.value.deals.filterOptions.pendingOrRejected },
  { value: '', label: strings.value.deals.filterOptions.all },
  { value: '0', label: strings.value.deals.filterOptions.pending },
  { value: '1', label: strings.value.deals.filterOptions.approved },
  { value: '2', label: strings.value.deals.filterOptions.rejected },
])
const editingItem = computed(() => items.value.find((item) => item.id === editingId.value) ?? null)
const filters = reactive({
  auditStatus: 'pending_or_rejected',
})

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
    error.value = cause instanceof Error ? cause.message : strings.value.deals.detailLoadError
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
  if (!Number.isFinite(shopId) || shopId <= 0) throw new Error(strings.value.deals.validations.shopRequired)
  if (!form.title.trim()) throw new Error(strings.value.deals.validations.titleRequired)
  if (!form.coverImage.trim()) throw new Error(strings.value.deals.validations.coverImageRequired)
  if (!Number.isFinite(price) || price <= 0) throw new Error(strings.value.deals.validations.pricePositive)
  if (!Number.isFinite(originalPrice) || originalPrice <= 0) throw new Error(strings.value.deals.validations.originalPricePositive)
  if (!Number.isFinite(stock) || stock < -1) throw new Error(strings.value.deals.validations.stockMin)
  const itemsPayload = form.items.map((item, index) => {
    const quantity = Number(item.quantity)
    const itemPrice = Number(item.price)
    const sort = Number(item.sort)
    if (!item.name.trim()) throw new Error(strings.value.deals.validations.itemNameRequired(index + 1))
    if (!Number.isFinite(quantity) || quantity < 1) throw new Error(strings.value.deals.validations.itemQuantityInvalid(index + 1))
    if (!Number.isFinite(itemPrice) || itemPrice < 0) throw new Error(strings.value.deals.validations.itemPriceInvalid(index + 1))
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
      fetchDeals({
        page: 1,
        pageSize: 50,
        auditStatus:
          filters.auditStatus === 'pending_or_rejected' || filters.auditStatus === ''
            ? undefined
            : Number(filters.auditStatus),
      }),
      fetchShops({ page: 1, pageSize: 100 }),
    ])
    const list = dealPage.list
    items.value =
      filters.auditStatus === 'pending_or_rejected'
        ? list.filter((item) => item.auditStatus === 0 || item.auditStatus === 2)
        : list
    shops.value = shopPage.list.map((shop) => ({ id: Number(shop.id), name: String(shop.name || `shop:${shop.id}`) }))
    if (!form.shopId && shops.value[0]) {
      form.shopId = String(shops.value[0].id)
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.deals.loadError
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
      notice.value = strings.value.deals.createNotice
    } else {
      await updateDeal(editingId.value, payload)
      notice.value = strings.value.deals.updateNotice
    }
    formOpen.value = false
    resetForm()
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.deals.saveError
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
    notice.value = item.status === 1 ? strings.value.deals.disabledNotice : strings.value.deals.enabledNotice
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.deals.toggleError
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <div>
        <p class="eyebrow">{{ strings.deals.eyebrow }}</p>
        <strong>{{ strings.deals.heading }}</strong>
        <p class="muted">{{ strings.deals.description }}</p>
      </div>
      <div class="row-actions">
        <label>
          <span class="muted">{{ strings.deals.filterLabel }}</span>
          <select
            v-model="filters.auditStatus"
            name="deal-audit-status-filter"
            data-testid="deal-audit-status-filter"
            @change="load"
          >
            <option v-for="option in filterOptions" :key="option.value || 'all'" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
        <button type="button" class="secondary-action" @click="load">{{ strings.common.refresh }}</button>
        <button v-if="canEdit" type="button" class="primary-action" data-testid="deal-create-open" @click="openCreate">
          {{ strings.deals.create }}
        </button>
      </div>
    </div>

    <p v-if="!canEdit" class="error" role="alert">{{ strings.deals.missingPermission('deal:edit') }}</p>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="notice" class="success-text">{{ notice }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>

    <article v-if="formOpen" class="card deal-form-card" data-testid="deal-form">
      <h3>{{ editingId == null ? strings.deals.formTitles.create : strings.deals.formTitles.edit(editingId) }}</h3>
      <p
        v-if="editingItem?.auditStatus === 2"
        class="error"
        data-testid="deal-form-reject-reason"
      >
        {{ strings.deals.rejectReasonSummary(editingItem?.rejectReason || strings.deals.missingRejectReason) }}
      </p>
      <form class="form-grid deal-form" @submit.prevent="save">
        <label>
          <span>{{ strings.deals.labels.shop }}</span>
          <select v-model="form.shopId" name="deal-shop-id" data-testid="deal-shop-id">
            <option value="">{{ strings.deals.placeholders.selectShop }}</option>
            <option v-for="shop in shops" :key="shop.id" :value="String(shop.id)">{{ shop.name }}</option>
          </select>
        </label>
        <label>
          <span>{{ strings.deals.labels.type }}</span>
          <select v-model="form.type" name="deal-type">
            <option value="1">{{ strings.deals.typeOptions.packageDeal }}</option>
            <option value="2">{{ strings.deals.typeOptions.voucher }}</option>
          </select>
        </label>
        <label class="full-span">
          <span>{{ strings.deals.labels.title }}</span>
          <input
            v-model="form.title"
            name="deal-title"
            data-testid="deal-title"
            maxlength="128"
            :placeholder="strings.deals.placeholders.title"
          />
        </label>
        <label class="full-span">
          <span>{{ strings.deals.labels.coverImage }}</span>
          <input v-model="form.coverImage" name="deal-cover" maxlength="255" placeholder="https://..." />
        </label>
        <label>
          <span>{{ strings.deals.labels.price }}</span>
          <input v-model="form.price" name="deal-price" data-testid="deal-price" inputmode="decimal" />
        </label>
        <label>
          <span>{{ strings.deals.labels.originalPrice }}</span>
          <input v-model="form.originalPrice" name="deal-original-price" data-testid="deal-original-price" inputmode="decimal" />
        </label>
        <label>
          <span>{{ strings.deals.labels.currency }}</span>
          <input v-model="form.currency" name="deal-currency" maxlength="3" />
        </label>
        <label>
          <span>{{ strings.deals.labels.stock }}</span>
          <input v-model="form.stock" name="deal-stock" inputmode="numeric" />
        </label>
        <label>
          <span>{{ strings.deals.labels.validStart }}</span>
          <input v-model="form.validStart" name="deal-valid-start" type="date" />
        </label>
        <label>
          <span>{{ strings.deals.labels.validEnd }}</span>
          <input v-model="form.validEnd" name="deal-valid-end" type="date" />
        </label>
        <label class="full-span">
          <span>{{ strings.deals.labels.rules }}</span>
          <textarea
            v-model="form.rules"
            name="deal-rules"
            rows="3"
            maxlength="2000"
            :placeholder="strings.deals.placeholders.rules"
          />
        </label>

        <div class="full-span deal-items">
          <div class="toolbar">
            <strong>{{ strings.deals.itemSectionHeading }}</strong>
            <button type="button" class="secondary-action" data-testid="deal-item-add" @click="addItem">
              {{ strings.deals.addItem }}
            </button>
          </div>
          <div v-for="(item, index) in form.items" :key="index" class="deal-item-row">
            <input
              v-model="item.name"
              :name="`deal-item-name-${index}`"
              :data-testid="`deal-item-name-${index}`"
              :placeholder="strings.deals.placeholders.itemName"
            />
            <input
              v-model="item.quantity"
              :name="`deal-item-quantity-${index}`"
              inputmode="numeric"
              :placeholder="strings.deals.placeholders.itemQuantity"
            />
            <input
              v-model="item.price"
              :name="`deal-item-price-${index}`"
              inputmode="decimal"
              :placeholder="strings.deals.placeholders.itemPrice"
            />
            <input
              v-model="item.sort"
              :name="`deal-item-sort-${index}`"
              inputmode="numeric"
              :placeholder="strings.deals.placeholders.itemSort"
            />
            <button type="button" class="danger-action" :disabled="form.items.length <= 1" @click="removeItem(index)">
              {{ strings.deals.deleteItem }}
            </button>
          </div>
        </div>

        <div class="full-span row-actions">
          <button type="submit" class="primary-action" data-testid="deal-save" :disabled="saving">
            {{ saving ? strings.deals.submitting : editingId == null ? strings.deals.submitCreate : strings.deals.submitUpdate }}
          </button>
          <button type="button" class="secondary-action" :disabled="saving" @click="formOpen = false">
            {{ strings.common.cancel }}
          </button>
        </div>
      </form>
    </article>

    <div v-if="!loading" class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.deals.tableHeaders.deal }}</th>
            <th>{{ strings.deals.tableHeaders.shop }}</th>
            <th>{{ strings.deals.tableHeaders.price }}</th>
            <th>{{ strings.deals.tableHeaders.audit }}</th>
            <th>{{ strings.deals.tableHeaders.availability }}</th>
            <th>{{ strings.deals.tableHeaders.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>
              <strong>{{ item.title }}</strong>
              <span class="table-subtext">{{ strings.deals.stockSummary(item.stock, item.soldCount ?? 0) }}</span>
            </td>
            <td>{{ item.shopName || `shop:${item.shopId}` }}</td>
            <td>{{ item.price }} {{ item.currency }}</td>
            <td>
              <div>{{ strings.deals.auditStatusText(item.auditStatus, item.auditStatusText) }}</div>
              <span
                v-if="item.auditStatus === 2 && item.rejectReason"
                class="table-subtext"
                :data-testid="`deal-reject-reason-${item.id}`"
              >
                {{ strings.deals.rejectReasonLabel }}{{ item.rejectReason }}
              </span>
            </td>
            <td>
              <button
                v-if="canEdit"
                type="button"
                :data-testid="`deal-toggle-${item.id}`"
                @click="toggle(item)"
              >
                {{ item.status === 1 ? strings.deals.takeDown : strings.deals.goLive }}
              </button>
              <span v-else class="muted">{{ strings.deals.liveStatusText(item.status, item.statusText) }}</span>
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
                {{ strings.deals.edit }}
              </button>
              <span v-else class="muted">{{ strings.deals.readOnly }}</span>
            </td>
          </tr>
          <tr v-if="items.length === 0">
            <td colspan="6" class="feedback">{{ strings.deals.empty }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
