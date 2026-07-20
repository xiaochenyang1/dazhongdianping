<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchPosts } from '@/services/community'
import type { CommunityPost } from '@/types/community'

const posts=ref<CommunityPost[]>([]),errorMessage=ref('')
onMounted(async()=>{try{posts.value=(await fetchPosts()).list}catch(e){errorMessage.value=e instanceof Error?e.message:'社区加载失败'}})
</script>

<template>
  <section class="page-section">
    <div class="page-header"><div><p class="eyebrow">Community · 只读版</p><h1>欧洲华人的生活经验，不该散落在聊天记录里。</h1><p>PC 端负责浏览和搜索收录；发布、点赞、关注与私信留在 APP。</p></div></div>
    <p class="feedback">下载 APP 参与互动、发布攻略和管理自己的帖子。<RouterLink to="/groups">浏览官方圈子</RouterLink> · <RouterLink to="/topics">查看话题广场与热榜</RouterLink></p>
    <p v-if="errorMessage" class="feedback is-error">{{errorMessage}}</p>
    <div class="rank-list">
      <RouterLink v-for="post in posts" :key="post.id" :to="`/community/posts/${post.id}`" class="content-card rank-item">
        <div class="rank-item__body"><p class="eyebrow"><RouterLink :to="`/users/${post.userId}`">{{post.userName}}</RouterLink> · {{post.createdAt}}</p><h2>{{post.title}}</h2><p>{{post.content}}</p><div class="tag-row"><span v-for="topic in post.topics" :key="topic">#{{topic}}</span></div><small>喜欢 {{post.likeCount}} · 评论 {{post.commentCount}}</small></div>
      </RouterLink>
    </div>
  </section>
</template>
