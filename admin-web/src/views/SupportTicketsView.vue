<script setup lang="ts">
import { ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  fetchAdminTicket,
  fetchAdminTickets,
  replyAdminTicket,
  updateAdminTicketStatus,
  type OpsTicket,
} from '@/services/ops'

const { state } = useAdminSession()
const tickets = ref<OpsTicket[]>([])
const selected = ref<OpsTicket | null>(null)
const status = ref<number | ''>('')
const reply = ref('')
const errorMessage = ref('')
const canWrite = () => state.permissions.includes('support:ticket:write')

async function load() {
  errorMessage.value = ''
  try {
    const page = await fetchAdminTickets({
      status: status.value === '' ? undefined : Number(status.value),
      page: 1,
      pageSize: 20,
    })
    tickets.value = page.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

async function open(id: number) {
  selected.value = await fetchAdminTicket(id)
  reply.value = ''
}

async function send() {
  if (!selected.value) return
  selected.value = await replyAdminTicket(selected.value.id, reply.value.trim())
  reply.value = ''
  await load()
}

async function setStatus(next: number) {
  if (!selected.value) return
  selected.value = await updateAdminTicketStatus(selected.value.id, next)
  await load()
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>客服工单</h1>
      <p class="page-desc">回复后待处理工单会进入处理中。状态只接受处理中、已解决、已关闭。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <div class="toolbar">
      <select v-model="status" @change="load">
        <option value="">全部</option>
        <option :value="1">待处理</option>
        <option :value="2">处理中</option>
        <option :value="3">已解决</option>
        <option :value="4">已关闭</option>
      </select>
    </div>
    <table class="data-table">
      <tbody>
        <tr v-for="ticket in tickets" :key="ticket.id">
          <td>#{{ ticket.id }} {{ ticket.subject }}</td>
          <td>{{ ticket.statusText }}</td>
          <td><button type="button" class="link" @click="open(ticket.id)">查看</button></td>
        </tr>
      </tbody>
    </table>
    <article v-if="selected">
      <h2>{{ selected.subject }}</h2>
      <p>{{ selected.content }}</p>
      <ul>
        <li v-for="message in selected.messages ?? []" :key="message.id">{{ message.senderType }} · {{ message.content }}</li>
      </ul>
      <form v-if="canWrite()" @submit.prevent="send">
        <textarea v-model="reply" required rows="3" />
        <button type="submit">回复</button>
        <button type="button" @click="setStatus(2)">处理中</button>
        <button type="button" @click="setStatus(3)">已解决</button>
        <button type="button" @click="setStatus(4)">已关闭</button>
      </form>
    </article>
  </section>
</template>
