<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { createCircle, listCircles, updateCircle, updateCircleStatus, type AdminCircle } from '@/services/circle'

const rows=ref<AdminCircle[]>([]), loading=ref(false), error=ref(''), editingId=ref<number|null>(null)
const keyword=ref(''), status=ref<number|undefined>(undefined)
const form=reactive({name:'',description:'',coverUrl:'',sort:0})
async function load(){loading.value=true;error.value='';try{rows.value=(await listCircles({status:status.value,keyword:keyword.value,page:1,pageSize:20})).list}catch(e){error.value=e instanceof Error?e.message:'圈子加载失败'}finally{loading.value=false}}
function edit(row:AdminCircle){editingId.value=row.id;Object.assign(form,{name:row.name,description:row.description,coverUrl:row.coverUrl,sort:row.sort})}
function reset(){editingId.value=null;Object.assign(form,{name:'',description:'',coverUrl:'',sort:0})}
async function save(){error.value='';try{const payload={...form};if(editingId.value)await updateCircle(editingId.value,payload);else await createCircle(payload);reset();await load()}catch(e){error.value=e instanceof Error?e.message:'保存失败'}}
async function toggle(row:AdminCircle){error.value='';try{await updateCircleStatus(row.id,row.status===1?2:1);await load()}catch(e){error.value=e instanceof Error?e.message:'状态更新失败'}}
onMounted(load)
</script>

<template>
  <section class="circle-page">
    <header><p class="eyebrow">社区运营</p><h1>官方圈子</h1><p>当前区域独立维护，停用后禁止新加入和发帖。</p></header>
    <div class="panel filters"><input v-model="keyword" placeholder="搜索圈子" /><select v-model="status"><option :value="undefined">全部状态</option><option :value="1">启用</option><option :value="2">停用</option></select><button @click="load">查询</button></div>
    <form class="panel editor" @submit.prevent="save">
      <input name="circle-name" v-model="form.name" minlength="2" maxlength="64" placeholder="圈子名称" required />
      <input v-model="form.description" maxlength="500" placeholder="圈子简介" />
      <input v-model="form.coverUrl" maxlength="255" placeholder="封面地址（可空）" />
      <input v-model.number="form.sort" type="number" placeholder="排序" />
      <button type="submit">{{ editingId ? '保存修改' : '创建圈子' }}</button><button v-if="editingId" type="button" @click="reset">取消</button>
    </form>
    <p v-if="error" class="feedback is-error">{{ error }}</p><p v-if="loading">加载中...</p>
    <div v-else class="circle-grid"><article v-for="row in rows" :key="row.id" class="panel circle-card"><div><span class="status" :class="{off:row.status===2}">{{ row.status===1?'启用':'停用' }}</span><h2>{{ row.name }}</h2><p>{{ row.description || '暂无简介' }}</p><small>成员 {{ row.memberCount }} · 帖子 {{ row.postCount }} · 排序 {{ row.sort }}</small></div><div class="actions"><button @click="edit(row)">编辑</button><button @click="toggle(row)">{{ row.status===1?'停用':'启用' }}</button></div></article></div>
  </section>
</template>

<style scoped>
.circle-page{display:grid;gap:18px}.panel{background:#fff;border-radius:18px;padding:18px;box-shadow:0 12px 32px rgba(15,23,42,.07)}.filters,.editor,.actions{display:flex;gap:10px;flex-wrap:wrap}.filters input,.editor input,.filters select{min-height:42px;padding:0 12px;border:1px solid #d8dee8;border-radius:10px}.circle-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px}.circle-card{display:flex;justify-content:space-between;gap:16px}.status{color:#16794b}.status.off{color:#9a3412}button{min-height:40px;padding:0 16px;border:0;border-radius:10px;cursor:pointer}.editor button[type=submit]{background:#e85d2a;color:#fff}.is-error{color:#b42318}
</style>
