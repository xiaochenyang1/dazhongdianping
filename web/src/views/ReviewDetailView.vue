<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
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
const reportReason = ref('')
const reportPanelOpen = ref(false)

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
  if (Number.isNaN(props.reviewId)) {
    errorMessage.value = '点评 ID 不合法'
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    review.value = props.owned ? await fetchOwnedReviewDetail(props.reviewId) : await fetchReviewDetail(props.reviewId)
    if (interactionEnabled.value) {
      await loadComments()
    } else {
      comments.value = []
      commentsErrorMessage.value = ''
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '点评详情加载失败'
  } finally {
    loading.value = false
  }
}

async function loadComments() {
  if (!interactionEnabled.value) {
    comments.value = []
    commentsErrorMessage.value = ''
    return
  }

  commentsLoading.value = true
  commentsErrorMessage.value = ''

  try {
    const page = await listReviewComments(props.reviewId, { page: 1, pageSize: 20 })
    comments.value = page.list
  } catch (error) {
    commentsErrorMessage.value = error instanceof Error ? error.message : '评论列表加载失败'
  } finally {
    commentsLoading.value = false
  }
}

async function handleToggleLike() {
  if (!review.value || !interactionEnabled.value || !ensureSignedIn(() => handleToggleLike())) {
    return
  }

  likeLoading.value = true
  resetInteractionFeedback()

  try {
    const result = await toggleReviewLike(review.value.id)
    review.value.likeCount = result.likeCount
    review.value.likedByCurrentUser = result.liked
    interactionMessage.value = result.liked ? '这次点赞真落下去了。' : '点赞已经取消。'
  } catch (error) {
    interactionErrorMessage.value = error instanceof Error ? error.message : '点赞操作失败'
  } finally {
    likeLoading.value = false
  }
}

async function submitComment() {
  if (!review.value || !interactionEnabled.value) {
    return
  }

  const content = commentContent.value.trim()
  if (!content) {
    interactionErrorMessage.value = '评论内容不能为空'
    return
  }
  if (!ensureSignedIn(() => submitComment())) {
    return
  }

  commentSubmitting.value = true
  resetInteractionFeedback()

  try {
    const created = await createReviewComment(review.value.id, { content })
    comments.value = [created, ...comments.value]
    review.value.commentCount += 1
    commentContent.value = ''
    interactionMessage.value = '评论已经发出去了。'
  } catch (error) {
    interactionErrorMessage.value = error instanceof Error ? error.message : '评论发布失败'
  } finally {
    commentSubmitting.value = false
  }
}

async function submitReport() {
  if (!review.value || !interactionEnabled.value) {
    return
  }

  const reason = reportReason.value.trim()
  if (!reason) {
    interactionErrorMessage.value = '举报理由不能为空'
    return
  }
  if (!ensureSignedIn(() => submitReport())) {
    return
  }

  reportSubmitting.value = true
  resetInteractionFeedback()

  try {
    await reportReview(review.value.id, { reason })
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
          <h2>当前先做平铺评论，够用就先别折腾盖楼。</h2>
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
        </article>
      </div>
      <p v-else class="feedback">这条点评现在还没人评论，你要不先开个头。</p>
    </section>
  </template>
</template>
