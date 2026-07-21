<script setup lang="ts">
import { ref, watch } from 'vue'
import { fetchPost, fetchPostComments } from '@/services/community'
import type { CommunityComment, CommunityPost } from '@/types/community'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
const props=defineProps<{postId:number}>(),post=ref<CommunityPost|null>(null),comments=ref<CommunityComment[]>([]),errorMessage=ref('')
let requestSequence = 0
useSeoMeta(() => {
  const canonicalPath = `/community/posts/${props.postId}`
  const currentPost = post.value
  if (!currentPost) return { title: '社区帖子', description: '阅读公开社区帖子与评论。', canonical: canonicalPath, robots: 'noindex,nofollow' }
  const canonical = absoluteSeoUrl(canonicalPath)
  return {
    title: currentPost.title,
    description: toSeoDescription(currentPost.content),
    canonical: canonicalPath,
    image: currentPost.images[0],
    type: 'article' as const,
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: currentPost.title,
      description: toSeoDescription(currentPost.content),
      articleBody: currentPost.content,
      articleSection: currentPost.topics,
      keywords: currentPost.topics.join(', '),
      url: canonical,
      mainEntityOfPage: { '@type': 'WebPage', '@id': canonical },
      image: currentPost.images.map(absoluteSeoUrl),
      author: { '@type': 'Person', name: currentPost.userName, url: absoluteSeoUrl(`/users/${currentPost.userId}`) },
      datePublished: currentPost.createdAt,
      interactionStatistic: [
        { '@type': 'InteractionCounter', interactionType: 'https://schema.org/LikeAction', userInteractionCount: currentPost.likeCount },
        { '@type': 'InteractionCounter', interactionType: 'https://schema.org/CommentAction', userInteractionCount: currentPost.commentCount },
      ],
    },
  }
})
watch(() => props.postId, async (postId) => {
  const request = ++requestSequence
  post.value = null
  comments.value = []
  errorMessage.value = ''
  try {
    const [detail, page] = await Promise.all([fetchPost(postId), fetchPostComments(postId)])
    if (request !== requestSequence) return
    post.value = detail
    comments.value = page.list
  } catch (e) {
    if (request === requestSequence) errorMessage.value = e instanceof Error ? e.message : '帖子加载失败'
  }
}, { immediate: true })
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
