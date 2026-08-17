<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { getAdminSystemHealth } from '@/services/admin'
import type {
  AdminSystemHealth,
  AdminSystemHealthStatus,
} from '@/types/admin'

const zhCopy = {
  eyebrow: '基础设施观测',
  heading: '系统健康',
  description: '查看核心依赖的实时连通性和第三方能力配置状态；页面不会返回连接串、密钥或访问令牌。',
  refresh: '重新检查',
  loading: '检查中...',
  loadError: '系统健康状态加载失败。',
  overall: '整体状态',
  runtime: '运行环境',
  uptime: '运行时长',
  checkedAt: '检查时间',
  version: '应用版本',
  profiles: 'Spring Profiles',
  tableEyebrow: '组件状态',
  tableHeading: '核心依赖与外部能力',
  tableDescription: '连通性检查会真实读取依赖；配置检查只核验必需配置是否存在，不会调用支付、短信或推送业务接口。',
  headers: {
    component: '组件',
    status: '状态',
    checkType: '检查方式',
    critical: '重要级别',
    latency: '耗时',
    detail: '说明',
  },
  empty: '暂无组件状态。',
  critical: '核心',
  optional: '可降级',
  latency: (value: number) => value > 0 ? `${value} ms` : '--',
  status: {
    up: '正常',
    degraded: '部分降级',
    down: '不可用',
    warning: '需关注',
    disabled: '未启用',
  },
  checkTypes: {
    connectivity: '实时连通性',
    configuration: '配置完整性',
    filesystem: '文件系统',
    provider: '当前提供方',
  },
  components: {
    database: 'MySQL 数据库',
    stateStore: '状态存储 / Redis',
    search: '搜索服务',
    fileStorage: '文件存储',
    payment: '支付渠道',
    verificationCode: '验证码渠道',
    push: '移动推送',
  },
  defaultProfile: 'default',
  uptimeText: (days: number, hours: number, minutes: number) =>
    days > 0 ? `${days} 天 ${hours} 小时` : hours > 0 ? `${hours} 小时 ${minutes} 分钟` : `${minutes} 分钟`,
}

const enCopy = {
  eyebrow: 'Infrastructure observability',
  heading: 'System Health',
  description: 'Inspect live dependency connectivity and third-party configuration without exposing URLs, secrets, or tokens.',
  refresh: 'Run checks again',
  loading: 'Checking...',
  loadError: 'Failed to load system health.',
  overall: 'Overall status',
  runtime: 'Runtime mode',
  uptime: 'Uptime',
  checkedAt: 'Checked at',
  version: 'Application version',
  profiles: 'Spring profiles',
  tableEyebrow: 'Component status',
  tableHeading: 'Core dependencies and external capabilities',
  tableDescription: 'Connectivity checks read the dependency live. Configuration checks only verify required settings and never invoke payment, messaging, or push business APIs.',
  headers: {
    component: 'Component',
    status: 'Status',
    checkType: 'Check type',
    critical: 'Impact',
    latency: 'Latency',
    detail: 'Detail',
  },
  empty: 'No component status is available.',
  critical: 'Critical',
  optional: 'Degradable',
  latency: (value: number) => value > 0 ? `${value} ms` : '--',
  status: {
    up: 'Healthy',
    degraded: 'Degraded',
    down: 'Unavailable',
    warning: 'Needs attention',
    disabled: 'Disabled',
  },
  checkTypes: {
    connectivity: 'Live connectivity',
    configuration: 'Configuration',
    filesystem: 'Filesystem',
    provider: 'Active provider',
  },
  components: {
    database: 'MySQL database',
    stateStore: 'State store / Redis',
    search: 'Search service',
    fileStorage: 'File storage',
    payment: 'Payment channel',
    verificationCode: 'Verification channels',
    push: 'Mobile push',
  },
  defaultProfile: 'default',
  uptimeText: (days: number, hours: number, minutes: number) =>
    days > 0 ? `${days}d ${hours}h` : hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`,
}

const { state } = useAdminSession()
const copy = computed(() => state.region === 'EU' ? enCopy : zhCopy)
const health = ref<AdminSystemHealth | null>(null)
const loading = ref(false)
const errorMessage = ref('')
let requestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : copy.value.loadError
}

function statusLabel(status: AdminSystemHealthStatus) {
  return copy.value.status[status] ?? status
}

function statusClass(status: AdminSystemHealthStatus) {
  if (status === 'up') return 'status-pill--good'
  if (status === 'disabled') return 'status-pill--muted'
  return 'status-pill--warn'
}

function componentLabel(key: string) {
  return (copy.value.components as Record<string, string>)[key] ?? key
}

function checkTypeLabel(checkType: string) {
  return (copy.value.checkTypes as Record<string, string>)[checkType] ?? checkType
}

function formatDate(value: string | null | undefined) {
  return value ? value.replace('T', ' ') : '--'
}

function formatUptime(seconds: number) {
  const safeSeconds = Math.max(0, Math.floor(seconds || 0))
  const days = Math.floor(safeSeconds / 86_400)
  const hours = Math.floor((safeSeconds % 86_400) / 3_600)
  const minutes = Math.floor((safeSeconds % 3_600) / 60)
  return copy.value.uptimeText(days, hours, minutes)
}

function profilesText() {
  return health.value?.activeProfiles.length
    ? health.value.activeProfiles.join(', ')
    : copy.value.defaultProfile
}

async function load() {
  const currentRequestId = ++requestId
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await getAdminSystemHealth()
    if (currentRequestId !== requestId) return
    health.value = result
  } catch (error) {
    if (currentRequestId === requestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ copy.eyebrow }}</p>
        <h1>{{ copy.heading }}</h1>
        <p>{{ copy.description }}</p>
      </div>
      <button type="button" class="primary-button" :disabled="loading" @click="load">
        {{ loading ? copy.loading : copy.refresh }}
      </button>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <div class="stat-grid system-health-summary">
      <article class="stat-card">
        <p>{{ copy.overall }}</p>
        <span v-if="health" class="status-pill" :class="statusClass(health.status)">
          {{ statusLabel(health.status) }}
        </span>
        <strong v-else>--</strong>
      </article>
      <article class="stat-card">
        <p>{{ copy.runtime }}</p>
        <strong>{{ health?.runtimeMode ?? '--' }}</strong>
        <span>{{ copy.profiles }}: {{ profilesText() }}</span>
      </article>
      <article class="stat-card">
        <p>{{ copy.uptime }}</p>
        <strong>{{ health ? formatUptime(health.uptimeSeconds) : '--' }}</strong>
        <span>{{ copy.version }}: {{ health?.applicationVersion ?? '--' }}</span>
      </article>
      <article class="stat-card">
        <p>{{ copy.checkedAt }}</p>
        <strong class="system-health-time">{{ formatDate(health?.checkedAt) }}</strong>
      </article>
    </div>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ copy.tableEyebrow }}</p>
          <h2>{{ copy.tableHeading }}</h2>
          <p>{{ copy.tableDescription }}</p>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table system-health-table">
          <thead>
            <tr>
              <th>{{ copy.headers.component }}</th>
              <th>{{ copy.headers.status }}</th>
              <th>{{ copy.headers.checkType }}</th>
              <th>{{ copy.headers.critical }}</th>
              <th>{{ copy.headers.latency }}</th>
              <th>{{ copy.headers.detail }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading && !health">
              <td colspan="6" class="table-empty">{{ copy.loading }}</td>
            </tr>
            <tr v-else-if="!health?.components.length">
              <td colspan="6" class="table-empty">{{ copy.empty }}</td>
            </tr>
            <tr v-for="component in health?.components" :key="component.key">
              <td><strong>{{ componentLabel(component.key) }}</strong></td>
              <td>
                <span class="status-pill" :class="statusClass(component.status)">
                  {{ statusLabel(component.status) }}
                </span>
              </td>
              <td>{{ checkTypeLabel(component.checkType) }}</td>
              <td>{{ component.critical ? copy.critical : copy.optional }}</td>
              <td class="numeric-cell">{{ copy.latency(component.latencyMillis) }}</td>
              <td class="system-health-detail">{{ component.detail }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </section>
</template>
