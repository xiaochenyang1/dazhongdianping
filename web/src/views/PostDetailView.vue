<script setup lang="ts">
import { ref, watch } from 'vue'
import { fetchPost, fetchPostComments } from '@/services/community'
import type { CommunityComment, CommunityPost } from '@/types/community'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'

const props = defineProps<{ postId: number }>()

const post = ref<CommunityPost | null>(null)
const comments = ref<CommunityComment[]>([])
const errorMessage = ref('')
let requestSequence = 0

function normalizeCommunityComments(list: CommunityComment[]): CommunityComment[] {
  return list.map((comment) => ({
    ...comment,
    replies: Array.isArray(comment.replies) ? normalizeCommunityComments(comment.replies) : [],
  }))
}

useSeoMeta(() => {
  const canonicalPath = `/community/posts/${props.postId}`
  const currentPost = post.value
  if (!currentPost) {
    return {
      title: '社区帖子',
      description: '阅读公开社区帖子与评论。',
      canonical: canonicalPath,
      robots: 'noindex,nofollow',
    }
  }
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
      author: {
        '@type': 'Person',
        name: currentPost.userName,
        url: absoluteSeoUrl(`/users/${currentPost.userId}`),
      },
      datePublished: currentPost.createdAt,
      interactionStatistic: [
        {
          '@type': 'InteractionCounter',
          interactionType: 'https://schema.org/LikeAction',
          userInteractionCount: currentPost.likeCount,
        },
        {
          '@type': 'InteractionCounter',
          interactionType: 'https://schema.org/CommentAction',
          userInteractionCount: currentPost.commentCount,
        },
      ],
    },
  }
})

watch(
  () => props.postId,
  async (postId) => {
    const request = ++requestSequence
    post.value = null
    comments.value = []
    errorMessage.value = ''
    try {
      const [detail, page] = await Promise.all([fetchPost(postId), fetchPostComments(postId)])
      if (request !== requestSequence) return
      post.value = detail
      comments.value = normalizeCommunityComments(page.list)
    } catch (error) {
      if (request === requestSequence) {
        errorMessage.value = error instanceof Error ? error.message : '帖子加载失败'
      }
    }
  },
  { immediate: true },
)
</script>

<template>
  <section v-if="post" class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">
          <span class="name-with-badge">
            <RouterLink :to="`/users/${post.userId}`">{{ post.userName }}</RouterLink>
            <span v-if="post.authorCertification" class="verified-badge verified-badge--compact">
              {{ post.authorCertification.label }}
            </span>
            <span>· {{ post.createdAt }}</span>
          </span>
        </p>
        <h1>{{ post.title }}</h1>
        <div class="tag-row">
          <span v-for="topic in post.topics" :key="topic">#{{ topic }}</span>
        </div>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card">
      <p>{{ post.content }}</p>
      <div v-if="post.images.length" class="gallery-grid">
        <img v-for="image in post.images" :key="image" :src="image" :alt="post.title" />
      </div>
    </article>

    <p class="feedback">PC 端现在还是只读；想互动就去 APP，别在这儿硬抠按钮。</p>

    <section class="content-card">
      <h2>公开评论</h2>
      <div v-if="comments.length > 0" class="review-list review-list--threaded">
        <article v-for="item in comments" :key="item.id" class="review-card">
          <strong>{{ item.userName }}</strong>
          <p>{{ item.content }}</p>
          <span>{{ item.createdAt }}</span>
          <div v-if="item.replies.length" class="comment-thread">
            <article v-for="reply in item.replies" :key="reply.id" class="review-card review-card--reply">
              <strong>{{ reply.userName }}</strong>
              <p v-if="reply.replyTo" class="reply-context">回复 {{ reply.replyTo.userName }}：{{ reply.replyTo.content }}</p>
              <p>{{ reply.content }}</p>
              <span>{{ reply.createdAt }}</span>
            </article>
          </div>
        </article>
      </div>
      <p v-else class="feedback">这条帖子下面还没人开口。</p>
    </section>
  </section>

  <p v-else-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
</template>

<style scoped>
.review-list--threaded {
  display: grid;
  gap: 16px;
}

.comment-thread {
  margin-top: 14px;
  padding-left: 18px;
  border-left: 2px solid rgba(148, 163, 184, 0.28);
  display: grid;
  gap: 12px;
}

.review-card--reply {
  background: rgba(248, 250, 252, 0.92);
}

.reply-context {
  color: #64748b;
}
</style>
