<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { fetchPost, fetchPostComments } from '@/services/community'
import type { CommunityComment, CommunityPost } from '@/types/community'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { useAppContext } from '@/composables/useAppContext'
import { communityStringsForRegion, localizeWebCommunityError } from '@/core/web_community_localizations'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'

const props = defineProps<{ postId: number }>()
const route = useRoute()
const { state: appState } = useAppContext()
const copy = computed(() => communityStringsForRegion(appState.region))
const certificationCopy = computed(() => discoveryStringsForRegion(appState.region).shopCard)

const post = ref<CommunityPost | null>(null)
const comments = ref<CommunityComment[]>([])
const errorMessage = ref('')
const shareMessage = ref('')
let requestSequence = 0

const auditBanner = computed(() => {
  const marker = String(route.query.audit || '')
  if (marker === 'approved') return copy.value.post.auditApproved
  if (marker === 'rejected') return copy.value.post.auditRejected
  return ''
})

async function sharePost() {
  if (!post.value) return
  shareMessage.value = ''
  const payload = {
    title: post.value.title,
    text: `${post.value.title} · ${post.value.userName}`,
    url: window.location.href,
  }
  try {
    if (typeof navigator.share === 'function') {
      await navigator.share(payload)
    } else if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(payload.url)
    } else {
      const textarea = document.createElement('textarea')
      textarea.value = payload.url
      textarea.setAttribute('readonly', '')
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      textarea.remove()
    }
    shareMessage.value = copy.value.post.shareReady
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') return
    shareMessage.value = localizeWebCommunityError(copy.value, error, copy.value.post.shareFailed)
  }
}

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
      title: copy.value.post.seoTitle,
      description: copy.value.post.seoDescription,
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
  [() => props.postId, () => appState.region],
  async ([postId]) => {
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
        errorMessage.value = localizeWebCommunityError(copy.value, error, copy.value.post.loadFailed)
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
              {{ certificationCopy.certificationLabel(post.authorCertification.code, post.authorCertification.label) }}
            </span>
            <span>· {{ formatWebDateTime(post.createdAt, copy.tag) }}</span>
          </span>
        </p>
        <h1>{{ post.title }}</h1>
        <div class="tag-row">
          <span v-for="topic in post.topics" :key="topic">#{{ topic }}</span>
        </div>
      </div>
      <div class="hero-actions">
        <button
          type="button"
          class="secondary-button"
          data-testid="share-post"
          @click="sharePost"
        >
          {{ copy.post.share }}
        </button>
      </div>
    </div>

    <p v-if="auditBanner" class="feedback is-success" data-testid="post-audit-banner">{{ auditBanner }}</p>
    <p v-if="shareMessage" class="feedback" role="status" data-testid="share-post-message">{{ shareMessage }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card">
      <p>{{ post.content }}</p>
      <div v-if="post.images.length" class="gallery-grid">
        <img v-for="image in post.images" :key="image" :src="image" :alt="post.title" />
      </div>
    </article>

    <p class="feedback">{{ copy.post.readOnly }}</p>

    <section class="content-card">
      <h2>{{ copy.post.commentsTitle }}</h2>
      <div v-if="comments.length > 0" class="review-list review-list--threaded">
        <article v-for="item in comments" :key="item.id" class="review-card">
          <strong>{{ item.userName }}</strong>
          <p>{{ item.content }}</p>
          <span>{{ formatWebDateTime(item.createdAt, copy.tag) }}</span>
          <div v-if="item.replies.length" class="comment-thread">
            <article v-for="reply in item.replies" :key="reply.id" class="review-card review-card--reply">
              <strong>{{ reply.userName }}</strong>
              <p v-if="reply.replyTo" class="reply-context">{{ copy.post.replyContext(reply.replyTo.userName, reply.replyTo.content) }}</p>
              <p>{{ reply.content }}</p>
              <span>{{ formatWebDateTime(reply.createdAt, copy.tag) }}</span>
            </article>
          </div>
        </article>
      </div>
      <p v-else class="feedback">{{ copy.post.noComments }}</p>
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
