<script setup lang="ts">
import { computed, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { fetchShops, type MerchantShopOption } from '@/services/merchant'
import { createMerchantTicket, fetchMerchantTickets, replyMerchantTicket, type MerchantTicket } from '@/services/ops'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), { permissions: () => [] })
const { state } = useMerchantSession()
const zh = computed(() => state.region !== 'EU')
const canReply = computed(() => props.permissions.includes('ticket:reply'))
const tickets = ref<MerchantTicket[]>([])
const shops = ref<MerchantShopOption[]>([])
const errorMessage = ref('')
const subject = ref('')
const content = ref('')
const shopId = ref<number | ''>('')
const replies = ref<Record<number, string>>({})

async function load() {
  errorMessage.value = ''
  try {
    tickets.value = (await fetchMerchantTickets()).list
    shops.value = (await fetchShops({ page: 1, pageSize: 50 })).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : (zh.value ? '加载失败' : 'Load failed')
  }
}

async function submit() {
  await createMerchantTicket({
    subject: subject.value.trim(),
    content: content.value.trim(),
    shopId: Number(shopId.value),
  })
  subject.value = ''
  content.value = ''
  await load()
}

async function reply(ticket: MerchantTicket) {
  await replyMerchantTicket(ticket.id, (replies.value[ticket.id] ?? '').trim())
  await load()
}

load()
</script>

<template>
  <section>
    <p class="muted">{{ zh ? '工单归属当前商户，不是操作员。' : 'Tickets belong to the merchant, not the operator.' }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <form v-if="canReply" @submit.prevent="submit">
      <input v-model="subject" required maxlength="128" :placeholder="zh ? '主题' : 'Subject'" />
      <textarea v-model="content" required maxlength="2000" rows="3" />
      <select v-model="shopId" required>
        <option value="">{{ zh ? '选择门店' : 'Shop' }}</option>
        <option v-for="shop in shops" :key="shop.id" :value="shop.id">{{ shop.name }}</option>
      </select>
      <button type="submit">{{ zh ? '提交' : 'Submit' }}</button>
    </form>
    <article v-for="ticket in tickets" :key="ticket.id">
      <h2>{{ ticket.subject }} · {{ ticket.statusText }}</h2>
      <p>{{ ticket.content }}</p>
      <form v-if="canReply && (ticket.status === 1 || ticket.status === 2)" @submit.prevent="reply(ticket)">
        <input v-model="replies[ticket.id]" required />
        <button type="submit">{{ zh ? '回复' : 'Reply' }}</button>
      </form>
    </article>
  </section>
</template>
