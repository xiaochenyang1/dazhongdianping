<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchPost, fetchPostComments } from '@/services/community'
import type { CommunityComment, CommunityPost } from '@/types/community'
const props=defineProps<{postId:number}>(),post=ref<CommunityPost|null>(null),comments=ref<CommunityComment[]>([]),errorMessage=ref('')
onMounted(async()=>{try{const [detail,page]=await Promise.all([fetchPost(props.postId),fetchPostComments(props.postId)]);post.value=detail;comments.value=page.list}catch(e){errorMessage.value=e instanceof Error?e.message:'帖子加载失败'}})
</script>

<template>
  <section v-if="post" class="page-section">
    <div class="page-header"><div><p class="eyebrow"><RouterLink :to="`/users/${post.userId}`">{{post.userName}}</RouterLink> · {{post.createdAt}}</p><h1>{{post.title}}</h1><div class="tag-row"><span v-for="topic in post.topics" :key="topic">#{{topic}}</span></div></div></div>
    <p v-if="errorMessage" class="feedback is-error">{{errorMessage}}</p>
    <article class="content-card"><p>{{post.content}}</p><div v-if="post.images.length" class="gallery-grid"><img v-for="image in post.images" :key="image" :src="image" :alt="post.title"></div></article>
    <p class="feedback">PC 端仅供阅读；下载 APP 参与互动。</p>
    <section class="content-card"><h2>公开评论</h2><div class="review-list"><article v-for="item in comments" :key="item.id" class="review-card"><strong>{{item.userName}}</strong><p>{{item.content}}</p><span>{{item.createdAt}}</span></article></div></section>
  </section>
  <p v-else-if="errorMessage" class="feedback is-error">{{errorMessage}}</p>
</template>
