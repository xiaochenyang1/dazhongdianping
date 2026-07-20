<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
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
    error.value = cause instanceof Error ? cause.message : '员工数据加载失败'
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
    error.value = '指定门店范围时至少选择一家门店'
    return
  }
  if (form.roleIds.length === 0) {
    error.value = '至少选择一个员工角色'
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
    error.value = cause instanceof Error ? cause.message : '员工保存失败'
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
    error.value = cause instanceof Error ? cause.message : '员工状态更新失败'
  }
}

onMounted(load)
</script>

<template>
  <section class="staff-page">
    <div class="page-heading">
      <div><p class="eyebrow">Access control</p><h1>员工与门店权限</h1><p class="muted">账号能干什么、能碰哪家店，在这里说清楚，别靠口头传功。</p></div>
      <button class="primary-action" type="button" @click="openCreate">新增员工</button>
    </div>

    <p v-if="error && editing === undefined" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="card feedback">员工数据加载中...</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead><tr><th>员工</th><th>角色</th><th>门店范围</th><th>状态</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-for="staff in staffs" :key="staff.id">
            <td><strong>{{ staff.name }}</strong><span class="table-subtext">{{ staff.account }}</span></td>
            <td>{{ staff.roles.map((role) => role.name).join('、') }}</td>
            <td>{{ staff.shopScopeType === 1 ? '全部门店' : `${staff.shopIds.length} 家指定门店` }}</td>
            <td><span class="status-pill" :class="staff.status === 1 ? 'status-1' : 'status-2'">{{ staff.status === 1 ? '启用' : '停用' }}</span></td>
            <td class="row-actions"><button type="button" class="secondary-action" @click="openEdit(staff)">编辑</button><button type="button" class="danger-action" @click="toggleStatus(staff)">{{ staff.status === 1 ? '停用' : '启用' }}</button></td>
          </tr>
          <tr v-if="staffs.length === 0"><td colspan="5" class="feedback">还没有员工账号。</td></tr>
        </tbody>
      </table>
    </div>

    <div v-if="editing !== undefined" class="dialog-backdrop" @click.self="closeEditor">
      <form class="dialog-card" @submit.prevent="save">
        <div class="dialog-heading"><div><p class="eyebrow">{{ editing ? 'Edit staff' : 'New staff' }}</p><h2>{{ editing ? '编辑员工权限' : '创建员工账号' }}</h2></div><button type="button" class="icon-action" @click="closeEditor">关闭</button></div>
        <div v-if="!editing" class="form-grid"><label>登录账号<input v-model.trim="form.account" name="account" required /></label><label>初始密码<input v-model="form.password" name="password" required minlength="8" type="password" /></label></div>
        <div class="form-grid"><label>员工姓名<input v-model.trim="form.name" name="name" required /></label><label>邮箱<input v-model.trim="form.email" name="email" type="email" /></label></div>
        <label>联系电话<input v-model.trim="form.phone" name="phone" /></label>
        <fieldset><legend>角色</legend><label v-for="role in selectableRoles" :key="role.id" class="check-option"><input v-model="form.roleIds" :name="`role-${role.id}`" type="checkbox" :value="role.id" /><span><strong>{{ role.name }}</strong><small>{{ role.permissions.join(' · ') }}</small></span></label></fieldset>
        <label>门店范围<select v-model.number="form.shopScopeType" name="shopScopeType"><option :value="1">全部门店</option><option :value="2">指定门店</option></select></label>
        <fieldset v-if="form.shopScopeType === 2"><legend>可管理门店</legend><label v-for="shop in shops" :key="shop.id" class="check-option"><input v-model="form.shopIds" :name="`shop-${shop.id}`" type="checkbox" :value="shop.id" /><span>{{ shop.name }}</span></label></fieldset>
        <p v-if="error" class="error" role="alert">{{ error }}</p>
        <div class="dialog-actions"><button type="button" class="secondary-action" @click="closeEditor">取消</button><button class="primary-action" :disabled="saving">{{ saving ? '保存中...' : '保存员工' }}</button></div>
      </form>
    </div>
  </section>
</template>
