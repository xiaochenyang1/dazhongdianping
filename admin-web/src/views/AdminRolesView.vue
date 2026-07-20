<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createAdminRole,
  listAdminPermissions,
  listAdminRoles,
  removeAdminRole,
  updateAdminRole,
  updateAdminRoleStatus,
} from '@/services/admin'
import type { AdminPermissionItem, AdminRole, AdminRolePayload } from '@/types/admin'

const { state } = useAdminSession()

const roles = ref<AdminRole[]>([])
const permissions = ref<AdminPermissionItem[]>([])
const loading = ref(false)
const errorMessage = ref('')
const dialogOpen = ref(false)
const editingRole = ref<AdminRole | null>(null)
const saving = ref(false)

const form = reactive<AdminRolePayload>({
  code: '',
  name: '',
  description: '',
  permissionIds: [],
})

const canWrite = computed(() => state.permissions.includes('system:role:write'))
const isSuperAdmin = computed(() => editingRole.value?.code === 'super_admin')
const permissionGroups = computed(() => {
  const labels: Record<string, string> = {
    audit: '审核中心',
    data: '数据管理',
    operations: '运营配置',
    system: '系统管理',
  }
  const groups = new Map<string, AdminPermissionItem[]>()
  permissions.value.forEach((permission) => {
    const list = groups.get(permission.category) ?? []
    list.push(permission)
    groups.set(permission.category, list)
  })
  return [...groups.entries()].map(([category, items]) => ({ category, label: labels[category] ?? category, items }))
})

function resetForm() {
  form.code = ''
  form.name = ''
  form.description = ''
  form.permissionIds = []
  errorMessage.value = ''
}

function openCreate() {
  editingRole.value = null
  resetForm()
  dialogOpen.value = true
}

function openEdit(role: AdminRole) {
  editingRole.value = role
  form.code = role.code
  form.name = role.name
  form.description = role.description
  form.permissionIds = [...role.permissionIds]
  errorMessage.value = ''
  dialogOpen.value = true
}

function closeDialog() {
  if (!saving.value) {
    dialogOpen.value = false
  }
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const [roleResult, permissionResult] = await Promise.all([listAdminRoles(), listAdminPermissions()])
    roles.value = roleResult
    permissions.value = permissionResult
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '角色与权限加载失败'
  } finally {
    loading.value = false
  }
}

async function submitForm() {
  if (form.permissionIds.length === 0) {
    errorMessage.value = '至少选择一个权限'
    return
  }
  saving.value = true
  errorMessage.value = ''
  const payload: AdminRolePayload = {
    code: form.code.trim(),
    name: form.name.trim(),
    description: form.description.trim(),
    permissionIds: [...form.permissionIds],
  }
  try {
    if (editingRole.value) {
      await updateAdminRole(editingRole.value.id, payload)
    } else {
      await createAdminRole(payload)
    }
    dialogOpen.value = false
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '角色保存失败'
  } finally {
    saving.value = false
  }
}

async function changeStatus(role: AdminRole) {
  if (!canWrite.value || role.code === 'super_admin') {
    return
  }
  const nextStatus = role.status === 1 ? 2 : 1
  const action = nextStatus === 2 ? '停用' : '启用'
  if (!window.confirm(`确认${action}角色「${role.name}」吗？`)) {
    return
  }
  errorMessage.value = ''
  try {
    await updateAdminRoleStatus(role.id, nextStatus)
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '角色状态更新失败'
  }
}

async function removeRole(role: AdminRole) {
  if (!canWrite.value || role.builtIn) {
    return
  }
  if (!window.confirm(`确认删除角色「${role.name}」吗？该操作不能撤销。`)) {
    return
  }
  errorMessage.value = ''
  try {
    await removeAdminRole(role.id)
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '角色删除失败'
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">Permission Registry</p>
        <h1>角色与权限</h1>
        <p>权限点由代码与数据库种子共同维护；角色可授权，权限码本身不允许在页面里随手造。</p>
      </div>
      <div class="header-actions">
        <button v-if="canWrite" type="button" class="primary-button" @click="openCreate">新建角色</button>
      </div>
    </header>

    <p v-if="errorMessage && !dialogOpen" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? '加载中...' : `共 ${roles.length} 个角色` }}</span>
        <span>内置角色保留稳定编码，自定义角色可删除。</span>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>角色</th>
              <th>权限数</th>
              <th>管理员引用</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="role in roles" :key="role.id">
              <td>
                <strong>{{ role.name }}</strong>
                <p class="code-box">{{ role.code }}</p>
              </td>
              <td class="numeric-cell">{{ role.permissionIds.length }}</td>
              <td class="numeric-cell">{{ role.adminCount }}</td>
              <td>
                <span class="status-pill" :class="role.status === 1 ? 'status-pill--good' : 'status-pill--muted'">
                  {{ role.status === 1 ? '启用' : '已停用' }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button type="button" class="table-action" @click="openEdit(role)">编辑</button>
                  <button
                    :data-testid="`role-status-${role.id}`"
                    type="button"
                    class="table-action"
                    :class="{ 'table-action--danger': role.status === 1 }"
                    :disabled="role.code === 'super_admin'"
                    :title="role.code === 'super_admin' ? '超级管理员角色不可停用' : ''"
                    @click="changeStatus(role)"
                  >
                    {{ role.status === 1 ? '停用' : '启用' }}
                  </button>
                  <button type="button" class="table-action table-action--danger" :disabled="role.builtIn" @click="removeRole(role)">删除</button>
                </div>
              </td>
            </tr>
            <tr v-if="!loading && roles.length === 0">
              <td class="table-empty" :colspan="canWrite ? 5 : 4">暂无角色</td>
            </tr>
          </tbody>
        </table>
      </div>
    </article>

    <div v-if="dialogOpen" class="dialog-backdrop" role="presentation" @click.self="closeDialog">
      <form class="dialog-panel system-dialog system-dialog--wide" data-testid="role-form" @submit.prevent="submitForm">
        <header class="dialog-panel__header">
          <div>
            <p class="eyebrow">Role Editor</p>
            <h2>{{ editingRole ? `编辑 ${editingRole.name}` : '新建角色' }}</h2>
          </div>
          <button type="button" class="dialog-close" aria-label="关闭" :disabled="saving" @click="closeDialog">×</button>
        </header>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

        <div class="form-grid form-grid--two">
          <label class="field">
            <span>角色编码</span>
            <input name="role-code" v-model="form.code" :disabled="Boolean(editingRole?.builtIn)" required />
          </label>
          <label class="field">
            <span>角色名称</span>
            <input name="role-name" v-model="form.name" required />
          </label>
          <label class="field field--full">
            <span>说明</span>
            <input name="role-description" v-model="form.description" />
          </label>
        </div>

        <section class="permission-matrix" :class="{ 'is-readonly': isSuperAdmin }">
          <header class="permission-matrix__header">
            <div>
              <h3>权限集合</h3>
              <p>超级管理员权限集合固定，其他角色按业务域最小授权。</p>
            </div>
          </header>
          <div class="permission-matrix__groups">
            <section v-for="group in permissionGroups" :key="group.category" class="permission-group">
              <h4>{{ group.label }}</h4>
              <label v-for="permission in group.items" :key="permission.id" class="permission-option">
                <input
                  :name="`permission-${permission.id}`"
                  v-model="form.permissionIds"
                  type="checkbox"
                  :value="permission.id"
                  :disabled="isSuperAdmin"
                />
                <span><strong>{{ permission.name }}</strong><small>{{ permission.code }}</small></span>
              </label>
            </section>
          </div>
        </section>

        <footer class="form-actions dialog-panel__footer">
          <button type="button" class="ghost-button" :disabled="saving" @click="closeDialog">取消</button>
          <button type="submit" class="primary-button" :disabled="saving">{{ saving ? '保存中...' : '保存角色' }}</button>
        </footer>
      </form>
    </div>
  </section>
</template>
