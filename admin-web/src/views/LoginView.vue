<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { loginAdmin } from '@/services/admin'
import type { Region } from '@/types/admin'

const route = useRoute()
const router = useRouter()
const { state, setSession, setRegion } = useAdminSession()

const form = reactive({
  account: 'admin',
  password: 'admin123456',
})

const loading = ref(false)
const errorMessage = ref('')

const redirectTarget = computed(() =>
  typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard',
)

const spotlightCards = computed(() => [
  {
    label: '登录凭据',
    value: 'admin / admin123456',
    detail: '示例账号来自数据库种子；请使用已启用且已分配角色的管理员账号登录。',
  },
  {
    label: '区域范围',
    value: state.region,
    detail: '登录响应会载入管理员资料、权限与区域范围，并按授权更新工作视角。',
  },
  {
    label: '授权模型',
    value: '数据库 RBAC 授权',
    detail: '管理员、角色和权限由服务端持久化管理，后台能力按授权加载。',
  },
])

const entryFacts = computed(() => [
  {
    label: '目标路由',
    value: redirectTarget.value,
  },
  {
    label: '会话模式',
    value: '数据库 RBAC 授权',
  },
  {
    label: '区域视角',
    value: state.region,
  },
])

const consoleNotes = [
  {
    title: '区域范围',
    detail: '登录响应会载入管理员资料、权限与区域范围；进入后台后按账号授权选择工作视角。',
  },
  {
    title: '实时权限',
    detail: '进入后台后通过 auth/me 实时水合管理员资料、权限与区域范围。',
  },
  {
    title: '管理员与角色管理',
    detail: '管理员账号、角色、权限和区域范围由数据库维护，页面能力以服务端实时核验为准。',
  },
]

async function handleSubmit() {
  loading.value = true
  errorMessage.value = ''

  try {
    const result = await loginAdmin({
      account: form.account.trim(),
      password: form.password,
    })

    setSession(result.accessToken, result.profile, result.permissions, result.regions)

    await router.replace(redirectTarget.value)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '登录失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <section class="auth-page auth-page--admin">
    <div class="auth-panel auth-panel--admin">
      <div class="auth-copy auth-copy--admin">
        <div class="auth-copy__brand">
          <span class="auth-copy__mark">DP</span>
          <div class="auth-copy__brand-text">
            <p class="eyebrow">Admin Concierge</p>
            <strong>运营控制席</strong>
          </div>
        </div>

        <div class="auth-copy__headline">
          <h1>管理员身份、角色权限与区域范围由数据库统一管理。</h1>
          <p>
            登录响应会载入管理员资料、权限与区域范围；进入后台后通过 auth/me 实时水合，
            页面能力以服务端核验为准。
          </p>
        </div>

        <div class="auth-copy__ribbon">
          <span>当前区域 {{ state.region }}</span>
          <span>数据库 RBAC</span>
          <span>实时权限核验</span>
        </div>

        <div class="tip-stack tip-stack--admin">
          <article v-for="card in spotlightCards" :key="card.label" class="tip-card tip-card--admin">
            <span>{{ card.label }}</span>
            <strong>{{ card.value }}</strong>
            <p>{{ card.detail }}</p>
          </article>
        </div>

        <div class="admin-brief">
          <article v-for="item in consoleNotes" :key="item.title" class="admin-brief__item">
            <strong>{{ item.title }}</strong>
            <p>{{ item.detail }}</p>
          </article>
        </div>
      </div>

      <form class="auth-card auth-card--admin" @submit.prevent="handleSubmit">
        <div class="auth-card__topline">
          <div>
            <p class="eyebrow">管理员登录</p>
            <h2>先进去把数据管起来。</h2>
          </div>
          <span class="auth-card__badge">Control Entry</span>
        </div>

        <p class="auth-card__summary">
          登录后会跳到 <span class="code-box">{{ redirectTarget }}</span>，系统根据数据库 RBAC 授权载入管理员资料、权限与区域范围，
          并在进入后台后实时核验。
        </p>

        <div class="auth-card__facts">
          <article v-for="fact in entryFacts" :key="fact.label" class="auth-card__fact">
            <span>{{ fact.label }}</span>
            <strong>{{ fact.value }}</strong>
          </article>
        </div>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

        <label class="field">
          <span>区域视角</span>
          <select :value="state.region" @change="setRegion(($event.target as HTMLSelectElement).value as Region)">
            <option value="CN">CN</option>
            <option value="EU">EU</option>
          </select>
        </label>

        <label class="field">
          <span>账号</span>
          <input v-model="form.account" type="text" placeholder="请输入管理员账号" autocomplete="username" />
        </label>

        <label class="field">
          <span>密码</span>
          <input
            v-model="form.password"
            type="password"
            placeholder="请输入管理员密码"
            autocomplete="current-password"
          />
        </label>

        <button type="submit" class="primary-button primary-button--block" :disabled="loading">
          {{ loading ? '登录中...' : '进入后台' }}
        </button>

        <div class="auth-card__footer">
          <span>管理员与角色管理、权限和区域范围由服务端实时核验，后台能力以数据库授权为准。</span>
          <div class="auth-card__chips">
            <span>管理员管理</span>
            <span>角色与权限</span>
            <span>区域范围</span>
          </div>
        </div>
      </form>
    </div>
  </section>
</template>
