<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { formatMoney } from '@/lib/currency'
import {
  createReviewComment,
  fetchOwnedReviewDetail,
  fetchReviewDetail,
  listReviewComments,
  reportReview,
  toggleReviewLike,
} from '@/services/review'
import type { ReviewComment, ReviewDetail } from '@/types/review'

const props = defineProps<{
  reviewId: number
  owned?: boolean
}>()

const route = useRoute()
const { state: appState } = useAppContext()
const { state: sessionState, openAuthDialog } = useUserSession()

const loading = ref(false)
const commentsLoading = ref(false)
const likeLoading = ref(false)
const commentSubmitting = ref(false)
const reportSubmitting = ref(false)
const errorMessage = ref('')
const commentsErrorMessage = ref('')
const interactionMessage = ref('')
const interactionErrorMessage = ref('')
const review = ref<ReviewDetail | null>(null)
const comments = ref<ReviewComment[]>([])
const commentContent = ref('')
const activeReplyTarget = ref<ReviewComment | null>(null)
const reportReason = ref('')
const reportPanelOpen = ref(false)
let reviewRequestId = 0
let commentsRequestId = 0

useSeoMeta(() => {
  const canonicalPath = `/reviews/${props.reviewId}`
  const currentReview = review.value
  const isPublic = !props.owned && currentReview?.auditStatus === 1 && currentReview.status === 1
  if (!currentReview) {
    return {
      title: props.owned ? '我的点评详情' : '点评详情',
      description: '查看公开点评详情、图片、点赞、评论和举报入口。',
      canonical: canonicalPath,
      robots: 'noindex,nofollow',
    }
  }

  return {
    title: `${currentReview.shopName}点评 - ${currentReview.userName}`,
    description: toSeoDescription(`${currentReview.shopName} 的公开点评：${currentReview.content}`),
    canonical: canonicalPath,
    robots: isPublic ? 'index,follow' : 'noindex,nofollow',
    image: currentReview.images[0]?.url,
    type: 'article' as const,
    jsonLd: isPublic
      ? {
          '@context': 'https://schema.org',
          '@type': 'Review',
          url: absoluteSeoUrl(canonicalPath),
          author: { '@type': 'Person', name: currentReview.userName },
          datePublished: currentReview.createdAt,
          dateModified: currentReview.updatedAt,
          reviewBody: currentReview.content,
          reviewRating: {
            '@type': 'Rating',
            ratingValue: currentReview.scoreOverall,
            bestRating: 5,
            worstRating: 1,
          },
          itemReviewed: {
            '@type': 'Restaurant',
            name: currentReview.shopName,
            url: absoluteSeoUrl(`/shops/${currentReview.shopId}`),
          },
        }
      : null,
  }
})

const auditClass = computed(() => {
  const auditStatus = review.value?.auditStatus ?? 0
  if (auditStatus === 1) {
    return 'status-pill status-pill--good'
  }
  if (auditStatus === 2) {
    return 'status-pill status-pill--muted'
  }
  return 'status-pill status-pill--warn'
})

const interactionEnabled = computed(
  () => !props.owned && review.value?.auditStatus === 1 && review.value?.status === 1,
)

function resetInteractionFeedback() {
  interactionMessage.value = ''
  interactionErrorMessage.value = ''
}

function resolveInteractionReviewId(resumedReviewId?: unknown) {
  return typeof resumedReviewId === 'number'
    ? resumedReviewId
    : review.value?.id ?? (!props.owned ? props.reviewId : undefined)
}

function ensureSignedIn(afterLogin?: () => void | Promise<void>) {
  if (sessionState.accessToken) {
    return true
  }

  openAuthDialog({
    mode: 'password',
    redirectTo: route.fullPath,
    afterLogin,
  })
  return false
}

async function loadReview() {
  const requestId = ++reviewRequestId
  ++commentsRequestId
  const targetReviewId = props.reviewId
  const owned = props.owned
  review.value = null
  comments.value = []
  commentsLoading.value = false
  errorMessage.value = ''
  commentsErrorMessage.value = ''
  resetInteractionFeedback()
  reportPanelOpen.value = false
  activeReplyTarget.value = null
  if (Number.isNaN(targetReviewId)) {
    errorMessage.value = '点评 ID 不合法'
    loading.value = false
    return
  }

  loading.value = true

  try {
    const detail = owned
      ? await fetchOwnedReviewDetail(targetReviewId)
      : await fetchReviewDetail(targetReviewId)
    if (requestId !== reviewRequestId) return
    review.value = detail
    if (interactionEnabled.value) {
      await loadComments(targetReviewId, requestId)
    } else {
      comments.value = []
      commentsErrorMessage.value = ''
    }
  } catch (error) {
    if (requestId === reviewRequestId) {
      errorMessage.value = error instanceof Error ? error.message : '点评详情加载失败'
    }
  } finally {
    if (requestId === reviewRequestId) loading.value = false
  }
}

async function loadComments(reviewId = props.reviewId, parentRequestId = reviewRequestId) {
  const requestId = ++commentsRequestId
  if (parentRequestId !== reviewRequestId) return
  if (!interactionEnabled.value) {
    comments.value = []
    commentsErrorMessage.value = ''
    return
  }

  commentsLoading.value = true
  commentsErrorMessage.value = ''

  try {
    const page = await listReviewComments(reviewId, { page: 1, pageSize: 20 })
    if (parentRequestId !== reviewRequestId || requestId !== commentsRequestId) return
    comments.value = page.list
  } catch (error) {
    if (parentRequestId === reviewRequestId && requestId === commentsRequestId) {
      commentsErrorMessage.value = error instanceof Error ? error.message : '评论列表加载失败'
    }
  } finally {
    if (parentRequestId === reviewRequestId && requestId === commentsRequestId) {
      commentsLoading.value = false
    }
  }
}

async function handleToggleLike(resumedReviewId?: unknown) {
  const targetReviewId = resolveInteractionReviewId(resumedReviewId)
  const hasResumedReviewId = typeof resumedReviewId === 'number'
  if (!targetReviewId || (!hasResumedReviewId && !interactionEnabled.value)) {
    return
  }
  if (!ensureSignedIn(() => handleToggleLike(targetReviewId))) {
    return
  }

  likeLoading.value = true
  resetInteractionFeedback()

  try {
    const result = await toggleReviewLike(targetReviewId)
    if (review.value?.id === targetReviewId) {
      review.value.likeCount = result.likeCount
      review.value.likedByCurrentUser = result.liked
    } else {
      await loadReview()
    }
    interactionMessage.value = result.liked ? '这次点赞真落下去了。' : '点赞已经取消。'
  } catch (error) {
    interactionErrorMessage.value = error instanceof Error ? error.message : '点赞操作失败'
  } finally {
    likeLoading.value = false
  }
}

async function submitComment(resumedReviewId?: unknown, resumedContent?: unknown) {
  const targetReviewId = resolveInteractionReviewId(resumedReviewId)
  const hasResumedReviewId = typeof resumedReviewId === 'number'
  if (!targetReviewId || (!hasResumedReviewId && !interactionEnabled.value)) {
    return
  }

  const contentSource = typeof resumedContent === 'string' ? resumedContent : commentContent.value
  const content = contentSource.trim()
  const replyTo =
    activeReplyTarget.value && activeReplyTarget.value.id > 0 ? activeReplyTarget.value.id : undefined
  if (!content) {
    interactionErrorMessage.value = '评论内容不能为空'
    return
  }
  if (!ensureSignedIn(() => submitComment(targetReviewId, content))) {
    return
  }

  commentSubmitting.value = true
  resetInteractionFeedback()

  try {
    await createReviewComment(targetReviewId, replyTo ? { content, replyTo } : { content })
    if (review.value?.id === targetReviewId) {
      review.value.commentCount += 1
      await loadComments(targetReviewId)
    } else {
      await loadReview()
    }
    commentContent.value = ''
    activeReplyTarget.value = null
    interactionMessage.value = replyTo ? '回复已经发出去了。' : '评论已经发出去了。'
  } catch (error) {
    interactionErrorMessage.value = error instanceof Error ? error.message : '评论发布失败'
  } finally {
    commentSubmitting.value = false
  }
}

function startReply(target: ReviewComment) {
  resetInteractionFeedback()
  if (!ensureSignedIn()) {
    return
  }
  activeReplyTarget.value = target
}

function clearReplyTarget() {
  activeReplyTarget.value = null
}

async function submitReport(resumedReviewId?: unknown, resumedReason?: unknown) {
  const targetReviewId = resolveInteractionReviewId(resumedReviewId)
  const hasResumedReviewId = typeof resumedReviewId === 'number'
  if (!targetReviewId || (!hasResumedReviewId && !interactionEnabled.value)) {
    return
  }

  const reasonSource = typeof resumedReason === 'string' ? resumedReason : reportReason.value
  const reason = reasonSource.trim()
  if (!reason) {
    interactionErrorMessage.value = '举报理由不能为空'
    return
  }
  if (!ensureSignedIn(() => submitReport(targetReviewId, reason))) {
    return
  }

  reportSubmitting.value = true
  resetInteractionFeedback()

  try {
    await reportReview(targetReviewId, { reason })
    if (!review.value || review.value.id !== targetReviewId) {
      await loadReview()
    }
    reportReason.value = ''
    reportPanelOpen.value = false
    interactionMessage.value = '举报已提交，后台会复核这条点评。'
  } catch (error) {
    interactionErrorMessage.value = error instanceof Error ? error.message : '举报提交失败'
  } finally {
    reportSubmitting.value = false
  }
}

function promptLogin() {
  resetInteractionFeedback()
  ensureSignedIn()
}

watch(
  () => [props.reviewId, props.owned, appState.region],
  () => {
    void loadReview()
  },
  { immediate: true },
)

watch(
  () => sessionState.accessToken,
  () => {
    if (!props.owned) {
      void loadReview()
    }
  },
)
</script>

<template>
  <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
  <p v-else-if="loading" class="feedback">点评详情加载中...</p>

  <template v-else-if="review">
    <section class="detail-hero detail-hero--compact">
      <div class="detail-hero__body">
        <p class="eyebrow">{{ owned ? '我的点评详情' : '公开点评详情' }}</p>
        <h1>{{ review.shopName }}</h1>
        <p class="detail-hero__summary">
          <RouterLink v-if="review.userId > 0" :to="`/users/${review.userId}`" class="inline-link">
            {{ review.userName }}
          </RouterLink>
          <template v-else>
            {{ review.userName }}
          </template>
          · {{ appState.region }} · {{ review.createdAt }}
          <span v-if="owned"> · 最后更新 {{ review.updatedAt }}</span>
        </p>

        <div class="detail-hero__stats">
          <div>
            <span>综合评分</span>
            <strong>{{ review.scoreOverall.toFixed(1) }}</strong>
          </div>
          <div>
            <span>人均消费</span>
            <strong>{{ formatMoney(review.cost, review.currency, 2) }}</strong>
          </div>
          <div>
            <span>审核状态</span>
            <strong>{{ review.auditStatusText }}</strong>
          </div>
        </div>

        <div class="hero-actions">
          <RouterLink :to="`/shops/${review.shopId}`" class="secondary-button">回到门店</RouterLink>
          <RouterLink v-if="owned" :to="`/reviews/${review.id}/edit`" class="primary-link">继续编辑</RouterLink>
          <RouterLink v-if="owned && review.auditStatus === 1" :to="`/reviews/${review.id}`" class="ghost-button">
            看公开页
          </RouterLink>
        </div>
      </div>

      <div class="hero-aside">
        <span :class="auditClass">{{ review.auditStatusText }}</span>
        <p class="support-copy">口味 {{ review.scoreTaste }} · 环境 {{ review.scoreEnv }} · 服务 {{ review.scoreService }}</p>
        <p class="support-copy">
          点赞 {{ review.likeCount }} · 评论 {{ review.commentCount }}
          <span v-if="interactionEnabled && review.likedByCurrentUser"> · 你已点赞</span>
        </p>
        <p v-if="review.auditRemark" class="feedback is-error">驳回原因：{{ review.auditRemark }}</p>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">点评正文</p>
          <h2>该说的体验都摆这儿，别整那些空心文案。</h2>
        </div>
      </div>
      <p class="rich-copy">{{ review.content }}</p>
      <div class="tag-row">
        <span v-for="tag in review.tags" :key="tag">{{ tag }}</span>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">点评图片</p>
          <h2>现在已经接了本地上传，图片 URL 不用再手填那套破事了。</h2>
        </div>
      </div>
      <div v-if="review.images.length > 0" class="photo-grid">
        <img v-for="image in review.images" :key="image.id" :src="image.url" :alt="review.shopName" />
      </div>
      <p v-else class="feedback">这条点评当前没有图片。</p>
    </section>

    <section v-if="interactionEnabled" class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">互动区</p>
          <h2>点赞、评论、举报这套链路已经落了，别再只是看个热闹。</h2>
        </div>
      </div>

      <div class="interaction-toolbar">
        <button type="button" class="primary-button" :disabled="likeLoading" @click="handleToggleLike">
          {{ review.likedByCurrentUser ? '取消点赞' : '给个赞' }} · {{ review.likeCount }}
        </button>
        <button type="button" class="ghost-button" @click="reportPanelOpen = !reportPanelOpen">
          {{ reportPanelOpen ? '先收起举报' : '举报这条点评' }}
        </button>
        <button v-if="!sessionState.accessToken" type="button" class="secondary-button" @click="promptLogin">
          登录后互动
        </button>
      </div>

      <div v-if="reportPanelOpen" class="report-panel">
        <label class="field field--full">
          <span>举报理由</span>
          <textarea
            v-model="reportReason"
            maxlength="200"
            placeholder="别写空话，直接说你觉得哪儿有问题。"
          />
        </label>
        <div class="report-panel__actions">
          <button type="button" class="secondary-button" @click="reportPanelOpen = false">取消</button>
          <button type="button" class="primary-button" :disabled="reportSubmitting" @click="submitReport">
            {{ reportSubmitting ? '提交中...' : '提交举报' }}
          </button>
        </div>
      </div>

      <div class="comment-composer">
        <label class="field field--full">
          <span>写条评论</span>
          <textarea
            v-model="commentContent"
            maxlength="300"
            placeholder="说人话，别整复制粘贴那一套。"
          />
        </label>
        <div v-if="activeReplyTarget" class="reply-banner">
          <span class="support-copy">正在回复 {{ activeReplyTarget.userName }}</span>
          <button type="button" class="ghost-button" @click="clearReplyTarget">取消回复</button>
        </div>
        <div class="comment-composer__actions">
          <span class="support-copy">{{ sessionState.accessToken ? '当前评论会直接公开展示在这条点评下。' : '登录后才能评论。' }}</span>
          <button
            v-if="sessionState.accessToken"
            type="button"
            class="primary-button"
            :disabled="commentSubmitting"
            @click="submitComment"
          >
            {{ commentSubmitting ? '发布中...' : '发布评论' }}
          </button>
          <button v-else type="button" class="secondary-button" @click="submitComment">先登录再说</button>
        </div>
      </div>

      <p v-if="interactionMessage" class="feedback is-success">{{ interactionMessage }}</p>
      <p v-if="interactionErrorMessage" class="feedback is-error">{{ interactionErrorMessage }}</p>

      <div class="section-header section-header--compact">
        <div>
          <p class="eyebrow">评论列表</p>
          <h2>现在是真盖楼了，回谁、挂哪层，都别再装没看见。</h2>
        </div>
      </div>

      <p v-if="commentsErrorMessage" class="feedback is-error">{{ commentsErrorMessage }}</p>
      <p v-else-if="commentsLoading" class="feedback">评论列表加载中...</p>
      <div v-else-if="comments.length > 0" class="comment-list">
        <article v-for="item in comments" :key="item.id" class="comment-card">
          <div class="comment-card__header">
            <strong>
              <RouterLink v-if="item.userId > 0" :to="`/users/${item.userId}`" class="inline-link">
                {{ item.userName }}
              </RouterLink>
              <template v-else>
                {{ item.userName }}
              </template>
            </strong>
            <span>{{ item.createdAt }}<template v-if="item.mine"> · 我的评论</template></span>
          </div>
          <p>{{ item.content }}</p>
          <div class="comment-card__actions">
            <button type="button" class="ghost-button" @click="startReply(item)">回复</button>
          </div>
          <div v-if="item.replies.length > 0" class="comment-replies">
            <article v-for="reply in item.replies" :key="reply.id" class="comment-card comment-card--reply">
              <div class="comment-card__header">
                <strong>
                  <RouterLink v-if="reply.userId > 0" :to="`/users/${reply.userId}`" class="inline-link">
                    {{ reply.userName }}
                  </RouterLink>
                  <template v-else>
                    {{ reply.userName }}
                  </template>
                </strong>
                <span>{{ reply.createdAt }}<template v-if="reply.mine"> · 我的回复</template></span>
              </div>
              <p v-if="reply.replyTo" class="reply-context">回复 {{ reply.replyTo.userName }}：{{ reply.replyTo.content }}</p>
              <p>{{ reply.content }}</p>
              <div class="comment-card__actions">
                <button type="button" class="ghost-button" @click="startReply(reply)">回复</button>
              </div>
            </article>
          </div>
        </article>
      </div>
      <p v-else class="feedback">这条点评现在还没人评论，你要不先开个头。</p>
    </section>
  </template>
</template>

<style scoped>
.reply-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin: 8px 0 0;
}

.comment-card__actions {
  margin-top: 10px;
}

.comment-replies {
  margin-top: 14px;
  padding-left: 18px;
  border-left: 2px solid rgba(148, 163, 184, 0.28);
  display: grid;
  gap: 12px;
}

.comment-card--reply {
  background: rgba(248, 250, 252, 0.9);
}

.reply-context {
  margin-bottom: 8px;
  color: #64748b;
}
</style>
