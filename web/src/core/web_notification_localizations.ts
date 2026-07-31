import type { Region } from '@/types/browse'
import type { UserNotification } from '@/types/notification'
import type { WebLocaleTag } from '@/core/web_localizations'

export interface WebNotificationStrings {
  tag: WebLocaleTag
  page: {
    loadFailed: string
    markAllFailed: string
    markAllSuccess: string
    eyebrow: string
    title: string
    summary: string
    markAllRead: (count: number) => string
    loading: string
    empty: string
    read: string
    unread: string
    viewDetails: string
    markRead: string
    loadingMore: string
    loadMore: string
    unknownTitle: string
    unknownContent: string
  }
  hints: Record<string, string>
}

const zhCnStrings: WebNotificationStrings = {
  tag: 'zh-CN',
  page: {
    loadFailed: '通知加载失败',
    markAllFailed: '全部已读失败',
    markAllSuccess: '全部通知已标记为已读',
    eyebrow: '消息中心',
    title: '赞评、预订提醒和系统通知都在这里。',
    summary: '支持单条已读和全部已读；私信通知请到 APP 查看完整会话。',
    markAllRead: (count) => `全部已读${count ? `（${count}）` : ''}`,
    loading: '通知加载中...',
    empty: '暂时没有通知。',
    read: '已读',
    unread: '未读',
    viewDetails: '查看详情',
    markRead: '标记已读',
    loadingMore: '加载中...',
    loadMore: '加载更多',
    unknownTitle: '系统通知',
    unknownContent: '请打开详情查看最新信息。',
  },
  hints: {
    'message.direct': '请在 APP 查看私信',
    'reservation.reminder': '预订提醒',
    'coupon.reminder': '券码到期提醒',
    'coupon.expired': '券码已过期',
    'order.paid': '支付成功',
    'order.refund.result': '退款结果',
    'reservation.created': '预订创建',
    'reservation.status': '预订状态',
    'review.audit.result': '点评审核',
    'expert.certification.result': '达人认证',
    'post.audit.result': '帖子审核',
    'coupon.verified': '券码核销',
    'review.hidden': '点评处理',
    'topic.update': '话题更新',
    'social.mention': '@提醒',
    'review.like': '点评获赞',
    'review.comment': '点评评论',
    'review.comment.reply': '评论回复',
    'review.reply': '商家回复',
    'post.comment': '帖子评论',
    'post.comment.reply': '帖子评论回复',
    'post.like': '帖子获赞',
    'post.repost': '帖子转发',
    'social.follow': '新增关注',
  },
}

const enStrings: WebNotificationStrings = {
  tag: 'en',
  page: {
    loadFailed: 'Could not load notifications',
    markAllFailed: 'Could not mark all notifications as read',
    markAllSuccess: 'All notifications marked as read',
    eyebrow: 'Notifications',
    title: 'Keep up with reactions, bookings and account updates.',
    summary: 'Open individual updates or mark everything as read. View full direct-message conversations in the app.',
    markAllRead: (count) => `Mark all read${count ? ` (${count})` : ''}`,
    loading: 'Loading notifications...',
    empty: 'No notifications yet.',
    read: 'Read',
    unread: 'Unread',
    viewDetails: 'View details',
    markRead: 'Mark read',
    loadingMore: 'Loading...',
    loadMore: 'Load more',
    unknownTitle: 'Notification',
    unknownContent: 'Open the details for the latest information.',
  },
  hints: {
    'message.direct': 'Open in the app',
    'reservation.reminder': 'Booking reminder',
    'coupon.reminder': 'Voucher expiry reminder',
    'coupon.expired': 'Voucher expired',
    'order.paid': 'Payment complete',
    'order.refund.result': 'Refund result',
    'reservation.created': 'Booking created',
    'reservation.status': 'Booking status',
    'review.audit.result': 'Review moderation',
    'expert.certification.result': 'Expert certification',
    'post.audit.result': 'Post moderation',
    'coupon.verified': 'Voucher redeemed',
    'review.hidden': 'Review update',
    'topic.update': 'Topic update',
    'social.mention': 'Mention',
    'review.like': 'Review liked',
    'review.comment': 'Review comment',
    'review.comment.reply': 'Comment reply',
    'review.reply': 'Merchant reply',
    'post.comment': 'Post comment',
    'post.comment.reply': 'Post comment reply',
    'post.like': 'Post liked',
    'post.repost': 'Post reposted',
    'social.follow': 'New follower',
  },
}

const STRINGS: Record<Region, WebNotificationStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

function queryValue(linkUrl: string, key: string) {
  const search = linkUrl.split('?')[1] || ''
  return new URLSearchParams(search).get(key) || ''
}

function actor(item: UserNotification) {
  return item.actorName.trim() || 'Someone'
}

export function notificationStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function notificationDisplayTitle(strings: WebNotificationStrings, item: UserNotification) {
  if (strings.tag === 'zh-CN') return item.title
  switch (item.type) {
    case 'social.follow': return 'New follower'
    case 'message.direct': return 'New direct message'
    case 'social.mention': return 'New mention'
    case 'post.audit.result': return queryValue(item.linkUrl, 'audit') === 'rejected' ? 'Post rejected' : 'Post approved'
    case 'topic.update': return 'New post in a followed topic'
    case 'order.paid': return 'Payment successful'
    case 'order.refund.result': return queryValue(item.linkUrl, 'refund') === 'rejected' ? 'Refund rejected' : 'Refund approved'
    case 'reservation.created': return queryValue(item.linkUrl, 'status') === 'pending' ? 'Booking submitted' : 'Booking confirmed'
    case 'reservation.reminder': return queryValue(item.linkUrl, 'remind') === '30' ? 'Booking starts in 30 minutes' : 'Booking reminder'
    case 'reservation.status': {
      const status = queryValue(item.linkUrl, 'status')
      if (status === 'arrived') return 'Arrival confirmed'
      if (status === 'rejected') return 'Booking rejected'
      if (status === 'no_show') return 'Booking marked as no-show'
      return 'Booking confirmed'
    }
    case 'coupon.reminder': return 'Voucher expiring soon'
    case 'coupon.expired': return 'Voucher expired'
    case 'coupon.verified': return 'Voucher redeemed'
    case 'review.like': return 'Your review was liked'
    case 'review.comment': return 'New review comment'
    case 'review.comment.reply':
    case 'post.comment.reply': return 'Your comment received a reply'
    case 'review.reply': return 'New merchant reply'
    case 'post.like': return 'Your post was liked'
    case 'post.comment': return 'New post comment'
    case 'post.repost': return 'Your post was reposted'
    case 'expert.certification.result': return queryValue(item.linkUrl, 'expert') === 'rejected' ? 'Expert certification rejected' : 'Expert certification approved'
    case 'review.audit.result': return queryValue(item.linkUrl, 'audit') === 'rejected' ? 'Review rejected' : 'Review approved'
    case 'review.hidden': return 'Review hidden'
    default: return HAN_TEXT.test(item.title) ? strings.page.unknownTitle : item.title
  }
}

export function notificationDisplayContent(strings: WebNotificationStrings, item: UserNotification) {
  if (strings.tag === 'zh-CN') return item.content
  switch (item.type) {
    case 'social.follow': return `${actor(item)} followed you.`
    case 'message.direct': return item.content
    case 'social.mention': return `${actor(item)} mentioned you in a post or comment.`
    case 'post.audit.result': return queryValue(item.linkUrl, 'audit') === 'rejected'
      ? 'Your post did not pass moderation. Open it to review the reason.'
      : 'Your post passed moderation and is now public.'
    case 'topic.update': return 'A topic you follow has a new post.'
    case 'order.paid': return 'Payment completed and your vouchers are ready.'
    case 'order.refund.result': return queryValue(item.linkUrl, 'refund') === 'rejected'
      ? 'Your refund request was rejected. Open the order for details.'
      : 'Your refund request was approved.'
    case 'reservation.created': return queryValue(item.linkUrl, 'status') === 'pending'
      ? 'Your booking was submitted and is awaiting confirmation.'
      : 'Your booking was created and confirmed.'
    case 'reservation.reminder': return 'Your booking starts soon. Open it for the latest details.'
    case 'reservation.status': return 'Your booking status changed. Open it for the latest details.'
    case 'coupon.reminder': return 'A voucher expires soon. Open it to check the expiry date.'
    case 'coupon.expired': return 'A voucher has expired and can no longer be redeemed.'
    case 'coupon.verified': return 'Your voucher was redeemed successfully.'
    case 'review.like': return `${actor(item)} liked your review.`
    case 'review.comment': return `${actor(item)} commented on your review.`
    case 'review.comment.reply':
    case 'post.comment.reply': return `${actor(item)} replied to your comment.`
    case 'review.reply': return 'A merchant replied to your review.'
    case 'post.like': return `${actor(item)} liked your post.`
    case 'post.comment': return `${actor(item)} commented on your post.`
    case 'post.repost': return `${actor(item)} reposted your post.`
    case 'expert.certification.result': return queryValue(item.linkUrl, 'expert') === 'rejected'
      ? 'Your expert certification was rejected. Open your profile for details.'
      : 'Your expert certification was approved.'
    case 'review.audit.result': return queryValue(item.linkUrl, 'audit') === 'rejected'
      ? 'Your review did not pass moderation. Open it to review the reason.'
      : 'Your review passed moderation and is now public.'
    case 'review.hidden': return 'Your review is no longer publicly visible. Open it for details.'
    default: return HAN_TEXT.test(item.content) ? strings.page.unknownContent : item.content
  }
}

export function notificationHint(strings: WebNotificationStrings, item: UserNotification) {
  return strings.hints[item.type] || item.type
}

export function localizeWebNotificationError(strings: WebNotificationStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN' || !HAN_TEXT.test(error.message)) return error.message || fallback
  return fallback
}
