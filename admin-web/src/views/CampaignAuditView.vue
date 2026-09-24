<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  auditGroupBuy,
  auditSeckill,
  fetchAdminGroupBuys,
  fetchAdminSeckills,
  type AdminCampaign,
} from '@/services/ops'

const { state } = useAdminSession()
const errorMessage = ref('')
const success = ref('')
const reason = ref('')
const pendingOnly = ref(true)
const savingId = ref(0)
const seckills = ref<AdminCampaign[]>([])
const groups = ref<AdminCampaign[]>([])
const canWrite = () => state.permissions.includes('operations:marketing:write')

const visibleSeckills = computed(() =>
  pendingOnly.value ? seckills.value.filter((item) => item.auditStatus === 1) : seckills.value,
)
const visibleGroups = computed(() =>
  pendingOnly.value ? groups.value.filter((item) => item.auditStatus === 1) : groups.value,
)

function statusText(status: number) {
  if (status === 1) return '待审核'
  if (status === 2) return '已通过'
  if (status === 3) return '已驳回'
  return String(status)
}

function windowText(item: AdminCampaign) {
  if (!item.startAt && !item.endAt) return ''
  return `${item.startAt ?? ''} – ${item.endAt ?? ''}`
}

async function load() {
  errorMessage.value = ''
  try {
    const [seckillList, groupList] = await Promise.all([fetchAdminSeckills(), fetchAdminGroupBuys()])
    seckills.value = seckillList
    groups.value = groupList
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

async function audit(kind: 'seckill' | 'groupbuy', id: number, approve: boolean) {
  if (savingId.value) return
  errorMessage.value = ''
  success.value = ''
  const rejectReason = reason.value.trim()
  if (!approve && !rejectReason) {
    errorMessage.value = '驳回需填写原因'
    return
  }
  savingId.value = id
  try {
    if (kind === 'seckill') await auditSeckill(id, approve, approve ? '' : rejectReason)
    else await auditGroupBuy(id, approve, approve ? '' : rejectReason)
    success.value = approve ? '已通过' : '已驳回'
    if (!approve) reason.value = ''
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核失败'
  } finally {
    savingId.value = 0
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>秒杀与拼团审核</h1>
      <p class="page-desc">默认只看待审核。券模板仍在营销券页面审核。当前区域：{{ state.region }}</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>
    <div class="toolbar">
      <label><input v-model="pendingOnly" type="checkbox" /> 只看待审核</label>
      <input v-if="canWrite()" v-model="reason" placeholder="驳回原因" />
    </div>
    <h2>秒杀</h2>
    <table class="data-table">
      <thead>
        <tr><th>活动</th><th>门店</th><th>价格</th><th>已售/库存</th><th>时间</th><th>状态</th><th></th></tr>
      </thead>
      <tbody>
        <tr v-for="item in visibleSeckills" :key="item.id">
          <td>{{ item.title }}</td>
          <td>{{ item.shopId }}</td>
          <td>{{ item.seckillPrice }} {{ item.currency }}</td>
          <td>{{ item.sold ?? 0 }}/{{ item.stock ?? 0 }}</td>
          <td>{{ windowText(item) }}</td>
          <td>{{ statusText(item.auditStatus) }}<span v-if="item.rejectReason"> · {{ item.rejectReason }}</span></td>
          <td v-if="canWrite() && item.auditStatus === 1">
            <button type="button" class="link" :disabled="savingId !== 0" @click="audit('seckill', item.id, true)">通过</button>
            <button type="button" class="link" :disabled="savingId !== 0" @click="audit('seckill', item.id, false)">驳回</button>
          </td>
          <td v-else></td>
        </tr>
        <tr v-if="visibleSeckills.length === 0"><td colspan="7">暂无秒杀</td></tr>
      </tbody>
    </table>
    <h2>拼团</h2>
    <table class="data-table">
      <thead>
        <tr><th>活动</th><th>门店</th><th>价格</th><th>成团人数</th><th>时间</th><th>状态</th><th></th></tr>
      </thead>
      <tbody>
        <tr v-for="item in visibleGroups" :key="item.id">
          <td>{{ item.title }}</td>
          <td>{{ item.shopId }}</td>
          <td>{{ item.groupPrice }} {{ item.currency }}</td>
          <td>{{ item.groupSize }}</td>
          <td>{{ windowText(item) }}</td>
          <td>{{ statusText(item.auditStatus) }}<span v-if="item.rejectReason"> · {{ item.rejectReason }}</span></td>
          <td v-if="canWrite() && item.auditStatus === 1">
            <button type="button" class="link" :disabled="savingId !== 0" @click="audit('groupbuy', item.id, true)">通过</button>
            <button type="button" class="link" :disabled="savingId !== 0" @click="audit('groupbuy', item.id, false)">驳回</button>
          </td>
          <td v-else></td>
        </tr>
        <tr v-if="visibleGroups.length === 0"><td colspan="7">暂无拼团</td></tr>
      </tbody>
    </table>
  </section>
</template>
