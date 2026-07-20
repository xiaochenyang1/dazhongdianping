<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { fetchAdminMe, fetchAdminMenus, logoutAdmin } from '@/services/admin'
import type { AdminMenuItem, Region } from '@/types/admin'

const route = useRoute()
const router = useRouter()
const { state, clearSession, setRegion, updateIdentity } = useAdminSession()

const menus = ref<AdminMenuItem[]>([])
const loadingMenus = ref(false)
const errorMessage = ref('')
const identityReady = ref(false)
let hydrationRequestId = 0

const pageTitle = computed(() => (typeof route.meta.title === 'string' ? route.meta.title : '管理端'))
const availableRegions = computed<Region[]>(() => state.regions.length > 0 ? state.regions : ['CN', 'EU'])

async function loadMenus() {
  const requestId = ++hydrationRequestId
  const token = state.token
  const fullPath = route.fullPath
  const isCurrentHydration = () => requestId === hydrationRequestId
    && state.token === token
    && route.fullPath === fullPath

  menus.value = []
  identityReady.value = false
  loadingMenus.value = true
  errorMessage.value = ''

  if (!state.token) {
    loadingMenus.value = false
    if (route.path !== '/login') {
      await router.replace('/login')
    }
    return
  }

  try {
    const identity = await fetchAdminMe()
    if (!isCurrentHydration()) {
      return
    }
    updateIdentity(identity)

    const requiredPermission = typeof route.meta.requiredPermission === 'string'
      ? route.meta.requiredPermission
      : undefined
    if (requiredPermission && !state.permissions.includes(requiredPermission)) {
      await router.replace('/dashboard')
      return
    }

    const loadedMenus = await fetchAdminMenus()
    if (!isCurrentHydration()) {
      return
    }
    menus.value = loadedMenus
    identityReady.value = true
  } catch (error) {
    if (isCurrentHydration()) {
      menus.value = []
      errorMessage.value = error instanceof Error ? error.message : '菜单加载失败'
      identityReady.value = false
    }

    if (!state.token) {
      await router.replace('/login')
    }
  } finally {
    if (isCurrentHydration()) {
      loadingMenus.value = false
    }
  }
}

function isActive(path: string) {
  return route.path === path || route.path.startsWith(`${path}/`)
}

async function handleLogout() {
  await logoutAdmin().catch(() => undefined)
  clearSession()
  await router.replace('/login')
}

watch(
  () => [state.token, route.fullPath],
  () => {
    void loadMenus()
  },
  { immediate: true },
)
</script>

<template>
  <div class="admin-shell">
    <aside class="admin-sidebar">
      <div class="brand-block">
        <p class="eyebrow">运营后台</p>
        <h1>大众点评运营控制台</h1>
        <p>账户、角色和区域范围由服务端实时核验，页面菜单只是工作入口，不是安全边界。</p>
      </div>

      <nav class="menu-groups" aria-label="后台菜单">
        <p v-if="loadingMenus" class="feedback">菜单加载中...</p>

        <template v-else>
          <section v-for="menu in menus" :key="menu.code" class="menu-group">
            <p class="menu-group__title">{{ menu.name }}</p>

            <RouterLink
              v-if="menu.children.length === 0"
              :to="menu.path"
              class="menu-link"
              :class="{ 'is-active': isActive(menu.path) }"
            >
              {{ menu.name }}
            </RouterLink>

            <RouterLink
              v-for="child in menu.children"
              :key="child.code"
              :to="child.path"
              class="menu-link"
              :class="{ 'is-active': isActive(child.path) }"
            >
              {{ child.name }}
            </RouterLink>
          </section>
        </template>
      </nav>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    </aside>

    <div class="admin-main">
      <header class="admin-topbar">
        <div>
          <p class="eyebrow">当前页面</p>
          <h2>{{ pageTitle }}</h2>
        </div>

        <div class="topbar-actions">
          <label class="compact-field">
            <span>区域</span>
            <select :value="state.region" @change="setRegion(($event.target as HTMLSelectElement).value as Region)">
              <option v-for="region in availableRegions" :key="region" :value="region">{{ region }}</option>
            </select>
          </label>

          <div class="topbar-profile">
            <strong>{{ state.profile?.name ?? '未登录管理员' }}</strong>
            <span>{{ state.profile?.account ?? '--' }}</span>
          </div>

          <button type="button" class="ghost-button" @click="handleLogout">退出登录</button>
        </div>
      </header>

      <main class="page-shell">
        <RouterView v-if="identityReady" />
        <p v-else-if="state.token" class="feedback">正在核验管理员身份...</p>
      </main>
    </div>
  </div>
</template>
