<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import {
  createStaff,
  fetchRoles,
  fetchShops,
  fetchStaffs,
  updateStaff,
  updateStaffStatus,
  type MerchantRole,
  type MerchantShopOption,
  type MerchantStaff,
} from '@/services/merchant'

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const staffs = ref<MerchantStaff[]>([])
const roles = ref<MerchantRole[]>([])
const shops = ref<MerchantShopOption[]>([])
const editing = ref<MerchantStaff | null | undefined>(undefined)
const form = reactive({
  account: '', password: '', name: '', phone: '', email: '',
  roleIds: [] as number[], shopScopeType: 1 as 1 | 2, shopIds: [] as number[],
})

const selectableRoles = computed(() => roles.value.filter((role) => role.code !== 'owner'))

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [staffPage, rolePage, shopPage] = await Promise.all([
      fetchStaffs({ page: 1, pageSize: 20 }), fetchRoles(), fetchShops({ page: 1, pageSize: 50 }),
    ])
    staffs.value = staffPage.list
    roles.value = rolePage.list
    shops.value = shopPage.list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.staffManagement.loadError
  } finally {
    loading.value = false
  }
}

function openCreate() {
  editing.value = null
  Object.assign(form, { account: '', password: '', name: '', phone: '', email: '', roleIds: [], shopScopeType: 1, shopIds: [] })
  error.value = ''
}

function openEdit(staff: MerchantStaff) {
  editing.value = staff
  Object.assign(form, {
    account: staff.account, password: '', name: staff.name, phone: '', email: '',
    roleIds: staff.roles.map((role) => role.id), shopScopeType: staff.shopScopeType, shopIds: [...staff.shopIds],
  })
  error.value = ''
}

function closeEditor() {
  editing.value = undefined
  error.value = ''
}

async function save() {
  if (form.shopScopeType === 2 && form.shopIds.length === 0) {
    error.value = strings.value.staffManagement.scopedShopRequired
    return
  }
  if (form.roleIds.length === 0) {
    error.value = strings.value.staffManagement.roleRequired
    return
  }
  saving.value = true
  error.value = ''
  const payload = {
    name: form.name.trim(), phone: form.phone.trim(), email: form.email.trim(),
    roleIds: [...form.roleIds], shopScopeType: form.shopScopeType,
    shopIds: form.shopScopeType === 2 ? [...form.shopIds] : [],
  }
  try {
    if (editing.value) await updateStaff(editing.value.id, payload)
    else await createStaff({ ...payload, account: form.account.trim(), password: form.password })
    closeEditor()
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.staffManagement.saveError
  } finally {
    saving.value = false
  }
}

async function toggleStatus(staff: MerchantStaff) {
  error.value = ''
  try {
    await updateStaffStatus(staff.id, staff.status === 1 ? 2 : 1)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.staffManagement.statusError
  }
}

onMounted(load)
</script>

<template>
  <section class="staff-page">
    <div class="page-heading">
      <div>
        <p class="eyebrow">{{ strings.staffManagement.eyebrow }}</p>
        <h1>{{ strings.staffManagement.heading }}</h1>
        <p class="muted">{{ strings.staffManagement.description }}</p>
      </div>
      <button class="primary-action" type="button" @click="openCreate">{{ strings.staffManagement.create }}</button>
    </div>

    <p v-if="error && editing === undefined" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="card feedback">{{ strings.staffManagement.loading }}</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.staffManagement.tableHeaders.staff }}</th>
            <th>{{ strings.staffManagement.tableHeaders.roles }}</th>
            <th>{{ strings.staffManagement.tableHeaders.shopScope }}</th>
            <th>{{ strings.staffManagement.tableHeaders.status }}</th>
            <th>{{ strings.staffManagement.tableHeaders.actions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="staff in staffs" :key="staff.id">
            <td><strong>{{ staff.name }}</strong><span class="table-subtext">{{ staff.account }}</span></td>
            <td>{{ staff.roles.map((role) => role.name).join('、') }}</td>
            <td>
              {{
                staff.shopScopeType === 1
                  ? strings.staffManagement.allShops
                  : strings.staffManagement.scopedShops(staff.shopIds.length)
              }}
            </td>
            <td>
              <span class="status-pill" :class="staff.status === 1 ? 'status-1' : 'status-2'">
                {{ strings.staffManagement.statusText(staff.status) }}
              </span>
            </td>
            <td class="row-actions">
              <button type="button" class="secondary-action" @click="openEdit(staff)">
                {{ strings.staffManagement.edit }}
              </button>
              <button type="button" class="danger-action" @click="toggleStatus(staff)">
                {{ staff.status === 1 ? strings.staffManagement.disable : strings.staffManagement.enable }}
              </button>
            </td>
          </tr>
          <tr v-if="staffs.length === 0"><td colspan="5" class="feedback">{{ strings.staffManagement.empty }}</td></tr>
        </tbody>
      </table>
    </div>

    <div v-if="editing !== undefined" class="dialog-backdrop" @click.self="closeEditor">
      <form class="dialog-card" @submit.prevent="save">
        <div class="dialog-heading">
          <div>
            <p class="eyebrow">
              {{ editing ? strings.staffManagement.dialogEyebrow.edit : strings.staffManagement.dialogEyebrow.create }}
            </p>
            <h2>
              {{ editing ? strings.staffManagement.dialogTitle.edit : strings.staffManagement.dialogTitle.create }}
            </h2>
          </div>
          <button type="button" class="icon-action" @click="closeEditor">{{ strings.staffManagement.close }}</button>
        </div>
        <div v-if="!editing" class="form-grid">
          <label>
            {{ strings.staffManagement.labels.account }}
            <input v-model.trim="form.account" name="account" required />
          </label>
          <label>
            {{ strings.staffManagement.labels.password }}
            <input v-model="form.password" name="password" required minlength="8" type="password" />
          </label>
        </div>
        <div class="form-grid">
          <label>
            {{ strings.staffManagement.labels.name }}
            <input v-model.trim="form.name" name="name" required />
          </label>
          <label>
            {{ strings.staffManagement.labels.email }}
            <input v-model.trim="form.email" name="email" type="email" />
          </label>
        </div>
        <label>
          {{ strings.staffManagement.labels.phone }}
          <input v-model.trim="form.phone" name="phone" />
        </label>
        <fieldset>
          <legend>{{ strings.staffManagement.labels.roles }}</legend>
          <label v-for="role in selectableRoles" :key="role.id" class="check-option">
            <input v-model="form.roleIds" :name="`role-${role.id}`" type="checkbox" :value="role.id" />
            <span><strong>{{ role.name }}</strong><small>{{ role.permissions.join(' · ') }}</small></span>
          </label>
        </fieldset>
        <label>
          {{ strings.staffManagement.labels.shopScope }}
          <select v-model.number="form.shopScopeType" name="shopScopeType">
            <option :value="1">{{ strings.staffManagement.labels.allShops }}</option>
            <option :value="2">{{ strings.staffManagement.labels.selectedShops }}</option>
          </select>
        </label>
        <fieldset v-if="form.shopScopeType === 2">
          <legend>{{ strings.staffManagement.labels.manageableShops }}</legend>
          <label v-for="shop in shops" :key="shop.id" class="check-option">
            <input v-model="form.shopIds" :name="`shop-${shop.id}`" type="checkbox" :value="shop.id" />
            <span>{{ shop.name }}</span>
          </label>
        </fieldset>
        <p v-if="error" class="error" role="alert">{{ error }}</p>
        <div class="dialog-actions">
          <button type="button" class="secondary-action" @click="closeEditor">{{ strings.common.cancel }}</button>
          <button class="primary-action" :disabled="saving">
            {{ saving ? strings.staffManagement.saving : strings.staffManagement.save }}
          </button>
        </div>
      </form>
    </div>
  </section>
</template>
