import type { Region } from '@/types/browse'

export interface WebReviewStrings {
  tag: 'zh-CN' | 'en'
  detail: {
    auditApproved: string
    auditRejected: string
    hiddenByAppeal: string
    shareTitle: (shop: string, user: string) => string
    shareReady: string
    shareFailed: string
    ownedSeoTitle: string
    publicSeoTitle: string
    seoDescription: string
    seoTitleFor: (shop: string, user: string) => string
    seoDescriptionFor: (shop: string, content: string) => string
    invalidId: string
    loadFailed: string
    commentsLoadFailed: string
    liked: string
    likeRemoved: string
    likeFailed: string
    commentRequired: string
    replySent: string
    commentSent: string
    commentFailed: string
    reportRequired: string
    reportSent: string
    reportFailed: string
    loading: string
    ownedEyebrow: string
    publicEyebrow: string
    lastUpdated: string
    overallScore: string
    averageSpend: string
    auditStatus: string
    auditStatusLabel: (status: number, fallback: string) => string
    backToShop: string
    share: string
    continueEditing: string
    viewPublic: string
    taste: string
    ambience: string
    service: string
    likes: string
    comments: string
    likedByYou: string
    rejectReason: string
    bodyEyebrow: string
    bodyTitle: string
    imagesEyebrow: string
    imagesTitle: string
    noImages: string
    interactionEyebrow: string
    interactionTitle: string
    unlike: string
    like: string
    collapseReport: string
    reportReview: string
    signInToInteract: string
    reportReason: string
    reportPlaceholder: string
    cancel: string
    submitting: string
    submitReport: string
    commentLabel: string
    commentPlaceholder: string
    replyingTo: (user: string) => string
    cancelReply: string
    commentPublic: string
    signInToComment: string
    publishing: string
    publishComment: string
    signInFirst: string
    commentsEyebrow: string
    commentsTitle: string
    commentsLoading: string
    myComment: string
    reply: string
    myReply: string
    replyContext: (user: string, content: string) => string
    noComments: string
  }
  editor: {
    editTitle: string
    createTitle: string
    editSummary: string
    createSummary: string
    formFallback: string
    missingShop: string
    loadFailed: string
    maxImages: string
    remainingImages: (count: number) => string
    uploadedImages: (count: number) => string
    uploadFailed: string
    submitFailed: string
    loading: string
    ratingsEyebrow: string
    ratingsTitle: string
    overallScore: string
    tasteScore: string
    ambienceScore: string
    serviceScore: string
    spend: string
    spendPlaceholder: string
    currency: string
    tags: string
    tagsPlaceholder: string
    body: string
    bodyPlaceholder: string
    uploadEyebrow: string
    uploadTitle: string
    uploading: string
    uploadedCount: (count: number) => string
    selectImages: string
    uploadSupport: string
    imageAlt: (index: number) => string
    imageLabel: (index: number) => string
    remove: string
    noImages: string
    submitting: string
    saveAndResubmit: string
    submitReview: string
    backToShop: string
  }
  errorTranslations: Record<string, string>
}

const zhCnStrings: WebReviewStrings = {
  tag: 'zh-CN',
  detail: {
    auditApproved: '平台已通过你的点评，现可公开展示。',
    auditRejected: '平台未通过你的点评，请查看驳回原因后修改重提。',
    hiddenByAppeal: '商户申诉成立，你的点评已从公开展示中隐藏。',
    shareTitle: (shop, user) => `${shop}点评 - ${user}`,
    shareReady: '分享链接已准备好',
    shareFailed: '分享失败，请稍后重试',
    ownedSeoTitle: '我的点评详情',
    publicSeoTitle: '点评详情',
    seoDescription: '查看公开点评详情、图片、点赞、评论和举报入口。',
    seoTitleFor: (shop, user) => `${shop}点评 - ${user}`,
    seoDescriptionFor: (shop, content) => `${shop} 的公开点评：${content}`,
    invalidId: '点评 ID 不合法',
    loadFailed: '点评详情加载失败',
    commentsLoadFailed: '评论列表加载失败',
    liked: '这次点赞真落下去了。',
    likeRemoved: '点赞已经取消。',
    likeFailed: '点赞操作失败',
    commentRequired: '评论内容不能为空',
    replySent: '回复已经发出去了。',
    commentSent: '评论已经发出去了。',
    commentFailed: '评论发布失败',
    reportRequired: '举报理由不能为空',
    reportSent: '举报已提交，后台会复核这条点评。',
    reportFailed: '举报提交失败',
    loading: '点评详情加载中...',
    ownedEyebrow: '我的点评详情',
    publicEyebrow: '公开点评详情',
    lastUpdated: '最后更新',
    overallScore: '综合评分',
    averageSpend: '人均消费',
    auditStatus: '审核状态',
    auditStatusLabel: (_status, fallback) => fallback,
    backToShop: '回到门店',
    share: '分享',
    continueEditing: '继续编辑',
    viewPublic: '看公开页',
    taste: '口味',
    ambience: '环境',
    service: '服务',
    likes: '点赞',
    comments: '评论',
    likedByYou: '你已点赞',
    rejectReason: '驳回原因',
    bodyEyebrow: '点评正文',
    bodyTitle: '该说的体验都摆这儿，别整那些空心文案。',
    imagesEyebrow: '点评图片',
    imagesTitle: '现在已经接了本地上传，图片 URL 不用再手填那套破事了。',
    noImages: '这条点评当前没有图片。',
    interactionEyebrow: '互动区',
    interactionTitle: '点赞、评论、举报这套链路已经落了，别再只是看个热闹。',
    unlike: '取消点赞',
    like: '给个赞',
    collapseReport: '先收起举报',
    reportReview: '举报这条点评',
    signInToInteract: '登录后互动',
    reportReason: '举报理由',
    reportPlaceholder: '别写空话，直接说你觉得哪儿有问题。',
    cancel: '取消',
    submitting: '提交中...',
    submitReport: '提交举报',
    commentLabel: '写条评论',
    commentPlaceholder: '说人话，别整复制粘贴那一套。',
    replyingTo: (user) => `正在回复 ${user}`,
    cancelReply: '取消回复',
    commentPublic: '当前评论会直接公开展示在这条点评下。',
    signInToComment: '登录后才能评论。',
    publishing: '发布中...',
    publishComment: '发布评论',
    signInFirst: '先登录再说',
    commentsEyebrow: '评论列表',
    commentsTitle: '现在是真盖楼了，回谁、挂哪层，都别再装没看见。',
    commentsLoading: '评论列表加载中...',
    myComment: '我的评论',
    reply: '回复',
    myReply: '我的回复',
    replyContext: (user, content) => `回复 ${user}：${content}`,
    noComments: '这条点评现在还没人评论，你要不先开个头。',
  },
  editor: {
    editTitle: '编辑点评',
    createTitle: '写点评',
    editSummary: '改完会重新进入审核，图片现在可以直接本地上传。',
    createSummary: '本地版本已经接了图片上传，别再手填 URL 了。',
    formFallback: '点评表单',
    missingShop: '门店信息不完整，没法写点评。',
    loadFailed: '点评编辑页加载失败',
    maxImages: '最多只能上传 9 张图片',
    remainingImages: (count) => `最多还能上传 ${count} 张图片，多出来的这批先别硬塞。`,
    uploadedImages: (count) => `已上传 ${count} 张图片。`,
    uploadFailed: '图片上传失败',
    submitFailed: '点评提交失败',
    loading: '点评表单加载中...',
    ratingsEyebrow: '评分与正文',
    ratingsTitle: '把关键体验填完整，审核和聚合才有意义。',
    overallScore: '综合评分',
    tasteScore: '口味评分',
    ambienceScore: '环境评分',
    serviceScore: '服务评分',
    spend: '消费金额',
    spendPlaceholder: '本次消费金额',
    currency: '货币',
    tags: '标签',
    tagsPlaceholder: '用逗号分隔，比如：适合聚餐, 出锅稳, 回头率高',
    body: '点评正文',
    bodyPlaceholder: '把真实体验说清楚，别整五个字就想糊过去。',
    uploadEyebrow: '图片上传',
    uploadTitle: '现在直接传本地图片，别再靠手填 URL 硬顶了。',
    uploading: '图片上传中...',
    uploadedCount: (count) => `当前已上传 ${count} / 9 张`,
    selectImages: '选择图片',
    uploadSupport: '支持 jpg / png / gif，单张最多 5MB，最多 9 张。',
    imageAlt: (index) => `点评图片 ${index}`,
    imageLabel: (index) => `图片 ${index}`,
    remove: '移除',
    noImages: '还没上传图片，当前已经能直接从本地选图了。',
    submitting: '提交中...',
    saveAndResubmit: '保存并重新提审',
    submitReview: '提交点评',
    backToShop: '返回门店',
  },
  errorTranslations: {},
}

const enStrings: WebReviewStrings = {
  tag: 'en',
  detail: {
    auditApproved: 'Your review was approved and is now public.',
    auditRejected: 'Your review was not approved. Check the moderation note, edit it and resubmit.',
    hiddenByAppeal: 'The merchant appeal was accepted and your review is no longer publicly visible.',
    shareTitle: (shop, user) => `${shop} review by ${user}`,
    shareReady: 'Share link is ready',
    shareFailed: 'Could not share this review. Please try again.',
    ownedSeoTitle: 'My review details',
    publicSeoTitle: 'Review details',
    seoDescription: 'View a public review, photos, likes, comments and reporting options.',
    seoTitleFor: (shop, user) => `${shop} review by ${user}`,
    seoDescriptionFor: (shop, content) => `Public review of ${shop}: ${content}`,
    invalidId: 'The review ID is invalid',
    loadFailed: 'Could not load review details',
    commentsLoadFailed: 'Could not load comments',
    liked: 'Review liked.',
    likeRemoved: 'Like removed.',
    likeFailed: 'Could not update the like',
    commentRequired: 'Enter a comment first',
    replySent: 'Reply published.',
    commentSent: 'Comment published.',
    commentFailed: 'Could not publish the comment',
    reportRequired: 'Enter a reason for the report',
    reportSent: 'Report submitted for moderation.',
    reportFailed: 'Could not submit the report',
    loading: 'Loading review details...',
    ownedEyebrow: 'My review',
    publicEyebrow: 'Public review',
    lastUpdated: 'Last updated',
    overallScore: 'Overall rating',
    averageSpend: 'Spend',
    auditStatus: 'Moderation status',
    auditStatusLabel: (status, fallback) => ({ 0: 'Pending', 1: 'Approved', 2: 'Rejected' } as Record<number, string>)[status] ?? fallback,
    backToShop: 'Back to place',
    share: 'Share',
    continueEditing: 'Continue editing',
    viewPublic: 'View public page',
    taste: 'Food',
    ambience: 'Ambience',
    service: 'Service',
    likes: 'likes',
    comments: 'comments',
    likedByYou: 'Liked by you',
    rejectReason: 'Moderation note',
    bodyEyebrow: 'Review',
    bodyTitle: 'The complete experience, in the reviewer’s own words.',
    imagesEyebrow: 'Photos',
    imagesTitle: 'Photos uploaded with this review.',
    noImages: 'This review does not include photos.',
    interactionEyebrow: 'Interactions',
    interactionTitle: 'Like, comment on or report this public review.',
    unlike: 'Unlike',
    like: 'Like',
    collapseReport: 'Close report form',
    reportReview: 'Report review',
    signInToInteract: 'Sign in to interact',
    reportReason: 'Reason for report',
    reportPlaceholder: 'Describe the specific issue with this review.',
    cancel: 'Cancel',
    submitting: 'Submitting...',
    submitReport: 'Submit report',
    commentLabel: 'Add a comment',
    commentPlaceholder: 'Share a relevant response to this review.',
    replyingTo: (user) => `Replying to ${user}`,
    cancelReply: 'Cancel reply',
    commentPublic: 'Your comment will be publicly visible below this review.',
    signInToComment: 'Sign in to comment.',
    publishing: 'Publishing...',
    publishComment: 'Publish comment',
    signInFirst: 'Sign in first',
    commentsEyebrow: 'Comments',
    commentsTitle: 'Public comments and replies in context.',
    commentsLoading: 'Loading comments...',
    myComment: 'My comment',
    reply: 'Reply',
    myReply: 'My reply',
    replyContext: (user, content) => `Replying to ${user}: ${content}`,
    noComments: 'No comments yet. Start the conversation.',
  },
  editor: {
    editTitle: 'Edit review',
    createTitle: 'Write a review',
    editSummary: 'Your changes will be resubmitted for moderation. You can also update the photos.',
    createSummary: 'Rate the visit, write your review and upload photos from this device.',
    formFallback: 'Review form',
    missingShop: 'Place information is missing, so this review cannot be created.',
    loadFailed: 'Could not load the review editor',
    maxImages: 'You can upload up to 9 images',
    remainingImages: (count) => `You can add ${count} more images. Extra files were skipped.`,
    uploadedImages: (count) => `${count} ${count === 1 ? 'image' : 'images'} uploaded.`,
    uploadFailed: 'Could not upload the image',
    submitFailed: 'Could not submit the review',
    loading: 'Loading review form...',
    ratingsEyebrow: 'Ratings and review',
    ratingsTitle: 'Add enough detail to help other visitors make a decision.',
    overallScore: 'Overall rating',
    tasteScore: 'Food rating',
    ambienceScore: 'Ambience rating',
    serviceScore: 'Service rating',
    spend: 'Amount spent',
    spendPlaceholder: 'Amount spent on this visit',
    currency: 'Currency',
    tags: 'Tags',
    tagsPlaceholder: 'Separate tags with commas, for example: group dining, reliable, worth returning',
    body: 'Review',
    bodyPlaceholder: 'Describe what you experienced and what other visitors should know.',
    uploadEyebrow: 'Photo upload',
    uploadTitle: 'Add photos directly from this device.',
    uploading: 'Uploading images...',
    uploadedCount: (count) => `${count} / 9 images uploaded`,
    selectImages: 'Select images',
    uploadSupport: 'JPG, PNG or GIF. Up to 5 MB each and 9 images total.',
    imageAlt: (index) => `Review image ${index}`,
    imageLabel: (index) => `Image ${index}`,
    remove: 'Remove',
    noImages: 'No images uploaded yet.',
    submitting: 'Submitting...',
    saveAndResubmit: 'Save and resubmit',
    submitReview: 'Submit review',
    backToShop: 'Back to place',
  },
  errorTranslations: {
    '点评 ID 不合法': 'The review ID is invalid',
    '点评详情加载失败': 'Could not load review details',
    '评论列表加载失败': 'Could not load comments',
    '点赞操作失败': 'Could not update the like',
    '评论内容不能为空': 'Enter a comment first',
    '评论发布失败': 'Could not publish the comment',
    '举报理由不能为空': 'Enter a reason for the report',
    '举报提交失败': 'Could not submit the report',
    '门店信息不完整，没法写点评。': 'Place information is missing, so this review cannot be created.',
    '点评编辑页加载失败': 'Could not load the review editor',
    '图片上传失败': 'Could not upload the image',
    '点评提交失败': 'Could not submit the review',
  },
}

const STRINGS: Record<Region, WebReviewStrings> = { CN: zhCnStrings, EU: enStrings }

export function reviewStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebReviewError(strings: WebReviewStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const traceMatch = error.message.match(/\s*(\[traceId:\s*[^\]]+\])\s*$/)
  const trace = traceMatch?.[1]
  const message = trace ? error.message.slice(0, traceMatch.index).trim() : error.message.trim()
  const localized = strings.errorTranslations[message]
    ?? (/\p{Script=Han}/u.test(message) ? fallback : message)
  return trace ? `${localized} ${trace}` : localized
}
