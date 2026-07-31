<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebReviewError, reviewStringsForRegion } from '@/core/web_review_localizations'
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
const copy = computed(() => reviewStringsForRegion(appState.region))
const certificationCopy = computed(() => discoveryStringsForRegion(appState.region).shopCard)
const auditBanner = computed(() => {
  if (!props.owned) return ''
  const marker = String(route.query.audit || '')
  if (marker === 'approved') return copy.value.detail.auditApproved
  if (marker === 'rejected') return copy.value.detail.auditRejected
  return ''
})
const hiddenBanner = computed(() => {
  if (!props.owned) return ''
  const marker = String(route.query.hidden || '')
  if (marker === 'appeal') return copy.value.detail.hiddenByAppeal
  return ''
})
const comments = ref<ReviewComment[]>([])
const commentContent = ref('')
const activeReplyTarget = ref<ReviewComment | null>(null)
const reportReason = ref('')
const reportPanelOpen = ref(false)
const shareMessage = ref('')
let reviewRequestId = 0
let commentsRequestId = 0

function normalizeReviewComments(list: ReviewComment[]): ReviewComment[] {
  return list.map((comment) => ({
    ...comment,
    replies: Array.isArray(comment.replies) ? normalizeReviewComments(comment.replies) : [],
  }))
}

async function shareReview() {
  if (!review.value) return
  shareMessage.value = ''
  const payload = {
    title: copy.value.detail.shareTitle(review.value.shopName, review.value.userName),
    text: `${review.value.shopName} · ${review.value.userName} · ★ ${review.value.scoreOverall}`,
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
    shareMessage.value = copy.value.detail.shareReady
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') return
    shareMessage.value = localizeWebReviewError(copy.value, error, copy.value.detail.shareFailed)
  }
}

useSeoMeta(() => {
  const canonicalPath = `/reviews/${props.reviewId}`
  const currentReview = review.value
  const isPublic = !props.owned && currentReview?.auditStatus === 1 && currentReview.status === 1
  if (!currentReview) {
    return {
      title: props.owned ? copy.value.detail.ownedSeoTitle : copy.value.detail.publicSeoTitle,
      description: copy.value.detail.seoDescription,
      canonical: canonicalPath,
      robots: 'noindex,nofollow',
    }
  }

  return {
    title: copy.value.detail.seoTitleFor(currentReview.shopName, currentReview.userName),
    description: toSeoDescription(copy.value.detail.seoDescriptionFor(currentReview.shopName, currentReview.content)),
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
    errorMessage.value = copy.value.detail.invalidId
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
      errorMessage.value = localizeWebReviewError(copy.value, error, copy.value.detail.loadFailed)
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
    comments.value = normalizeReviewComments(page.list)
  } catch (error) {
    if (parentRequestId === reviewRequestId && requestId === commentsRequestId) {
      commentsErrorMessage.value = localizeWebReviewError(copy.value, error, copy.value.detail.commentsLoadFailed)
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
    interactionMessage.value = result.liked ? copy.value.detail.liked : copy.value.detail.likeRemoved
  } catch (error) {
    interactionErrorMessage.value = localizeWebReviewError(copy.value, error, copy.value.detail.likeFailed)
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
    interactionErrorMessage.value = copy.value.detail.commentRequired
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
    interactionMessage.value = replyTo ? copy.value.detail.replySent : copy.value.detail.commentSent
  } catch (error) {
    interactionErrorMessage.value = localizeWebReviewError(copy.value, error, copy.value.detail.commentFailed)
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
    interactionErrorMessage.value = copy.value.detail.reportRequired
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
    interactionMessage.value = copy.value.detail.reportSent
  } catch (error) {
    interactionErrorMessage.value = localizeWebReviewError(copy.value, error, copy.value.detail.reportFailed)
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
  <p v-else-if="loading" class="feedback">{{ copy.detail.loading }}</p>

  <template v-else-if="review">
    <section class="detail-hero detail-hero--compact">
      <div class="detail-hero__body">
        <p class="eyebrow">{{ owned ? copy.detail.ownedEyebrow : copy.detail.publicEyebrow }}</p>
        <h1>{{ review.shopName }}</h1>
        <p v-if="auditBanner" class="feedback is-success" data-testid="review-audit-banner">{{ auditBanner }}</p>
        <p v-if="hiddenBanner" class="feedback is-error" data-testid="review-hidden-banner">{{ hiddenBanner }}</p>
        <p class="detail-hero__summary">
          <span class="name-with-badge">
            <RouterLink v-if="review.userId > 0" :to="`/users/${review.userId}`" class="inline-link">
              {{ review.userName }}
            </RouterLink>
            <template v-else>
              <span>{{ review.userName }}</span>
            </template>
            <span v-if="review.authorCertification" class="verified-badge verified-badge--compact">
              {{ certificationCopy.certificationLabel(review.authorCertification.code, review.authorCertification.label) }}
            </span>
            <span>· {{ appState.region }} · {{ formatWebDateTime(review.createdAt, copy.tag) }}</span>
          </span>
          <span v-if="owned"> · {{ copy.detail.lastUpdated }} {{ formatWebDateTime(review.updatedAt, copy.tag) }}</span>
        </p>

        <div class="detail-hero__stats">
          <div>
            <span>{{ copy.detail.overallScore }}</span>
            <strong>{{ review.scoreOverall.toFixed(1) }}</strong>
          </div>
          <div>
            <span>{{ copy.detail.averageSpend }}</span>
            <strong>{{ formatMoney(review.cost, review.currency, 2) }}</strong>
          </div>
          <div>
            <span>{{ copy.detail.auditStatus }}</span>
            <strong>{{ copy.detail.auditStatusLabel(review.auditStatus, review.auditStatusText) }}</strong>
          </div>
        </div>

        <div class="hero-actions">
          <RouterLink :to="`/shops/${review.shopId}`" class="secondary-button">{{ copy.detail.backToShop }}</RouterLink>
          <button
            v-if="!owned"
            type="button"
            class="secondary-button"
            data-testid="share-review"
            @click="shareReview"
          >
            {{ copy.detail.share }}
          </button>
          <RouterLink v-if="owned" :to="`/reviews/${review.id}/edit`" class="primary-link">{{ copy.detail.continueEditing }}</RouterLink>
          <RouterLink v-if="owned && review.auditStatus === 1" :to="`/reviews/${review.id}`" class="ghost-button">
            {{ copy.detail.viewPublic }}
          </RouterLink>
        </div>
        <p
          v-if="shareMessage"
          class="feedback"
          role="status"
          data-testid="share-review-message"
        >
          {{ shareMessage }}
        </p>
      </div>

      <div class="hero-aside">
        <span :class="auditClass">{{ copy.detail.auditStatusLabel(review.auditStatus, review.auditStatusText) }}</span>
        <p class="support-copy">{{ copy.detail.taste }} {{ review.scoreTaste }} · {{ copy.detail.ambience }} {{ review.scoreEnv }} · {{ copy.detail.service }} {{ review.scoreService }}</p>
        <p class="support-copy">
          {{ copy.detail.likes }} {{ review.likeCount }} · {{ copy.detail.comments }} {{ review.commentCount }}
          <span v-if="interactionEnabled && review.likedByCurrentUser"> · {{ copy.detail.likedByYou }}</span>
        </p>
        <p v-if="review.auditRemark" class="feedback is-error">{{ copy.detail.rejectReason }}: {{ review.auditRemark }}</p>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.detail.bodyEyebrow }}</p>
          <h2>{{ copy.detail.bodyTitle }}</h2>
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
          <p class="eyebrow">{{ copy.detail.imagesEyebrow }}</p>
          <h2>{{ copy.detail.imagesTitle }}</h2>
        </div>
      </div>
      <div v-if="review.images.length > 0" class="photo-grid">
        <img v-for="image in review.images" :key="image.id" :src="image.url" :alt="review.shopName" />
      </div>
      <p v-else class="feedback">{{ copy.detail.noImages }}</p>
    </section>

    <section v-if="interactionEnabled" class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ copy.detail.interactionEyebrow }}</p>
          <h2>{{ copy.detail.interactionTitle }}</h2>
        </div>
      </div>

      <div class="interaction-toolbar">
        <button type="button" class="primary-button" :disabled="likeLoading" @click="handleToggleLike">
          {{ review.likedByCurrentUser ? copy.detail.unlike : copy.detail.like }} · {{ review.likeCount }}
        </button>
        <button type="button" class="ghost-button" @click="reportPanelOpen = !reportPanelOpen">
          {{ reportPanelOpen ? copy.detail.collapseReport : copy.detail.reportReview }}
        </button>
        <button v-if="!sessionState.accessToken" type="button" class="secondary-button" @click="promptLogin">
          {{ copy.detail.signInToInteract }}
        </button>
      </div>

      <div v-if="reportPanelOpen" class="report-panel">
        <label class="field field--full">
          <span>{{ copy.detail.reportReason }}</span>
          <textarea
            v-model="reportReason"
            maxlength="200"
            :placeholder="copy.detail.reportPlaceholder"
          />
        </label>
        <div class="report-panel__actions">
          <button type="button" class="secondary-button" @click="reportPanelOpen = false">{{ copy.detail.cancel }}</button>
          <button type="button" class="primary-button" :disabled="reportSubmitting" @click="submitReport">
            {{ reportSubmitting ? copy.detail.submitting : copy.detail.submitReport }}
          </button>
        </div>
      </div>

      <div class="comment-composer">
        <label class="field field--full">
          <span>{{ copy.detail.commentLabel }}</span>
          <textarea
            v-model="commentContent"
            maxlength="300"
            :placeholder="copy.detail.commentPlaceholder"
          />
        </label>
        <div v-if="activeReplyTarget" class="reply-banner">
          <span class="support-copy">{{ copy.detail.replyingTo(activeReplyTarget.userName) }}</span>
          <button type="button" class="ghost-button" @click="clearReplyTarget">{{ copy.detail.cancelReply }}</button>
        </div>
        <div class="comment-composer__actions">
          <span class="support-copy">{{ sessionState.accessToken ? copy.detail.commentPublic : copy.detail.signInToComment }}</span>
          <button
            v-if="sessionState.accessToken"
            type="button"
            class="primary-button"
            :disabled="commentSubmitting"
            @click="submitComment"
          >
            {{ commentSubmitting ? copy.detail.publishing : copy.detail.publishComment }}
          </button>
          <button v-else type="button" class="secondary-button" @click="submitComment">{{ copy.detail.signInFirst }}</button>
        </div>
      </div>

      <p v-if="interactionMessage" class="feedback is-success">{{ interactionMessage }}</p>
      <p v-if="interactionErrorMessage" class="feedback is-error">{{ interactionErrorMessage }}</p>

      <div class="section-header section-header--compact">
        <div>
          <p class="eyebrow">{{ copy.detail.commentsEyebrow }}</p>
          <h2>{{ copy.detail.commentsTitle }}</h2>
        </div>
      </div>

      <p v-if="commentsErrorMessage" class="feedback is-error">{{ commentsErrorMessage }}</p>
      <p v-else-if="commentsLoading" class="feedback">{{ copy.detail.commentsLoading }}</p>
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
            <span>{{ formatWebDateTime(item.createdAt, copy.tag) }}<template v-if="item.mine"> · {{ copy.detail.myComment }}</template></span>
          </div>
          <p>{{ item.content }}</p>
          <div class="comment-card__actions">
            <button type="button" class="ghost-button" @click="startReply(item)">{{ copy.detail.reply }}</button>
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
                <span>{{ formatWebDateTime(reply.createdAt, copy.tag) }}<template v-if="reply.mine"> · {{ copy.detail.myReply }}</template></span>
              </div>
              <p v-if="reply.replyTo" class="reply-context">{{ copy.detail.replyContext(reply.replyTo.userName, reply.replyTo.content) }}</p>
              <p>{{ reply.content }}</p>
              <div class="comment-card__actions">
                <button type="button" class="ghost-button" @click="startReply(reply)">{{ copy.detail.reply }}</button>
              </div>
            </article>
          </div>
        </article>
      </div>
      <p v-else class="feedback">{{ copy.detail.noComments }}</p>
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
