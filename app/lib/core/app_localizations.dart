import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations._(this.tag, this._values);

  final String tag;
  final Map<String, String> _values;

  static const delegate = AppLocalizationsDelegate();
  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('en'),
  ];

  static const _simplified = {
    'homeTitle': '本地生活',
    'searchHint': '搜索餐厅、超市和生活服务',
    'featured': '附近推荐',
    'profile': '我的',
    'homeSubtitle': '发现附近更适合华人的好去处',
    'europe': '欧洲',
    'china': '中国',
    'language': '切换语言',
    'map': '地图',
    'mapsConfigured': 'Google Maps 已配置',
    'mapsUnavailable': 'Google Maps 未配置，仍可按城市和列表浏览。',
    'realPaymentUnavailable': '真实支付未配置，客户端不会伪造支付成功。',
    'pushUnavailable': 'FCM/APNs 未配置，通知仍可通过站内消息补偿。',
    'notifications': '消息通知',
    'account': '个人中心',
    'cityRankings': '城市榜单',
    'activities': '运营活动',
    'placesLoadFailed': '附近门店加载失败',
    'noPlaces': '当前城市暂无门店',
    'homeNavigation': '首页',
    'exploreNavigation': '发现',
    'ordersNavigation': '订单',
    'searchTitle': '搜索结果',
    'searchSuggestionsLoading': '联想加载中...',
    'searchSuggestions': '搜索联想',
    'searchFailed': '搜索失败：{error}',
    'processing': '处理中...',
    'retry': '重试',
    'requestFailed': '请求失败',
    'invalidApiResponse': '服务返回格式异常',
    'unsupportedApiClientCapability': '当前 API 客户端不支持 {capability}',
    'noMatchingPlaces': '没有匹配的门店',
    'loading': '加载中...',
    'loadMore': '加载更多',
    'loadMoreShopsFailed': '加载更多门店失败：{error}',
    'discoveryFailed': '搜索发现加载失败：{error}',
    'browseErrorShopNotFound': '这家门店不存在',
    'browseErrorSearchHistoryNotFound': '这条搜索历史不存在',
    'browseErrorInvalidShopId': '门店参数无效',
    'browseErrorUnsupportedReviewSort': '当前点评排序方式不受支持',
    'browseErrorUnsupportedFavoriteTarget': '当前收藏目标类型不受支持',
    'enterKeyword': '输入关键词开始搜索',
    'recentSearches': '最近搜过',
    'clearing': '清空中...',
    'clear': '清空',
    'moreHistory': '更多历史',
    'hotSearches': '当前热词',
    'clearHistoryFailed': '清空搜索历史失败：{error}',
    'removeHistoryFailed': '删除搜索历史失败：{error}',
    'loadMoreHistoryFailed': '加载更多搜索历史失败：{error}',
    'rankDetailTitle': '榜单详情',
    'refreshRanksFailed': '刷新榜单失败：{error}',
    'ranksLoadFailed': '榜单加载失败：{error}',
    'rankErrorNotFound': '这个榜单不存在',
    'rankErrorInvalidType': '当前榜单类型不受支持',
    'noPublicRanks': '当前区域暂无公开榜单',
    'rankTypeMustEat': '必吃榜',
    'rankTypeTopRated': '好评榜',
    'rankTypeTrending': '热门榜',
    'shopCount': '{count} 家门店',
    'topShop': '榜首 {name}',
    'rankDetailLoadFailed': '榜单详情加载失败：{error}',
    'rankNoShops': '该榜单暂无门店',
    'activityDetailTitle': '活动详情',
    'refreshActivitiesFailed': '刷新活动失败：{error}',
    'activitiesLoadFailed': '活动加载失败：{error}',
    'noOnlineActivities': '当前区域暂无上线活动',
    'activityChannelHome': '首页',
    'activityChannelSearch': '搜索',
    'activityChannelChannel': '频道',
    'activityChannelPage': '活动页',
    'activityChannelCommunity': '社区',
    'activityTypeThemed': '专题活动',
    'activityTypeHoliday': '节日活动',
    'activityTypeNewCustomer': '新客活动',
    'activityTypeMerchantSupport': '商户扶持',
    'activityTypeContentTopic': '内容话题',
    'resourceCount': '{count} 个资源',
    'activityDetailLoadFailed': '活动详情加载失败：{error}',
    'activityErrorNotFoundOrOffline': '当前活动不存在或未上线',
    'activityNoItems': '该活动暂无资源项',
    'cannotOpenExternalLink': '无法打开外部链接',
    'openTargetFailed': '{target}打开失败：{error}',
    'targetShop': '店铺',
    'targetDeal': '团购',
    'targetPost': '帖子',
    'targetRank': '榜单',
    'targetTopic': '话题',
    'targetExternalLink': '外部链接',
    'targetResource': '资源',
    'refreshNotificationsFailed': '刷新消息失败：{error}',
    'loadMoreFailed': '加载更多失败：{error}',
    'markReadFailed': '标记已读失败：{error}',
    'allNotificationsMarkedRead': '全部通知已标记为已读',
    'markAllReadFailed': '全部已读失败：{error}',
    'markAllRead': '全部已读',
    'markAllReadWithCount': '全部已读（{count}）',
    'filterAll': '全部',
    'filterUnreadOnly': '只看未读',
    'notificationsLoadFailed': '消息加载失败：{error}',
    'notificationErrorUnavailable': '通知服务暂时不可用',
    'notificationErrorRefreshUnavailable': '通知暂时无法刷新',
    'reload': '重新加载',
    'refresh': '刷新',
    'noUnreadNotifications': '暂无未读消息',
    'noNotifications': '暂无消息',
    'continueFindUnread': '继续查找未读消息',
    'unreadBadge': '未读',
    'notificationTitleSocialFollow': '新增关注',
    'notificationTitleDirectMessage': '收到私信',
    'notificationTitleMention': '有人@了你',
    'notificationTitlePostApproved': '帖子已通过审核',
    'notificationTitlePostRejected': '帖子未通过审核',
    'notificationTitleTopicUpdate': '关注的话题有新内容',
    'notificationTitleOrderPaid': '支付成功',
    'notificationTitleReservationConfirmed': '预订已自动确认',
    'notificationTitleReservationSubmitted': '预订已提交',
    'notificationTitleReservationReminderThirtyMinutes': '预订即将开始（30 分钟）',
    'notificationTitleReservationReminderTwoHours': '预订提醒（2 小时）',
    'notificationTitleCouponReminder': '券码即将到期',
    'notificationTitleCouponExpired': '券码已过期',
    'notificationTitleCouponVerified': '券码已核销',
    'notificationTitleMerchantReply': '商家回复',
    'notificationFollowedYou': '{name} 关注了你',
    'notificationDirectMessagePreview': '{name}：{preview}',
    'notificationPostApprovedContent': '《{title}》 已公开',
    'notificationPostRejectedContent': '《{title}》 未通过审核',
    'notificationOrderNumber': '订单 {orderNo}',
    'notificationCouponsReady': '券码已发放，可在我的券查看',
    'notificationReservationAutoConfirmedAction': '系统已自动确认你的预订',
    'notificationReservationSubmittedAction': '已提交，等待商户确认',
    'notificationCouponCodeLabel': '券码 {code}',
    'notificationCouponExpiringInDays': '{code} 将在 {days} 天后过期',
    'notificationCouponRedeemedAt': '{code} 已在 {shop} 核销',
    'notificationCouponRedeemed': '已核销成功',
    'notificationExpertApprovedContent': '你的本地达人认证已审核通过',
    'notificationExpertRejectedContent': '你的本地达人认证未通过，请查看原因后重提',
    'notificationTitleRefundApproved': '退款已通过',
    'notificationTitleRefundRejected': '退款已驳回',
    'notificationTitleReservationMerchantConfirmed': '预订已确认',
    'notificationTitleReservationArrived': '已确认到店',
    'notificationTitleReservationRejected': '预订被拒绝',
    'notificationTitleReservationNoShow': '预订已标记爽约',
    'notificationTitleReviewApproved': '点评已通过审核',
    'notificationTitleReviewRejected': '点评未通过审核',
    'notificationTitleReviewHidden': '点评已被隐藏',
    'notificationTitleBanAppealApproved': '封禁申诉已通过',
    'notificationTitleBanAppealRejected': '封禁申诉已驳回',
    'notificationTitleAccountUnbanned': '账号已解封',
    'notificationActorPlatform': '平台',
    'notificationActorMerchant': '商户',
    'notificationRefundApprovedAction': '{actor}已同意退款',
    'notificationRefundRejectedAction': '{actor}已驳回退款',
    'notificationReservationMerchantConfirmedAction': '商户已确认你的预订',
    'notificationReservationArrivedAction': '商户已确认你到店',
    'notificationReservationMerchantRejectedAction': '商户已拒绝你的预订',
    'notificationReservationMarkedNoShowAction': '商户已将本次预订标记为爽约',
    'notificationReviewApprovedContent': '{shop} · 你的点评已公开展示',
    'notificationReviewRejectedContent': '{shop} · 你的点评未通过审核',
    'notificationReviewHiddenContent': '{shop} · 商户申诉成立，你的点评已从公开展示中隐藏',
    'notificationTitleReviewLike': '点评获赞',
    'notificationTitleReviewComment': '点评新评论',
    'notificationTitleCommentReply': '评论被回复',
    'notificationTitlePostLike': '帖子获赞',
    'notificationTitlePostComment': '帖子新评论',
    'notificationTitlePostRepost': '帖子被转发',
    'notificationLikedYourReview': '{name} 赞了你的点评：{preview}',
    'notificationCommentedOnYourReview': '{name} 评论了你的点评：{preview}',
    'notificationRepliedToYou': '{name} 回复了你：{preview}',
    'notificationLikedYourPost': '{name} 赞了你的帖子《{title}》',
    'notificationCommentedOnYourPost': '{name} 评论了你的帖子：{preview}',
    'notificationRepostedYourPost': '{name} 转发了你的帖子《{title}》',
    'notificationMentionedYouInPost': '{name} 在帖子《{title}》中提到了你',
    'notificationMentionedYouInPostComment': '{name} 在帖子《{title}》的评论中提到了你',
    'notificationTopicUpdateContent': '{name} 在 #{topic} 发布了《{title}》',
    'notificationBanAppealApprovedContent': '你的封禁申诉已通过，账号已解封，现在可以正常登录使用了。',
    'notificationBanAppealRejectedContent': '你的封禁申诉未通过',
    'notificationAccountUnbannedContent':
        '管理员已解除你的账号封禁，关联的申诉已自动通过，现在可以正常登录使用了。',
    'loggingOut': '退出中...',
    'logout': '退出',
    'profileLoadFailed': '用户资料加载失败：{error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} 积分',
    'growthValueLabel': '{value} 成长值',
    'accountSettings': '账户设置',
    'accountSettingsSubtitle': '资料、绑定账号、修改密码',
    'localExpertCertification': '本地达人认证',
    'localExpertCertificationSubtitle': '提交或重提本地达人申请',
    'growthRecords': '成长值流水',
    'growthRecordsSubtitle': 'Lv.{level} · 成长值 {growth} · 积分 {points}',
    'myMessages': '我的私信',
    'blockedUsers': '黑名单管理',
    'myCircles': '我的圈子',
    'myReviews': '我的点评',
    'myPosts': '我的帖子',
    'myFavorites': '我的收藏',
    'myOrders': '我的订单',
    'myCoupons': '我的券',
    'myReservations': '我的预订',
    'myBrowseHistory': '我的足迹',
    'privacyCenter': '隐私中心',
    'communityTitle': '华人社区',
    'topicPlaza': '话题广场',
    'localCircles': '同城圈子',
    'recommendedTab': '推荐',
    'followingTab': '关注',
    'createPost': '发帖',
    'followingFeedLoginRequired': '登录后查看关注流，关注的人更新时会出现在这里。',
    'loadMorePostsFailed': '加载更多帖子失败：{error}',
    'communityLoadFailed': '社区加载失败：{error}',
    'noCommunityPosts': '暂无帖子',
    'postMetaStats': ' · ❤ {likes} · 评论 {comments}',
    'hotTab': '热榜',
    'followingTopicsTab': '已关注',
    'loadMoreTopicsFailed': '加载更多话题失败：{error}',
    'topicsLoadFailed': '话题加载失败：{error}',
    'followingTopicsLoginRequired': '登录后查看关注的话题，不会额外生成独立动态流。',
    'goLogin': '去登录',
    'hotScore': '热度 {score}',
    'topicSevenDayStats': '7 天：{posts} 帖 · {likes} 赞 · {comments} 评论',
    'topicFollowMeta': '{followers} 人关注 · {posts} 篇公开帖子',
    'topicFollowerCount': '{count} 人关注',
    'topicErrorNotFound': '这个话题不存在',
    'topicErrorUnavailable': '这个话题暂时不可用',
    'topicErrorFollowFailed': '关注请求未能完成',
    'followStatusUpdateFailed': '关注状态更新失败：{error}',
    'followed': '已关注',
    'followTopic': '关注话题',
    'publicPosts': '公开帖子',
    'postsLoadFailed': '帖子加载失败：{error}',
    'noPublicPostsHere': '这里还没有公开帖子。',
    'communityErrorPostNotFound': '这条帖子不存在',
    'communityErrorReportDuplicate': '你已经举报过这条帖子了，请不要重复提交',
    'communityErrorReplyTargetMissing': '你要回复的评论不存在',
    'communityErrorJoinCircleToPost': '请先加入圈子再发帖',
    'loadMoreCirclesFailed': '加载更多圈子失败：{error}',
    'circlesLoadFailed': '圈子加载失败：{error}',
    'circleErrorJoinedOnlyLoginRequired': '登录后才能查看已加入的圈子',
    'circleErrorNotFound': '这个圈子不存在',
    'circleMeta': '{members} 位成员 · {posts} 篇帖子',
    'circleStatusUpdateFailed': '圈子状态更新失败：{error}',
    'joined': '已加入',
    'joinCircle': '加入圈子',
    'viewMembers': '查看成员',
    'postInCircle': '在圈子发帖',
    'joinCircleToPost': '加入圈子后即可发布内容，历史帖子公开可见。',
    'circleNewPosts': '圈子新帖',
    'loadMoreMembersFailed': '加载更多成员失败：{error}',
    'circleMembersTitle': '{name}成员',
    'membersLoadFailed': '成员加载失败：{error}',
    'directMessages': '私信',
    'directMessageUser': '私信用户',
    'messageErrorUserNotFound': '这位用户不存在',
    'messageErrorConversationMissing': '这个会话不存在',
    'messageErrorCannotMessageSelf': '你不能给自己发送私信',
    'messageErrorBlockedRelationship': '你们之间存在拉黑关系，暂时无法发送私信',
    'messageErrorCannotBlockSelf': '你不能拉黑自己',
    'messageErrorReportTargetUnavailable': '这个举报目标不存在，或你暂时无权访问',
    'messageErrorReportDuplicate': '你已经举报过这个目标了，请不要重复提交',
    'refreshConversationsFailed': '刷新会话失败：{error}',
    'loadMoreConversationsFailed': '加载更多会话失败：{error}',
    'conversationsLoadFailed': '会话加载失败：{error}',
    'noDirectMessages': '还没有私信，去公开主页打个招呼吧。',
    'messageMarkReadFailed': '已读状态同步失败：{error}',
    'loadEarlierMessagesFailed': '加载更早消息失败：{error}',
    'sendFailed': '发送失败：{error}',
    'actionFailed': '操作失败：{error}',
    'reportConversation': '举报会话',
    'blockUser': '拉黑用户',
    'unblockUser': '解除拉黑',
    'reportSubmitted': '举报已提交',
    'blockedBothWays': '已拉黑，双方无法继续发送',
    'unblocked': '已解除拉黑',
    'chatHistoryLoadFailed': '聊天记录加载失败：{error}',
    'loadEarlierMessages': '加载更早消息',
    'blockedComposerHint': '已拉黑，解除后可继续发送',
    'messageHint': '写点什么…',
    'send': '发送',
    'harassmentOrInappropriate': '骚扰或不当内容',
    'refreshBlockedUsersFailed': '刷新黑名单失败：{error}',
    'loadMoreBlockedUsersFailed': '加载更多黑名单失败：{error}',
    'unblockedUser': '已解除对 {name} 的拉黑',
    'unblockFailed': '解除拉黑失败：{error}',
    'blockedUsersLoadFailed': '黑名单加载失败：{error}',
    'blockedUsersEmpty': '黑名单为空',
    'blockedAt': '拉黑时间：{time}',
    'userFallback': '用户 {id}',
    'anonymousPeer': 'TA',
    'payPending': '待支付',
    'payPaid': '已支付',
    'payRefunded': '已退款',
    'payPartialRefund': '部分退款',
    'couponPending': '待使用',
    'couponUsed': '已使用',
    'couponExpired': '已过期',
    'couponRefunded': '已退款',
    'loadMoreOrdersFailed': '加载更多订单失败：{error}',
    'ordersLoadFailed': '订单加载失败：{error}',
    'noOrdersForFilter': '当前筛选下暂无订单',
    'loadMoreCouponsFailed': '加载更多券码失败：{error}',
    'couponsLoadFailed': '券码加载失败：{error}',
    'noCouponsForFilter': '当前筛选下暂无券码',
    'couponHighlight': '定位券码 {code}',
    'groupDeals': '团购优惠',
    'dealsLoadFailed': '团购加载失败：{error}',
    'noDealsForShop': '当前门店暂无团购',
    'soldCount': '已售 {count}',
    'stockCount': '库存 {count}',
    'buy': '购买',
    'tradeErrorDealNotFound': '这项团购不存在',
    'tradeErrorDealExpired': '这项团购已过期',
    'tradeErrorDealOutOfStock': '这项团购库存不足',
    'tradeErrorOrderNotFound': '这笔订单不存在',
    'tradeErrorOrderPaymentUnavailable': '这笔订单当前无法支付',
    'tradeErrorOrderCancelUnavailable': '这笔订单当前无法取消',
    'tradeErrorOrderRefundUnavailable': '这笔订单当前无法退款',
    'tradeErrorRefundUsedCoupons': '订单里有已核销的券，暂不支持整单退款',
    'tradeErrorRefundExists': '这笔订单已有退款申请',
    'tradeErrorCouponCodeRequired': '请输入券码',
    'tradeErrorCouponNotFound': '这张券不存在',
    'tradeErrorPaymentChannelUnavailable': '支付服务暂未配置',
    'createOrderFailed': '下单失败：{error}',
    'orderCreatedOpenDetailFailed': '订单 {orderNo} 已创建，但打开详情失败：{error}',
    'dealDetail': '团购详情',
    'dealDetailLoadFailed': '团购详情加载失败：{error}',
    'soldAndStock': '已售 {sold} · 库存 {stock}',
    'validUntil': '有效期 {range}',
    'noPackageItems': '暂无套餐明细',
    'quantityLabel': '数量 {count}',
    'orderDetail': '订单详情',
    'cancelOrder': '取消订单',
    'cancelOrderConfirm': '订单取消后将释放库存，确定继续？',
    'keepOrder': '先不取消',
    'confirmCancel': '确认取消',
    'applyRefund': '申请退款',
    'submitApplication': '提交申请',
    'cancelAction': '取消',
    'orderLoadFailedTapRetry': '订单加载失败，点击重试',
    'orderShopMeta': '{shop} · 订单 {orderNo}',
    'startPayment': '发起支付',
    'refundLabel': '退款：{status}',
    'couponCopied': '券码已复制',
    'couponDetail': '券详情',
    'couponDetailLoadFailed': '券码详情加载失败：{error}',
    'qrLoadFailed': '二维码加载失败',
    'verifiedAt': '核销时间 {time}',
    'showCodeToMerchant': '请向商户出示券码',
    'priceSoldMeta': '{price} · 已售 {count}',
    'usageRules': '使用规则',
    'packageContents': '套餐内容',
    'quantitySimple': '数量',
    'unitPrice': '单价',
    'paidAmount': '实付',
    'orderCanceled': '订单已取消',
    'refundReason': '退款原因',
    'refundSubmitted': '退款申请已提交',
    'refundStatusPending': '待审核',
    'refundStatusApproved': '退款成功',
    'refundStatusRejected': '已驳回',
    'defaultRefundReason': '行程有变',
    'paymentRequestCreated': '已创建 {channel} 支付请求，请在支付渠道完成付款',
    'paymentStartFailed': '支付发起失败：{error}',
    'relatedCoupons': '关联券码',
    'redeemable': '可核销',
    'notRedeemable': '不可核销',
    'copying': '复制中...',
    'copyCouponCode': '复制券码',
    'validUntilDate': '有效期至 {date}',
    'noExpiry': '不限期',
    'dealValidityRange': '团购有效期 {start} ~ {end}',
    'noExtraRules': '暂无补充规则',
    'defaultVerifyHint': '券码由商户核销；用户端不提供自助核销，避免误操作。',
    'detailRefreshFailed': '详情刷新失败：{error}',
    'reloadFullDetail': '重新加载完整详情',
    'reservationPending': '待确认',
    'reservationConfirmed': '已确认',
    'reservationArrived': '已到店',
    'reservationUserCanceled': '用户取消',
    'reservationMerchantRejected': '商户拒绝',
    'reservationNoShow': '爽约',
    'reservationConfirmModeAuto': '自动确认',
    'reservationConfirmModeManual': '人工确认',
    'reservationActionCreated': '创建预订',
    'reservationActionMerchantConfirmed': '商户确认',
    'reservationActionMerchantRejected': '商户拒绝',
    'reservationActionUserCanceled': '用户取消',
    'reservationActionUserRescheduled': '用户改期',
    'reservationActionMerchantRescheduled': '商户改期',
    'reservationActionCheckedIn': '确认到店',
    'reservationActionMarkedNoShow': '标记爽约',
    'reservationActionArrivalReminder': '到店提醒',
    'loadMoreReservationsFailed': '加载更多预订失败：{error}',
    'reservationsLoadFailed': '预订加载失败：{error}',
    'noReservationsForFilter': '当前筛选下暂无预订',
    'reservationListMeta': '{no}\n{time} · {people} 人 · {status}',
    'onlineReservation': '在线预订',
    'selectSlotFirst': '请选择时段',
    'reservationCreated': '预订 {no} 已创建：{status}',
    'reservationFailed': '预订失败：{error}',
    'reservationErrorInvalidPeopleCount': '预订人数至少为 1 人',
    'reservationErrorSlotOrTimeRequired': '请先选择预订时段',
    'reservationErrorSlotCapacityUnavailable': '当前时段剩余名额不足',
    'reservationErrorCancelDeadlinePassed': '已经超过可取消时间',
    'reservationErrorCancelUnavailable': '当前预订暂时无法取消',
    'reservationErrorRescheduleSlotCapacityUnavailable': '新时段剩余名额不足',
    'reservationErrorRescheduleUnavailable': '当前预订暂时无法改期',
    'reservationErrorSlotNotFound': '预订时段不存在',
    'reservationErrorNotFound': '这笔预订不存在',
    'dateLabel': '日期 {date}',
    'peopleCount': '{count} 人',
    'slotsLoadFailed': '时段加载失败：{error}',
    'slotRemaining': '{start}-{end} · 剩余 {count}',
    'contactName': '联系人',
    'contactPhone': '联系电话',
    'remark': '备注',
    'submitting': '提交中...',
    'submitReservation': '提交预订',
    'reservationDetail': '预订详情',
    'reservationLoadFailedTapRetry': '预订加载失败，点击重试',
    'cancelReservation': '取消预订',
    'cancelReservationConfirm': '取消时间限制由门店规则决定，确定继续？',
    'keepReservation': '先不取消',
    'reservationCanceled': '预订已取消',
    'findRescheduleSlots': '查询改期时段',
    'confirmReschedule': '确认改期',
    'reservationRescheduled': '预订已改期',
    'rescheduleReason': '用户在线改期',
    'reservationTimePeople': '{time} · {people} 人',
    'rescheduleSlotMeta': '{start} · {mode} · 余 {count}',
    'changeTimeline': '变更时间线',
    'noChangeRecords': '暂无变更记录',
    'liked': '已点赞',
    'like': '点赞',
    'unliked': '已取消点赞',
    'likeFailed': '点赞失败：{error}',
    'commentPublished': '评论已发布',
    'commentFailed': '评论失败：{error}',
    'loadMoreCommentsFailed': '加载更多评论失败：{error}',
    'reportReview': '举报点评',
    'reportReason': '举报理由',
    'submitReport': '提交举报',
    'reportFailed': '举报失败：{error}',
    'deleteReview': '删除点评',
    'deleteReviewConfirm': '删除后不可恢复，确认删除这条点评吗？',
    'confirmDelete': '确认删除',
    'reviewDeleted': '点评已删除',
    'deleteFailed': '删除失败：{error}',
    'reply': '回复',
    'myReviewDetail': '我的点评详情',
    'reviewDetail': '点评详情',
    'edit': '编辑',
    'deleting': '删除中...',
    'delete': '删除',
    'reviewDetailLoadFailed': '点评详情加载失败：{error}',
    'reviewErrorNotFound': '这条点评不存在',
    'reviewErrorReportDuplicate': '你已经举报过这条点评了，请不要重复提交',
    'reviewErrorReplyTargetMissing': '你要回复的评论不存在',
    'reviewErrorUserUnavailable': '你的账号当前不可用',
    'reviewErrorShopUnavailable': '这个门店当前不可点评',
    'reviewErrorShopImmutable': '点评所属门店不可修改',
    'auditRemarkLabel': '审核备注：{remark}',
    'merchantReplyLabel': '商家回复：{reply}',
    'anonymousUser': '匿名用户',
    'report': '举报',
    'reviewLoginToInteract': '登录后可点赞、评论和举报这条点评。',
    'commentsSection': '评论',
    'replyingTo': '回复 @{name}',
    'writeComment': '写评论',
    'publishing': '发布中...',
    'publishComment': '发布评论',
    'commentsLoadFailed': '评论加载失败：{error}',
    'retryComments': '重试评论',
    'noComments': '暂无评论',
    'writeReview': '写点评',
    'editReview': '编辑点评',
    'reviewLoadFailedTapRetry': '点评加载失败，点击重试',
    'reviewContentHint': '写下你的真实体验……',
    'uploadedCount': '已上传 {count}/9',
    'uploading': '上传中…',
    'addImages': '添加图片',
    'spendAmount': '本次消费',
    'tagsLabel': '标签（最多 10 个）',
    'tagsHint': '中文服务，适合聚会，性价比高',
    'saveAndResubmit': '保存并重新提交审核',
    'publishReview': '发布点评',
    'reviewingShop': '正在点评',
    'scoreOverall': '总体',
    'scoreTaste': '口味',
    'scoreEnv': '环境',
    'scoreService': '服务',
    'averageSpendLabel': '人均 {amount}',
    'replyToPreview': '回复 {name}：{content}',
    'likeCommentStats': '点赞 {likes} · 评论 {comments}',
    'loadMoreComments': '加载更多评论',
    'maxNineImages': '最多上传 9 张图片',
    'imagePickFailed': '图片选择失败：{error}',
    'imageUploadFailed': '图片上传失败：{error}',
    'reviewUpdatedResubmitted': '点评已更新并重新进入审核',
    'reviewSubmittedPending': '点评已提交，等待审核',
    'saveFailed': '保存失败：{error}',
    'ratingPrompt': '这次体验，值几颗星？',
    'ratingHint': '拖动评分，别客气，也别冤枉人。',
    'saySomethingUseful': '说点有用的',
    'reviewWritingHint': '味道、服务、排队和避坑信息，都比“还不错”值钱。',
    'pleaseWriteRealExperience': '请写下真实体验',
    'onSitePhotos': '现场照片',
    'photosUploadHint': '最多 9 张，选择后会立即上传。',
    'spendAndTags': '消费与标签',
    'spendTagsHint': '金额用于人均参考；多个标签请用逗号分隔。',
    'enterNonNegativeAmount': '请输入不小于 0 的金额',
    'loginTitle': '登录大众点评',
    'loginHero': '连接欧洲华人生活',
    'loginSubtitle': '邮箱和手机号都能登录，别整第三方登录套娃。',
    'passwordLogin': '密码登录',
    'codeLogin': '验证码登录',
    'emailOrPhone': '邮箱或手机号',
    'password': '密码',
    'verificationCode': '验证码',
    'sendingCode': '发送中...',
    'sendCode': '发送验证码',
    'enterEmailOrPhone': '请输入邮箱或手机号',
    'enterEmailOrPhoneFirst': '先输入邮箱或手机号',
    'codeSent': '验证码已发送',
    'localCodeHint': '本地验证码：{code}',
    'accountBannedHint': '账号 {account} 当前处于封禁状态。如果认为是误封，可以提交申诉，运营复核通过后会自动解封。',
    'submitBanAppeal': '提交封禁申诉',
    'loginSuccess': '登录成功',
    'loggingIn': '登录中...',
    'login': '登录',
    'registerAccount': '注册账号',
    'passwordResetPleaseLogin': '密码已重置，请使用新密码登录',
    'forgotPassword': '忘记密码',
    'banAppeal': '封禁申诉',
    'registerTitle': '注册账号',
    'registerSubtitle': '邮箱或手机号都能注册，验证码只用于本次注册。',
    'nicknameOptional': '昵称（可选）',
    'registerCode': '注册验证码',
    'setPassword': '设置密码',
    'registering': '注册中...',
    'registerAndLogin': '注册并登录',
    'resetPasswordTitle': '找回密码',
    'resetPasswordSubtitle': '用当前绑定邮箱或手机号验证身份，重置后再返回登录。',
    'resetCode': '重置验证码',
    'newPassword': '新密码',
    'confirmNewPassword': '确认新密码',
    'resetting': '重置中...',
    'resetPassword': '重置密码',
    'banAppealTitle': '封禁申诉',
    'banAppealHero': '账号被封后的自助申诉入口',
    'banAppealSubtitle': '用当前绑定邮箱或手机号验证身份。运营复核通过后会自动解封，再回登录页继续使用。',
    'appealCode': '申诉验证码',
    'appealReasonMin10': '申诉理由（至少 10 个字）',
    'banReasonLabel': '封禁原因：{value}',
    'appealContentLabel': '申诉内容：{value}',
    'rejectReasonLabel': '驳回说明：{value}',
    'submittedAtLabel': '提交时间：{value}',
    'processedAtLabel': '处理时间：{value}',
    'submittingAppeal': '提交中...',
    'submitAppeal': '提交申诉',
    'querying': '查询中...',
    'queryAppealProgress': '查询申诉进度',
    'backToLogin': '返回登录',
    'codeSentRetry': '验证码已发送，{seconds} 秒后可重发',
    'fillAccountCodePassword': '账号、验证码和密码都得填',
    'fillAccountCodeNewPassword': '账号、验证码和新密码都得填',
    'passwordsDoNotMatch': '两次输入的新密码对不上',
    'authErrorInvalidCredentials': '账号或密码不正确，请重新输入后再试',
    'authErrorAccountBanned': '这个账号当前已被封禁，暂时无法登录',
    'authErrorAccountRegistered': '这个账号已经注册过了，直接登录或找回密码即可',
    'authErrorAccountNotFound': '找不到这个账号，请检查邮箱或手机号是否填写正确',
    'authErrorCodeInvalid': '验证码无效或已过期，请重新获取后再试',
    'authErrorInvalidEmail': '邮箱格式不正确，请检查后重试',
    'authErrorInvalidPhone': '手机号格式不正确，请检查后重试',
    'authErrorCodeRateLimited': '验证码发送太频繁了，请稍等一会儿再试',
    'authErrorCodeSendUnavailable': '验证码发送服务暂时不可用，请稍后再试',
    'authErrorCodeVerifyUnavailable': '验证码校验服务暂时不可用，请稍后再试',
    'authErrorEmailAlreadyBound': '这个邮箱已经被其他账号绑定了，请换一个再试',
    'authErrorPhoneAlreadyBound': '这个手机号已经被其他账号绑定了，请换一个再试',
    'authErrorOldPasswordIncorrect': '当前密码不正确，请重新输入后再试',
    'authErrorSamePasswordAsOld': '新密码不能和当前密码相同，请换一个再试',
    'authErrorCurrentUserNotFound': '当前账号不存在，请重新登录后再试',
    'authErrorSessionMissing': '当前登录状态已失效，请重新登录后再试',
    'authErrorProfileNicknameTooLong': '昵称最多只能填写 64 个字符',
    'authErrorProfileAvatarTooLong': '头像地址最多只能填写 255 个字符',
    'authErrorProfileSignatureTooLong': '签名最多只能填写 255 个字符',
    'authErrorProfileUpdateFailed': '资料更新失败了，请稍后再试',
    'registerHero': '加入欧洲华人生活圈',
    'resetPasswordHero': '重新设置登录密码',
    'fillAccountAndCodeBeforeAppeal': '先填好账号和验证码，再提交申诉',
    'appealReasonTooShort': '申诉理由至少写 10 个字，把误封的情况说清楚',
    'appealSubmitted': '申诉 #{id} 已提交，运营会尽快复核',
    'queryNeedsAccountAndCode': '查询进度也需要账号和一条新的验证码',
    'appealProgressRefreshed': '已刷新申诉 #{id} 的最新进度',
    'appealStatusTitle': '申诉 #{id} · {status}',
    'appealApprovedHint': '申诉已通过，账号已解封。请返回登录页继续使用。',
    'banAppealErrorAccountNotFound': '找不到这个账号，请检查邮箱或手机号是否填写正确',
    'banAppealErrorAccountNotBanned': '这个账号当前没有被封禁，不需要提交申诉',
    'banAppealErrorPendingExists': '你已经有一条申诉在处理中，请耐心等待审核结果',
    'banAppealErrorNoRecord': '这个账号暂时没有申诉记录',
    'banAppealErrorStatusChanged': '申诉状态刚刚发生变化，请刷新后重试',
    'banAppealErrorCodeInvalid': '验证码无效或已过期，请重新获取后再试',
    'banAppealErrorInvalidEmail': '邮箱格式不正确，请检查后重试',
    'banAppealErrorInvalidPhone': '手机号格式不正确，请检查后重试',
    'privacySubtitle': '导出能带走，删除有冷静期，规则和任务状态都摊开讲清楚。',
    'privacyLoadFailed': '隐私数据加载失败：{error}',
    'exportModuleAccount': '账号数据',
    'exportModuleReviews': '点评数据',
    'exportModuleOrders': '订单数据',
    'exportModulePosts': '帖子数据',
    'exportModuleReservations': '预订数据',
    'exportModuleFavorites': '收藏数据',
    'exportModuleFollows': '关注关系',
    'exportModuleMessages': '私信数据',
    'exportModuleCircles': '圈子关系',
    'exportModuleTopics': '话题关注',
    'privacyExportHint': '帖子、关注关系、私信、圈子和话题关注均支持真实导出。',
    'noExportTasks': '还没有导出任务',
    'agreementRecordsHint': '记录你确认过的用户协议和隐私政策版本，省得日后各说各话。',
    'noAgreementRecords': '还没有协议同意记录。',
    'deviceLifecycleHint': '登录设备会保留生命周期记录；未配置推送时不会冒充 FCM/APNs 已接通。',
    'noRegisteredDevices': '还没有登记设备。',
    'loadMoreExportTasksFailed': '加载更多导出任务失败：{error}',
    'agreementRecorded': '协议同意记录已留痕',
    'agreementRecordFailed': '协议留痕失败：{error}',
    'deviceDeactivated': '设备已停用并清除推送 token',
    'deviceDeactivateFailed': '停用设备失败：{error}',
    'exportSaved': '导出文件已保存：{path}',
    'exportDownloadFailed': '下载导出文件失败：{error}',
    'selectExportModule': '至少选择一个导出模块',
    'exportTaskCreated': '导出任务已创建，准备好后可下载',
    'createExportFailed': '创建导出任务失败：{error}',
    'deleteRequestCanceled': '删除申请已撤销，账号会继续保留',
    'cancelDeleteFailed': '撤销删除申请失败：{error}',
    'privacyErrorExportLimitReached': '今天的隐私导出次数已经用完了，明天再试',
    'privacyErrorExportUnavailable': '这个导出文件当前还不能下载，请稍后再试',
    'privacyErrorExportMissing': '导出文件已经不存在了，请重新创建导出任务',
    'privacyErrorDeleteTaskPending': '你已经有一条删除申请在处理中，先处理当前这条',
    'privacyErrorDeleteTaskCannotCancel': '当前这条删除申请已经不能撤销了，请刷新状态后再看',
    'privacyErrorDeleteTaskCancelFailed': '撤销删除申请失败了，请稍后再试',
    'privacyErrorDeleteTaskMissing': '这条删除申请已经不存在了，请刷新页面',
    'fillAccountAndDeleteReason': '校验账号和删除原因都得填',
    'codeNotFilled': '验证码还没填',
    'passwordNotFilled': '登录密码还没填',
    'deleteEnteredCoolingOff': '删除申请已进入冷静期，到期前可以撤销',
    'submitDeleteFailed': '提交删除申请失败：{error}',
    'fillBoundAccountFirst': '先填写当前已绑定账号',
    'sendDeleteCodeFailed': '发送注销验证码失败：{error}',
    'privacyDeleteErrorBoundAccountOnly': '只能使用当前已绑定的邮箱或手机号来校验注销申请',
    'privacyDeleteErrorNoPassword': '这个账号当前没有可校验的登录密码，请改用验证码方式验证',
    'privacyDeleteErrorWrongPassword': '当前登录密码不正确，请重新输入后再试',
    'createdAtLabel': '创建于 {time}',
    'expiresAtLabel': '到期 {time}',
    'reasonLabel': '原因：{value}',
    'coolingOffDeadline': '冷静期截止：{value}',
    'verifyByCode': '验证码校验',
    'verifyByPassword': '密码校验',
    'boundAccount': '当前已绑定账号',
    'deleteVerificationCode': '注销验证码',
    'currentLoginPassword': '当前登录密码',
    'deleteReason': '删除原因',
    'coolingOffIntro': '提交后进入 {days} 天冷静期，到期前可以撤销。',
    'accountSettingsSubtitleLong': '资料、绑定和密码都走真实后端校验，没整一堆看着能点的摆设。',
    'accountProfileLoadFailed': '账户资料加载失败：{error}',
    'nickname': '昵称',
    'avatarUrl': '头像 URL',
    'gender': '性别',
    'genderUnknown': '未知',
    'genderMale': '男',
    'genderFemale': '女',
    'signature': '签名',
    'emailLabel': '邮箱：{value}',
    'phoneLabel': '手机号：{value}',
    'unbound': '未绑定',
    'email': '邮箱',
    'phone': '手机号',
    'bindVerificationCode': '绑定验证码',
    'oldPassword': '旧密码',
    'expertApplicationSubmitted': '达人认证申请已提交',
    'expertStatusLoadFailed': '认证状态加载失败：{error}',
    'reviewedAtLabel': '审核时间：{value}',
    'effectiveStartLabel': '生效开始：{value}',
    'effectiveEndLabel': '生效结束：{value}',
    'expertReasonHint': '说明你在本地区的内容贡献、探店经验或持续输出计划',
    'expertPendingHint': '申请审核中，请耐心等待结果。',
    'expertApprovedHint': '你已通过本地达人认证，公开内容会展示达人标识。',
    'expertStatusNotApplied': '未申请',
    'expertStatusPendingReview': '待审核',
    'expertStatusApproved': '已通过',
    'expertStatusRejected': '已驳回',
    'expertReasonRequired': '请先填写申请理由',
    'expertReasonTooLong': '申请理由不能超过 500 字',
    'expertErrorPendingExists': '你已经有一条达人认证申请在审核中，先等当前结果出来',
    'expertErrorAlreadyApproved': '你当前已经是认证达人了，不需要重复申请',
    'localExpertBadge': '本地达人',
    'verifiedMerchantBadge': '认证商户',
    'applicationReason': '申请理由',
    'expertCertificationApprovedNotice': '本地达人认证已通过',
    'expertCertificationRejectedNotice': '本地达人认证未通过，可查看原因后重提',
    'expertCertificationUpdatedNotice': '本地达人认证状态已更新',
    'growthRecordsErrorSessionMissing': '当前登录状态已失效，请重新登录后再试',
    'growthRecordsLoadFailed': '流水加载失败：{error}',
    'noGrowthRecords': '还没有成长值 / 积分流水',
    'refreshGrowthRecordsFailed': '刷新流水失败：{error}',
    'growthTypeValue': '成长值',
    'growthTypePoints': '积分',
    'growthActionReviewCreate': '发布点评',
    'growthActionReviewLiked': '点评获赞',
    'growthActionReviewImage': '带图点评',
    'growthActionOrderComplete': '完成订单',
    'growthRewardReviewCreate': '发点评奖励',
    'growthRewardReviewLiked': '点评获赞奖励',
    'growthRewardReviewImage': '带图点评奖励',
    'growthRewardOrderComplete': '完成订单奖励',
    'balanceAfterLabel': '余额 {value}',
    'privacyHero': '你的数据，由你说了算',
    'exportDailyLimit': '每天最多 {count} 次',
    'exportFileRetention': '文件保留 {hours} 小时',
    'canCancelBeforeDeadline': '到期前可以撤销',
    'creatingExport': '创建中...',
    'recordingAcceptance': '记录中...',
    'deactivatingDevice': '停用中...',
    'exportTaskTitle': '任务 #{id}',
    'downloadZip': '下载 ZIP',
    'downloadingZip': '下载中...',
    'exportStatusPending': '待处理',
    'exportStatusProcessing': '处理中',
    'exportStatusReady': '可下载',
    'exportStatusExpired': '已过期',
    'exportStatusFailed': '失败',
    'exportStatusCanceled': '已取消',
    'deleteStatusPendingConfirm': '待确认',
    'deleteStatusCoolingOff': '冷静期中',
    'deleteStatusProcessing': '处理中',
    'deleteStatusCompleted': '已完成',
    'deleteStatusCanceled': '已取消',
    'deleteStatusRejected': '已驳回',
    'cancellingDelete': '撤销中...',
    'cookieMarketingNotice': 'Cookie/营销告知',
    'lastActiveAt': '最近活跃 {time}',
    'profileSaved': '资料已保存',
    'saveProfileFailed': '保存资料失败：{error}',
    'fillTargetFirst': '请先填写{target}',
    'codeSentWithLocal': '验证码已发送（本地验证码：{code}）',
    'sendCodeFailed': '发送验证码失败：{error}',
    'fillAccountAndCode': '请填写账号和验证码',
    'accountBound': '账号已绑定',
    'bindFailed': '绑定失败：{error}',
    'enterOldPassword': '请输入旧密码',
    'enterNewPassword': '请输入新密码',
    'newPasswordsDoNotMatch': '两次输入的新密码不一致',
    'passwordUpdated': '密码已更新',
    'updatePasswordFailed': '更新密码失败：{error}',
    'accountSettingsHero': '把账户握在自己手里',
    'basicProfile': '基础资料',
    'accountBinding': '账号绑定',
    'changePassword': '修改密码',
    'saving': '保存中...',
    'saveProfile': '保存资料',
    'binding': '绑定中...',
    'confirmBind': '确认绑定',
    'updating': '更新中...',
    'updatePassword': '更新密码',
    'hasPasswordHint': '当前账号已有密码，修改时需要校验旧密码。',
    'noPasswordHint': '当前账号还没有密码，可以直接设置新密码。',
    'dataExport': '数据导出',
    'accountDeletion': '账号删除',
    'coolingOffDays': '{days} 天冷静期',
    'createExportTask': '创建导出任务',
    'loadMoreExportTasks': '加载更多导出任务',
    'agreementTrace': '协议留痕',
    'confirmPrivacyPolicy': '确认隐私政策',
    'confirmUserAgreement': '确认用户协议',
    'deviceManagement': '设备管理',
    'deactivateThisDevice': '停用此设备',
    'privacyPolicy': '隐私政策',
    'userAgreement': '用户协议',
    'unknownAgreement': '未知协议',
    'unknownDevice': '未知设备',
    'deleteTaskTitle': '删除任务 #{id} · {status}',
    'cancelDeleteRequest': '撤销删除申请',
    'submitDeleteRequest': '提交删除申请',
    'sendDeleteCode': '发送注销验证码',
    'localCodeOnly': '本地验证码：{code}',
    'unknownStatus': '未知状态',
    'deviceEnabled': '启用',
    'deviceDisabled': '已停用',
    'deviceLoggedOut': '已登出',
    'publicProfile': '公开主页',
    'publicProfileLoadFailed': '用户主页加载失败：{error}',
    'sendDirectMessage': '发私信',
    'loginToFollowUser': '登录后可以关注这位用户。',
    'publicProfileErrorUserNotFound': '这位用户不存在',
    'publicProfileErrorSessionMissing': '当前登录状态已失效，请重新登录后再试',
    'publicProfileErrorCannotFollowSelf': '你不能关注自己',
    'loadMoreUsersFailed': '加载更多用户失败：{error}',
    'relationListLoadFailed': '关系列表加载失败：{error}',
    'followers': '粉丝',
    'followingUsers': '关注',
    'noRelationUsers': '暂无用户',
    'userCollectionErrorSessionMissing': '当前登录状态已失效，请重新登录后再试',
    'collectionLoadFailed': '加载失败：{error}',
    'noCollectionData': '暂无数据',
    'favoritedAt': '收藏于 {time}',
    'postLabel': '帖子',
    'address': '地址',
    'shopDetail': '门店详情',
    'shopDetailLoadFailed': '门店详情加载失败：{error}',
    'openingHours': '营业时间',
    'favoriteActionFailed': '收藏操作失败：{error}',
    'shareCopied': '分享文案已复制',
    'viewAll': '查看全部',
    'shopReviewsLoadFailed': '门店点评加载失败：{error}',
    'noPublicReviews': '暂无公开点评',
    'similarShopsLoadFailed': '相似门店加载失败：{error}',
    'noSimilarShops': '暂无相似门店',
    'sortLatest': '最新',
    'sortHottest': '最热',
    'sortBestRated': '好评优先',
    'minScoreFour': '4 分以上',
    'withPhotosOnly': '只看带图',
    'alreadyAtEnd': '已经到底了',
    'refreshBrowseHistoryFailed': '刷新足迹失败：{error}',
    'loadMoreBrowseHistoryFailed': '加载更多足迹失败：{error}',
    'clearBrowseHistoryFailed': '清空足迹失败：{error}',
    'deleteBrowseHistoryFailed': '删除足迹失败：{error}',
    'browseHistoryLoadFailed': '足迹加载失败：{error}',
    'noBrowseHistory': '当前区域还没有浏览足迹',
    'browseViewCount': '浏览 {count} 次',
    'deleteBrowseHistoryTooltip': '删除足迹',
    'clearAll': '清空',
    'postSubmittedForAudit': '帖子已提交审核',
    'deletePost': '删除帖子',
    'deletePostConfirm': '删除后不可恢复，确认删除这条帖子吗？',
    'postDeleted': '帖子已删除',
    'postEditorLoadFailed': '帖子编辑数据加载失败：{error}',
    'publishToCircle': '发布到 {name}',
    'circlePostNeedsAudit': '内容仍需经过现有社区审核。',
    'titleLabel': '标题',
    'bodyLabel': '正文',
    'topicsCommaSeparated': '话题，用逗号分隔',
    'submitForAudit': '提交审核',
    'postDetail': '帖子详情',
    'postLoadFailed': '帖子加载失败：{error}',
    'reposted': '已转发',
    'unreposted': '已取消转发',
    'repostFailed': '转发操作失败：{error}',
    'reportPost': '举报帖子',
    'reportSubmitFailed': '举报提交失败：{error}',
    'cancelReply': '取消回复',
    'saySomethingUsefulShort': '说点有用的',
    'likeCountLabel': '点赞 {count}',
    'replyingToUser': '正在回复 {name}',
    'simplifiedChinese': '简体中文',
    'traditionalChinese': '繁體中文',
    'englishLanguage': 'English',
    'noSignature': '暂未填写签名',
    'reviewsMetric': '点评',
    'noFollowers': '暂无粉丝',
    'noFollowing': '暂无关注',
    'levelFollowersMeta': 'Lv.{level} · 粉丝 {count}',
    'shopHash': '门店 #{id}',
    'postHash': '帖子 #{id}',
    'recordHash': '记录 #{id}',
    'shopLabel': '门店',
    'unfavoritePost': '取消收藏',
    'favoritePost': '收藏帖子',
    'unrepostWithCount': '取消转发 {count}',
    'repostWithCount': '转发 {count}',
    'editPost': '编辑帖子',
    'publishPost': '发布帖子',
    'pleaseEnterTitle': '请输入标题',
    'pleaseEnterBody': '请输入正文',
    'postSaveFailed': '帖子保存失败：{error}',
    'unfavoriteShop': '取消收藏',
    'favoriteShop': '收藏门店',
    'favoriteStatusLoading': '收藏状态加载中...',
    'sharing': '分享中...',
    'shareShop': '分享门店',
    'shopReviewsSection': '门店点评',
    'similarShopsSection': '相似门店',
    'retryReviews': '重试点评',
    'retryRecommendations': '重试推荐',
  };
  static const _traditional = {
    'homeTitle': '在地生活',
    'searchHint': '搜尋餐廳、超市和生活服務',
    'featured': '附近推薦',
    'profile': '我的',
    'homeSubtitle': '探索附近更適合華人的好去處',
    'europe': '歐洲',
    'china': '中國',
    'language': '切換語言',
    'map': '地圖',
    'mapsConfigured': 'Google Maps 已設定',
    'mapsUnavailable': 'Google Maps 尚未設定，仍可依城市和列表瀏覽。',
    'realPaymentUnavailable': '真實支付尚未設定，客戶端不會偽造支付成功。',
    'pushUnavailable': 'FCM/APNs 尚未設定，通知仍可透過站內訊息補償。',
    'notifications': '訊息通知',
    'account': '個人中心',
    'cityRankings': '城市排行榜',
    'activities': '精選活動',
    'placesLoadFailed': '附近店家載入失敗',
    'noPlaces': '目前城市暫無店家',
    'homeNavigation': '首頁',
    'exploreNavigation': '探索',
    'ordersNavigation': '訂單',
    'searchTitle': '搜尋結果',
    'searchSuggestionsLoading': '聯想載入中...',
    'searchSuggestions': '搜尋聯想',
    'searchFailed': '搜尋失敗：{error}',
    'processing': '處理中...',
    'retry': '重試',
    'requestFailed': '請求失敗',
    'invalidApiResponse': '服務回傳格式異常',
    'unsupportedApiClientCapability': '目前 API 客戶端不支援 {capability}',
    'noMatchingPlaces': '沒有符合條件的店家',
    'loading': '載入中...',
    'loadMore': '載入更多',
    'loadMoreShopsFailed': '載入更多店家失敗：{error}',
    'discoveryFailed': '搜尋探索載入失敗：{error}',
    'browseErrorShopNotFound': '這家店家不存在',
    'browseErrorSearchHistoryNotFound': '這筆搜尋記錄不存在',
    'browseErrorInvalidShopId': '店家參數無效',
    'browseErrorUnsupportedReviewSort': '目前評論排序方式不受支援',
    'browseErrorUnsupportedFavoriteTarget': '目前收藏目標類型不受支援',
    'enterKeyword': '輸入關鍵字開始搜尋',
    'recentSearches': '最近搜尋',
    'clearing': '清除中...',
    'clear': '清除',
    'moreHistory': '更多記錄',
    'hotSearches': '熱門搜尋',
    'clearHistoryFailed': '清除搜尋記錄失敗：{error}',
    'removeHistoryFailed': '刪除搜尋記錄失敗：{error}',
    'loadMoreHistoryFailed': '載入更多搜尋記錄失敗：{error}',
    'rankDetailTitle': '排行榜詳情',
    'refreshRanksFailed': '重新整理排行榜失敗：{error}',
    'ranksLoadFailed': '排行榜載入失敗：{error}',
    'rankErrorNotFound': '這個排行榜不存在',
    'rankErrorInvalidType': '目前排行榜類型不受支援',
    'noPublicRanks': '目前區域暫無公開排行榜',
    'rankTypeMustEat': '必吃榜',
    'rankTypeTopRated': '好評榜',
    'rankTypeTrending': '熱門榜',
    'shopCount': '{count} 家店家',
    'topShop': '榜首 {name}',
    'rankDetailLoadFailed': '排行榜詳情載入失敗：{error}',
    'rankNoShops': '此排行榜暫無店家',
    'activityDetailTitle': '活動詳情',
    'refreshActivitiesFailed': '重新整理活動失敗：{error}',
    'activitiesLoadFailed': '活動載入失敗：{error}',
    'noOnlineActivities': '目前區域暫無上線活動',
    'activityChannelHome': '首頁',
    'activityChannelSearch': '搜尋',
    'activityChannelChannel': '頻道',
    'activityChannelPage': '活動頁',
    'activityChannelCommunity': '社群',
    'activityTypeThemed': '專題活動',
    'activityTypeHoliday': '節日活動',
    'activityTypeNewCustomer': '新客活動',
    'activityTypeMerchantSupport': '商戶扶持',
    'activityTypeContentTopic': '內容話題',
    'resourceCount': '{count} 個資源',
    'activityDetailLoadFailed': '活動詳情載入失敗：{error}',
    'activityErrorNotFoundOrOffline': '目前活動不存在或未上線',
    'activityNoItems': '此活動暫無資源項',
    'cannotOpenExternalLink': '無法開啟外部連結',
    'openTargetFailed': '{target}開啟失敗：{error}',
    'targetShop': '店家',
    'targetDeal': '團購',
    'targetPost': '貼文',
    'targetRank': '排行榜',
    'targetTopic': '話題',
    'targetExternalLink': '外部連結',
    'targetResource': '資源',
    'refreshNotificationsFailed': '重新整理訊息失敗：{error}',
    'loadMoreFailed': '載入更多失敗：{error}',
    'markReadFailed': '標記已讀失敗：{error}',
    'allNotificationsMarkedRead': '全部通知已標記為已讀',
    'markAllReadFailed': '全部已讀失敗：{error}',
    'markAllRead': '全部已讀',
    'markAllReadWithCount': '全部已讀（{count}）',
    'filterAll': '全部',
    'filterUnreadOnly': '只看未讀',
    'notificationsLoadFailed': '訊息載入失敗：{error}',
    'notificationErrorUnavailable': '通知服務暫時不可用',
    'notificationErrorRefreshUnavailable': '通知暫時無法重新整理',
    'reload': '重新載入',
    'refresh': '重新整理',
    'noUnreadNotifications': '暫無未讀訊息',
    'noNotifications': '暫無訊息',
    'continueFindUnread': '繼續尋找未讀訊息',
    'unreadBadge': '未讀',
    'notificationTitleSocialFollow': '新增關注',
    'notificationTitleDirectMessage': '收到私信',
    'notificationTitleMention': '有人提到了你',
    'notificationTitlePostApproved': '貼文已通過審核',
    'notificationTitlePostRejected': '貼文未通過審核',
    'notificationTitleTopicUpdate': '關注的話題有新內容',
    'notificationTitleOrderPaid': '支付成功',
    'notificationTitleReservationConfirmed': '預訂已自動確認',
    'notificationTitleReservationSubmitted': '預訂已提交',
    'notificationTitleReservationReminderThirtyMinutes': '預訂即將開始（30 分鐘）',
    'notificationTitleReservationReminderTwoHours': '預訂提醒（2 小時）',
    'notificationTitleCouponReminder': '券碼即將到期',
    'notificationTitleCouponExpired': '券碼已過期',
    'notificationTitleCouponVerified': '券碼已核銷',
    'notificationTitleMerchantReply': '商家回覆',
    'notificationFollowedYou': '{name} 關注了你',
    'notificationDirectMessagePreview': '{name}：{preview}',
    'notificationPostApprovedContent': '《{title}》 已公開',
    'notificationPostRejectedContent': '《{title}》 未通過審核',
    'notificationOrderNumber': '訂單 {orderNo}',
    'notificationCouponsReady': '券碼已發放，可在我的券查看',
    'notificationReservationAutoConfirmedAction': '系統已自動確認你的預訂',
    'notificationReservationSubmittedAction': '已提交，等待商戶確認',
    'notificationCouponCodeLabel': '券碼 {code}',
    'notificationCouponExpiringInDays': '{code} 將在 {days} 天後過期',
    'notificationCouponRedeemedAt': '{code} 已在 {shop} 核銷',
    'notificationCouponRedeemed': '已核銷成功',
    'notificationExpertApprovedContent': '你的在地達人認證已審核通過',
    'notificationExpertRejectedContent': '你的在地達人認證未通過，請查看原因後重提',
    'notificationTitleRefundApproved': '退款已通過',
    'notificationTitleRefundRejected': '退款已駁回',
    'notificationTitleReservationMerchantConfirmed': '預訂已確認',
    'notificationTitleReservationArrived': '已確認到店',
    'notificationTitleReservationRejected': '預訂被拒絕',
    'notificationTitleReservationNoShow': '預訂已標記爽約',
    'notificationTitleReviewApproved': '評論已通過審核',
    'notificationTitleReviewRejected': '評論未通過審核',
    'notificationTitleReviewHidden': '評論已被隱藏',
    'notificationTitleBanAppealApproved': '封禁申訴已通過',
    'notificationTitleBanAppealRejected': '封禁申訴已駁回',
    'notificationTitleAccountUnbanned': '帳號已解封',
    'notificationActorPlatform': '平台',
    'notificationActorMerchant': '商家',
    'notificationRefundApprovedAction': '{actor}已同意退款',
    'notificationRefundRejectedAction': '{actor}已駁回退款',
    'notificationReservationMerchantConfirmedAction': '商家已確認你的預訂',
    'notificationReservationArrivedAction': '商家已確認你到店',
    'notificationReservationMerchantRejectedAction': '商家已拒絕你的預訂',
    'notificationReservationMarkedNoShowAction': '商家已將本次預訂標記為爽約',
    'notificationReviewApprovedContent': '{shop} · 你的評論已公開展示',
    'notificationReviewRejectedContent': '{shop} · 你的評論未通過審核',
    'notificationReviewHiddenContent': '{shop} · 商家申訴成立，你的評論已從公開展示中隱藏',
    'notificationTitleReviewLike': '評論獲讚',
    'notificationTitleReviewComment': '評論新留言',
    'notificationTitleCommentReply': '評論被回覆',
    'notificationTitlePostLike': '貼文獲讚',
    'notificationTitlePostComment': '貼文新留言',
    'notificationTitlePostRepost': '貼文被轉發',
    'notificationLikedYourReview': '{name} 讚了你的評論：{preview}',
    'notificationCommentedOnYourReview': '{name} 評論了你的評論：{preview}',
    'notificationRepliedToYou': '{name} 回覆了你：{preview}',
    'notificationLikedYourPost': '{name} 讚了你的貼文《{title}》',
    'notificationCommentedOnYourPost': '{name} 評論了你的貼文：{preview}',
    'notificationRepostedYourPost': '{name} 轉發了你的貼文《{title}》',
    'notificationMentionedYouInPost': '{name} 在貼文《{title}》中提到了你',
    'notificationMentionedYouInPostComment': '{name} 在貼文《{title}》的留言中提到了你',
    'notificationTopicUpdateContent': '{name} 在 #{topic} 發布了《{title}》',
    'notificationBanAppealApprovedContent': '你的封禁申訴已通過，帳號已解封，現在可以正常登入使用了。',
    'notificationBanAppealRejectedContent': '你的封禁申訴未通過',
    'notificationAccountUnbannedContent':
        '管理員已解除你的帳號封禁，關聯的申訴已自動通過，現在可以正常登入使用了。',
    'loggingOut': '登出中...',
    'logout': '登出',
    'profileLoadFailed': '使用者資料載入失敗：{error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} 積分',
    'growthValueLabel': '{value} 成長值',
    'accountSettings': '帳戶設定',
    'accountSettingsSubtitle': '資料、綁定帳號、修改密碼',
    'localExpertCertification': '在地達人認證',
    'localExpertCertificationSubtitle': '提交或重新提交在地達人申請',
    'growthRecords': '成長值流水',
    'growthRecordsSubtitle': 'Lv.{level} · 成長值 {growth} · 積分 {points}',
    'myMessages': '我的私信',
    'blockedUsers': '黑名單管理',
    'myCircles': '我的圈子',
    'myReviews': '我的評論',
    'myPosts': '我的貼文',
    'myFavorites': '我的收藏',
    'myOrders': '我的訂單',
    'myCoupons': '我的券',
    'myReservations': '我的預訂',
    'myBrowseHistory': '我的足跡',
    'privacyCenter': '隱私中心',
    'communityTitle': '華人社群',
    'topicPlaza': '話題廣場',
    'localCircles': '同城圈子',
    'recommendedTab': '推薦',
    'followingTab': '追蹤',
    'createPost': '發文',
    'followingFeedLoginRequired': '登入後查看追蹤動態，你追蹤的人更新時會出現在這裡。',
    'loadMorePostsFailed': '載入更多貼文失敗：{error}',
    'communityLoadFailed': '社群載入失敗：{error}',
    'noCommunityPosts': '暫無貼文',
    'postMetaStats': ' · ❤ {likes} · 評論 {comments}',
    'hotTab': '熱榜',
    'followingTopicsTab': '已追蹤',
    'loadMoreTopicsFailed': '載入更多話題失敗：{error}',
    'topicsLoadFailed': '話題載入失敗：{error}',
    'followingTopicsLoginRequired': '登入後查看追蹤的話題，不會額外產生獨立動態流。',
    'goLogin': '去登入',
    'hotScore': '熱度 {score}',
    'topicSevenDayStats': '7 天：{posts} 帖 · {likes} 讚 · {comments} 評論',
    'topicFollowMeta': '{followers} 人追蹤 · {posts} 篇公開貼文',
    'topicFollowerCount': '{count} 人追蹤',
    'topicErrorNotFound': '這個話題不存在',
    'topicErrorUnavailable': '這個話題暫時不可用',
    'topicErrorFollowFailed': '追蹤請求未能完成',
    'followStatusUpdateFailed': '追蹤狀態更新失敗：{error}',
    'followed': '已追蹤',
    'followTopic': '追蹤話題',
    'publicPosts': '公開貼文',
    'postsLoadFailed': '貼文載入失敗：{error}',
    'noPublicPostsHere': '這裡還沒有公開貼文。',
    'communityErrorPostNotFound': '這則貼文不存在',
    'communityErrorReportDuplicate': '你已經檢舉過這則貼文了，請不要重複提交',
    'communityErrorReplyTargetMissing': '你要回覆的評論不存在',
    'communityErrorJoinCircleToPost': '請先加入圈子再發文',
    'loadMoreCirclesFailed': '載入更多圈子失敗：{error}',
    'circlesLoadFailed': '圈子載入失敗：{error}',
    'circleErrorJoinedOnlyLoginRequired': '登入後才能查看已加入的圈子',
    'circleErrorNotFound': '這個圈子不存在',
    'circleMeta': '{members} 位成員 · {posts} 篇貼文',
    'circleStatusUpdateFailed': '圈子狀態更新失敗：{error}',
    'joined': '已加入',
    'joinCircle': '加入圈子',
    'viewMembers': '查看成員',
    'postInCircle': '在圈子發文',
    'joinCircleToPost': '加入圈子後即可發布內容，歷史貼文公開可見。',
    'circleNewPosts': '圈子新貼',
    'loadMoreMembersFailed': '載入更多成員失敗：{error}',
    'circleMembersTitle': '{name}成員',
    'membersLoadFailed': '成員載入失敗：{error}',
    'directMessages': '私信',
    'directMessageUser': '私信使用者',
    'messageErrorUserNotFound': '這位使用者不存在',
    'messageErrorConversationMissing': '這個對話不存在',
    'messageErrorCannotMessageSelf': '你不能給自己發私信',
    'messageErrorBlockedRelationship': '你們之間存在封鎖關係，暫時無法發送私信',
    'messageErrorCannotBlockSelf': '你不能封鎖自己',
    'messageErrorReportTargetUnavailable': '這個檢舉目標不存在，或你目前無權存取',
    'messageErrorReportDuplicate': '你已經檢舉過這個目標了，請不要重複提交',
    'refreshConversationsFailed': '重新整理對話失敗：{error}',
    'loadMoreConversationsFailed': '載入更多對話失敗：{error}',
    'conversationsLoadFailed': '對話載入失敗：{error}',
    'noDirectMessages': '還沒有私信，去公開主頁打個招呼吧。',
    'messageMarkReadFailed': '已讀狀態同步失敗：{error}',
    'loadEarlierMessagesFailed': '載入更早訊息失敗：{error}',
    'sendFailed': '傳送失敗：{error}',
    'actionFailed': '操作失敗：{error}',
    'reportConversation': '檢舉對話',
    'blockUser': '封鎖使用者',
    'unblockUser': '解除封鎖',
    'reportSubmitted': '檢舉已提交',
    'blockedBothWays': '已封鎖，雙方無法繼續傳送',
    'unblocked': '已解除封鎖',
    'chatHistoryLoadFailed': '聊天紀錄載入失敗：{error}',
    'loadEarlierMessages': '載入更早訊息',
    'blockedComposerHint': '已封鎖，解除後可繼續傳送',
    'messageHint': '寫點什麼…',
    'send': '傳送',
    'harassmentOrInappropriate': '騷擾或不當內容',
    'refreshBlockedUsersFailed': '重新整理黑名單失敗：{error}',
    'loadMoreBlockedUsersFailed': '載入更多黑名單失敗：{error}',
    'unblockedUser': '已解除對 {name} 的封鎖',
    'unblockFailed': '解除封鎖失敗：{error}',
    'blockedUsersLoadFailed': '黑名單載入失敗：{error}',
    'blockedUsersEmpty': '黑名單為空',
    'blockedAt': '封鎖時間：{time}',
    'userFallback': '使用者 {id}',
    'anonymousPeer': 'TA',
    'payPending': '待支付',
    'payPaid': '已支付',
    'payRefunded': '已退款',
    'payPartialRefund': '部分退款',
    'couponPending': '待使用',
    'couponUsed': '已使用',
    'couponExpired': '已過期',
    'couponRefunded': '已退款',
    'loadMoreOrdersFailed': '載入更多訂單失敗：{error}',
    'ordersLoadFailed': '訂單載入失敗：{error}',
    'noOrdersForFilter': '目前篩選下暫無訂單',
    'loadMoreCouponsFailed': '載入更多券碼失敗：{error}',
    'couponsLoadFailed': '券碼載入失敗：{error}',
    'noCouponsForFilter': '目前篩選下暫無券碼',
    'couponHighlight': '定位券碼 {code}',
    'groupDeals': '團購優惠',
    'dealsLoadFailed': '團購載入失敗：{error}',
    'noDealsForShop': '目前店家暫無團購',
    'soldCount': '已售 {count}',
    'stockCount': '庫存 {count}',
    'buy': '購買',
    'tradeErrorDealNotFound': '這項團購不存在',
    'tradeErrorDealExpired': '這項團購已過期',
    'tradeErrorDealOutOfStock': '這項團購庫存不足',
    'tradeErrorOrderNotFound': '這筆訂單不存在',
    'tradeErrorOrderPaymentUnavailable': '這筆訂單目前無法付款',
    'tradeErrorOrderCancelUnavailable': '這筆訂單目前無法取消',
    'tradeErrorOrderRefundUnavailable': '這筆訂單目前無法退款',
    'tradeErrorRefundUsedCoupons': '訂單內有已核銷的券，暫不支援整單退款',
    'tradeErrorRefundExists': '這筆訂單已有退款申請',
    'tradeErrorCouponCodeRequired': '請輸入券碼',
    'tradeErrorCouponNotFound': '這張券不存在',
    'tradeErrorPaymentChannelUnavailable': '支付服務尚未配置',
    'createOrderFailed': '下單失敗：{error}',
    'orderCreatedOpenDetailFailed': '訂單 {orderNo} 已建立，但開啟詳情失敗：{error}',
    'dealDetail': '團購詳情',
    'dealDetailLoadFailed': '團購詳情載入失敗：{error}',
    'soldAndStock': '已售 {sold} · 庫存 {stock}',
    'validUntil': '有效期 {range}',
    'noPackageItems': '暫無套餐明細',
    'quantityLabel': '數量 {count}',
    'orderDetail': '訂單詳情',
    'cancelOrder': '取消訂單',
    'cancelOrderConfirm': '訂單取消後將釋放庫存，確定繼續？',
    'keepOrder': '先不取消',
    'confirmCancel': '確認取消',
    'applyRefund': '申請退款',
    'submitApplication': '提交申請',
    'cancelAction': '取消',
    'orderLoadFailedTapRetry': '訂單載入失敗，點擊重試',
    'orderShopMeta': '{shop} · 訂單 {orderNo}',
    'startPayment': '發起支付',
    'refundLabel': '退款：{status}',
    'couponCopied': '券碼已複製',
    'couponDetail': '券詳情',
    'couponDetailLoadFailed': '券碼詳情載入失敗：{error}',
    'qrLoadFailed': '二維碼載入失敗',
    'verifiedAt': '核銷時間 {time}',
    'showCodeToMerchant': '請向商家出示券碼',
    'priceSoldMeta': '{price} · 已售 {count}',
    'usageRules': '使用規則',
    'packageContents': '套餐內容',
    'quantitySimple': '數量',
    'unitPrice': '單價',
    'paidAmount': '實付',
    'orderCanceled': '訂單已取消',
    'refundReason': '退款原因',
    'refundSubmitted': '退款申請已提交',
    'refundStatusPending': '待審核',
    'refundStatusApproved': '退款成功',
    'refundStatusRejected': '已駁回',
    'defaultRefundReason': '行程有變',
    'paymentRequestCreated': '已建立 {channel} 支付請求，請在支付渠道完成付款',
    'paymentStartFailed': '支付發起失敗：{error}',
    'relatedCoupons': '關聯券碼',
    'redeemable': '可核銷',
    'notRedeemable': '不可核銷',
    'copying': '複製中...',
    'copyCouponCode': '複製券碼',
    'validUntilDate': '有效期至 {date}',
    'noExpiry': '不限期',
    'dealValidityRange': '團購有效期 {start} ~ {end}',
    'noExtraRules': '暫無補充規則',
    'defaultVerifyHint': '券碼由商家核銷；用戶端不提供自助核銷，避免誤操作。',
    'detailRefreshFailed': '詳情重新整理失敗：{error}',
    'reloadFullDetail': '重新載入完整詳情',
    'reservationPending': '待確認',
    'reservationConfirmed': '已確認',
    'reservationArrived': '已到店',
    'reservationUserCanceled': '使用者取消',
    'reservationMerchantRejected': '商家拒絕',
    'reservationNoShow': '爽約',
    'reservationConfirmModeAuto': '自動確認',
    'reservationConfirmModeManual': '人工確認',
    'reservationActionCreated': '建立預訂',
    'reservationActionMerchantConfirmed': '商家確認',
    'reservationActionMerchantRejected': '商家拒絕',
    'reservationActionUserCanceled': '使用者取消',
    'reservationActionUserRescheduled': '使用者改期',
    'reservationActionMerchantRescheduled': '商家改期',
    'reservationActionCheckedIn': '確認到店',
    'reservationActionMarkedNoShow': '標記爽約',
    'reservationActionArrivalReminder': '到店提醒',
    'loadMoreReservationsFailed': '載入更多預訂失敗：{error}',
    'reservationsLoadFailed': '預訂載入失敗：{error}',
    'noReservationsForFilter': '目前篩選下暫無預訂',
    'reservationListMeta': '{no}\n{time} · {people} 人 · {status}',
    'onlineReservation': '線上預訂',
    'selectSlotFirst': '請選擇時段',
    'reservationCreated': '預訂 {no} 已建立：{status}',
    'reservationFailed': '預訂失敗：{error}',
    'reservationErrorInvalidPeopleCount': '預訂人數至少為 1 人',
    'reservationErrorSlotOrTimeRequired': '請先選擇預訂時段',
    'reservationErrorSlotCapacityUnavailable': '目前時段剩餘名額不足',
    'reservationErrorCancelDeadlinePassed': '已超過可取消時間',
    'reservationErrorCancelUnavailable': '目前預訂暫時無法取消',
    'reservationErrorRescheduleSlotCapacityUnavailable': '新時段剩餘名額不足',
    'reservationErrorRescheduleUnavailable': '目前預訂暫時無法改期',
    'reservationErrorSlotNotFound': '預訂時段不存在',
    'reservationErrorNotFound': '這筆預訂不存在',
    'dateLabel': '日期 {date}',
    'peopleCount': '{count} 人',
    'slotsLoadFailed': '時段載入失敗：{error}',
    'slotRemaining': '{start}-{end} · 剩餘 {count}',
    'contactName': '聯絡人',
    'contactPhone': '聯絡電話',
    'remark': '備註',
    'submitting': '提交中...',
    'submitReservation': '提交預訂',
    'reservationDetail': '預訂詳情',
    'reservationLoadFailedTapRetry': '預訂載入失敗，點擊重試',
    'cancelReservation': '取消預訂',
    'cancelReservationConfirm': '取消時間限制由店家規則決定，確定繼續？',
    'keepReservation': '先不取消',
    'reservationCanceled': '預訂已取消',
    'findRescheduleSlots': '查詢改期時段',
    'confirmReschedule': '確認改期',
    'reservationRescheduled': '預訂已改期',
    'rescheduleReason': '使用者線上改期',
    'reservationTimePeople': '{time} · {people} 人',
    'rescheduleSlotMeta': '{start} · {mode} · 餘 {count}',
    'changeTimeline': '變更時間線',
    'noChangeRecords': '暫無變更記錄',
    'liked': '已按讚',
    'like': '按讚',
    'unliked': '已取消按讚',
    'likeFailed': '按讚失敗：{error}',
    'commentPublished': '評論已發布',
    'commentFailed': '評論失敗：{error}',
    'loadMoreCommentsFailed': '載入更多評論失敗：{error}',
    'reportReview': '檢舉評論',
    'reportReason': '檢舉理由',
    'submitReport': '提交檢舉',
    'reportFailed': '檢舉失敗：{error}',
    'deleteReview': '刪除評論',
    'deleteReviewConfirm': '刪除後不可恢復，確認刪除這則評論嗎？',
    'confirmDelete': '確認刪除',
    'reviewDeleted': '評論已刪除',
    'deleteFailed': '刪除失敗：{error}',
    'reply': '回覆',
    'myReviewDetail': '我的評論詳情',
    'reviewDetail': '評論詳情',
    'edit': '編輯',
    'deleting': '刪除中...',
    'delete': '刪除',
    'reviewDetailLoadFailed': '評論詳情載入失敗：{error}',
    'reviewErrorNotFound': '這則評論不存在',
    'reviewErrorReportDuplicate': '你已經檢舉過這則評論了，請不要重複提交',
    'reviewErrorReplyTargetMissing': '你要回覆的評論不存在',
    'reviewErrorUserUnavailable': '你的帳號目前不可用',
    'reviewErrorShopUnavailable': '這個商家目前不可評論',
    'reviewErrorShopImmutable': '評論所屬商家不可修改',
    'auditRemarkLabel': '審核備註：{remark}',
    'merchantReplyLabel': '商家回覆：{reply}',
    'anonymousUser': '匿名使用者',
    'report': '檢舉',
    'reviewLoginToInteract': '登入後可按讚、評論和檢舉這則評論。',
    'commentsSection': '評論',
    'replyingTo': '回覆 @{name}',
    'writeComment': '寫評論',
    'publishing': '發布中...',
    'publishComment': '發布評論',
    'commentsLoadFailed': '評論載入失敗：{error}',
    'retryComments': '重試評論',
    'noComments': '暫無評論',
    'writeReview': '寫評論',
    'editReview': '編輯評論',
    'reviewLoadFailedTapRetry': '評論載入失敗，點擊重試',
    'reviewContentHint': '寫下你的真實體驗……',
    'uploadedCount': '已上傳 {count}/9',
    'uploading': '上傳中…',
    'addImages': '新增圖片',
    'spendAmount': '本次消費',
    'tagsLabel': '標籤（最多 10 個）',
    'tagsHint': '中文服務，適合聚會，性價比高',
    'saveAndResubmit': '儲存並重新提交審核',
    'publishReview': '發布評論',
    'reviewingShop': '正在評論',
    'scoreOverall': '總體',
    'scoreTaste': '口味',
    'scoreEnv': '環境',
    'scoreService': '服務',
    'averageSpendLabel': '人均 {amount}',
    'replyToPreview': '回覆 {name}：{content}',
    'likeCommentStats': '按讚 {likes} · 評論 {comments}',
    'loadMoreComments': '載入更多評論',
    'maxNineImages': '最多上傳 9 張圖片',
    'imagePickFailed': '圖片選擇失敗：{error}',
    'imageUploadFailed': '圖片上傳失敗：{error}',
    'reviewUpdatedResubmitted': '評論已更新並重新進入審核',
    'reviewSubmittedPending': '評論已提交，等待審核',
    'saveFailed': '儲存失敗：{error}',
    'ratingPrompt': '這次體驗，值幾顆星？',
    'ratingHint': '拖動評分，別客氣，也別冤枉人。',
    'saySomethingUseful': '說點有用的',
    'reviewWritingHint': '味道、服務、排隊和避雷資訊，都比「還不錯」值錢。',
    'pleaseWriteRealExperience': '請寫下真實體驗',
    'onSitePhotos': '現場照片',
    'photosUploadHint': '最多 9 張，選擇後會立即上傳。',
    'spendAndTags': '消費與標籤',
    'spendTagsHint': '金額用於人均參考；多個標籤請用逗號分隔。',
    'enterNonNegativeAmount': '請輸入不小於 0 的金額',
    'loginTitle': '登入大眾點評',
    'loginHero': '連接歐洲華人生活',
    'loginSubtitle': '信箱和手機號都能登入，別整第三方登入套娃。',
    'passwordLogin': '密碼登入',
    'codeLogin': '驗證碼登入',
    'emailOrPhone': '信箱或手機號',
    'password': '密碼',
    'verificationCode': '驗證碼',
    'sendingCode': '發送中...',
    'sendCode': '發送驗證碼',
    'enterEmailOrPhone': '請輸入信箱或手機號',
    'enterEmailOrPhoneFirst': '先輸入信箱或手機號',
    'codeSent': '驗證碼已發送',
    'localCodeHint': '本地驗證碼：{code}',
    'accountBannedHint': '帳號 {account} 目前處於封禁狀態。如果認為是誤封，可以提交申訴，運營覆核通過後會自動解封。',
    'submitBanAppeal': '提交封禁申訴',
    'loginSuccess': '登入成功',
    'loggingIn': '登入中...',
    'login': '登入',
    'registerAccount': '註冊帳號',
    'passwordResetPleaseLogin': '密碼已重設，請使用新密碼登入',
    'forgotPassword': '忘記密碼',
    'banAppeal': '封禁申訴',
    'registerTitle': '註冊帳號',
    'registerSubtitle': '信箱或手機號都能註冊，驗證碼只用於本次註冊。',
    'nicknameOptional': '暱稱（可選）',
    'registerCode': '註冊驗證碼',
    'setPassword': '設定密碼',
    'registering': '註冊中...',
    'registerAndLogin': '註冊並登入',
    'resetPasswordTitle': '找回密碼',
    'resetPasswordSubtitle': '用目前綁定信箱或手機號驗證身份，重設後再返回登入。',
    'resetCode': '重設驗證碼',
    'newPassword': '新密碼',
    'confirmNewPassword': '確認新密碼',
    'resetting': '重設中...',
    'resetPassword': '重設密碼',
    'banAppealTitle': '封禁申訴',
    'banAppealHero': '帳號被封後的自助申訴入口',
    'banAppealSubtitle': '用目前綁定信箱或手機號驗證身份。運營覆核通過後會自動解封，再回登入頁繼續使用。',
    'appealCode': '申訴驗證碼',
    'appealReasonMin10': '申訴理由（至少 10 個字）',
    'banReasonLabel': '封禁原因：{value}',
    'appealContentLabel': '申訴內容：{value}',
    'rejectReasonLabel': '駁回說明：{value}',
    'submittedAtLabel': '提交時間：{value}',
    'processedAtLabel': '處理時間：{value}',
    'submittingAppeal': '提交中...',
    'submitAppeal': '提交申訴',
    'querying': '查詢中...',
    'queryAppealProgress': '查詢申訴進度',
    'backToLogin': '返回登入',
    'codeSentRetry': '驗證碼已發送，{seconds} 秒後可重發',
    'fillAccountCodePassword': '帳號、驗證碼和密碼都得填',
    'fillAccountCodeNewPassword': '帳號、驗證碼和新密碼都得填',
    'passwordsDoNotMatch': '兩次輸入的新密碼對不上',
    'authErrorInvalidCredentials': '帳號或密碼不正確，請重新輸入後再試',
    'authErrorAccountBanned': '這個帳號目前已被封禁，暫時無法登入',
    'authErrorAccountRegistered': '這個帳號已經註冊過了，直接登入或找回密碼即可',
    'authErrorAccountNotFound': '找不到這個帳號，請檢查信箱或手機號是否填寫正確',
    'authErrorCodeInvalid': '驗證碼無效或已過期，請重新取得後再試',
    'authErrorInvalidEmail': '信箱格式不正確，請檢查後重試',
    'authErrorInvalidPhone': '手機號格式不正確，請檢查後重試',
    'authErrorCodeRateLimited': '驗證碼發送太頻繁了，請稍等一會兒再試',
    'authErrorCodeSendUnavailable': '驗證碼發送服務暫時不可用，請稍後再試',
    'authErrorCodeVerifyUnavailable': '驗證碼校驗服務暫時不可用，請稍後再試',
    'authErrorEmailAlreadyBound': '這個信箱已經被其他帳號綁定了，請換一個再試',
    'authErrorPhoneAlreadyBound': '這個手機號已經被其他帳號綁定了，請換一個再試',
    'authErrorOldPasswordIncorrect': '目前密碼不正確，請重新輸入後再試',
    'authErrorSamePasswordAsOld': '新密碼不能和目前密碼相同，請換一個再試',
    'authErrorCurrentUserNotFound': '目前帳號不存在，請重新登入後再試',
    'authErrorSessionMissing': '目前登入狀態已失效，請重新登入後再試',
    'authErrorProfileNicknameTooLong': '暱稱最多只能填寫 64 個字元',
    'authErrorProfileAvatarTooLong': '頭像網址最多只能填寫 255 個字元',
    'authErrorProfileSignatureTooLong': '簽名最多只能填寫 255 個字元',
    'authErrorProfileUpdateFailed': '資料更新失敗了，請稍後再試',
    'registerHero': '加入歐洲華人生活圈',
    'resetPasswordHero': '重新設定登入密碼',
    'fillAccountAndCodeBeforeAppeal': '先填好帳號和驗證碼，再提交申訴',
    'appealReasonTooShort': '申訴理由至少寫 10 個字，把誤封的情況說清楚',
    'appealSubmitted': '申訴 #{id} 已提交，運營會盡快覆核',
    'queryNeedsAccountAndCode': '查詢進度也需要帳號和一條新的驗證碼',
    'appealProgressRefreshed': '已刷新申訴 #{id} 的最新進度',
    'appealStatusTitle': '申訴 #{id} · {status}',
    'appealApprovedHint': '申訴已通過，帳號已解封。請返回登入頁繼續使用。',
    'banAppealErrorAccountNotFound': '找不到這個帳號，請檢查信箱或手機號是否填寫正確',
    'banAppealErrorAccountNotBanned': '這個帳號目前沒有被封禁，不需要提交申訴',
    'banAppealErrorPendingExists': '你已經有一筆申訴正在處理中，請耐心等待審核結果',
    'banAppealErrorNoRecord': '這個帳號暫時沒有申訴記錄',
    'banAppealErrorStatusChanged': '申訴狀態剛剛發生變化，請重新整理後重試',
    'banAppealErrorCodeInvalid': '驗證碼無效或已過期，請重新取得後再試',
    'banAppealErrorInvalidEmail': '信箱格式不正確，請檢查後重試',
    'banAppealErrorInvalidPhone': '手機號格式不正確，請檢查後重試',
    'privacySubtitle': '匯出能帶走，刪除有冷靜期，規則和任務狀態都攤開講清楚。',
    'privacyLoadFailed': '隱私資料載入失敗：{error}',
    'exportModuleAccount': '帳號資料',
    'exportModuleReviews': '評論資料',
    'exportModuleOrders': '訂單資料',
    'exportModulePosts': '貼文資料',
    'exportModuleReservations': '預訂資料',
    'exportModuleFavorites': '收藏資料',
    'exportModuleFollows': '追蹤關係',
    'exportModuleMessages': '私信資料',
    'exportModuleCircles': '圈子關係',
    'exportModuleTopics': '話題追蹤',
    'privacyExportHint': '貼文、追蹤關係、私信、圈子和話題追蹤均支援真實匯出。',
    'noExportTasks': '還沒有匯出任務',
    'agreementRecordsHint': '記錄你確認過的使用者協議和隱私政策版本，省得日後各說各話。',
    'noAgreementRecords': '還沒有協議同意記錄。',
    'deviceLifecycleHint': '登入裝置會保留生命週期記錄；未設定推播時不會冒充 FCM/APNs 已接通。',
    'noRegisteredDevices': '還沒有登記裝置。',
    'loadMoreExportTasksFailed': '載入更多匯出任務失敗：{error}',
    'agreementRecorded': '協議同意記錄已留痕',
    'agreementRecordFailed': '協議留痕失敗：{error}',
    'deviceDeactivated': '裝置已停用並清除推播 token',
    'deviceDeactivateFailed': '停用裝置失敗：{error}',
    'exportSaved': '匯出檔案已儲存：{path}',
    'exportDownloadFailed': '下載匯出檔案失敗：{error}',
    'selectExportModule': '至少選擇一個匯出模組',
    'exportTaskCreated': '匯出任務已建立，準備好後可下載',
    'createExportFailed': '建立匯出任務失敗：{error}',
    'deleteRequestCanceled': '刪除申請已撤銷，帳號會繼續保留',
    'cancelDeleteFailed': '撤銷刪除申請失敗：{error}',
    'privacyErrorExportLimitReached': '今天的隱私匯出次數已經用完了，明天再試',
    'privacyErrorExportUnavailable': '這個匯出檔案目前還不能下載，請稍後再試',
    'privacyErrorExportMissing': '匯出檔案已經不存在了，請重新建立匯出任務',
    'privacyErrorDeleteTaskPending': '你已經有一筆刪除申請正在處理中，先處理目前這筆',
    'privacyErrorDeleteTaskCannotCancel': '目前這筆刪除申請已經不能撤銷了，請重新整理狀態後再看',
    'privacyErrorDeleteTaskCancelFailed': '撤銷刪除申請失敗了，請稍後再試',
    'privacyErrorDeleteTaskMissing': '這筆刪除申請已經不存在了，請重新整理頁面',
    'fillAccountAndDeleteReason': '校驗帳號和刪除原因都得填',
    'codeNotFilled': '驗證碼還沒填',
    'passwordNotFilled': '登入密碼還沒填',
    'deleteEnteredCoolingOff': '刪除申請已進入冷靜期，到期前可以撤銷',
    'submitDeleteFailed': '提交刪除申請失敗：{error}',
    'fillBoundAccountFirst': '先填寫目前已綁定帳號',
    'sendDeleteCodeFailed': '發送註銷驗證碼失敗：{error}',
    'privacyDeleteErrorBoundAccountOnly': '只能使用目前已綁定的信箱或手機號來校驗註銷申請',
    'privacyDeleteErrorNoPassword': '這個帳號目前沒有可校驗的登入密碼，請改用驗證碼方式驗證',
    'privacyDeleteErrorWrongPassword': '目前登入密碼不正確，請重新輸入後再試',
    'createdAtLabel': '建立於 {time}',
    'expiresAtLabel': '到期 {time}',
    'reasonLabel': '原因：{value}',
    'coolingOffDeadline': '冷靜期截止：{value}',
    'verifyByCode': '驗證碼校驗',
    'verifyByPassword': '密碼校驗',
    'boundAccount': '目前已綁定帳號',
    'deleteVerificationCode': '註銷驗證碼',
    'currentLoginPassword': '目前登入密碼',
    'deleteReason': '刪除原因',
    'coolingOffIntro': '提交後進入 {days} 天冷靜期，到期前可以撤銷。',
    'accountSettingsSubtitleLong': '資料、綁定和密碼都走真實後端校驗，沒整一堆看著能點的擺設。',
    'accountProfileLoadFailed': '帳戶資料載入失敗：{error}',
    'nickname': '暱稱',
    'avatarUrl': '頭像 URL',
    'gender': '性別',
    'genderUnknown': '未知',
    'genderMale': '男',
    'genderFemale': '女',
    'signature': '簽名',
    'emailLabel': '信箱：{value}',
    'phoneLabel': '手機號：{value}',
    'unbound': '未綁定',
    'email': '信箱',
    'phone': '手機號',
    'bindVerificationCode': '綁定驗證碼',
    'oldPassword': '舊密碼',
    'expertApplicationSubmitted': '達人認證申請已提交',
    'expertStatusLoadFailed': '認證狀態載入失敗：{error}',
    'reviewedAtLabel': '審核時間：{value}',
    'effectiveStartLabel': '生效開始：{value}',
    'effectiveEndLabel': '生效結束：{value}',
    'expertReasonHint': '說明你在本地區的內容貢獻、探店經驗或持續輸出計畫',
    'expertPendingHint': '申請審核中，請耐心等待結果。',
    'expertApprovedHint': '你已通過在地達人認證，公開內容會展示達人標識。',
    'expertStatusNotApplied': '未申請',
    'expertStatusPendingReview': '待審核',
    'expertStatusApproved': '已通過',
    'expertStatusRejected': '已駁回',
    'expertReasonRequired': '請先填寫申請理由',
    'expertReasonTooLong': '申請理由不能超過 500 字',
    'expertErrorPendingExists': '你已經有一筆達人認證申請在審核中，先等目前結果出來',
    'expertErrorAlreadyApproved': '你目前已經是認證達人了，不需要重複申請',
    'localExpertBadge': '在地達人',
    'verifiedMerchantBadge': '認證商戶',
    'applicationReason': '申請理由',
    'expertCertificationApprovedNotice': '在地達人認證已通過',
    'expertCertificationRejectedNotice': '在地達人認證未通過，可查看原因後重新提交',
    'expertCertificationUpdatedNotice': '在地達人認證狀態已更新',
    'growthRecordsErrorSessionMissing': '目前登入狀態已失效，請重新登入後再試',
    'growthRecordsLoadFailed': '流水載入失敗：{error}',
    'noGrowthRecords': '還沒有成長值 / 積分流水',
    'refreshGrowthRecordsFailed': '重新整理流水失敗：{error}',
    'growthTypeValue': '成長值',
    'growthTypePoints': '積分',
    'growthActionReviewCreate': '發布評論',
    'growthActionReviewLiked': '評論獲讚',
    'growthActionReviewImage': '帶圖評論',
    'growthActionOrderComplete': '完成訂單',
    'growthRewardReviewCreate': '發評論獎勵',
    'growthRewardReviewLiked': '評論獲讚獎勵',
    'growthRewardReviewImage': '帶圖評論獎勵',
    'growthRewardOrderComplete': '完成訂單獎勵',
    'balanceAfterLabel': '餘額 {value}',
    'privacyHero': '你的資料，由你說了算',
    'exportDailyLimit': '每天最多 {count} 次',
    'exportFileRetention': '檔案保留 {hours} 小時',
    'canCancelBeforeDeadline': '到期前可以撤銷',
    'creatingExport': '建立中...',
    'recordingAcceptance': '記錄中...',
    'deactivatingDevice': '停用中...',
    'exportTaskTitle': '任務 #{id}',
    'downloadZip': '下載 ZIP',
    'downloadingZip': '下載中...',
    'exportStatusPending': '待處理',
    'exportStatusProcessing': '處理中',
    'exportStatusReady': '可下載',
    'exportStatusExpired': '已過期',
    'exportStatusFailed': '失敗',
    'exportStatusCanceled': '已取消',
    'deleteStatusPendingConfirm': '待確認',
    'deleteStatusCoolingOff': '冷靜期中',
    'deleteStatusProcessing': '處理中',
    'deleteStatusCompleted': '已完成',
    'deleteStatusCanceled': '已取消',
    'deleteStatusRejected': '已駁回',
    'cancellingDelete': '撤銷中...',
    'cookieMarketingNotice': 'Cookie/行銷告知',
    'lastActiveAt': '最近活躍 {time}',
    'profileSaved': '資料已儲存',
    'saveProfileFailed': '儲存資料失敗：{error}',
    'fillTargetFirst': '請先填寫{target}',
    'codeSentWithLocal': '驗證碼已發送（本地驗證碼：{code}）',
    'sendCodeFailed': '發送驗證碼失敗：{error}',
    'fillAccountAndCode': '請填寫帳號和驗證碼',
    'accountBound': '帳號已綁定',
    'bindFailed': '綁定失敗：{error}',
    'enterOldPassword': '請輸入舊密碼',
    'enterNewPassword': '請輸入新密碼',
    'newPasswordsDoNotMatch': '兩次輸入的新密碼不一致',
    'passwordUpdated': '密碼已更新',
    'updatePasswordFailed': '更新密碼失敗：{error}',
    'accountSettingsHero': '把帳戶握在自己手裡',
    'basicProfile': '基礎資料',
    'accountBinding': '帳號綁定',
    'changePassword': '修改密碼',
    'saving': '儲存中...',
    'saveProfile': '儲存資料',
    'binding': '綁定中...',
    'confirmBind': '確認綁定',
    'updating': '更新中...',
    'updatePassword': '更新密碼',
    'hasPasswordHint': '目前帳號已有密碼，修改時需要校驗舊密碼。',
    'noPasswordHint': '目前帳號還沒有密碼，可以直接設定新密碼。',
    'dataExport': '資料匯出',
    'accountDeletion': '帳號刪除',
    'coolingOffDays': '{days} 天冷靜期',
    'createExportTask': '建立匯出任務',
    'loadMoreExportTasks': '載入更多匯出任務',
    'agreementTrace': '協議留痕',
    'confirmPrivacyPolicy': '確認隱私政策',
    'confirmUserAgreement': '確認使用者協議',
    'deviceManagement': '裝置管理',
    'deactivateThisDevice': '停用此裝置',
    'privacyPolicy': '隱私政策',
    'userAgreement': '使用者協議',
    'unknownAgreement': '未知協議',
    'unknownDevice': '未知裝置',
    'deleteTaskTitle': '刪除任務 #{id} · {status}',
    'cancelDeleteRequest': '撤銷刪除申請',
    'submitDeleteRequest': '提交刪除申請',
    'sendDeleteCode': '發送註銷驗證碼',
    'localCodeOnly': '本地驗證碼：{code}',
    'unknownStatus': '未知狀態',
    'deviceEnabled': '啟用',
    'deviceDisabled': '已停用',
    'deviceLoggedOut': '已登出',
    'publicProfile': '公開主頁',
    'publicProfileLoadFailed': '使用者主頁載入失敗：{error}',
    'sendDirectMessage': '發私信',
    'loginToFollowUser': '登入後可以追蹤這位使用者。',
    'publicProfileErrorUserNotFound': '這位使用者不存在',
    'publicProfileErrorSessionMissing': '目前登入狀態已失效，請重新登入後再試',
    'publicProfileErrorCannotFollowSelf': '你不能追蹤自己',
    'loadMoreUsersFailed': '載入更多使用者失敗：{error}',
    'relationListLoadFailed': '關係列表載入失敗：{error}',
    'followers': '粉絲',
    'followingUsers': '追蹤',
    'noRelationUsers': '暫無使用者',
    'userCollectionErrorSessionMissing': '目前登入狀態已失效，請重新登入後再試',
    'collectionLoadFailed': '載入失敗：{error}',
    'noCollectionData': '暫無資料',
    'favoritedAt': '收藏於 {time}',
    'postLabel': '貼文',
    'address': '地址',
    'shopDetail': '店家詳情',
    'shopDetailLoadFailed': '店家詳情載入失敗：{error}',
    'openingHours': '營業時間',
    'favoriteActionFailed': '收藏操作失敗：{error}',
    'shareCopied': '分享文案已複製',
    'viewAll': '查看全部',
    'shopReviewsLoadFailed': '店家評論載入失敗：{error}',
    'noPublicReviews': '暫無公開評論',
    'similarShopsLoadFailed': '相似店家載入失敗：{error}',
    'noSimilarShops': '暫無相似店家',
    'sortLatest': '最新',
    'sortHottest': '最熱',
    'sortBestRated': '好評優先',
    'minScoreFour': '4 分以上',
    'withPhotosOnly': '只看帶圖',
    'alreadyAtEnd': '已經到底了',
    'refreshBrowseHistoryFailed': '重新整理足跡失敗：{error}',
    'loadMoreBrowseHistoryFailed': '載入更多足跡失敗：{error}',
    'clearBrowseHistoryFailed': '清空足跡失敗：{error}',
    'deleteBrowseHistoryFailed': '刪除足跡失敗：{error}',
    'browseHistoryLoadFailed': '足跡載入失敗：{error}',
    'noBrowseHistory': '目前區域還沒有瀏覽足跡',
    'browseViewCount': '瀏覽 {count} 次',
    'deleteBrowseHistoryTooltip': '刪除足跡',
    'clearAll': '清空',
    'postSubmittedForAudit': '貼文已提交審核',
    'deletePost': '刪除貼文',
    'deletePostConfirm': '刪除後不可恢復，確認刪除這則貼文嗎？',
    'postDeleted': '貼文已刪除',
    'postEditorLoadFailed': '貼文編輯資料載入失敗：{error}',
    'publishToCircle': '發布到 {name}',
    'circlePostNeedsAudit': '內容仍需經過現有社群審核。',
    'titleLabel': '標題',
    'bodyLabel': '正文',
    'topicsCommaSeparated': '話題，用逗號分隔',
    'submitForAudit': '提交審核',
    'postDetail': '貼文詳情',
    'postLoadFailed': '貼文載入失敗：{error}',
    'reposted': '已轉發',
    'unreposted': '已取消轉發',
    'repostFailed': '轉發操作失敗：{error}',
    'reportPost': '檢舉貼文',
    'reportSubmitFailed': '檢舉提交失敗：{error}',
    'cancelReply': '取消回覆',
    'saySomethingUsefulShort': '說點有用的',
    'likeCountLabel': '按讚 {count}',
    'replyingToUser': '正在回覆 {name}',
    'simplifiedChinese': '简体中文',
    'traditionalChinese': '繁體中文',
    'englishLanguage': 'English',
    'noSignature': '暫未填寫簽名',
    'reviewsMetric': '評論',
    'noFollowers': '暫無粉絲',
    'noFollowing': '暫無追蹤',
    'levelFollowersMeta': 'Lv.{level} · 粉絲 {count}',
    'shopHash': '店家 #{id}',
    'postHash': '貼文 #{id}',
    'recordHash': '記錄 #{id}',
    'shopLabel': '店家',
    'unfavoritePost': '取消收藏',
    'favoritePost': '收藏貼文',
    'unrepostWithCount': '取消轉發 {count}',
    'repostWithCount': '轉發 {count}',
    'editPost': '編輯貼文',
    'publishPost': '發布貼文',
    'pleaseEnterTitle': '請輸入標題',
    'pleaseEnterBody': '請輸入正文',
    'postSaveFailed': '貼文儲存失敗：{error}',
    'unfavoriteShop': '取消收藏',
    'favoriteShop': '收藏店家',
    'favoriteStatusLoading': '收藏狀態載入中...',
    'sharing': '分享中...',
    'shareShop': '分享店家',
    'shopReviewsSection': '店家評論',
    'similarShopsSection': '相似店家',
    'retryReviews': '重試評論',
    'retryRecommendations': '重試推薦',
  };
  static const _english = {
    'homeTitle': 'Local life',
    'searchHint': 'Search restaurants, supermarkets and services',
    'featured': 'Featured near you',
    'profile': 'Me',
    'homeSubtitle': 'Chinese-friendly places nearby',
    'europe': 'Europe',
    'china': 'China',
    'language': 'Change language',
    'map': 'Map',
    'mapsConfigured': 'Google Maps is configured',
    'mapsUnavailable':
        'Google Maps is not configured. City and list browsing remain available.',
    'realPaymentUnavailable':
        'Real payment is not configured. The client will not fake a successful payment.',
    'pushUnavailable':
        'FCM/APNs is not configured. Notifications can still fall back to in-app messages.',
    'notifications': 'Notifications',
    'account': 'Profile',
    'cityRankings': 'City rankings',
    'activities': 'Activities',
    'placesLoadFailed': 'Could not load nearby places',
    'noPlaces': 'No places in this city yet',
    'homeNavigation': 'Home',
    'exploreNavigation': 'Explore',
    'ordersNavigation': 'Orders',
    'searchTitle': 'Search results',
    'searchSuggestionsLoading': 'Loading suggestions...',
    'searchSuggestions': 'Suggestions',
    'searchFailed': 'Search failed: {error}',
    'processing': 'Working...',
    'retry': 'Retry',
    'requestFailed': 'Request failed',
    'invalidApiResponse': 'The server returned invalid data',
    'unsupportedApiClientCapability':
        'This API client does not support {capability}',
    'noMatchingPlaces': 'No matching places',
    'loading': 'Loading...',
    'loadMore': 'Load more',
    'loadMoreShopsFailed': 'Could not load more places: {error}',
    'discoveryFailed': 'Could not load search discovery: {error}',
    'browseErrorShopNotFound': 'This place could not be found.',
    'browseErrorSearchHistoryNotFound':
        'This search history item could not be found.',
    'browseErrorInvalidShopId': 'The place id is invalid.',
    'browseErrorUnsupportedReviewSort':
        'This review sort option is unsupported.',
    'browseErrorUnsupportedFavoriteTarget':
        'This favorite target type is unsupported.',
    'enterKeyword': 'Enter a keyword to search',
    'recentSearches': 'Recent searches',
    'clearing': 'Clearing...',
    'clear': 'Clear',
    'moreHistory': 'More history',
    'hotSearches': 'Popular searches',
    'clearHistoryFailed': 'Could not clear search history: {error}',
    'removeHistoryFailed': 'Could not remove search history: {error}',
    'loadMoreHistoryFailed': 'Could not load more search history: {error}',
    'rankDetailTitle': 'Ranking details',
    'refreshRanksFailed': 'Could not refresh rankings: {error}',
    'ranksLoadFailed': 'Could not load rankings: {error}',
    'rankErrorNotFound': 'This ranking could not be found.',
    'rankErrorInvalidType': 'This ranking type is unsupported.',
    'noPublicRanks': 'No public rankings in this region yet',
    'rankTypeMustEat': 'Must-eat ranking',
    'rankTypeTopRated': 'Top-rated ranking',
    'rankTypeTrending': 'Trending ranking',
    'shopCount': '{count} places',
    'topShop': 'Top place: {name}',
    'rankDetailLoadFailed': 'Could not load ranking details: {error}',
    'rankNoShops': 'This ranking has no places yet',
    'activityDetailTitle': 'Activity details',
    'refreshActivitiesFailed': 'Could not refresh activities: {error}',
    'activitiesLoadFailed': 'Could not load activities: {error}',
    'noOnlineActivities': 'No live activities in this region yet',
    'activityChannelHome': 'Home',
    'activityChannelSearch': 'Search',
    'activityChannelChannel': 'Channel',
    'activityChannelPage': 'Activity page',
    'activityChannelCommunity': 'Community',
    'activityTypeThemed': 'Themed campaign',
    'activityTypeHoliday': 'Holiday campaign',
    'activityTypeNewCustomer': 'New customer campaign',
    'activityTypeMerchantSupport': 'Merchant support',
    'activityTypeContentTopic': 'Content topic',
    'resourceCount': '{count} resources',
    'activityDetailLoadFailed': 'Could not load activity details: {error}',
    'activityErrorNotFoundOrOffline':
        'This activity could not be found or is no longer online.',
    'activityNoItems': 'This activity has no resources yet',
    'cannotOpenExternalLink': 'Could not open the external link',
    'openTargetFailed': 'Could not open {target}: {error}',
    'targetShop': 'place',
    'targetDeal': 'deal',
    'targetPost': 'post',
    'targetRank': 'ranking',
    'targetTopic': 'topic',
    'targetExternalLink': 'external link',
    'targetResource': 'resource',
    'refreshNotificationsFailed': 'Could not refresh notifications: {error}',
    'loadMoreFailed': 'Could not load more: {error}',
    'markReadFailed': 'Could not mark as read: {error}',
    'allNotificationsMarkedRead': 'All notifications marked as read',
    'markAllReadFailed': 'Could not mark all as read: {error}',
    'markAllRead': 'Mark all read',
    'markAllReadWithCount': 'Mark all read ({count})',
    'filterAll': 'All',
    'filterUnreadOnly': 'Unread only',
    'notificationsLoadFailed': 'Could not load notifications: {error}',
    'notificationErrorUnavailable':
        'The notification service is temporarily unavailable.',
    'notificationErrorRefreshUnavailable':
        'Notifications could not be refreshed right now.',
    'reload': 'Reload',
    'refresh': 'Refresh',
    'noUnreadNotifications': 'No unread notifications',
    'noNotifications': 'No notifications yet',
    'continueFindUnread': 'Keep looking for unread',
    'unreadBadge': 'Unread',
    'notificationTitleSocialFollow': 'New follower',
    'notificationTitleDirectMessage': 'New direct message',
    'notificationTitleMention': 'You were mentioned',
    'notificationTitlePostApproved': 'Post approved',
    'notificationTitlePostRejected': 'Post rejected',
    'notificationTitleTopicUpdate': 'New topic update',
    'notificationTitleOrderPaid': 'Payment successful',
    'notificationTitleReservationConfirmed': 'Reservation auto-confirmed',
    'notificationTitleReservationSubmitted': 'Reservation submitted',
    'notificationTitleReservationReminderThirtyMinutes':
        'Reservation starts in 30 min',
    'notificationTitleReservationReminderTwoHours':
        'Reservation reminder (2 hours)',
    'notificationTitleCouponReminder': 'Coupon reminder',
    'notificationTitleCouponExpired': 'Coupon expired',
    'notificationTitleCouponVerified': 'Coupon redeemed',
    'notificationTitleMerchantReply': 'Merchant reply',
    'notificationFollowedYou': '{name} followed you',
    'notificationDirectMessagePreview': '{name}: {preview}',
    'notificationPostApprovedContent': '"{title}" is now public',
    'notificationPostRejectedContent': '"{title}" was rejected',
    'notificationOrderNumber': 'Order {orderNo}',
    'notificationCouponsReady': 'Coupons are ready in My coupons',
    'notificationReservationAutoConfirmedAction':
        'Your reservation was automatically confirmed',
    'notificationReservationSubmittedAction':
        'Submitted and waiting for merchant confirmation',
    'notificationCouponCodeLabel': 'Coupon {code}',
    'notificationCouponExpiringInDays': '{code} expires in {days} days',
    'notificationCouponRedeemedAt': '{code} was redeemed at {shop}',
    'notificationCouponRedeemed': 'Redeemed',
    'notificationExpertApprovedContent':
        'Your local expert certification was approved',
    'notificationExpertRejectedContent':
        'Your local expert certification was rejected. Review the reason and resubmit.',
    'notificationTitleRefundApproved': 'Refund approved',
    'notificationTitleRefundRejected': 'Refund rejected',
    'notificationTitleReservationMerchantConfirmed': 'Reservation confirmed',
    'notificationTitleReservationArrived': 'Arrival confirmed',
    'notificationTitleReservationRejected': 'Reservation rejected',
    'notificationTitleReservationNoShow': 'Reservation marked no-show',
    'notificationTitleReviewApproved': 'Review approved',
    'notificationTitleReviewRejected': 'Review rejected',
    'notificationTitleReviewHidden': 'Review hidden',
    'notificationTitleBanAppealApproved': 'Ban appeal approved',
    'notificationTitleBanAppealRejected': 'Ban appeal rejected',
    'notificationTitleAccountUnbanned': 'Account unbanned',
    'notificationActorPlatform': 'Platform',
    'notificationActorMerchant': 'Merchant',
    'notificationRefundApprovedAction': '{actor} approved your refund',
    'notificationRefundRejectedAction': '{actor} rejected your refund',
    'notificationReservationMerchantConfirmedAction':
        'The merchant confirmed your reservation',
    'notificationReservationArrivedAction':
        'The merchant confirmed your arrival',
    'notificationReservationMerchantRejectedAction':
        'The merchant rejected your reservation',
    'notificationReservationMarkedNoShowAction':
        'The merchant marked this reservation as no-show',
    'notificationReviewApprovedContent': '{shop} · Your review is now public',
    'notificationReviewRejectedContent': '{shop} · Your review was rejected',
    'notificationReviewHiddenContent':
        '{shop} · The merchant appeal was approved and your review was hidden from public view',
    'notificationTitleReviewLike': 'Review liked',
    'notificationTitleReviewComment': 'New review comment',
    'notificationTitleCommentReply': 'Comment reply',
    'notificationTitlePostLike': 'Post liked',
    'notificationTitlePostComment': 'New post comment',
    'notificationTitlePostRepost': 'Post reposted',
    'notificationLikedYourReview': '{name} liked your review: {preview}',
    'notificationCommentedOnYourReview':
        '{name} commented on your review: {preview}',
    'notificationRepliedToYou': '{name} replied to you: {preview}',
    'notificationLikedYourPost': '{name} liked your post "{title}"',
    'notificationCommentedOnYourPost':
        '{name} commented on your post: {preview}',
    'notificationRepostedYourPost': '{name} reposted your post "{title}"',
    'notificationMentionedYouInPost':
        '{name} mentioned you in the post "{title}"',
    'notificationMentionedYouInPostComment':
        '{name} mentioned you in a comment on "{title}"',
    'notificationTopicUpdateContent': '{name} posted "{title}" in #{topic}',
    'notificationBanAppealApprovedContent':
        'Your ban appeal was approved. Your account has been unbanned and you can sign in again.',
    'notificationBanAppealRejectedContent': 'Your ban appeal was rejected',
    'notificationAccountUnbannedContent':
        'An admin removed your account ban. The related appeal was auto-approved and you can sign in again.',
    'loggingOut': 'Signing out...',
    'logout': 'Sign out',
    'profileLoadFailed': 'Could not load profile: {error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} points',
    'growthValueLabel': '{value} growth',
    'accountSettings': 'Account settings',
    'accountSettingsSubtitle': 'Profile, linked accounts, password',
    'localExpertCertification': 'Local expert certification',
    'localExpertCertificationSubtitle':
        'Submit or resubmit a local expert application',
    'growthRecords': 'Growth history',
    'growthRecordsSubtitle': 'Lv.{level} · growth {growth} · points {points}',
    'myMessages': 'Messages',
    'blockedUsers': 'Blocked users',
    'myCircles': 'My circles',
    'myReviews': 'My reviews',
    'myPosts': 'My posts',
    'myFavorites': 'Favorites',
    'myOrders': 'Orders',
    'myCoupons': 'Coupons',
    'myReservations': 'Reservations',
    'myBrowseHistory': 'Browse history',
    'privacyCenter': 'Privacy center',
    'communityTitle': 'Community',
    'topicPlaza': 'Topics',
    'localCircles': 'Local circles',
    'recommendedTab': 'For you',
    'followingTab': 'Following',
    'createPost': 'Post',
    'followingFeedLoginRequired':
        'Sign in to see your following feed. Updates from people you follow will appear here.',
    'loadMorePostsFailed': 'Could not load more posts: {error}',
    'communityLoadFailed': 'Could not load community: {error}',
    'noCommunityPosts': 'No posts yet',
    'postMetaStats': ' · ❤ {likes} · comments {comments}',
    'hotTab': 'Trending',
    'followingTopicsTab': 'Following',
    'loadMoreTopicsFailed': 'Could not load more topics: {error}',
    'topicsLoadFailed': 'Could not load topics: {error}',
    'followingTopicsLoginRequired':
        'Sign in to see followed topics. This does not create a separate feed.',
    'goLogin': 'Sign in',
    'hotScore': 'Heat {score}',
    'topicSevenDayStats':
        '7 days: {posts} posts · {likes} likes · {comments} comments',
    'topicFollowMeta': '{followers} followers · {posts} public posts',
    'topicFollowerCount': '{count} followers',
    'topicErrorNotFound': 'This topic could not be found.',
    'topicErrorUnavailable': 'This topic is unavailable.',
    'topicErrorFollowFailed': 'The follow request could not be completed.',
    'followStatusUpdateFailed': 'Could not update follow status: {error}',
    'followed': 'Following',
    'followTopic': 'Follow topic',
    'publicPosts': 'Public posts',
    'postsLoadFailed': 'Could not load posts: {error}',
    'noPublicPostsHere': 'No public posts here yet.',
    'communityErrorPostNotFound': 'This post could not be found.',
    'communityErrorReportDuplicate':
        'You already reported this post. Do not submit it again.',
    'communityErrorReplyTargetMissing':
        'The comment you are replying to could not be found.',
    'communityErrorJoinCircleToPost': 'Join the circle before posting.',
    'loadMoreCirclesFailed': 'Could not load more circles: {error}',
    'circlesLoadFailed': 'Could not load circles: {error}',
    'circleErrorJoinedOnlyLoginRequired':
        'Sign in to see the circles you joined.',
    'circleErrorNotFound': 'This circle could not be found.',
    'circleMeta': '{members} members · {posts} posts',
    'circleStatusUpdateFailed': 'Could not update circle status: {error}',
    'joined': 'Joined',
    'joinCircle': 'Join circle',
    'viewMembers': 'View members',
    'postInCircle': 'Post in circle',
    'joinCircleToPost':
        'Join the circle to publish. Existing posts stay publicly visible.',
    'circleNewPosts': 'New circle posts',
    'loadMoreMembersFailed': 'Could not load more members: {error}',
    'circleMembersTitle': '{name} members',
    'membersLoadFailed': 'Could not load members: {error}',
    'directMessages': 'Messages',
    'directMessageUser': 'Message user',
    'messageErrorUserNotFound': 'This user could not be found.',
    'messageErrorConversationMissing': 'This conversation could not be found.',
    'messageErrorCannotMessageSelf':
        'You cannot send direct messages to yourself.',
    'messageErrorBlockedRelationship':
        'You cannot send a direct message while a block relationship exists.',
    'messageErrorCannotBlockSelf': 'You cannot block yourself.',
    'messageErrorReportTargetUnavailable':
        'This report target is unavailable or you do not have access.',
    'messageErrorReportDuplicate':
        'You already reported this target. Do not submit it again.',
    'refreshConversationsFailed': 'Could not refresh conversations: {error}',
    'loadMoreConversationsFailed': 'Could not load more conversations: {error}',
    'conversationsLoadFailed': 'Could not load conversations: {error}',
    'noDirectMessages': 'No messages yet. Say hello from a public profile.',
    'messageMarkReadFailed': 'Could not sync read status: {error}',
    'loadEarlierMessagesFailed': 'Could not load earlier messages: {error}',
    'sendFailed': 'Could not send: {error}',
    'actionFailed': 'Could not complete the action: {error}',
    'reportConversation': 'Report conversation',
    'blockUser': 'Block user',
    'unblockUser': 'Unblock',
    'reportSubmitted': 'Report submitted',
    'blockedBothWays': 'Blocked. Neither side can send messages.',
    'unblocked': 'Unblocked',
    'chatHistoryLoadFailed': 'Could not load chat history: {error}',
    'loadEarlierMessages': 'Load earlier messages',
    'blockedComposerHint': 'Blocked. Unblock to keep chatting.',
    'messageHint': 'Write a message…',
    'send': 'Send',
    'harassmentOrInappropriate': 'Harassment or inappropriate content',
    'refreshBlockedUsersFailed': 'Could not refresh blocked users: {error}',
    'loadMoreBlockedUsersFailed': 'Could not load more blocked users: {error}',
    'unblockedUser': 'Unblocked {name}',
    'unblockFailed': 'Could not unblock: {error}',
    'blockedUsersLoadFailed': 'Could not load blocked users: {error}',
    'blockedUsersEmpty': 'No blocked users',
    'blockedAt': 'Blocked at: {time}',
    'userFallback': 'User {id}',
    'anonymousPeer': 'Someone',
    'payPending': 'Unpaid',
    'payPaid': 'Paid',
    'payRefunded': 'Refunded',
    'payPartialRefund': 'Partially refunded',
    'couponPending': 'Available',
    'couponUsed': 'Used',
    'couponExpired': 'Expired',
    'couponRefunded': 'Refunded',
    'loadMoreOrdersFailed': 'Could not load more orders: {error}',
    'ordersLoadFailed': 'Could not load orders: {error}',
    'noOrdersForFilter': 'No orders for this filter',
    'loadMoreCouponsFailed': 'Could not load more coupons: {error}',
    'couponsLoadFailed': 'Could not load coupons: {error}',
    'noCouponsForFilter': 'No coupons for this filter',
    'couponHighlight': 'Locate coupon {code}',
    'groupDeals': 'Group deals',
    'dealsLoadFailed': 'Could not load deals: {error}',
    'noDealsForShop': 'No deals for this place yet',
    'soldCount': 'Sold {count}',
    'stockCount': 'Stock {count}',
    'buy': 'Buy',
    'tradeErrorDealNotFound': 'This deal could not be found.',
    'tradeErrorDealExpired': 'This deal has expired.',
    'tradeErrorDealOutOfStock': 'This deal is sold out.',
    'tradeErrorOrderNotFound': 'This order could not be found.',
    'tradeErrorOrderPaymentUnavailable': 'This order cannot be paid right now.',
    'tradeErrorOrderCancelUnavailable':
        'This order cannot be canceled right now.',
    'tradeErrorOrderRefundUnavailable':
        'This order cannot be refunded right now.',
    'tradeErrorRefundUsedCoupons':
        'This order includes redeemed coupons, so a full refund is unavailable.',
    'tradeErrorRefundExists': 'A refund request already exists for this order.',
    'tradeErrorCouponCodeRequired': 'Enter a coupon code.',
    'tradeErrorCouponNotFound': 'This coupon could not be found.',
    'tradeErrorPaymentChannelUnavailable':
        'Payment services are not configured yet.',
    'createOrderFailed': 'Could not create order: {error}',
    'orderCreatedOpenDetailFailed':
        'Order {orderNo} was created, but opening details failed: {error}',
    'dealDetail': 'Deal details',
    'dealDetailLoadFailed': 'Could not load deal details: {error}',
    'soldAndStock': 'Sold {sold} · stock {stock}',
    'validUntil': 'Valid {range}',
    'noPackageItems': 'No package items yet',
    'quantityLabel': 'Qty {count}',
    'orderDetail': 'Order details',
    'cancelOrder': 'Cancel order',
    'cancelOrderConfirm': 'Canceling releases inventory. Continue?',
    'keepOrder': 'Keep order',
    'confirmCancel': 'Confirm cancel',
    'applyRefund': 'Request refund',
    'submitApplication': 'Submit',
    'cancelAction': 'Cancel',
    'orderLoadFailedTapRetry': 'Could not load order. Tap to retry',
    'orderShopMeta': '{shop} · order {orderNo}',
    'startPayment': 'Pay now',
    'refundLabel': 'Refund: {status}',
    'couponCopied': 'Coupon code copied',
    'couponDetail': 'Coupon details',
    'couponDetailLoadFailed': 'Could not load coupon details: {error}',
    'qrLoadFailed': 'Could not load QR code',
    'verifiedAt': 'Verified at {time}',
    'showCodeToMerchant': 'Show this code to the merchant',
    'priceSoldMeta': '{price} · sold {count}',
    'usageRules': 'Usage rules',
    'packageContents': 'Package contents',
    'quantitySimple': 'Quantity',
    'unitPrice': 'Unit price',
    'paidAmount': 'Paid',
    'orderCanceled': 'Order canceled',
    'refundReason': 'Refund reason',
    'refundSubmitted': 'Refund request submitted',
    'refundStatusPending': 'Pending review',
    'refundStatusApproved': 'Refunded',
    'refundStatusRejected': 'Rejected',
    'defaultRefundReason': 'Plans changed',
    'paymentRequestCreated':
        'Created a {channel} payment request. Finish payment in the channel.',
    'paymentStartFailed': 'Could not start payment: {error}',
    'relatedCoupons': 'Linked coupons',
    'redeemable': 'Redeemable',
    'notRedeemable': 'Not redeemable',
    'copying': 'Copying...',
    'copyCouponCode': 'Copy code',
    'validUntilDate': 'Valid until {date}',
    'noExpiry': 'No expiry',
    'dealValidityRange': 'Deal validity {start} ~ {end}',
    'noExtraRules': 'No extra rules',
    'defaultVerifyHint':
        'Merchants redeem this code. Self-service redemption is disabled on the user side.',
    'detailRefreshFailed': 'Could not refresh details: {error}',
    'reloadFullDetail': 'Reload full details',
    'reservationPending': 'Pending',
    'reservationConfirmed': 'Confirmed',
    'reservationArrived': 'Arrived',
    'reservationUserCanceled': 'Canceled by user',
    'reservationMerchantRejected': 'Rejected by merchant',
    'reservationNoShow': 'No-show',
    'reservationConfirmModeAuto': 'Auto confirm',
    'reservationConfirmModeManual': 'Manual confirm',
    'reservationActionCreated': 'Created reservation',
    'reservationActionMerchantConfirmed': 'Merchant confirmed',
    'reservationActionMerchantRejected': 'Merchant rejected',
    'reservationActionUserCanceled': 'Canceled by user',
    'reservationActionUserRescheduled': 'Rescheduled by user',
    'reservationActionMerchantRescheduled': 'Rescheduled by merchant',
    'reservationActionCheckedIn': 'Checked in',
    'reservationActionMarkedNoShow': 'Marked no-show',
    'reservationActionArrivalReminder': 'Arrival reminder',
    'loadMoreReservationsFailed': 'Could not load more reservations: {error}',
    'reservationsLoadFailed': 'Could not load reservations: {error}',
    'noReservationsForFilter': 'No reservations for this filter',
    'reservationListMeta': '{no}\n{time} · {people} guests · {status}',
    'onlineReservation': 'Book online',
    'selectSlotFirst': 'Please select a time slot',
    'reservationCreated': 'Reservation {no} created: {status}',
    'reservationFailed': 'Could not create reservation: {error}',
    'reservationErrorInvalidPeopleCount': 'Guest count must be at least 1.',
    'reservationErrorSlotOrTimeRequired': 'Select a reservation slot first.',
    'reservationErrorSlotCapacityUnavailable':
        'This time slot no longer has enough availability.',
    'reservationErrorCancelDeadlinePassed':
        'The cancellation window has passed.',
    'reservationErrorCancelUnavailable':
        'This reservation cannot be canceled right now.',
    'reservationErrorRescheduleSlotCapacityUnavailable':
        'The new time slot no longer has enough availability.',
    'reservationErrorRescheduleUnavailable':
        'This reservation cannot be rescheduled right now.',
    'reservationErrorSlotNotFound': 'This reservation slot could not be found.',
    'reservationErrorNotFound': 'This reservation could not be found.',
    'dateLabel': 'Date {date}',
    'peopleCount': '{count} guests',
    'slotsLoadFailed': 'Could not load time slots: {error}',
    'slotRemaining': '{start}-{end} · {count} left',
    'contactName': 'Contact name',
    'contactPhone': 'Contact phone',
    'remark': 'Notes',
    'submitting': 'Submitting...',
    'submitReservation': 'Submit reservation',
    'reservationDetail': 'Reservation details',
    'reservationLoadFailedTapRetry': 'Could not load reservation. Tap to retry',
    'cancelReservation': 'Cancel reservation',
    'cancelReservationConfirm':
        'Cancellation cutoffs follow shop rules. Continue?',
    'keepReservation': 'Keep reservation',
    'reservationCanceled': 'Reservation canceled',
    'findRescheduleSlots': 'Find new slots',
    'confirmReschedule': 'Confirm reschedule',
    'reservationRescheduled': 'Reservation rescheduled',
    'rescheduleReason': 'Rescheduled by user',
    'reservationTimePeople': '{time} · {people} guests',
    'rescheduleSlotMeta': '{start} · {mode} · {count} left',
    'changeTimeline': 'Change timeline',
    'noChangeRecords': 'No change records yet',
    'liked': 'Liked',
    'like': 'Like',
    'unliked': 'Like removed',
    'likeFailed': 'Could not like: {error}',
    'commentPublished': 'Comment published',
    'commentFailed': 'Could not comment: {error}',
    'loadMoreCommentsFailed': 'Could not load more comments: {error}',
    'reportReview': 'Report review',
    'reportReason': 'Report reason',
    'submitReport': 'Submit report',
    'reportFailed': 'Could not report: {error}',
    'deleteReview': 'Delete review',
    'deleteReviewConfirm': 'This cannot be undone. Delete this review?',
    'confirmDelete': 'Delete',
    'reviewDeleted': 'Review deleted',
    'deleteFailed': 'Could not delete: {error}',
    'reply': 'Reply',
    'myReviewDetail': 'My review details',
    'reviewDetail': 'Review details',
    'edit': 'Edit',
    'deleting': 'Deleting...',
    'delete': 'Delete',
    'reviewDetailLoadFailed': 'Could not load review details: {error}',
    'reviewErrorNotFound': 'This review could not be found.',
    'reviewErrorReportDuplicate':
        'You already reported this review. Do not submit it again.',
    'reviewErrorReplyTargetMissing':
        'The comment you are replying to could not be found.',
    'reviewErrorUserUnavailable': 'Your account is currently unavailable.',
    'reviewErrorShopUnavailable': 'This place is unavailable for reviews.',
    'reviewErrorShopImmutable': 'The place for this review cannot be changed.',
    'auditRemarkLabel': 'Audit note: {remark}',
    'merchantReplyLabel': 'Merchant reply: {reply}',
    'anonymousUser': 'Anonymous user',
    'report': 'Report',
    'reviewLoginToInteract': 'Sign in to like, comment, or report this review.',
    'commentsSection': 'Comments',
    'replyingTo': 'Replying to @{name}',
    'writeComment': 'Write a comment',
    'publishing': 'Publishing...',
    'publishComment': 'Post comment',
    'commentsLoadFailed': 'Could not load comments: {error}',
    'retryComments': 'Retry comments',
    'noComments': 'No comments yet',
    'writeReview': 'Write a review',
    'editReview': 'Edit review',
    'reviewLoadFailedTapRetry': 'Could not load review. Tap to retry',
    'reviewContentHint': 'Share your real experience…',
    'uploadedCount': 'Uploaded {count}/9',
    'uploading': 'Uploading…',
    'addImages': 'Add photos',
    'spendAmount': 'Spend amount',
    'tagsLabel': 'Tags (up to 10)',
    'tagsHint': 'Chinese service, good for groups, great value',
    'saveAndResubmit': 'Save and resubmit for review',
    'publishReview': 'Publish review',
    'reviewingShop': 'Reviewing',
    'scoreOverall': 'Overall',
    'scoreTaste': 'Taste',
    'scoreEnv': 'Environment',
    'scoreService': 'Service',
    'averageSpendLabel': 'Avg spend {amount}',
    'replyToPreview': 'Reply to {name}: {content}',
    'likeCommentStats': '{likes} likes · {comments} comments',
    'loadMoreComments': 'Load more comments',
    'maxNineImages': 'Up to 9 photos',
    'imagePickFailed': 'Could not pick image: {error}',
    'imageUploadFailed': 'Could not upload image: {error}',
    'reviewUpdatedResubmitted': 'Review updated and resubmitted for audit',
    'reviewSubmittedPending': 'Review submitted and pending audit',
    'saveFailed': 'Could not save: {error}',
    'ratingPrompt': 'How many stars for this visit?',
    'ratingHint': 'Drag to rate — be fair, not harsh.',
    'saySomethingUseful': 'Say something useful',
    'reviewWritingHint':
        'Taste, service, queues and tips beat a vague “pretty good”.',
    'pleaseWriteRealExperience': 'Please write a real experience',
    'onSitePhotos': 'Photos from the visit',
    'photosUploadHint': 'Up to 9 photos. Upload starts after you pick them.',
    'spendAndTags': 'Spend and tags',
    'spendTagsHint': 'Amount helps average spend. Separate tags with commas.',
    'enterNonNegativeAmount': 'Enter an amount of 0 or more',
    'loginTitle': 'Sign in to Dianping',
    'loginHero': 'Chinese local life in Europe',
    'loginSubtitle': 'Sign in with email or phone. No third-party login maze.',
    'passwordLogin': 'Password',
    'codeLogin': 'Code',
    'emailOrPhone': 'Email or phone',
    'password': 'Password',
    'verificationCode': 'Verification code',
    'sendingCode': 'Sending...',
    'sendCode': 'Send code',
    'enterEmailOrPhone': 'Enter email or phone',
    'enterEmailOrPhoneFirst': 'Enter email or phone first',
    'codeSent': 'Code sent',
    'localCodeHint': 'Local code: {code}',
    'accountBannedHint':
        'Account {account} is banned. If this looks wrong, submit an appeal. Approval auto-unbans you.',
    'submitBanAppeal': 'Submit ban appeal',
    'loginSuccess': 'Signed in',
    'loggingIn': 'Signing in...',
    'login': 'Sign in',
    'registerAccount': 'Create account',
    'passwordResetPleaseLogin':
        'Password reset. Sign in with the new password.',
    'forgotPassword': 'Forgot password',
    'banAppeal': 'Ban appeal',
    'registerTitle': 'Create account',
    'registerSubtitle':
        'Register with email or phone. The code is only for this registration.',
    'nicknameOptional': 'Nickname (optional)',
    'registerCode': 'Registration code',
    'setPassword': 'Set password',
    'registering': 'Creating...',
    'registerAndLogin': 'Register and sign in',
    'resetPasswordTitle': 'Reset password',
    'resetPasswordSubtitle':
        'Verify your bound email or phone, then return to sign in.',
    'resetCode': 'Reset code',
    'newPassword': 'New password',
    'confirmNewPassword': 'Confirm new password',
    'resetting': 'Resetting...',
    'resetPassword': 'Reset password',
    'banAppealTitle': 'Ban appeal',
    'banAppealHero': 'Self-service appeal after a ban',
    'banAppealSubtitle':
        'Verify with your bound email or phone. Approval auto-unbans you so you can sign in again.',
    'appealCode': 'Appeal code',
    'appealReasonMin10': 'Appeal reason (at least 10 characters)',
    'banReasonLabel': 'Ban reason: {value}',
    'appealContentLabel': 'Appeal: {value}',
    'rejectReasonLabel': 'Rejection note: {value}',
    'submittedAtLabel': 'Submitted: {value}',
    'processedAtLabel': 'Processed: {value}',
    'submittingAppeal': 'Submitting...',
    'submitAppeal': 'Submit appeal',
    'querying': 'Checking...',
    'queryAppealProgress': 'Check appeal status',
    'backToLogin': 'Back to sign in',
    'codeSentRetry': 'Code sent. Retry in {seconds}s',
    'fillAccountCodePassword': 'Account, code and password are required',
    'fillAccountCodeNewPassword': 'Account, code and new password are required',
    'passwordsDoNotMatch': 'New passwords do not match',
    'authErrorInvalidCredentials':
        'The account or password is incorrect. Check them and try again.',
    'authErrorAccountBanned':
        'This account is currently banned and cannot sign in.',
    'authErrorAccountRegistered':
        'This account is already registered. Sign in or reset the password instead.',
    'authErrorAccountNotFound':
        'We could not find this account. Check the email or phone number and try again.',
    'authErrorCodeInvalid':
        'The verification code is invalid or expired. Request a new one and try again.',
    'authErrorInvalidEmail':
        'The email format looks invalid. Check it and try again.',
    'authErrorInvalidPhone':
        'The phone number format looks invalid. Check it and try again.',
    'authErrorCodeRateLimited':
        'Verification codes are being sent too often. Wait a bit and try again.',
    'authErrorCodeSendUnavailable':
        'Code sending is not available right now. Try again later.',
    'authErrorCodeVerifyUnavailable':
        'Code verification is not available right now. Try again later.',
    'authErrorEmailAlreadyBound':
        'This email is already bound to another account.',
    'authErrorPhoneAlreadyBound':
        'This phone number is already bound to another account.',
    'authErrorOldPasswordIncorrect': 'The current password is incorrect.',
    'authErrorSamePasswordAsOld':
        'The new password must be different from the current password.',
    'authErrorCurrentUserNotFound':
        'Your account could not be found. Please sign in again.',
    'authErrorSessionMissing':
        'Your sign-in session is no longer available. Please sign in again.',
    'authErrorProfileNicknameTooLong':
        'Nickname must be 64 characters or fewer.',
    'authErrorProfileAvatarTooLong':
        'Avatar URL must be 255 characters or fewer.',
    'authErrorProfileSignatureTooLong': 'Bio must be 255 characters or fewer.',
    'authErrorProfileUpdateFailed':
        'The profile could not be updated. Try again later.',
    'registerHero': 'Join Chinese local life in Europe',
    'resetPasswordHero': 'Set a new sign-in password',
    'fillAccountAndCodeBeforeAppeal': 'Fill account and code before submitting',
    'appealReasonTooShort':
        'Write at least 10 characters explaining the mistaken ban',
    'appealSubmitted': 'Appeal #{id} submitted. Ops will review soon',
    'queryNeedsAccountAndCode':
        'Progress checks also need account and a fresh code',
    'appealProgressRefreshed': 'Refreshed progress for appeal #{id}',
    'appealStatusTitle': 'Appeal #{id} · {status}',
    'appealApprovedHint':
        'Appeal approved and account unbanned. Return to sign in.',
    'banAppealErrorAccountNotFound':
        'We could not find this account. Check the email or phone number and try again.',
    'banAppealErrorAccountNotBanned':
        'This account is not currently banned, so no appeal is needed.',
    'banAppealErrorPendingExists':
        'You already have an appeal under review. Wait for the result before submitting another.',
    'banAppealErrorNoRecord':
        'No appeal record was found for this account yet.',
    'banAppealErrorStatusChanged':
        'The appeal status changed just now. Refresh and try again.',
    'banAppealErrorCodeInvalid':
        'The verification code is invalid or expired. Request a new one and try again.',
    'banAppealErrorInvalidEmail':
        'The email format looks invalid. Check it and try again.',
    'banAppealErrorInvalidPhone':
        'The phone number format looks invalid. Check it and try again.',
    'privacySubtitle':
        'Exports leave with you. Deletion has a cooling-off period. Rules and task status stay explicit.',
    'privacyLoadFailed': 'Could not load privacy data: {error}',
    'exportModuleAccount': 'Account data',
    'exportModuleReviews': 'Review data',
    'exportModuleOrders': 'Order data',
    'exportModulePosts': 'Post data',
    'exportModuleReservations': 'Reservation data',
    'exportModuleFavorites': 'Favorites',
    'exportModuleFollows': 'Follow graph',
    'exportModuleMessages': 'Message data',
    'exportModuleCircles': 'Circle memberships',
    'exportModuleTopics': 'Topic follows',
    'privacyExportHint':
        'Posts, follows, messages, circles and topic follows support real exports.',
    'noExportTasks': 'No export tasks yet',
    'agreementRecordsHint':
        'We keep the terms and privacy versions you accepted, so records stay clear later.',
    'noAgreementRecords': 'No agreement records yet.',
    'deviceLifecycleHint':
        'Signed-in devices keep lifecycle records. Unconfigured push is never faked as FCM/APNs.',
    'noRegisteredDevices': 'No registered devices yet.',
    'loadMoreExportTasksFailed': 'Could not load more export tasks: {error}',
    'agreementRecorded': 'Agreement acceptance recorded',
    'agreementRecordFailed': 'Could not record agreement: {error}',
    'deviceDeactivated': 'Device deactivated and push token cleared',
    'deviceDeactivateFailed': 'Could not deactivate device: {error}',
    'exportSaved': 'Export saved: {path}',
    'exportDownloadFailed': 'Could not download export: {error}',
    'selectExportModule': 'Select at least one export module',
    'exportTaskCreated': 'Export task created. Download when ready',
    'createExportFailed': 'Could not create export task: {error}',
    'deleteRequestCanceled': 'Delete request canceled. Account stays active',
    'cancelDeleteFailed': 'Could not cancel delete request: {error}',
    'privacyErrorExportLimitReached':
        'Today\'s privacy export quota is already used up. Try again tomorrow.',
    'privacyErrorExportUnavailable':
        'This export file is not available for download yet. Try again later.',
    'privacyErrorExportMissing':
        'This export file no longer exists. Create a new export task.',
    'privacyErrorDeleteTaskPending':
        'You already have a delete request in progress. Finish the current one first.',
    'privacyErrorDeleteTaskCannotCancel':
        'This delete request can no longer be canceled. Refresh the status and try again.',
    'privacyErrorDeleteTaskCancelFailed':
        'The delete request could not be canceled. Try again later.',
    'privacyErrorDeleteTaskMissing':
        'This delete request no longer exists. Refresh the page.',
    'fillAccountAndDeleteReason':
        'Bound account and delete reason are required',
    'codeNotFilled': 'Verification code is missing',
    'passwordNotFilled': 'Login password is missing',
    'deleteEnteredCoolingOff':
        'Delete request is in cooling-off and can be canceled before it ends',
    'submitDeleteFailed': 'Could not submit delete request: {error}',
    'fillBoundAccountFirst': 'Enter your currently bound account first',
    'sendDeleteCodeFailed': 'Could not send deletion code: {error}',
    'privacyDeleteErrorBoundAccountOnly':
        'Use a currently bound email or phone number to verify account deletion.',
    'privacyDeleteErrorNoPassword':
        'This account does not have a login password available for verification. Use code verification instead.',
    'privacyDeleteErrorWrongPassword':
        'The current login password is incorrect.',
    'createdAtLabel': 'Created {time}',
    'expiresAtLabel': 'Expires {time}',
    'reasonLabel': 'Reason: {value}',
    'coolingOffDeadline': 'Cooling-off ends: {value}',
    'verifyByCode': 'Verify with code',
    'verifyByPassword': 'Verify with password',
    'boundAccount': 'Currently bound account',
    'deleteVerificationCode': 'Deletion code',
    'currentLoginPassword': 'Current login password',
    'deleteReason': 'Delete reason',
    'coolingOffIntro':
        'Submission starts a {days}-day cooling-off period and can be canceled before it ends.',
    'accountSettingsSubtitleLong':
        'Profile, bindings and password all hit real backend validation — no fake controls.',
    'accountProfileLoadFailed': 'Could not load account profile: {error}',
    'nickname': 'Nickname',
    'avatarUrl': 'Avatar URL',
    'gender': 'Gender',
    'genderUnknown': 'Unknown',
    'genderMale': 'Male',
    'genderFemale': 'Female',
    'signature': 'Bio',
    'emailLabel': 'Email: {value}',
    'phoneLabel': 'Phone: {value}',
    'unbound': 'Not bound',
    'email': 'Email',
    'phone': 'Phone',
    'bindVerificationCode': 'Binding code',
    'oldPassword': 'Current password',
    'expertApplicationSubmitted': 'Local expert application submitted',
    'expertStatusLoadFailed': 'Could not load certification status: {error}',
    'reviewedAtLabel': 'Reviewed: {value}',
    'effectiveStartLabel': 'Effective from: {value}',
    'effectiveEndLabel': 'Effective until: {value}',
    'expertReasonHint':
        'Describe your local content work, exploration experience or ongoing plans',
    'expertPendingHint': 'Application is under review. Please wait.',
    'expertApprovedHint':
        'You are a local expert. Public content can show the expert badge.',
    'expertStatusNotApplied': 'Not applied',
    'expertStatusPendingReview': 'Pending review',
    'expertStatusApproved': 'Approved',
    'expertStatusRejected': 'Rejected',
    'expertReasonRequired': 'Please enter an application reason',
    'expertReasonTooLong': 'Application reason cannot exceed 500 characters',
    'expertErrorPendingExists':
        'You already have a local expert application under review. Wait for the current result first.',
    'expertErrorAlreadyApproved':
        'You are already a certified local expert. No need to apply again.',
    'localExpertBadge': 'Local expert',
    'verifiedMerchantBadge': 'Verified merchant',
    'applicationReason': 'Application reason',
    'expertCertificationApprovedNotice': 'Local expert certification approved',
    'expertCertificationRejectedNotice':
        'Local expert certification rejected. Review the reason and resubmit.',
    'expertCertificationUpdatedNotice':
        'Local expert certification status updated',
    'growthRecordsErrorSessionMissing':
        'Your sign-in session is no longer available. Please sign in again.',
    'growthRecordsLoadFailed': 'Could not load growth history: {error}',
    'noGrowthRecords': 'No growth or points history yet',
    'refreshGrowthRecordsFailed': 'Could not refresh growth history: {error}',
    'growthTypeValue': 'Growth value',
    'growthTypePoints': 'Points',
    'growthActionReviewCreate': 'Review published',
    'growthActionReviewLiked': 'Review liked',
    'growthActionReviewImage': 'Photo review',
    'growthActionOrderComplete': 'Order completed',
    'growthRewardReviewCreate': 'Review publishing reward',
    'growthRewardReviewLiked': 'Review like reward',
    'growthRewardReviewImage': 'Photo review reward',
    'growthRewardOrderComplete': 'Order completion reward',
    'balanceAfterLabel': 'Balance {value}',
    'privacyHero': 'Your data, your call',
    'exportDailyLimit': 'Up to {count} times per day',
    'exportFileRetention': 'Files kept for {hours} hours',
    'canCancelBeforeDeadline': 'You can cancel before the deadline',
    'creatingExport': 'Creating...',
    'recordingAcceptance': 'Recording...',
    'deactivatingDevice': 'Deactivating...',
    'exportTaskTitle': 'Task #{id}',
    'downloadZip': 'Download ZIP',
    'downloadingZip': 'Downloading...',
    'exportStatusPending': 'Pending',
    'exportStatusProcessing': 'Processing',
    'exportStatusReady': 'Ready to download',
    'exportStatusExpired': 'Expired',
    'exportStatusFailed': 'Failed',
    'exportStatusCanceled': 'Canceled',
    'deleteStatusPendingConfirm': 'Pending confirmation',
    'deleteStatusCoolingOff': 'Cooling-off period',
    'deleteStatusProcessing': 'Processing',
    'deleteStatusCompleted': 'Completed',
    'deleteStatusCanceled': 'Canceled',
    'deleteStatusRejected': 'Rejected',
    'cancellingDelete': 'Cancelling...',
    'cookieMarketingNotice': 'Cookie / marketing notice',
    'lastActiveAt': 'Last active {time}',
    'profileSaved': 'Profile saved',
    'saveProfileFailed': 'Could not save profile: {error}',
    'fillTargetFirst': 'Enter {target} first',
    'codeSentWithLocal': 'Code sent (local code: {code})',
    'sendCodeFailed': 'Could not send code: {error}',
    'fillAccountAndCode': 'Enter account and verification code',
    'accountBound': 'Account bound',
    'bindFailed': 'Could not bind account: {error}',
    'enterOldPassword': 'Enter current password',
    'enterNewPassword': 'Enter new password',
    'newPasswordsDoNotMatch': 'New passwords do not match',
    'passwordUpdated': 'Password updated',
    'updatePasswordFailed': 'Could not update password: {error}',
    'accountSettingsHero': 'Keep your account in your hands',
    'basicProfile': 'Basic profile',
    'accountBinding': 'Account binding',
    'changePassword': 'Change password',
    'saving': 'Saving...',
    'saveProfile': 'Save profile',
    'binding': 'Binding...',
    'confirmBind': 'Confirm binding',
    'updating': 'Updating...',
    'updatePassword': 'Update password',
    'hasPasswordHint':
        'This account already has a password. Changing it requires the current one.',
    'noPasswordHint':
        'This account has no password yet. You can set a new one directly.',
    'dataExport': 'Data export',
    'accountDeletion': 'Account deletion',
    'coolingOffDays': '{days}-day cooling-off',
    'createExportTask': 'Create export task',
    'loadMoreExportTasks': 'Load more export tasks',
    'agreementTrace': 'Agreement records',
    'confirmPrivacyPolicy': 'Confirm privacy policy',
    'confirmUserAgreement': 'Confirm user agreement',
    'deviceManagement': 'Device management',
    'deactivateThisDevice': 'Deactivate this device',
    'privacyPolicy': 'Privacy policy',
    'userAgreement': 'User agreement',
    'unknownAgreement': 'Unknown agreement',
    'unknownDevice': 'Unknown device',
    'deleteTaskTitle': 'Delete task #{id} · {status}',
    'cancelDeleteRequest': 'Cancel delete request',
    'submitDeleteRequest': 'Submit delete request',
    'sendDeleteCode': 'Send deletion code',
    'localCodeOnly': 'Local code: {code}',
    'unknownStatus': 'Unknown status',
    'deviceEnabled': 'Active',
    'deviceDisabled': 'Deactivated',
    'deviceLoggedOut': 'Signed out',
    'publicProfile': 'Public profile',
    'publicProfileLoadFailed': 'Could not load profile: {error}',
    'sendDirectMessage': 'Message',
    'loginToFollowUser': 'Sign in to follow this user.',
    'publicProfileErrorUserNotFound': 'This user could not be found.',
    'publicProfileErrorSessionMissing':
        'Your sign-in session is no longer available. Please sign in again.',
    'publicProfileErrorCannotFollowSelf': 'You cannot follow yourself.',
    'loadMoreUsersFailed': 'Could not load more users: {error}',
    'relationListLoadFailed': 'Could not load relation list: {error}',
    'followers': 'Followers',
    'followingUsers': 'Following',
    'noRelationUsers': 'No users yet',
    'userCollectionErrorSessionMissing':
        'Your sign-in session is no longer available. Please sign in again.',
    'collectionLoadFailed': 'Could not load: {error}',
    'noCollectionData': 'No data yet',
    'favoritedAt': 'Saved {time}',
    'postLabel': 'Post',
    'address': 'Address',
    'shopDetail': 'Place details',
    'shopDetailLoadFailed': 'Could not load place details: {error}',
    'openingHours': 'Opening hours',
    'favoriteActionFailed': 'Could not update favorite: {error}',
    'shareCopied': 'Share text copied',
    'viewAll': 'View all',
    'shopReviewsLoadFailed': 'Could not load place reviews: {error}',
    'noPublicReviews': 'No public reviews yet',
    'similarShopsLoadFailed': 'Could not load similar places: {error}',
    'noSimilarShops': 'No similar places yet',
    'sortLatest': 'Latest',
    'sortHottest': 'Top',
    'sortBestRated': 'Best rated',
    'minScoreFour': '4+ stars',
    'withPhotosOnly': 'With photos',
    'alreadyAtEnd': 'You have reached the end',
    'refreshBrowseHistoryFailed': 'Could not refresh history: {error}',
    'loadMoreBrowseHistoryFailed': 'Could not load more history: {error}',
    'clearBrowseHistoryFailed': 'Could not clear history: {error}',
    'deleteBrowseHistoryFailed': 'Could not delete history item: {error}',
    'browseHistoryLoadFailed': 'Could not load history: {error}',
    'noBrowseHistory': 'No browse history in this region yet',
    'browseViewCount': 'Viewed {count} times',
    'deleteBrowseHistoryTooltip': 'Delete history item',
    'clearAll': 'Clear all',
    'postSubmittedForAudit': 'Post submitted for review',
    'deletePost': 'Delete post',
    'deletePostConfirm': 'This cannot be undone. Delete this post?',
    'postDeleted': 'Post deleted',
    'postEditorLoadFailed': 'Could not load post editor data: {error}',
    'publishToCircle': 'Post to {name}',
    'circlePostNeedsAudit': 'Content still goes through community review.',
    'titleLabel': 'Title',
    'bodyLabel': 'Body',
    'topicsCommaSeparated': 'Topics, comma separated',
    'submitForAudit': 'Submit for review',
    'postDetail': 'Post details',
    'postLoadFailed': 'Could not load post: {error}',
    'reposted': 'Reposted',
    'unreposted': 'Repost removed',
    'repostFailed': 'Could not update repost: {error}',
    'reportPost': 'Report post',
    'reportSubmitFailed': 'Could not submit report: {error}',
    'cancelReply': 'Cancel reply',
    'saySomethingUsefulShort': 'Say something useful',
    'likeCountLabel': '{count} likes',
    'replyingToUser': 'Replying to {name}',
    'simplifiedChinese': '简体中文',
    'traditionalChinese': '繁體中文',
    'englishLanguage': 'English',
    'noSignature': 'No bio yet',
    'reviewsMetric': 'Reviews',
    'noFollowers': 'No followers yet',
    'noFollowing': 'Not following anyone yet',
    'levelFollowersMeta': 'Lv.{level} · {count} followers',
    'shopHash': 'Place #{id}',
    'postHash': 'Post #{id}',
    'recordHash': 'Record #{id}',
    'shopLabel': 'Place',
    'unfavoritePost': 'Remove favorite',
    'favoritePost': 'Save post',
    'unrepostWithCount': 'Undo repost {count}',
    'repostWithCount': 'Repost {count}',
    'editPost': 'Edit post',
    'publishPost': 'Publish post',
    'pleaseEnterTitle': 'Enter a title',
    'pleaseEnterBody': 'Enter the body',
    'postSaveFailed': 'Could not save post: {error}',
    'unfavoriteShop': 'Remove favorite',
    'favoriteShop': 'Save place',
    'favoriteStatusLoading': 'Loading favorite status...',
    'sharing': 'Sharing...',
    'shareShop': 'Share place',
    'shopReviewsSection': 'Reviews',
    'similarShopsSection': 'Similar places',
    'retryReviews': 'Retry reviews',
    'retryRecommendations': 'Retry recommendations',
  };

  factory AppLocalizations.forTag(String tag) {
    final normalized = tag.toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh-tw') || normalized.startsWith('zh-hk')) {
      return AppLocalizations._(tag, _traditional);
    }
    if (normalized.startsWith('zh')) {
      return AppLocalizations._(tag, _simplified);
    }
    return AppLocalizations._(tag, _english);
  }

  factory AppLocalizations.forLocale(Locale locale) {
    final countryCode = locale.countryCode;
    return AppLocalizations.forTag(
      countryCode == null || countryCode.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}-$countryCode',
    );
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations.forTag('zh-CN');
  }

  String _text(String key) => _values[key]!;
  String _withError(String key, Object error) =>
      _text(key).replaceFirst('{error}', _normalizeErrorText(error));
  String _withCount(String key, int count) =>
      _text(key).replaceFirst('{count}', '$count');
  String _withName(String key, String name) =>
      _text(key).replaceFirst('{name}', name);

  String _appendNotificationRemark(String base, String? remark) {
    if (remark == null || remark.trim().isEmpty) return base;
    final separator = tag.startsWith('en') ? ': ' : '：';
    return '$base$separator${remark.trim()}';
  }

  String _normalizeErrorText(Object error) {
    final text = switch (error) {
      StateError() => error.message,
      FormatException() => error.message,
      ArgumentError() => error.message?.toString() ?? error.toString(),
      AssertionError() => error.message?.toString() ?? error.toString(),
      _ => error.toString(),
    };
    return _stripErrorPrefix(text);
  }

  String _stripErrorPrefix(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed
        .replaceFirst(RegExp(r'^Bad state:\s*'), '')
        .replaceFirst(RegExp(r'^Invalid argument\(s\):\s*'), '')
        .replaceFirst(
          RegExp(r'^(?:[A-Za-z]+)?(?:Exception|Error)(?: \([^)]+\))?:\s*'),
          '',
        );
  }

  String get homeTitle => _text('homeTitle');
  String get searchHint => _text('searchHint');
  String get featured => _text('featured');
  String get profile => _text('profile');
  String get homeSubtitle => _text('homeSubtitle');
  String get europe => _text('europe');
  String get china => _text('china');
  String get language => _text('language');
  String get map => _text('map');
  String get mapsConfigured => _text('mapsConfigured');
  String get mapsUnavailable => _text('mapsUnavailable');
  String get realPaymentUnavailable => _text('realPaymentUnavailable');
  String get pushUnavailable => _text('pushUnavailable');
  String get notifications => _text('notifications');
  String get account => _text('account');
  String get cityRankings => _text('cityRankings');
  String get activities => _text('activities');
  String get placesLoadFailed => _text('placesLoadFailed');
  String get noPlaces => _text('noPlaces');
  String get homeNavigation => _text('homeNavigation');
  String get exploreNavigation => _text('exploreNavigation');
  String get ordersNavigation => _text('ordersNavigation');
  String get searchTitle => _text('searchTitle');
  String get searchSuggestionsLoading => _text('searchSuggestionsLoading');
  String get searchSuggestions => _text('searchSuggestions');
  String searchFailed(Object error) => _withError('searchFailed', error);
  String get processing => _text('processing');
  String get retry => _text('retry');
  String get requestFailed => _text('requestFailed');
  String get invalidApiResponse => _text('invalidApiResponse');
  String unsupportedApiClientCapability(String capability) => _text(
    'unsupportedApiClientCapability',
  ).replaceFirst('{capability}', capability);
  String get noMatchingPlaces => _text('noMatchingPlaces');
  String get loading => _text('loading');
  String get loadMore => _text('loadMore');
  String loadMoreShopsFailed(Object error) =>
      _withError('loadMoreShopsFailed', error);
  String discoveryFailed(Object error) => _withError('discoveryFailed', error);
  String get browseErrorShopNotFound => _text('browseErrorShopNotFound');
  String get browseErrorSearchHistoryNotFound =>
      _text('browseErrorSearchHistoryNotFound');
  String get browseErrorInvalidShopId => _text('browseErrorInvalidShopId');
  String get browseErrorUnsupportedReviewSort =>
      _text('browseErrorUnsupportedReviewSort');
  String get browseErrorUnsupportedFavoriteTarget =>
      _text('browseErrorUnsupportedFavoriteTarget');
  String get enterKeyword => _text('enterKeyword');
  String get recentSearches => _text('recentSearches');
  String get clearing => _text('clearing');
  String get clear => _text('clear');
  String get moreHistory => _text('moreHistory');
  String get hotSearches => _text('hotSearches');
  String clearHistoryFailed(Object error) =>
      _withError('clearHistoryFailed', error);
  String removeHistoryFailed(Object error) =>
      _withError('removeHistoryFailed', error);
  String loadMoreHistoryFailed(Object error) =>
      _withError('loadMoreHistoryFailed', error);
  String get rankDetailTitle => _text('rankDetailTitle');
  String refreshRanksFailed(Object error) =>
      _withError('refreshRanksFailed', error);
  String ranksLoadFailed(Object error) => _withError('ranksLoadFailed', error);
  String get rankErrorNotFound => _text('rankErrorNotFound');
  String get rankErrorInvalidType => _text('rankErrorInvalidType');
  String get noPublicRanks => _text('noPublicRanks');
  String get rankTypeMustEat => _text('rankTypeMustEat');
  String get rankTypeTopRated => _text('rankTypeTopRated');
  String get rankTypeTrending => _text('rankTypeTrending');
  String shopCount(int count) => _withCount('shopCount', count);
  String topShop(String name) => _withName('topShop', name);
  String rankDetailLoadFailed(Object error) =>
      _withError('rankDetailLoadFailed', error);
  String get rankNoShops => _text('rankNoShops');
  String get activityDetailTitle => _text('activityDetailTitle');
  String refreshActivitiesFailed(Object error) =>
      _withError('refreshActivitiesFailed', error);
  String activitiesLoadFailed(Object error) =>
      _withError('activitiesLoadFailed', error);
  String get noOnlineActivities => _text('noOnlineActivities');
  String get activityChannelHome => _text('activityChannelHome');
  String get activityChannelSearch => _text('activityChannelSearch');
  String get activityChannelChannel => _text('activityChannelChannel');
  String get activityChannelPage => _text('activityChannelPage');
  String get activityChannelCommunity => _text('activityChannelCommunity');
  String get activityTypeThemed => _text('activityTypeThemed');
  String get activityTypeHoliday => _text('activityTypeHoliday');
  String get activityTypeNewCustomer => _text('activityTypeNewCustomer');
  String get activityTypeMerchantSupport =>
      _text('activityTypeMerchantSupport');
  String get activityTypeContentTopic => _text('activityTypeContentTopic');
  String resourceCount(int count) => _withCount('resourceCount', count);
  String activityDetailLoadFailed(Object error) =>
      _withError('activityDetailLoadFailed', error);
  String get activityErrorNotFoundOrOffline =>
      _text('activityErrorNotFoundOrOffline');
  String get activityNoItems => _text('activityNoItems');
  String get cannotOpenExternalLink => _text('cannotOpenExternalLink');
  String openTargetFailed(String target, Object error) => _text(
    'openTargetFailed',
  ).replaceFirst('{target}', target).replaceFirst('{error}', '$error');
  String get targetShop => _text('targetShop');
  String get targetDeal => _text('targetDeal');
  String get targetPost => _text('targetPost');
  String get targetRank => _text('targetRank');
  String get targetTopic => _text('targetTopic');
  String get targetExternalLink => _text('targetExternalLink');
  String get targetResource => _text('targetResource');
  String rankTypeLabel({int? type, String? fallback}) {
    if (type != null) {
      return switch (type) {
        1 => rankTypeMustEat,
        2 => rankTypeTopRated,
        3 => rankTypeTrending,
        _ => fallback != null && fallback.isNotEmpty ? fallback : targetRank,
      };
    }
    return switch (fallback) {
      '必吃榜' || 'Must-eat ranking' => rankTypeMustEat,
      '好评榜' || '好評榜' || 'Top-rated ranking' => rankTypeTopRated,
      '热门榜' || '熱門榜' || 'Trending ranking' => rankTypeTrending,
      final value when value != null && value.isNotEmpty => value,
      _ => targetRank,
    };
  }

  String activityChannelLabel({int? channel, String? fallback}) {
    if (channel != null) {
      return switch (channel) {
        1 => activityChannelHome,
        2 => activityChannelSearch,
        3 => activityChannelChannel,
        4 => activityChannelPage,
        5 => activityChannelCommunity,
        _ =>
          fallback != null && fallback.isNotEmpty ? fallback : targetResource,
      };
    }
    return switch (fallback) {
      '首页' || '首頁' || 'Home' => activityChannelHome,
      '搜索' || '搜尋' || 'Search' => activityChannelSearch,
      '频道' || '頻道' || 'Channel' => activityChannelChannel,
      '活动页' || '活動頁' || 'Activity page' => activityChannelPage,
      '社区' || '社區' || '社群' || 'Community' => activityChannelCommunity,
      final value when value != null && value.isNotEmpty => value,
      _ => targetResource,
    };
  }

  String activityTypeLabel({int? type, String? fallback}) {
    if (type != null) {
      return switch (type) {
        1 => activityTypeThemed,
        2 => activityTypeHoliday,
        3 => activityTypeNewCustomer,
        4 => activityTypeMerchantSupport,
        5 => activityTypeContentTopic,
        _ =>
          fallback != null && fallback.isNotEmpty ? fallback : targetResource,
      };
    }
    return switch (fallback) {
      '专题活动' ||
      '專題活動' ||
      '专题' ||
      '專題' ||
      'Themed campaign' => activityTypeThemed,
      '节日活动' || '節日活動' || 'Holiday campaign' => activityTypeHoliday,
      '新客活动' || '新客活動' || 'New customer campaign' => activityTypeNewCustomer,
      '商户扶持' || '商戶扶持' || 'Merchant support' => activityTypeMerchantSupport,
      '内容话题' || '內容話題' || 'Content topic' => activityTypeContentTopic,
      final value when value != null && value.isNotEmpty => value,
      _ => targetResource,
    };
  }

  String activityTargetTypeLabel({int? targetType, String? fallback}) {
    if (targetType != null) {
      return switch (targetType) {
        1 => targetShop,
        2 => targetDeal,
        3 => targetPost,
        4 => targetRank,
        5 => targetTopic,
        6 => targetExternalLink,
        _ =>
          fallback != null && fallback.isNotEmpty ? fallback : targetResource,
      };
    }
    return switch (fallback) {
      '店铺' || '店家' || 'Shop' || 'Place' || 'place' => targetShop,
      '团购' || '團購' || 'Deal' || 'deal' => targetDeal,
      '帖子' || '貼文' || 'Post' || 'post' => targetPost,
      '榜单' || '排行榜' || 'Ranking' || 'ranking' => targetRank,
      '话题' || '話題' || 'Topic' || 'topic' => targetTopic,
      '外链' ||
      '外鏈' ||
      '外部链接' ||
      '外部連結' ||
      'External link' ||
      'external link' => targetExternalLink,
      final value when value != null && value.isNotEmpty => value,
      _ => targetResource,
    };
  }

  String refreshNotificationsFailed(Object error) =>
      _withError('refreshNotificationsFailed', error);
  String loadMoreFailed(Object error) => _withError('loadMoreFailed', error);
  String markReadFailed(Object error) => _withError('markReadFailed', error);
  String get allNotificationsMarkedRead => _text('allNotificationsMarkedRead');
  String markAllReadFailed(Object error) =>
      _withError('markAllReadFailed', error);
  String get markAllRead => _text('markAllRead');
  String markAllReadWithCount(int count) =>
      _withCount('markAllReadWithCount', count);
  String get filterAll => _text('filterAll');
  String get filterUnreadOnly => _text('filterUnreadOnly');
  String notificationsLoadFailed(Object error) =>
      _withError('notificationsLoadFailed', error);
  String get notificationErrorUnavailable =>
      _text('notificationErrorUnavailable');
  String get notificationErrorRefreshUnavailable =>
      _text('notificationErrorRefreshUnavailable');
  String get reload => _text('reload');
  String get refresh => _text('refresh');
  String get noUnreadNotifications => _text('noUnreadNotifications');
  String get noNotifications => _text('noNotifications');
  String get continueFindUnread => _text('continueFindUnread');
  String get unreadBadge => _text('unreadBadge');
  String get notificationTitleSocialFollow =>
      _text('notificationTitleSocialFollow');
  String get notificationTitleDirectMessage =>
      _text('notificationTitleDirectMessage');
  String get notificationTitleMention => _text('notificationTitleMention');
  String get notificationTitlePostApproved =>
      _text('notificationTitlePostApproved');
  String get notificationTitlePostRejected =>
      _text('notificationTitlePostRejected');
  String get notificationTitleTopicUpdate =>
      _text('notificationTitleTopicUpdate');
  String get notificationTitleOrderPaid => _text('notificationTitleOrderPaid');
  String get notificationTitleReservationConfirmed =>
      _text('notificationTitleReservationConfirmed');
  String get notificationTitleReservationSubmitted =>
      _text('notificationTitleReservationSubmitted');
  String get notificationTitleReservationReminderThirtyMinutes =>
      _text('notificationTitleReservationReminderThirtyMinutes');
  String get notificationTitleReservationReminderTwoHours =>
      _text('notificationTitleReservationReminderTwoHours');
  String get notificationTitleCouponReminder =>
      _text('notificationTitleCouponReminder');
  String get notificationTitleCouponExpired =>
      _text('notificationTitleCouponExpired');
  String get notificationTitleCouponVerified =>
      _text('notificationTitleCouponVerified');
  String get notificationTitleMerchantReply =>
      _text('notificationTitleMerchantReply');
  String get notificationTitleReviewLike =>
      _text('notificationTitleReviewLike');
  String get notificationTitleReviewComment =>
      _text('notificationTitleReviewComment');
  String get notificationTitleCommentReply =>
      _text('notificationTitleCommentReply');
  String get notificationTitlePostLike => _text('notificationTitlePostLike');
  String get notificationTitlePostComment =>
      _text('notificationTitlePostComment');
  String get notificationTitlePostRepost =>
      _text('notificationTitlePostRepost');
  String notificationFollowedYou(String name) =>
      _text('notificationFollowedYou').replaceFirst('{name}', name);
  String notificationLikedYourReview({
    required String name,
    required String preview,
  }) => _text(
    'notificationLikedYourReview',
  ).replaceFirst('{name}', name).replaceFirst('{preview}', preview);
  String notificationCommentedOnYourReview({
    required String name,
    required String preview,
  }) => _text(
    'notificationCommentedOnYourReview',
  ).replaceFirst('{name}', name).replaceFirst('{preview}', preview);
  String notificationRepliedToYou({
    required String name,
    required String preview,
  }) => _text(
    'notificationRepliedToYou',
  ).replaceFirst('{name}', name).replaceFirst('{preview}', preview);
  String notificationLikedYourPost({
    required String name,
    required String title,
  }) => _text(
    'notificationLikedYourPost',
  ).replaceFirst('{name}', name).replaceFirst('{title}', title);
  String notificationCommentedOnYourPost({
    required String name,
    required String preview,
  }) => _text(
    'notificationCommentedOnYourPost',
  ).replaceFirst('{name}', name).replaceFirst('{preview}', preview);
  String notificationRepostedYourPost({
    required String name,
    required String title,
  }) => _text(
    'notificationRepostedYourPost',
  ).replaceFirst('{name}', name).replaceFirst('{title}', title);
  String notificationMentionedYouInPost({
    required String name,
    required String title,
  }) => _text(
    'notificationMentionedYouInPost',
  ).replaceFirst('{name}', name).replaceFirst('{title}', title);
  String notificationMentionedYouInPostComment({
    required String name,
    required String title,
  }) => _text(
    'notificationMentionedYouInPostComment',
  ).replaceFirst('{name}', name).replaceFirst('{title}', title);
  String notificationTopicUpdateContent({
    required String name,
    required String topic,
    required String title,
  }) => _text('notificationTopicUpdateContent')
      .replaceFirst('{name}', name)
      .replaceFirst('{topic}', topic)
      .replaceFirst('{title}', title);
  String get notificationBanAppealApprovedContent =>
      _text('notificationBanAppealApprovedContent');
  String notificationBanAppealRejectedContent({String? reason}) {
    final base = _text('notificationBanAppealRejectedContent');
    return _appendNotificationRemark(base, reason);
  }

  String get notificationAccountUnbannedContent =>
      _text('notificationAccountUnbannedContent');
  String notificationDirectMessagePreview({
    required String name,
    required String preview,
  }) => _text(
    'notificationDirectMessagePreview',
  ).replaceFirst('{name}', name).replaceFirst('{preview}', preview);
  String notificationPostApprovedContent(String title, {String? remark}) {
    final base = _text(
      'notificationPostApprovedContent',
    ).replaceFirst('{title}', title);
    return _appendNotificationRemark(base, remark);
  }

  String notificationPostRejectedContent(String title, {String? remark}) {
    final base = _text(
      'notificationPostRejectedContent',
    ).replaceFirst('{title}', title);
    return _appendNotificationRemark(base, remark);
  }

  String notificationOrderNumber(String orderNo) =>
      _text('notificationOrderNumber').replaceFirst('{orderNo}', orderNo);
  String get notificationCouponsReady => _text('notificationCouponsReady');
  String get notificationReservationAutoConfirmedAction =>
      _text('notificationReservationAutoConfirmedAction');
  String get notificationReservationSubmittedAction =>
      _text('notificationReservationSubmittedAction');
  String notificationCouponCodeLabel(String code) =>
      _text('notificationCouponCodeLabel').replaceFirst('{code}', code);
  String notificationCouponExpiringInDays({
    required String code,
    required int days,
  }) {
    if (tag.startsWith('en')) {
      final unit = days == 1 ? 'day' : 'days';
      return '$code expires in $days $unit';
    }
    return _text(
      'notificationCouponExpiringInDays',
    ).replaceFirst('{code}', code).replaceFirst('{days}', '$days');
  }

  String notificationCouponRedeemedAt({
    required String code,
    required String shop,
  }) => _text(
    'notificationCouponRedeemedAt',
  ).replaceFirst('{code}', code).replaceFirst('{shop}', shop);
  String get notificationCouponRedeemed => _text('notificationCouponRedeemed');
  String get notificationExpertApprovedContent =>
      _text('notificationExpertApprovedContent');
  String get notificationExpertRejectedContent =>
      _text('notificationExpertRejectedContent');
  String get notificationTitleRefundApproved =>
      _text('notificationTitleRefundApproved');
  String get notificationTitleRefundRejected =>
      _text('notificationTitleRefundRejected');
  String get notificationTitleReservationMerchantConfirmed =>
      _text('notificationTitleReservationMerchantConfirmed');
  String get notificationTitleReservationArrived =>
      _text('notificationTitleReservationArrived');
  String get notificationTitleReservationRejected =>
      _text('notificationTitleReservationRejected');
  String get notificationTitleReservationNoShow =>
      _text('notificationTitleReservationNoShow');
  String get notificationTitleReviewApproved =>
      _text('notificationTitleReviewApproved');
  String get notificationTitleReviewRejected =>
      _text('notificationTitleReviewRejected');
  String get notificationTitleReviewHidden =>
      _text('notificationTitleReviewHidden');
  String get notificationTitleBanAppealApproved =>
      _text('notificationTitleBanAppealApproved');
  String get notificationTitleBanAppealRejected =>
      _text('notificationTitleBanAppealRejected');
  String get notificationTitleAccountUnbanned =>
      _text('notificationTitleAccountUnbanned');
  String get notificationActorPlatform => _text('notificationActorPlatform');
  String get notificationActorMerchant => _text('notificationActorMerchant');
  String notificationRefundApprovedAction(String actor) =>
      _text('notificationRefundApprovedAction').replaceFirst('{actor}', actor);
  String notificationRefundRejectedAction(String actor) =>
      _text('notificationRefundRejectedAction').replaceFirst('{actor}', actor);
  String get notificationReservationMerchantConfirmedAction =>
      _text('notificationReservationMerchantConfirmedAction');
  String get notificationReservationArrivedAction =>
      _text('notificationReservationArrivedAction');
  String get notificationReservationMerchantRejectedAction =>
      _text('notificationReservationMerchantRejectedAction');
  String get notificationReservationMarkedNoShowAction =>
      _text('notificationReservationMarkedNoShowAction');
  String notificationReviewApprovedContent(String shop, {String? remark}) {
    final base = _text(
      'notificationReviewApprovedContent',
    ).replaceFirst('{shop}', shop);
    return _appendNotificationRemark(base, remark);
  }

  String notificationReviewRejectedContent(String shop, {String? remark}) {
    final base = _text(
      'notificationReviewRejectedContent',
    ).replaceFirst('{shop}', shop);
    return _appendNotificationRemark(base, remark);
  }

  String notificationReviewHiddenContent(String shop, {String? remark}) {
    final base = _text(
      'notificationReviewHiddenContent',
    ).replaceFirst('{shop}', shop);
    return _appendNotificationRemark(base, remark);
  }

  String get loggingOut => _text('loggingOut');
  String get logout => _text('logout');
  String profileLoadFailed(Object error) =>
      _withError('profileLoadFailed', error);
  String levelRegionPoints({
    required int level,
    required String region,
    required int points,
  }) => _text('levelRegionPoints')
      .replaceFirst('{level}', '$level')
      .replaceFirst('{region}', region)
      .replaceFirst('{points}', '$points');
  String growthValueLabel(int value) =>
      _text('growthValueLabel').replaceFirst('{value}', '$value');
  String get accountSettings => _text('accountSettings');
  String get accountSettingsSubtitle => _text('accountSettingsSubtitle');
  String get localExpertCertification => _text('localExpertCertification');
  String get localExpertCertificationSubtitle =>
      _text('localExpertCertificationSubtitle');
  String get growthRecords => _text('growthRecords');
  String growthRecordsSubtitle({
    required int level,
    required int growth,
    required int points,
  }) => _text('growthRecordsSubtitle')
      .replaceFirst('{level}', '$level')
      .replaceFirst('{growth}', '$growth')
      .replaceFirst('{points}', '$points');
  String get myMessages => _text('myMessages');
  String get blockedUsers => _text('blockedUsers');
  String get myCircles => _text('myCircles');
  String get myReviews => _text('myReviews');
  String get myPosts => _text('myPosts');
  String get myFavorites => _text('myFavorites');
  String get myOrders => _text('myOrders');
  String get myCoupons => _text('myCoupons');
  String get myReservations => _text('myReservations');
  String get myBrowseHistory => _text('myBrowseHistory');
  String get privacyCenter => _text('privacyCenter');
  String get communityTitle => _text('communityTitle');
  String get topicPlaza => _text('topicPlaza');
  String get localCircles => _text('localCircles');
  String get recommendedTab => _text('recommendedTab');
  String get followingTab => _text('followingTab');
  String get createPost => _text('createPost');
  String get followingFeedLoginRequired => _text('followingFeedLoginRequired');
  String loadMorePostsFailed(Object error) =>
      _withError('loadMorePostsFailed', error);
  String communityLoadFailed(Object error) =>
      _withError('communityLoadFailed', error);
  String get noCommunityPosts => _text('noCommunityPosts');
  String postMetaStats({required int likes, required int comments}) => _text(
    'postMetaStats',
  ).replaceFirst('{likes}', '$likes').replaceFirst('{comments}', '$comments');
  String get hotTab => _text('hotTab');
  String get followingTopicsTab => _text('followingTopicsTab');
  String loadMoreTopicsFailed(Object error) =>
      _withError('loadMoreTopicsFailed', error);
  String topicsLoadFailed(Object error) =>
      _withError('topicsLoadFailed', error);
  String get followingTopicsLoginRequired =>
      _text('followingTopicsLoginRequired');
  String get goLogin => _text('goLogin');
  String hotScore(num score) =>
      _text('hotScore').replaceFirst('{score}', '$score');
  String topicSevenDayStats({
    required int posts,
    required int likes,
    required int comments,
  }) => _text('topicSevenDayStats')
      .replaceFirst('{posts}', '$posts')
      .replaceFirst('{likes}', '$likes')
      .replaceFirst('{comments}', '$comments');
  String topicFollowMeta({required int followers, required int posts}) => _text(
    'topicFollowMeta',
  ).replaceFirst('{followers}', '$followers').replaceFirst('{posts}', '$posts');
  String topicFollowerCount(int count) =>
      _text('topicFollowerCount').replaceFirst('{count}', '$count');
  String get topicErrorNotFound => _text('topicErrorNotFound');
  String get topicErrorUnavailable => _text('topicErrorUnavailable');
  String get topicErrorFollowFailed => _text('topicErrorFollowFailed');
  String followStatusUpdateFailed(Object error) =>
      _withError('followStatusUpdateFailed', error);
  String get followed => _text('followed');
  String get followTopic => _text('followTopic');
  String get publicPosts => _text('publicPosts');
  String postsLoadFailed(Object error) => _withError('postsLoadFailed', error);
  String get noPublicPostsHere => _text('noPublicPostsHere');
  String get communityErrorPostNotFound => _text('communityErrorPostNotFound');
  String get communityErrorReportDuplicate =>
      _text('communityErrorReportDuplicate');
  String get communityErrorReplyTargetMissing =>
      _text('communityErrorReplyTargetMissing');
  String get communityErrorJoinCircleToPost =>
      _text('communityErrorJoinCircleToPost');
  String loadMoreCirclesFailed(Object error) =>
      _withError('loadMoreCirclesFailed', error);
  String circlesLoadFailed(Object error) =>
      _withError('circlesLoadFailed', error);
  String get circleErrorJoinedOnlyLoginRequired =>
      _text('circleErrorJoinedOnlyLoginRequired');
  String get circleErrorNotFound => _text('circleErrorNotFound');
  String circleMeta({required int members, required int posts}) => _text(
    'circleMeta',
  ).replaceFirst('{members}', '$members').replaceFirst('{posts}', '$posts');
  String circleStatusUpdateFailed(Object error) =>
      _withError('circleStatusUpdateFailed', error);
  String get joined => _text('joined');
  String get joinCircle => _text('joinCircle');
  String get viewMembers => _text('viewMembers');
  String get postInCircle => _text('postInCircle');
  String get joinCircleToPost => _text('joinCircleToPost');
  String get circleNewPosts => _text('circleNewPosts');
  String loadMoreMembersFailed(Object error) =>
      _withError('loadMoreMembersFailed', error);
  String circleMembersTitle(String name) =>
      _text('circleMembersTitle').replaceFirst('{name}', name);
  String membersLoadFailed(Object error) =>
      _withError('membersLoadFailed', error);
  String get directMessages => _text('directMessages');
  String get directMessageUser => _text('directMessageUser');
  String get messageErrorUserNotFound => _text('messageErrorUserNotFound');
  String get messageErrorConversationMissing =>
      _text('messageErrorConversationMissing');
  String get messageErrorCannotMessageSelf =>
      _text('messageErrorCannotMessageSelf');
  String get messageErrorBlockedRelationship =>
      _text('messageErrorBlockedRelationship');
  String get messageErrorCannotBlockSelf =>
      _text('messageErrorCannotBlockSelf');
  String get messageErrorReportTargetUnavailable =>
      _text('messageErrorReportTargetUnavailable');
  String get messageErrorReportDuplicate =>
      _text('messageErrorReportDuplicate');
  String refreshConversationsFailed(Object error) =>
      _withError('refreshConversationsFailed', error);
  String loadMoreConversationsFailed(Object error) =>
      _withError('loadMoreConversationsFailed', error);
  String conversationsLoadFailed(Object error) =>
      _withError('conversationsLoadFailed', error);
  String get noDirectMessages => _text('noDirectMessages');
  String messageMarkReadFailed(Object error) =>
      _withError('messageMarkReadFailed', error);
  String loadEarlierMessagesFailed(Object error) =>
      _withError('loadEarlierMessagesFailed', error);
  String sendFailed(Object error) => _withError('sendFailed', error);
  String actionFailed(Object error) => _withError('actionFailed', error);
  String get reportConversation => _text('reportConversation');
  String get blockUser => _text('blockUser');
  String get unblockUser => _text('unblockUser');
  String get reportSubmitted => _text('reportSubmitted');
  String get blockedBothWays => _text('blockedBothWays');
  String get unblocked => _text('unblocked');
  String chatHistoryLoadFailed(Object error) =>
      _withError('chatHistoryLoadFailed', error);
  String get loadEarlierMessages => _text('loadEarlierMessages');
  String get blockedComposerHint => _text('blockedComposerHint');
  String get messageHint => _text('messageHint');
  String get send => _text('send');
  String get harassmentOrInappropriate => _text('harassmentOrInappropriate');
  String refreshBlockedUsersFailed(Object error) =>
      _withError('refreshBlockedUsersFailed', error);
  String loadMoreBlockedUsersFailed(Object error) =>
      _withError('loadMoreBlockedUsersFailed', error);
  String unblockedUser(String name) =>
      _text('unblockedUser').replaceFirst('{name}', name);
  String unblockFailed(Object error) => _withError('unblockFailed', error);
  String blockedUsersLoadFailed(Object error) =>
      _withError('blockedUsersLoadFailed', error);
  String get blockedUsersEmpty => _text('blockedUsersEmpty');
  String blockedAt(String time) =>
      _text('blockedAt').replaceFirst('{time}', time);
  String userFallback(int id) =>
      _text('userFallback').replaceFirst('{id}', '$id');
  String get anonymousPeer => _text('anonymousPeer');

  String get payPending => _text('payPending');
  String get payPaid => _text('payPaid');
  String get payRefunded => _text('payRefunded');
  String get payPartialRefund => _text('payPartialRefund');
  String get couponPending => _text('couponPending');
  String get couponUsed => _text('couponUsed');
  String get couponExpired => _text('couponExpired');
  String get couponRefunded => _text('couponRefunded');
  String loadMoreOrdersFailed(Object error) =>
      _withError('loadMoreOrdersFailed', error);
  String ordersLoadFailed(Object error) =>
      _withError('ordersLoadFailed', error);
  String get noOrdersForFilter => _text('noOrdersForFilter');
  String loadMoreCouponsFailed(Object error) =>
      _withError('loadMoreCouponsFailed', error);
  String couponsLoadFailed(Object error) =>
      _withError('couponsLoadFailed', error);
  String get noCouponsForFilter => _text('noCouponsForFilter');
  String couponHighlight(String code) =>
      _text('couponHighlight').replaceFirst('{code}', code);
  String get groupDeals => _text('groupDeals');
  String dealsLoadFailed(Object error) => _withError('dealsLoadFailed', error);
  String get noDealsForShop => _text('noDealsForShop');
  String soldCount(int count) => _withCount('soldCount', count);
  String stockCount(int count) => _withCount('stockCount', count);
  String get buy => _text('buy');
  String get tradeErrorDealNotFound => _text('tradeErrorDealNotFound');
  String get tradeErrorDealExpired => _text('tradeErrorDealExpired');
  String get tradeErrorDealOutOfStock => _text('tradeErrorDealOutOfStock');
  String get tradeErrorOrderNotFound => _text('tradeErrorOrderNotFound');
  String get tradeErrorOrderPaymentUnavailable =>
      _text('tradeErrorOrderPaymentUnavailable');
  String get tradeErrorOrderCancelUnavailable =>
      _text('tradeErrorOrderCancelUnavailable');
  String get tradeErrorOrderRefundUnavailable =>
      _text('tradeErrorOrderRefundUnavailable');
  String get tradeErrorRefundUsedCoupons =>
      _text('tradeErrorRefundUsedCoupons');
  String get tradeErrorRefundExists => _text('tradeErrorRefundExists');
  String get tradeErrorCouponCodeRequired =>
      _text('tradeErrorCouponCodeRequired');
  String get tradeErrorCouponNotFound => _text('tradeErrorCouponNotFound');
  String get tradeErrorPaymentChannelUnavailable =>
      _text('tradeErrorPaymentChannelUnavailable');
  String createOrderFailed(Object error) =>
      _withError('createOrderFailed', error);
  String orderCreatedOpenDetailFailed(String orderNo, Object error) => _text(
    'orderCreatedOpenDetailFailed',
  ).replaceFirst('{orderNo}', orderNo).replaceFirst('{error}', '$error');
  String get dealDetail => _text('dealDetail');
  String dealDetailLoadFailed(Object error) =>
      _withError('dealDetailLoadFailed', error);
  String soldAndStock({required int sold, required int stock}) => _text(
    'soldAndStock',
  ).replaceFirst('{sold}', '$sold').replaceFirst('{stock}', '$stock');
  String validUntil(String range) =>
      _text('validUntil').replaceFirst('{range}', range);
  String get noPackageItems => _text('noPackageItems');
  String quantityLabel(int count) => _withCount('quantityLabel', count);
  String get orderDetail => _text('orderDetail');
  String get cancelOrder => _text('cancelOrder');
  String get cancelOrderConfirm => _text('cancelOrderConfirm');
  String get keepOrder => _text('keepOrder');
  String get confirmCancel => _text('confirmCancel');
  String get applyRefund => _text('applyRefund');
  String get submitApplication => _text('submitApplication');
  String get cancelAction => _text('cancelAction');
  String get orderLoadFailedTapRetry => _text('orderLoadFailedTapRetry');
  String orderShopMeta({required String shop, required String orderNo}) =>
      _text(
        'orderShopMeta',
      ).replaceFirst('{shop}', shop).replaceFirst('{orderNo}', orderNo);
  String get startPayment => _text('startPayment');
  String refundLabel(String status) =>
      _text('refundLabel').replaceFirst('{status}', status);
  String get couponCopied => _text('couponCopied');
  String get couponDetail => _text('couponDetail');
  String couponDetailLoadFailed(Object error) =>
      _withError('couponDetailLoadFailed', error);
  String get qrLoadFailed => _text('qrLoadFailed');
  String verifiedAt(String time) =>
      _text('verifiedAt').replaceFirst('{time}', time);
  String get showCodeToMerchant => _text('showCodeToMerchant');
  String priceSoldMeta({required String price, required int count}) => _text(
    'priceSoldMeta',
  ).replaceFirst('{price}', price).replaceFirst('{count}', '$count');

  String get usageRules => _text('usageRules');
  String get packageContents => _text('packageContents');
  String get quantitySimple => _text('quantitySimple');
  String get unitPrice => _text('unitPrice');
  String get paidAmount => _text('paidAmount');
  String get orderCanceled => _text('orderCanceled');
  String get refundReason => _text('refundReason');
  String get refundSubmitted => _text('refundSubmitted');
  String get refundStatusPending => _text('refundStatusPending');
  String get refundStatusApproved => _text('refundStatusApproved');
  String get refundStatusRejected => _text('refundStatusRejected');
  String get defaultRefundReason => _text('defaultRefundReason');
  String paymentRequestCreated(String channel) =>
      _text('paymentRequestCreated').replaceFirst('{channel}', channel);
  String paymentStartFailed(Object error) =>
      _withError('paymentStartFailed', error);
  String get relatedCoupons => _text('relatedCoupons');

  String get redeemable => _text('redeemable');
  String get notRedeemable => _text('notRedeemable');
  String get copying => _text('copying');
  String get copyCouponCode => _text('copyCouponCode');
  String validUntilDate(String date) =>
      _text('validUntilDate').replaceFirst('{date}', date);
  String get noExpiry => _text('noExpiry');
  String dealValidityRange({required String start, required String end}) =>
      _text(
        'dealValidityRange',
      ).replaceFirst('{start}', start).replaceFirst('{end}', end);
  String get noExtraRules => _text('noExtraRules');
  String get defaultVerifyHint => _text('defaultVerifyHint');

  String detailRefreshFailed(Object error) =>
      _withError('detailRefreshFailed', error);
  String get reloadFullDetail => _text('reloadFullDetail');
  String get reservationPending => _text('reservationPending');
  String get reservationConfirmed => _text('reservationConfirmed');
  String get reservationArrived => _text('reservationArrived');
  String get reservationUserCanceled => _text('reservationUserCanceled');
  String get reservationMerchantRejected =>
      _text('reservationMerchantRejected');
  String get reservationNoShow => _text('reservationNoShow');
  String get reservationConfirmModeAuto => _text('reservationConfirmModeAuto');
  String get reservationConfirmModeManual =>
      _text('reservationConfirmModeManual');
  String get reservationActionCreated => _text('reservationActionCreated');
  String get reservationActionMerchantConfirmed =>
      _text('reservationActionMerchantConfirmed');
  String get reservationActionMerchantRejected =>
      _text('reservationActionMerchantRejected');
  String get reservationActionUserCanceled =>
      _text('reservationActionUserCanceled');
  String get reservationActionUserRescheduled =>
      _text('reservationActionUserRescheduled');
  String get reservationActionMerchantRescheduled =>
      _text('reservationActionMerchantRescheduled');
  String get reservationActionCheckedIn => _text('reservationActionCheckedIn');
  String get reservationActionMarkedNoShow =>
      _text('reservationActionMarkedNoShow');
  String get reservationActionArrivalReminder =>
      _text('reservationActionArrivalReminder');
  String loadMoreReservationsFailed(Object error) =>
      _withError('loadMoreReservationsFailed', error);
  String reservationsLoadFailed(Object error) =>
      _withError('reservationsLoadFailed', error);
  String get noReservationsForFilter => _text('noReservationsForFilter');
  String reservationListMeta({
    required String no,
    required String time,
    required int people,
    required String status,
  }) => _text('reservationListMeta')
      .replaceFirst('{no}', no)
      .replaceFirst('{time}', time)
      .replaceFirst('{people}', '$people')
      .replaceFirst('{status}', status);
  String get onlineReservation => _text('onlineReservation');
  String get selectSlotFirst => _text('selectSlotFirst');
  String reservationCreated({required String no, required String status}) =>
      _text(
        'reservationCreated',
      ).replaceFirst('{no}', no).replaceFirst('{status}', status);
  String reservationFailed(Object error) =>
      _withError('reservationFailed', error);
  String get reservationErrorInvalidPeopleCount =>
      _text('reservationErrorInvalidPeopleCount');
  String get reservationErrorSlotOrTimeRequired =>
      _text('reservationErrorSlotOrTimeRequired');
  String get reservationErrorSlotCapacityUnavailable =>
      _text('reservationErrorSlotCapacityUnavailable');
  String get reservationErrorCancelDeadlinePassed =>
      _text('reservationErrorCancelDeadlinePassed');
  String get reservationErrorCancelUnavailable =>
      _text('reservationErrorCancelUnavailable');
  String get reservationErrorRescheduleSlotCapacityUnavailable =>
      _text('reservationErrorRescheduleSlotCapacityUnavailable');
  String get reservationErrorRescheduleUnavailable =>
      _text('reservationErrorRescheduleUnavailable');
  String get reservationErrorSlotNotFound =>
      _text('reservationErrorSlotNotFound');
  String get reservationErrorNotFound => _text('reservationErrorNotFound');
  String dateLabel(String date) =>
      _text('dateLabel').replaceFirst('{date}', date);
  String peopleCount(int count) => _withCount('peopleCount', count);
  String slotsLoadFailed(Object error) => _withError('slotsLoadFailed', error);
  String slotRemaining({
    required String start,
    required String end,
    required int count,
  }) => _text('slotRemaining')
      .replaceFirst('{start}', start)
      .replaceFirst('{end}', end)
      .replaceFirst('{count}', '$count');
  String get contactName => _text('contactName');
  String get contactPhone => _text('contactPhone');
  String get remark => _text('remark');
  String get submitting => _text('submitting');
  String get submitReservation => _text('submitReservation');
  String get reservationDetail => _text('reservationDetail');
  String get reservationLoadFailedTapRetry =>
      _text('reservationLoadFailedTapRetry');
  String get cancelReservation => _text('cancelReservation');
  String get cancelReservationConfirm => _text('cancelReservationConfirm');
  String get keepReservation => _text('keepReservation');
  String get reservationCanceled => _text('reservationCanceled');
  String get findRescheduleSlots => _text('findRescheduleSlots');
  String get confirmReschedule => _text('confirmReschedule');
  String get reservationRescheduled => _text('reservationRescheduled');
  String get rescheduleReason => _text('rescheduleReason');
  String reservationTimePeople({required String time, required int people}) =>
      _text(
        'reservationTimePeople',
      ).replaceFirst('{time}', time).replaceFirst('{people}', '$people');
  String rescheduleSlotMeta({
    required String start,
    required String mode,
    required int count,
  }) => _text('rescheduleSlotMeta')
      .replaceFirst('{start}', start)
      .replaceFirst('{mode}', mode)
      .replaceFirst('{count}', '$count');
  String get changeTimeline => _text('changeTimeline');
  String get noChangeRecords => _text('noChangeRecords');

  String get liked => _text('liked');
  String get like => _text('like');
  String get unliked => _text('unliked');
  String likeFailed(Object error) => _withError('likeFailed', error);
  String get commentPublished => _text('commentPublished');
  String commentFailed(Object error) => _withError('commentFailed', error);
  String loadMoreCommentsFailed(Object error) =>
      _withError('loadMoreCommentsFailed', error);
  String get reportReview => _text('reportReview');
  String get reportReason => _text('reportReason');
  String get submitReport => _text('submitReport');
  String reportFailed(Object error) => _withError('reportFailed', error);
  String get deleteReview => _text('deleteReview');
  String get deleteReviewConfirm => _text('deleteReviewConfirm');
  String get confirmDelete => _text('confirmDelete');
  String get reviewDeleted => _text('reviewDeleted');
  String deleteFailed(Object error) => _withError('deleteFailed', error);
  String get reply => _text('reply');
  String get myReviewDetail => _text('myReviewDetail');
  String get reviewDetail => _text('reviewDetail');
  String get edit => _text('edit');
  String get deleting => _text('deleting');
  String get delete => _text('delete');
  String reviewDetailLoadFailed(Object error) =>
      _withError('reviewDetailLoadFailed', error);
  String get reviewErrorNotFound => _text('reviewErrorNotFound');
  String get reviewErrorReportDuplicate => _text('reviewErrorReportDuplicate');
  String get reviewErrorReplyTargetMissing =>
      _text('reviewErrorReplyTargetMissing');
  String get reviewErrorUserUnavailable => _text('reviewErrorUserUnavailable');
  String get reviewErrorShopUnavailable => _text('reviewErrorShopUnavailable');
  String get reviewErrorShopImmutable => _text('reviewErrorShopImmutable');
  String auditRemarkLabel(String remark) =>
      _text('auditRemarkLabel').replaceFirst('{remark}', remark);
  String merchantReplyLabel(String reply) =>
      _text('merchantReplyLabel').replaceFirst('{reply}', reply);
  String get anonymousUser => _text('anonymousUser');
  String get report => _text('report');
  String get reviewLoginToInteract => _text('reviewLoginToInteract');
  String get commentsSection => _text('commentsSection');
  String replyingTo(String name) =>
      _text('replyingTo').replaceFirst('{name}', name);
  String get writeComment => _text('writeComment');
  String get publishing => _text('publishing');
  String get publishComment => _text('publishComment');
  String commentsLoadFailed(Object error) =>
      _withError('commentsLoadFailed', error);
  String get retryComments => _text('retryComments');
  String get noComments => _text('noComments');
  String get writeReview => _text('writeReview');
  String get editReview => _text('editReview');
  String get reviewLoadFailedTapRetry => _text('reviewLoadFailedTapRetry');
  String get reviewContentHint => _text('reviewContentHint');
  String uploadedCount(int count) => _withCount('uploadedCount', count);
  String get uploading => _text('uploading');
  String get addImages => _text('addImages');
  String get spendAmount => _text('spendAmount');
  String get tagsLabel => _text('tagsLabel');
  String get tagsHint => _text('tagsHint');
  String get saveAndResubmit => _text('saveAndResubmit');
  String get publishReview => _text('publishReview');
  String get reviewingShop => _text('reviewingShop');
  String get scoreOverall => _text('scoreOverall');
  String get scoreTaste => _text('scoreTaste');
  String get scoreEnv => _text('scoreEnv');
  String get scoreService => _text('scoreService');
  String averageSpendLabel({required String amount}) =>
      _text('averageSpendLabel').replaceFirst('{amount}', amount);

  String replyToPreview({required String name, required String content}) =>
      _text(
        'replyToPreview',
      ).replaceFirst('{name}', name).replaceFirst('{content}', content);
  String likeCommentStats({required int likes, required int comments}) => _text(
    'likeCommentStats',
  ).replaceFirst('{likes}', '$likes').replaceFirst('{comments}', '$comments');
  String get loadMoreComments => _text('loadMoreComments');

  String get maxNineImages => _text('maxNineImages');
  String imagePickFailed(Object error) => _withError('imagePickFailed', error);
  String imageUploadFailed(Object error) =>
      _withError('imageUploadFailed', error);
  String get reviewUpdatedResubmitted => _text('reviewUpdatedResubmitted');
  String get reviewSubmittedPending => _text('reviewSubmittedPending');
  String saveFailed(Object error) => _withError('saveFailed', error);
  String get ratingPrompt => _text('ratingPrompt');
  String get ratingHint => _text('ratingHint');
  String get saySomethingUseful => _text('saySomethingUseful');
  String get reviewWritingHint => _text('reviewWritingHint');
  String get pleaseWriteRealExperience => _text('pleaseWriteRealExperience');
  String get onSitePhotos => _text('onSitePhotos');
  String get photosUploadHint => _text('photosUploadHint');
  String get spendAndTags => _text('spendAndTags');
  String get spendTagsHint => _text('spendTagsHint');
  String get enterNonNegativeAmount => _text('enterNonNegativeAmount');

  String get loginTitle => _text('loginTitle');
  String get loginHero => _text('loginHero');
  String get loginSubtitle => _text('loginSubtitle');
  String get passwordLogin => _text('passwordLogin');
  String get codeLogin => _text('codeLogin');
  String get emailOrPhone => _text('emailOrPhone');
  String get password => _text('password');
  String get verificationCode => _text('verificationCode');
  String get sendingCode => _text('sendingCode');
  String get sendCode => _text('sendCode');
  String get enterEmailOrPhone => _text('enterEmailOrPhone');
  String get enterEmailOrPhoneFirst => _text('enterEmailOrPhoneFirst');
  String get codeSent => _text('codeSent');
  String localCodeHint(String code) =>
      _text('localCodeHint').replaceFirst('{code}', code);
  String accountBannedHint(String account) =>
      _text('accountBannedHint').replaceFirst('{account}', account);
  String get submitBanAppeal => _text('submitBanAppeal');
  String get loginSuccess => _text('loginSuccess');
  String get loggingIn => _text('loggingIn');
  String get login => _text('login');
  String get registerAccount => _text('registerAccount');
  String get passwordResetPleaseLogin => _text('passwordResetPleaseLogin');
  String get forgotPassword => _text('forgotPassword');
  String get banAppeal => _text('banAppeal');
  String get registerTitle => _text('registerTitle');
  String get registerSubtitle => _text('registerSubtitle');
  String get nicknameOptional => _text('nicknameOptional');
  String get registerCode => _text('registerCode');
  String get setPassword => _text('setPassword');
  String get registering => _text('registering');
  String get registerAndLogin => _text('registerAndLogin');
  String get resetPasswordTitle => _text('resetPasswordTitle');
  String get resetPasswordSubtitle => _text('resetPasswordSubtitle');
  String get resetCode => _text('resetCode');
  String get newPassword => _text('newPassword');
  String get confirmNewPassword => _text('confirmNewPassword');
  String get resetting => _text('resetting');
  String get resetPassword => _text('resetPassword');
  String get banAppealTitle => _text('banAppealTitle');
  String get banAppealHero => _text('banAppealHero');
  String get banAppealSubtitle => _text('banAppealSubtitle');
  String get appealCode => _text('appealCode');
  String get appealReasonMin10 => _text('appealReasonMin10');
  String banReasonLabel(String value) =>
      _text('banReasonLabel').replaceFirst('{value}', value);
  String appealContentLabel(String value) =>
      _text('appealContentLabel').replaceFirst('{value}', value);
  String rejectReasonLabel(String value) =>
      _text('rejectReasonLabel').replaceFirst('{value}', value);
  String submittedAtLabel(String value) =>
      _text('submittedAtLabel').replaceFirst('{value}', value);
  String processedAtLabel(String value) =>
      _text('processedAtLabel').replaceFirst('{value}', value);
  String get submittingAppeal => _text('submittingAppeal');
  String get submitAppeal => _text('submitAppeal');
  String get querying => _text('querying');
  String get queryAppealProgress => _text('queryAppealProgress');
  String get backToLogin => _text('backToLogin');

  String codeSentRetry(int seconds) =>
      _text('codeSentRetry').replaceFirst('{seconds}', '$seconds');
  String get fillAccountCodePassword => _text('fillAccountCodePassword');
  String get fillAccountCodeNewPassword => _text('fillAccountCodeNewPassword');
  String get passwordsDoNotMatch => _text('passwordsDoNotMatch');
  String get authErrorInvalidCredentials =>
      _text('authErrorInvalidCredentials');
  String get authErrorAccountBanned => _text('authErrorAccountBanned');
  String get authErrorAccountRegistered => _text('authErrorAccountRegistered');
  String get authErrorAccountNotFound => _text('authErrorAccountNotFound');
  String get authErrorCodeInvalid => _text('authErrorCodeInvalid');
  String get authErrorInvalidEmail => _text('authErrorInvalidEmail');
  String get authErrorInvalidPhone => _text('authErrorInvalidPhone');
  String get authErrorCodeRateLimited => _text('authErrorCodeRateLimited');
  String get authErrorCodeSendUnavailable =>
      _text('authErrorCodeSendUnavailable');
  String get authErrorCodeVerifyUnavailable =>
      _text('authErrorCodeVerifyUnavailable');
  String get authErrorEmailAlreadyBound => _text('authErrorEmailAlreadyBound');
  String get authErrorPhoneAlreadyBound => _text('authErrorPhoneAlreadyBound');
  String get authErrorOldPasswordIncorrect =>
      _text('authErrorOldPasswordIncorrect');
  String get authErrorSamePasswordAsOld => _text('authErrorSamePasswordAsOld');
  String get authErrorCurrentUserNotFound =>
      _text('authErrorCurrentUserNotFound');
  String get authErrorSessionMissing => _text('authErrorSessionMissing');
  String get authErrorProfileNicknameTooLong =>
      _text('authErrorProfileNicknameTooLong');
  String get authErrorProfileAvatarTooLong =>
      _text('authErrorProfileAvatarTooLong');
  String get authErrorProfileSignatureTooLong =>
      _text('authErrorProfileSignatureTooLong');
  String get authErrorProfileUpdateFailed =>
      _text('authErrorProfileUpdateFailed');
  String get registerHero => _text('registerHero');
  String get resetPasswordHero => _text('resetPasswordHero');
  String get fillAccountAndCodeBeforeAppeal =>
      _text('fillAccountAndCodeBeforeAppeal');
  String get appealReasonTooShort => _text('appealReasonTooShort');
  String appealSubmitted(int id) =>
      _text('appealSubmitted').replaceFirst('{id}', '$id');
  String get queryNeedsAccountAndCode => _text('queryNeedsAccountAndCode');
  String appealProgressRefreshed(int id) =>
      _text('appealProgressRefreshed').replaceFirst('{id}', '$id');
  String appealStatusTitle({required int id, required String status}) => _text(
    'appealStatusTitle',
  ).replaceFirst('{id}', '$id').replaceFirst('{status}', status);
  String get appealApprovedHint => _text('appealApprovedHint');
  String get banAppealErrorAccountNotFound =>
      _text('banAppealErrorAccountNotFound');
  String get banAppealErrorAccountNotBanned =>
      _text('banAppealErrorAccountNotBanned');
  String get banAppealErrorPendingExists =>
      _text('banAppealErrorPendingExists');
  String get banAppealErrorNoRecord => _text('banAppealErrorNoRecord');
  String get banAppealErrorStatusChanged =>
      _text('banAppealErrorStatusChanged');
  String get banAppealErrorCodeInvalid => _text('banAppealErrorCodeInvalid');
  String get banAppealErrorInvalidEmail => _text('banAppealErrorInvalidEmail');
  String get banAppealErrorInvalidPhone => _text('banAppealErrorInvalidPhone');

  String get privacySubtitle => _text('privacySubtitle');
  String privacyLoadFailed(Object error) =>
      _withError('privacyLoadFailed', error);
  String get exportModuleAccount => _text('exportModuleAccount');
  String get exportModuleReviews => _text('exportModuleReviews');
  String get exportModuleOrders => _text('exportModuleOrders');
  String get exportModulePosts => _text('exportModulePosts');
  String get exportModuleReservations => _text('exportModuleReservations');
  String get exportModuleFavorites => _text('exportModuleFavorites');
  String get exportModuleFollows => _text('exportModuleFollows');
  String get exportModuleMessages => _text('exportModuleMessages');
  String get exportModuleCircles => _text('exportModuleCircles');
  String get exportModuleTopics => _text('exportModuleTopics');
  String get privacyExportHint => _text('privacyExportHint');
  String get noExportTasks => _text('noExportTasks');
  String get agreementRecordsHint => _text('agreementRecordsHint');
  String get noAgreementRecords => _text('noAgreementRecords');
  String get deviceLifecycleHint => _text('deviceLifecycleHint');
  String get noRegisteredDevices => _text('noRegisteredDevices');
  String loadMoreExportTasksFailed(Object error) =>
      _withError('loadMoreExportTasksFailed', error);
  String get agreementRecorded => _text('agreementRecorded');
  String agreementRecordFailed(Object error) =>
      _withError('agreementRecordFailed', error);
  String get deviceDeactivated => _text('deviceDeactivated');
  String deviceDeactivateFailed(Object error) =>
      _withError('deviceDeactivateFailed', error);
  String exportSaved(String path) =>
      _text('exportSaved').replaceFirst('{path}', path);
  String exportDownloadFailed(Object error) =>
      _withError('exportDownloadFailed', error);
  String get selectExportModule => _text('selectExportModule');
  String get exportTaskCreated => _text('exportTaskCreated');
  String createExportFailed(Object error) =>
      _withError('createExportFailed', error);
  String get deleteRequestCanceled => _text('deleteRequestCanceled');
  String cancelDeleteFailed(Object error) =>
      _withError('cancelDeleteFailed', error);
  String get privacyErrorExportLimitReached =>
      _text('privacyErrorExportLimitReached');
  String get privacyErrorExportUnavailable =>
      _text('privacyErrorExportUnavailable');
  String get privacyErrorExportMissing => _text('privacyErrorExportMissing');
  String get privacyErrorDeleteTaskPending =>
      _text('privacyErrorDeleteTaskPending');
  String get privacyErrorDeleteTaskCannotCancel =>
      _text('privacyErrorDeleteTaskCannotCancel');
  String get privacyErrorDeleteTaskCancelFailed =>
      _text('privacyErrorDeleteTaskCancelFailed');
  String get privacyErrorDeleteTaskMissing =>
      _text('privacyErrorDeleteTaskMissing');
  String get fillAccountAndDeleteReason => _text('fillAccountAndDeleteReason');
  String get codeNotFilled => _text('codeNotFilled');
  String get passwordNotFilled => _text('passwordNotFilled');
  String get deleteEnteredCoolingOff => _text('deleteEnteredCoolingOff');
  String submitDeleteFailed(Object error) =>
      _withError('submitDeleteFailed', error);
  String get fillBoundAccountFirst => _text('fillBoundAccountFirst');
  String sendDeleteCodeFailed(Object error) =>
      _withError('sendDeleteCodeFailed', error);
  String get privacyDeleteErrorBoundAccountOnly =>
      _text('privacyDeleteErrorBoundAccountOnly');
  String get privacyDeleteErrorNoPassword =>
      _text('privacyDeleteErrorNoPassword');
  String get privacyDeleteErrorWrongPassword =>
      _text('privacyDeleteErrorWrongPassword');
  String createdAtLabel(String time) =>
      _text('createdAtLabel').replaceFirst('{time}', time);
  String expiresAtLabel(String time) =>
      _text('expiresAtLabel').replaceFirst('{time}', time);
  String reasonLabel(String value) =>
      _text('reasonLabel').replaceFirst('{value}', value);
  String coolingOffDeadline(String value) =>
      _text('coolingOffDeadline').replaceFirst('{value}', value);
  String get verifyByCode => _text('verifyByCode');
  String get verifyByPassword => _text('verifyByPassword');
  String get boundAccount => _text('boundAccount');
  String get deleteVerificationCode => _text('deleteVerificationCode');
  String get currentLoginPassword => _text('currentLoginPassword');
  String get deleteReason => _text('deleteReason');
  String coolingOffIntro(int days) =>
      _text('coolingOffIntro').replaceFirst('{days}', '$days');
  String get accountSettingsSubtitleLong =>
      _text('accountSettingsSubtitleLong');
  String accountProfileLoadFailed(Object error) =>
      _withError('accountProfileLoadFailed', error);
  String get nickname => _text('nickname');
  String get avatarUrl => _text('avatarUrl');
  String get gender => _text('gender');
  String get genderUnknown => _text('genderUnknown');
  String get genderMale => _text('genderMale');
  String get genderFemale => _text('genderFemale');
  String get signature => _text('signature');
  String emailLabel(String value) =>
      _text('emailLabel').replaceFirst('{value}', value);
  String phoneLabel(String value) =>
      _text('phoneLabel').replaceFirst('{value}', value);
  String get unbound => _text('unbound');
  String get email => _text('email');
  String get phone => _text('phone');
  String get bindVerificationCode => _text('bindVerificationCode');
  String get oldPassword => _text('oldPassword');
  String get expertApplicationSubmitted => _text('expertApplicationSubmitted');
  String expertStatusLoadFailed(Object error) =>
      _withError('expertStatusLoadFailed', error);
  String reviewedAtLabel(String value) =>
      _text('reviewedAtLabel').replaceFirst('{value}', value);
  String effectiveStartLabel(String value) =>
      _text('effectiveStartLabel').replaceFirst('{value}', value);
  String effectiveEndLabel(String value) =>
      _text('effectiveEndLabel').replaceFirst('{value}', value);
  String get expertReasonHint => _text('expertReasonHint');
  String get expertPendingHint => _text('expertPendingHint');
  String get expertApprovedHint => _text('expertApprovedHint');
  String get expertStatusNotApplied => _text('expertStatusNotApplied');
  String get expertStatusPendingReview => _text('expertStatusPendingReview');
  String get expertStatusApproved => _text('expertStatusApproved');
  String get expertStatusRejected => _text('expertStatusRejected');
  String get expertReasonRequired => _text('expertReasonRequired');
  String get expertReasonTooLong => _text('expertReasonTooLong');
  String get expertErrorPendingExists => _text('expertErrorPendingExists');
  String get expertErrorAlreadyApproved => _text('expertErrorAlreadyApproved');
  String get localExpertBadge => _text('localExpertBadge');
  String get verifiedMerchantBadge => _text('verifiedMerchantBadge');
  String get expertCertificationApprovedNotice =>
      _text('expertCertificationApprovedNotice');
  String get expertCertificationRejectedNotice =>
      _text('expertCertificationRejectedNotice');
  String get expertCertificationUpdatedNotice =>
      _text('expertCertificationUpdatedNotice');
  String get applicationReason => _text('applicationReason');
  String get growthRecordsErrorSessionMissing =>
      _text('growthRecordsErrorSessionMissing');
  String growthRecordsLoadFailed(Object error) =>
      _withError('growthRecordsLoadFailed', error);
  String get noGrowthRecords => _text('noGrowthRecords');
  String refreshGrowthRecordsFailed(Object error) =>
      _withError('refreshGrowthRecordsFailed', error);
  String get growthTypeValue => _text('growthTypeValue');
  String get growthTypePoints => _text('growthTypePoints');
  String get growthActionReviewCreate => _text('growthActionReviewCreate');
  String get growthActionReviewLiked => _text('growthActionReviewLiked');
  String get growthActionReviewImage => _text('growthActionReviewImage');
  String get growthActionOrderComplete => _text('growthActionOrderComplete');
  String get growthRewardReviewCreate => _text('growthRewardReviewCreate');
  String get growthRewardReviewLiked => _text('growthRewardReviewLiked');
  String get growthRewardReviewImage => _text('growthRewardReviewImage');
  String get growthRewardOrderComplete => _text('growthRewardOrderComplete');
  String balanceAfterLabel(Object value) =>
      _text('balanceAfterLabel').replaceFirst('{value}', '$value');
  String get privacyHero => _text('privacyHero');
  String exportDailyLimit(int count) =>
      _text('exportDailyLimit').replaceFirst('{count}', '$count');
  String exportFileRetention(int hours) =>
      _text('exportFileRetention').replaceFirst('{hours}', '$hours');
  String get canCancelBeforeDeadline => _text('canCancelBeforeDeadline');
  String get creatingExport => _text('creatingExport');
  String get recordingAcceptance => _text('recordingAcceptance');
  String get deactivatingDevice => _text('deactivatingDevice');
  String exportTaskTitle(Object id) =>
      _text('exportTaskTitle').replaceFirst('{id}', '$id');
  String get downloadZip => _text('downloadZip');
  String get downloadingZip => _text('downloadingZip');
  String get exportStatusPending => _text('exportStatusPending');
  String get exportStatusProcessing => _text('exportStatusProcessing');
  String get exportStatusReady => _text('exportStatusReady');
  String get exportStatusExpired => _text('exportStatusExpired');
  String get exportStatusFailed => _text('exportStatusFailed');
  String get exportStatusCanceled => _text('exportStatusCanceled');
  String get deleteStatusPendingConfirm => _text('deleteStatusPendingConfirm');
  String get deleteStatusCoolingOff => _text('deleteStatusCoolingOff');
  String get deleteStatusProcessing => _text('deleteStatusProcessing');
  String get deleteStatusCompleted => _text('deleteStatusCompleted');
  String get deleteStatusCanceled => _text('deleteStatusCanceled');
  String get deleteStatusRejected => _text('deleteStatusRejected');
  String get cancellingDelete => _text('cancellingDelete');
  String get cookieMarketingNotice => _text('cookieMarketingNotice');
  String lastActiveAt(String time) =>
      _text('lastActiveAt').replaceFirst('{time}', time);
  String expertCertificationStatusLabel(int status, {String? fallback}) {
    return switch (status) {
      0 => expertStatusNotApplied,
      1 => expertStatusPendingReview,
      2 => expertStatusApproved,
      3 => expertStatusRejected,
      _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
    };
  }

  String certificationBadgeLabel({String? code, String? fallback}) {
    final normalizedCode = code?.trim();
    if (normalizedCode != null && normalizedCode.isNotEmpty) {
      return switch (normalizedCode) {
        'local_expert' => localExpertBadge,
        'verified_merchant' => verifiedMerchantBadge,
        _ => fallback != null && fallback.isNotEmpty ? fallback : '',
      };
    }
    return switch (fallback) {
      '本地达人' || '在地達人' || 'Local expert' => localExpertBadge,
      '认证商户' || '認證商戶' || 'Verified merchant' => verifiedMerchantBadge,
      final value when value != null && value.isNotEmpty => value,
      _ => '',
    };
  }

  String growthRecordTypeLabel(int type, {String? fallback}) {
    return switch (type) {
      1 => growthTypeValue,
      2 => growthTypePoints,
      _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
    };
  }

  String growthRecordActionLabel(String action, {String? fallback}) {
    final localizedFallback = _growthRecordActionLabelFromFallback(fallback);
    if (localizedFallback != null) return localizedFallback;
    return switch (action) {
      'review_create' => growthActionReviewCreate,
      'review_liked' => growthActionReviewLiked,
      'review_image' => growthActionReviewImage,
      'order_complete' => growthActionOrderComplete,
      _ => fallback != null && fallback.isNotEmpty ? fallback : action,
    };
  }

  String growthRecordRemarkLabel(String action, {String? fallback}) {
    final localizedFallback = _growthRecordRemarkLabelFromFallback(fallback);
    if (localizedFallback != null) return localizedFallback;
    return switch (action) {
      'review_create' => growthRewardReviewCreate,
      'review_liked' => growthRewardReviewLiked,
      'review_image' => growthRewardReviewImage,
      'order_complete' => growthRewardOrderComplete,
      _ => fallback != null && fallback.isNotEmpty ? fallback : action,
    };
  }

  String? _growthRecordActionLabelFromFallback(String? fallback) {
    return switch (fallback) {
      '发布点评' || '發布評論' || 'Review published' => growthActionReviewCreate,
      '点评获赞' || '評論獲讚' || 'Review liked' => growthActionReviewLiked,
      '带图点评' || '帶圖評論' || 'Photo review' => growthActionReviewImage,
      '完成订单' || '完成訂單' || 'Order completed' => growthActionOrderComplete,
      final value when value != null && value.isNotEmpty => value,
      _ => null,
    };
  }

  String? _growthRecordRemarkLabelFromFallback(String? fallback) {
    return switch (fallback) {
      '发点评奖励' ||
      '發評論獎勵' ||
      'Review publishing reward' => growthRewardReviewCreate,
      '点评获赞奖励' || '評論獲讚獎勵' || 'Review like reward' => growthRewardReviewLiked,
      '带图点评奖励' || '帶圖評論獎勵' || 'Photo review reward' => growthRewardReviewImage,
      '完成订单奖励' ||
      '完成訂單獎勵' ||
      'Order completion reward' => growthRewardOrderComplete,
      final value when value != null && value.isNotEmpty => value,
      _ => null,
    };
  }

  String exportModuleLabel(String module) {
    return switch (module) {
      'account' => exportModuleAccount,
      'reviews' => exportModuleReviews,
      'orders' => exportModuleOrders,
      'posts' => exportModulePosts,
      'reservations' => exportModuleReservations,
      'favorites' => exportModuleFavorites,
      'follows' => exportModuleFollows,
      'messages' => exportModuleMessages,
      'circles' => exportModuleCircles,
      'topics' => exportModuleTopics,
      _ => module,
    };
  }

  String privacyExportTaskStatusLabel(int status, {String? fallback}) {
    return switch (status) {
      0 => exportStatusPending,
      1 => exportStatusProcessing,
      2 => exportStatusReady,
      3 => exportStatusExpired,
      4 => exportStatusFailed,
      5 => exportStatusCanceled,
      _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
    };
  }

  String privacyDeleteTaskStatusLabel(int status, {String? fallback}) {
    return switch (status) {
      0 => deleteStatusPendingConfirm,
      1 => deleteStatusCoolingOff,
      2 => deleteStatusProcessing,
      3 => deleteStatusCompleted,
      4 => deleteStatusCanceled,
      5 => deleteStatusRejected,
      _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
    };
  }

  String auditStatusLabel({int? status, String? fallback}) {
    if (status != null) {
      return switch (status) {
        0 => expertStatusPendingReview,
        1 => expertStatusApproved,
        2 => expertStatusRejected,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '待审核' || '待審核' || 'Pending review' => expertStatusPendingReview,
      '审核通过' || '審核通過' || '已通过' || '已通過' || 'Approved' => expertStatusApproved,
      '审核驳回' || '審核駁回' || '已驳回' || '已駁回' || 'Rejected' => expertStatusRejected,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String banAppealStatusLabel({int? status, String? fallback}) {
    if (status != null) {
      return switch (status) {
        0 => expertStatusPendingReview,
        1 => expertStatusApproved,
        2 => expertStatusRejected,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '待审核' || '待審核' || 'Pending review' => expertStatusPendingReview,
      '已通过' || '已通過' || 'Approved' => expertStatusApproved,
      '已驳回' || '已駁回' || 'Rejected' => expertStatusRejected,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String payStatusLabel({int? status, String? fallback}) {
    if (status != null) {
      return switch (status) {
        0 => payPending,
        1 => payPaid,
        2 => payRefunded,
        3 => payPartialRefund,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '待支付' || '待付款' || 'Pending payment' => payPending,
      '已支付' || 'Paid' => payPaid,
      '已退款' || 'Refunded' => payRefunded,
      '部分退款' || 'Partially refunded' => payPartialRefund,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String couponStatusLabel({int? status, String? fallback}) {
    if (status != null) {
      return switch (status) {
        1 => couponPending,
        2 => couponUsed,
        3 => couponExpired,
        4 => couponRefunded,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '待使用' || 'Pending use' => couponPending,
      '已使用' || 'Used' => couponUsed,
      '已过期' || '已過期' || 'Expired' => couponExpired,
      '已退款' || 'Refunded' => couponRefunded,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String refundStatusLabel({int? status, String? fallback}) {
    if (status != null) {
      return switch (status) {
        0 => refundStatusPending,
        1 => refundStatusApproved,
        2 => refundStatusRejected,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '待审核' ||
      '待審核' ||
      '申请中' ||
      '申請中' ||
      'Pending review' ||
      'Refund requested' => refundStatusPending,
      '退款成功' || 'Refunded' || 'Refund successful' => refundStatusApproved,
      '已驳回' || '已駁回' || 'Rejected' => refundStatusRejected,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String reservationStatusLabel({int? status, String? fallback}) {
    if (status != null) {
      return switch (status) {
        0 => reservationPending,
        1 => reservationConfirmed,
        2 => reservationArrived,
        3 => reservationUserCanceled,
        4 => reservationMerchantRejected,
        5 => reservationNoShow,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '待确认' || '待確認' || 'Pending' => reservationPending,
      '已确认' || '已確認' || 'Confirmed' => reservationConfirmed,
      '已到店' || 'Arrived' => reservationArrived,
      '用户取消' || '使用者取消' || 'Canceled by user' => reservationUserCanceled,
      '商户拒绝' || '商家拒絕' || 'Rejected by merchant' => reservationMerchantRejected,
      '爽约' || 'No-show' => reservationNoShow,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String reservationConfirmModeLabel({int? mode, String? fallback}) {
    if (mode != null) {
      return switch (mode) {
        1 => reservationConfirmModeAuto,
        2 => reservationConfirmModeManual,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '自动确认' ||
      '自動確認' ||
      'Auto confirm' ||
      'Automatic confirmation' => reservationConfirmModeAuto,
      '人工确认' ||
      '人工確認' ||
      'Manual confirm' ||
      'Manual confirmation' => reservationConfirmModeManual,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String reservationTimelineActionLabel({int? actionType, String? fallback}) {
    if (actionType != null) {
      return switch (actionType) {
        1 => reservationActionCreated,
        2 => reservationActionMerchantConfirmed,
        3 => reservationActionMerchantRejected,
        4 => reservationActionUserCanceled,
        5 => reservationActionUserRescheduled,
        6 => reservationActionMerchantRescheduled,
        7 => reservationActionCheckedIn,
        8 => reservationActionMarkedNoShow,
        9 => reservationActionArrivalReminder,
        _ => fallback != null && fallback.isNotEmpty ? fallback : unknownStatus,
      };
    }
    return switch (fallback) {
      '创建预订' ||
      '建立預訂' ||
      'Created reservation' ||
      'Reservation created' => reservationActionCreated,
      '商户确认' ||
      '商家確認' ||
      'Merchant confirmed' ||
      'Confirmed by merchant' => reservationActionMerchantConfirmed,
      '商户拒绝' ||
      '商家拒絕' ||
      'Merchant rejected' ||
      'Rejected by merchant' => reservationActionMerchantRejected,
      '用户取消' ||
      '使用者取消' ||
      'Canceled by user' ||
      'Cancelled by user' => reservationActionUserCanceled,
      '用户改期' ||
      '使用者改期' ||
      'Rescheduled by user' => reservationActionUserRescheduled,
      '商户改期' ||
      '商家改期' ||
      'Rescheduled by merchant' => reservationActionMerchantRescheduled,
      '确认到店' || '確認到店' || 'Checked in' => reservationActionCheckedIn,
      '标记爽约' || '標記爽約' || 'Marked no-show' => reservationActionMarkedNoShow,
      '到店提醒' || 'Arrival reminder' => reservationActionArrivalReminder,
      final value when value != null && value.isNotEmpty => value,
      _ => unknownStatus,
    };
  }

  String reservationTimelineRemarkLabel({
    int? actionType,
    required String fallback,
  }) {
    if (fallback.isEmpty) return '';
    return switch (fallback) {
      '系统发送到店前 30 分钟提醒' => notificationTitleReservationReminderThirtyMinutes,
      '系统发送到店前 2 小时提醒' => notificationTitleReservationReminderTwoHours,
      '创建预订' ||
      '建立預訂' ||
      'Created reservation' ||
      'Reservation created' ||
      '商户确认' ||
      '商家確認' ||
      'Merchant confirmed' ||
      'Confirmed by merchant' ||
      '用户取消' ||
      '使用者取消' ||
      'Canceled by user' ||
      'Cancelled by user' ||
      '确认到店' ||
      '確認到店' ||
      'Checked in' ||
      '标记爽约' ||
      '標記爽約' ||
      'Marked no-show' => reservationTimelineActionLabel(
        actionType: actionType,
        fallback: fallback,
      ),
      _ => fallback,
    };
  }

  String get profileSaved => _text('profileSaved');
  String saveProfileFailed(Object error) =>
      _withError('saveProfileFailed', error);
  String fillTargetFirst(String target) =>
      _text('fillTargetFirst').replaceFirst('{target}', target);
  String codeSentWithLocal(String code) =>
      _text('codeSentWithLocal').replaceFirst('{code}', code);
  String sendCodeFailed(Object error) => _withError('sendCodeFailed', error);
  String get fillAccountAndCode => _text('fillAccountAndCode');
  String get accountBound => _text('accountBound');
  String bindFailed(Object error) => _withError('bindFailed', error);
  String get enterOldPassword => _text('enterOldPassword');
  String get enterNewPassword => _text('enterNewPassword');
  String get newPasswordsDoNotMatch => _text('newPasswordsDoNotMatch');
  String get passwordUpdated => _text('passwordUpdated');
  String updatePasswordFailed(Object error) =>
      _withError('updatePasswordFailed', error);
  String get accountSettingsHero => _text('accountSettingsHero');
  String get basicProfile => _text('basicProfile');
  String get accountBinding => _text('accountBinding');
  String get changePassword => _text('changePassword');
  String get saving => _text('saving');
  String get saveProfile => _text('saveProfile');
  String get binding => _text('binding');
  String get confirmBind => _text('confirmBind');
  String get updating => _text('updating');
  String get updatePassword => _text('updatePassword');
  String get hasPasswordHint => _text('hasPasswordHint');
  String get noPasswordHint => _text('noPasswordHint');

  String get dataExport => _text('dataExport');
  String get accountDeletion => _text('accountDeletion');
  String coolingOffDays(int days) =>
      _text('coolingOffDays').replaceFirst('{days}', '$days');
  String get createExportTask => _text('createExportTask');
  String get loadMoreExportTasks => _text('loadMoreExportTasks');
  String get agreementTrace => _text('agreementTrace');
  String get confirmPrivacyPolicy => _text('confirmPrivacyPolicy');
  String get confirmUserAgreement => _text('confirmUserAgreement');
  String get deviceManagement => _text('deviceManagement');
  String get deactivateThisDevice => _text('deactivateThisDevice');
  String get privacyPolicy => _text('privacyPolicy');
  String get userAgreement => _text('userAgreement');
  String get unknownAgreement => _text('unknownAgreement');
  String get unknownDevice => _text('unknownDevice');
  String deleteTaskTitle({required int id, required String status}) => _text(
    'deleteTaskTitle',
  ).replaceFirst('{id}', '$id').replaceFirst('{status}', status);
  String get cancelDeleteRequest => _text('cancelDeleteRequest');
  String get submitDeleteRequest => _text('submitDeleteRequest');
  String get sendDeleteCode => _text('sendDeleteCode');
  String localCodeOnly(String code) =>
      _text('localCodeOnly').replaceFirst('{code}', code);
  String get unknownStatus => _text('unknownStatus');

  String get deviceEnabled => _text('deviceEnabled');
  String get deviceDisabled => _text('deviceDisabled');
  String get deviceLoggedOut => _text('deviceLoggedOut');

  String get publicProfile => _text('publicProfile');
  String publicProfileLoadFailed(Object error) =>
      _withError('publicProfileLoadFailed', error);
  String get sendDirectMessage => _text('sendDirectMessage');
  String get loginToFollowUser => _text('loginToFollowUser');
  String get publicProfileErrorUserNotFound =>
      _text('publicProfileErrorUserNotFound');
  String get publicProfileErrorSessionMissing =>
      _text('publicProfileErrorSessionMissing');
  String get publicProfileErrorCannotFollowSelf =>
      _text('publicProfileErrorCannotFollowSelf');
  String loadMoreUsersFailed(Object error) =>
      _withError('loadMoreUsersFailed', error);
  String relationListLoadFailed(Object error) =>
      _withError('relationListLoadFailed', error);
  String get followers => _text('followers');
  String get followingUsers => _text('followingUsers');
  String get noRelationUsers => _text('noRelationUsers');
  String get userCollectionErrorSessionMissing =>
      _text('userCollectionErrorSessionMissing');
  String collectionLoadFailed(Object error) =>
      _withError('collectionLoadFailed', error);
  String get noCollectionData => _text('noCollectionData');
  String favoritedAt(String time) =>
      _text('favoritedAt').replaceFirst('{time}', time);
  String get postLabel => _text('postLabel');
  String get address => _text('address');
  String get shopDetail => _text('shopDetail');
  String shopDetailLoadFailed(Object error) =>
      _withError('shopDetailLoadFailed', error);
  String get openingHours => _text('openingHours');
  String favoriteActionFailed(Object error) =>
      _withError('favoriteActionFailed', error);
  String get shareCopied => _text('shareCopied');
  String get viewAll => _text('viewAll');
  String shopReviewsLoadFailed(Object error) =>
      _withError('shopReviewsLoadFailed', error);
  String get noPublicReviews => _text('noPublicReviews');
  String similarShopsLoadFailed(Object error) =>
      _withError('similarShopsLoadFailed', error);
  String get noSimilarShops => _text('noSimilarShops');
  String get sortLatest => _text('sortLatest');
  String get sortHottest => _text('sortHottest');
  String get sortBestRated => _text('sortBestRated');
  String get minScoreFour => _text('minScoreFour');
  String get withPhotosOnly => _text('withPhotosOnly');
  String get alreadyAtEnd => _text('alreadyAtEnd');
  String refreshBrowseHistoryFailed(Object error) =>
      _withError('refreshBrowseHistoryFailed', error);
  String loadMoreBrowseHistoryFailed(Object error) =>
      _withError('loadMoreBrowseHistoryFailed', error);
  String clearBrowseHistoryFailed(Object error) =>
      _withError('clearBrowseHistoryFailed', error);
  String deleteBrowseHistoryFailed(Object error) =>
      _withError('deleteBrowseHistoryFailed', error);
  String browseHistoryLoadFailed(Object error) =>
      _withError('browseHistoryLoadFailed', error);
  String get noBrowseHistory => _text('noBrowseHistory');
  String browseViewCount(int count) =>
      _text('browseViewCount').replaceFirst('{count}', '$count');
  String get deleteBrowseHistoryTooltip => _text('deleteBrowseHistoryTooltip');
  String get clearAll => _text('clearAll');
  String get postSubmittedForAudit => _text('postSubmittedForAudit');
  String get deletePost => _text('deletePost');
  String get deletePostConfirm => _text('deletePostConfirm');
  String get postDeleted => _text('postDeleted');
  String postEditorLoadFailed(Object error) =>
      _withError('postEditorLoadFailed', error);
  String publishToCircle(String name) =>
      _text('publishToCircle').replaceFirst('{name}', name);
  String get circlePostNeedsAudit => _text('circlePostNeedsAudit');
  String get titleLabel => _text('titleLabel');
  String get bodyLabel => _text('bodyLabel');
  String get topicsCommaSeparated => _text('topicsCommaSeparated');
  String get submitForAudit => _text('submitForAudit');
  String get postDetail => _text('postDetail');
  String postLoadFailed(Object error) => _withError('postLoadFailed', error);
  String get reposted => _text('reposted');
  String get unreposted => _text('unreposted');
  String repostFailed(Object error) => _withError('repostFailed', error);
  String get reportPost => _text('reportPost');
  String reportSubmitFailed(Object error) =>
      _withError('reportSubmitFailed', error);
  String get cancelReply => _text('cancelReply');
  String get saySomethingUsefulShort => _text('saySomethingUsefulShort');
  String likeCountLabel(int count) => _withCount('likeCountLabel', count);
  String replyingToUser(String name) =>
      _text('replyingToUser').replaceFirst('{name}', name);
  String get simplifiedChinese => _text('simplifiedChinese');
  String get traditionalChinese => _text('traditionalChinese');
  String get englishLanguage => _text('englishLanguage');

  String get noSignature => _text('noSignature');
  String get reviewsMetric => _text('reviewsMetric');
  String get noFollowers => _text('noFollowers');
  String get noFollowing => _text('noFollowing');
  String levelFollowersMeta({required int level, required int count}) => _text(
    'levelFollowersMeta',
  ).replaceFirst('{level}', '$level').replaceFirst('{count}', '$count');
  String shopHash(Object id) => _text('shopHash').replaceFirst('{id}', '$id');
  String postHash(Object id) => _text('postHash').replaceFirst('{id}', '$id');
  String recordHash(Object id) =>
      _text('recordHash').replaceFirst('{id}', '$id');
  String get shopLabel => _text('shopLabel');

  String get unfavoritePost => _text('unfavoritePost');
  String get favoritePost => _text('favoritePost');
  String unrepostWithCount(int count) => _withCount('unrepostWithCount', count);
  String repostWithCount(int count) => _withCount('repostWithCount', count);
  String get editPost => _text('editPost');
  String get publishPost => _text('publishPost');
  String get pleaseEnterTitle => _text('pleaseEnterTitle');
  String get pleaseEnterBody => _text('pleaseEnterBody');
  String postSaveFailed(Object error) => _withError('postSaveFailed', error);

  String get unfavoriteShop => _text('unfavoriteShop');
  String get favoriteShop => _text('favoriteShop');
  String get favoriteStatusLoading => _text('favoriteStatusLoading');
  String get sharing => _text('sharing');
  String get shareShop => _text('shareShop');
  String get shopReviewsSection => _text('shopReviewsSection');
  String get similarShopsSection => _text('similarShopsSection');

  String get retryReviews => _text('retryReviews');
  String get retryRecommendations => _text('retryRecommendations');
  String statusWithRedeemability(String status, bool usable) =>
      '$status · ${usable ? redeemable : notRedeemable}';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'zh', 'en'}.contains(locale.languageCode.toLowerCase());

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations.forLocale(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
