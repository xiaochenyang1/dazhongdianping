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
    'noMatchingPlaces': '没有匹配的门店',
    'loading': '加载中...',
    'loadMore': '加载更多',
    'loadMoreShopsFailed': '加载更多门店失败：{error}',
    'discoveryFailed': '搜索发现加载失败：{error}',
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
    'noPublicRanks': '当前区域暂无公开榜单',
    'shopCount': '{count} 家门店',
    'topShop': '榜首 {name}',
    'rankDetailLoadFailed': '榜单详情加载失败：{error}',
    'rankNoShops': '该榜单暂无门店',
    'activityDetailTitle': '活动详情',
    'refreshActivitiesFailed': '刷新活动失败：{error}',
    'activitiesLoadFailed': '活动加载失败：{error}',
    'noOnlineActivities': '当前区域暂无上线活动',
    'resourceCount': '{count} 个资源',
    'activityDetailLoadFailed': '活动详情加载失败：{error}',
    'activityNoItems': '该活动暂无资源项',
    'cannotOpenExternalLink': '无法打开外部链接',
    'openTargetFailed': '{target}打开失败：{error}',
    'targetDeal': '团购',
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
    'reload': '重新加载',
    'refresh': '刷新',
    'noUnreadNotifications': '暂无未读消息',
    'noNotifications': '暂无消息',
    'continueFindUnread': '继续查找未读消息',
    'unreadBadge': '未读',
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
    'topicSevenDayStats':
        '7 天：{posts} 帖 · {likes} 赞 · {comments} 评论',
    'topicFollowMeta': '{followers} 人关注 · {posts} 篇公开帖子',
    'topicFollowerCount': '{count} 人关注',
    'followStatusUpdateFailed': '关注状态更新失败：{error}',
    'followed': '已关注',
    'followTopic': '关注话题',
    'publicPosts': '公开帖子',
    'postsLoadFailed': '帖子加载失败：{error}',
    'noPublicPostsHere': '这里还没有公开帖子。',
    'loadMoreCirclesFailed': '加载更多圈子失败：{error}',
    'circlesLoadFailed': '圈子加载失败：{error}',
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
    'loadMoreReservationsFailed': '加载更多预订失败：{error}',
    'reservationsLoadFailed': '预订加载失败：{error}',
    'noReservationsForFilter': '当前筛选下暂无预订',
    'reservationListMeta': '{no}\n{time} · {people} 人 · {status}',
    'onlineReservation': '在线预订',
    'selectSlotFirst': '请选择时段',
    'reservationCreated': '预订 {no} 已创建：{status}',
    'reservationFailed': '预订失败：{error}',
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
    'auditRemarkLabel': '审核备注：{remark}',
    'merchantReplyLabel': '商家回复：{reply}',
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
    'registerHero': '加入欧洲华人生活圈',
    'resetPasswordHero': '重新设置登录密码',
    'fillAccountAndCodeBeforeAppeal': '先填好账号和验证码，再提交申诉',
    'appealReasonTooShort': '申诉理由至少写 10 个字，把误封的情况说清楚',
    'appealSubmitted': '申诉 #{id} 已提交，运营会尽快复核',
    'queryNeedsAccountAndCode': '查询进度也需要账号和一条新的验证码',
    'appealProgressRefreshed': '已刷新申诉 #{id} 的最新进度',
    'appealStatusTitle': '申诉 #{id} · {status}',
    'appealApprovedHint': '申诉已通过，账号已解封。请返回登录页继续使用。',
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
    'noMatchingPlaces': '沒有符合條件的店家',
    'loading': '載入中...',
    'loadMore': '載入更多',
    'loadMoreShopsFailed': '載入更多店家失敗：{error}',
    'discoveryFailed': '搜尋探索載入失敗：{error}',
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
    'noPublicRanks': '目前區域暫無公開排行榜',
    'shopCount': '{count} 家店家',
    'topShop': '榜首 {name}',
    'rankDetailLoadFailed': '排行榜詳情載入失敗：{error}',
    'rankNoShops': '此排行榜暫無店家',
    'activityDetailTitle': '活動詳情',
    'refreshActivitiesFailed': '重新整理活動失敗：{error}',
    'activitiesLoadFailed': '活動載入失敗：{error}',
    'noOnlineActivities': '目前區域暫無上線活動',
    'resourceCount': '{count} 個資源',
    'activityDetailLoadFailed': '活動詳情載入失敗：{error}',
    'activityNoItems': '此活動暫無資源項',
    'cannotOpenExternalLink': '無法開啟外部連結',
    'openTargetFailed': '{target}開啟失敗：{error}',
    'targetDeal': '團購',
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
    'reload': '重新載入',
    'refresh': '重新整理',
    'noUnreadNotifications': '暫無未讀訊息',
    'noNotifications': '暫無訊息',
    'continueFindUnread': '繼續尋找未讀訊息',
    'unreadBadge': '未讀',
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
    'topicSevenDayStats':
        '7 天：{posts} 帖 · {likes} 讚 · {comments} 評論',
    'topicFollowMeta': '{followers} 人追蹤 · {posts} 篇公開貼文',
    'topicFollowerCount': '{count} 人追蹤',
    'followStatusUpdateFailed': '追蹤狀態更新失敗：{error}',
    'followed': '已追蹤',
    'followTopic': '追蹤話題',
    'publicPosts': '公開貼文',
    'postsLoadFailed': '貼文載入失敗：{error}',
    'noPublicPostsHere': '這裡還沒有公開貼文。',
    'loadMoreCirclesFailed': '載入更多圈子失敗：{error}',
    'circlesLoadFailed': '圈子載入失敗：{error}',
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
    'loadMoreReservationsFailed': '載入更多預訂失敗：{error}',
    'reservationsLoadFailed': '預訂載入失敗：{error}',
    'noReservationsForFilter': '目前篩選下暫無預訂',
    'reservationListMeta': '{no}\n{time} · {people} 人 · {status}',
    'onlineReservation': '線上預訂',
    'selectSlotFirst': '請選擇時段',
    'reservationCreated': '預訂 {no} 已建立：{status}',
    'reservationFailed': '預訂失敗：{error}',
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
    'auditRemarkLabel': '審核備註：{remark}',
    'merchantReplyLabel': '商家回覆：{reply}',
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
    'registerHero': '加入歐洲華人生活圈',
    'resetPasswordHero': '重新設定登入密碼',
    'fillAccountAndCodeBeforeAppeal': '先填好帳號和驗證碼，再提交申訴',
    'appealReasonTooShort': '申訴理由至少寫 10 個字，把誤封的情況說清楚',
    'appealSubmitted': '申訴 #{id} 已提交，運營會盡快覆核',
    'queryNeedsAccountAndCode': '查詢進度也需要帳號和一條新的驗證碼',
    'appealProgressRefreshed': '已刷新申訴 #{id} 的最新進度',
    'appealStatusTitle': '申訴 #{id} · {status}',
    'appealApprovedHint': '申訴已通過，帳號已解封。請返回登入頁繼續使用。',
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
    'noMatchingPlaces': 'No matching places',
    'loading': 'Loading...',
    'loadMore': 'Load more',
    'loadMoreShopsFailed': 'Could not load more places: {error}',
    'discoveryFailed': 'Could not load search discovery: {error}',
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
    'noPublicRanks': 'No public rankings in this region yet',
    'shopCount': '{count} places',
    'topShop': 'Top place: {name}',
    'rankDetailLoadFailed': 'Could not load ranking details: {error}',
    'rankNoShops': 'This ranking has no places yet',
    'activityDetailTitle': 'Activity details',
    'refreshActivitiesFailed': 'Could not refresh activities: {error}',
    'activitiesLoadFailed': 'Could not load activities: {error}',
    'noOnlineActivities': 'No live activities in this region yet',
    'resourceCount': '{count} resources',
    'activityDetailLoadFailed': 'Could not load activity details: {error}',
    'activityNoItems': 'This activity has no resources yet',
    'cannotOpenExternalLink': 'Could not open the external link',
    'openTargetFailed': 'Could not open {target}: {error}',
    'targetDeal': 'deal',
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
    'reload': 'Reload',
    'refresh': 'Refresh',
    'noUnreadNotifications': 'No unread notifications',
    'noNotifications': 'No notifications yet',
    'continueFindUnread': 'Keep looking for unread',
    'unreadBadge': 'Unread',
    'loggingOut': 'Signing out...',
    'logout': 'Sign out',
    'profileLoadFailed': 'Could not load profile: {error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} points',
    'growthValueLabel': '{value} growth',
    'accountSettings': 'Account settings',
    'accountSettingsSubtitle': 'Profile, linked accounts, password',
    'localExpertCertification': 'Local expert certification',
    'localExpertCertificationSubtitle': 'Submit or resubmit a local expert application',
    'growthRecords': 'Growth history',
    'growthRecordsSubtitle':
        'Lv.{level} · growth {growth} · points {points}',
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
    'followStatusUpdateFailed': 'Could not update follow status: {error}',
    'followed': 'Following',
    'followTopic': 'Follow topic',
    'publicPosts': 'Public posts',
    'postsLoadFailed': 'Could not load posts: {error}',
    'noPublicPostsHere': 'No public posts here yet.',
    'loadMoreCirclesFailed': 'Could not load more circles: {error}',
    'circlesLoadFailed': 'Could not load circles: {error}',
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
    'refreshConversationsFailed': 'Could not refresh conversations: {error}',
    'loadMoreConversationsFailed': 'Could not load more conversations: {error}',
    'conversationsLoadFailed': 'Could not load conversations: {error}',
    'noDirectMessages':
        'No messages yet. Say hello from a public profile.',
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
    'loadMoreReservationsFailed': 'Could not load more reservations: {error}',
    'reservationsLoadFailed': 'Could not load reservations: {error}',
    'noReservationsForFilter': 'No reservations for this filter',
    'reservationListMeta': '{no}\n{time} · {people} guests · {status}',
    'onlineReservation': 'Book online',
    'selectSlotFirst': 'Please select a time slot',
    'reservationCreated': 'Reservation {no} created: {status}',
    'reservationFailed': 'Could not create reservation: {error}',
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
    'auditRemarkLabel': 'Audit note: {remark}',
    'merchantReplyLabel': 'Merchant reply: {reply}',
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
    'passwordResetPleaseLogin': 'Password reset. Sign in with the new password.',
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
    'registerHero': 'Join Chinese local life in Europe',
    'resetPasswordHero': 'Set a new sign-in password',
    'fillAccountAndCodeBeforeAppeal': 'Fill account and code before submitting',
    'appealReasonTooShort':
        'Write at least 10 characters explaining the mistaken ban',
    'appealSubmitted': 'Appeal #{id} submitted. Ops will review soon',
    'queryNeedsAccountAndCode': 'Progress checks also need account and a fresh code',
    'appealProgressRefreshed': 'Refreshed progress for appeal #{id}',
    'appealStatusTitle': 'Appeal #{id} · {status}',
    'appealApprovedHint':
        'Appeal approved and account unbanned. Return to sign in.',
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
      _text(key).replaceFirst('{error}', '$error');
  String _withCount(String key, int count) =>
      _text(key).replaceFirst('{count}', '$count');
  String _withName(String key, String name) =>
      _text(key).replaceFirst('{name}', name);

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
  String get noMatchingPlaces => _text('noMatchingPlaces');
  String get loading => _text('loading');
  String get loadMore => _text('loadMore');
  String loadMoreShopsFailed(Object error) =>
      _withError('loadMoreShopsFailed', error);
  String discoveryFailed(Object error) => _withError('discoveryFailed', error);
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
  String get noPublicRanks => _text('noPublicRanks');
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
  String resourceCount(int count) => _withCount('resourceCount', count);
  String activityDetailLoadFailed(Object error) =>
      _withError('activityDetailLoadFailed', error);
  String get activityNoItems => _text('activityNoItems');
  String get cannotOpenExternalLink => _text('cannotOpenExternalLink');
  String openTargetFailed(String target, Object error) => _text(
    'openTargetFailed',
  ).replaceFirst('{target}', target).replaceFirst('{error}', '$error');
  String get targetDeal => _text('targetDeal');
  String get targetTopic => _text('targetTopic');
  String get targetExternalLink => _text('targetExternalLink');
  String get targetResource => _text('targetResource');
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
  String get reload => _text('reload');
  String get refresh => _text('refresh');
  String get noUnreadNotifications => _text('noUnreadNotifications');
  String get noNotifications => _text('noNotifications');
  String get continueFindUnread => _text('continueFindUnread');
  String get unreadBadge => _text('unreadBadge');
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
  String topicsLoadFailed(Object error) => _withError('topicsLoadFailed', error);
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
  String followStatusUpdateFailed(Object error) =>
      _withError('followStatusUpdateFailed', error);
  String get followed => _text('followed');
  String get followTopic => _text('followTopic');
  String get publicPosts => _text('publicPosts');
  String postsLoadFailed(Object error) => _withError('postsLoadFailed', error);
  String get noPublicPostsHere => _text('noPublicPostsHere');
  String loadMoreCirclesFailed(Object error) =>
      _withError('loadMoreCirclesFailed', error);
  String circlesLoadFailed(Object error) =>
      _withError('circlesLoadFailed', error);
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
  String ordersLoadFailed(Object error) => _withError('ordersLoadFailed', error);
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
  String createOrderFailed(Object error) =>
      _withError('createOrderFailed', error);
  String orderCreatedOpenDetailFailed(String orderNo, Object error) => _text(
        'orderCreatedOpenDetailFailed',
      )
      .replaceFirst('{orderNo}', orderNo)
      .replaceFirst('{error}', '$error');
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
  String orderShopMeta({required String shop, required String orderNo}) => _text(
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
      _text('dealValidityRange')
          .replaceFirst('{start}', start)
          .replaceFirst('{end}', end);
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
      _text('reservationCreated')
          .replaceFirst('{no}', no)
          .replaceFirst('{status}', status);
  String reservationFailed(Object error) =>
      _withError('reservationFailed', error);
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
      _text('reservationTimePeople')
          .replaceFirst('{time}', time)
          .replaceFirst('{people}', '$people');
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
  String auditRemarkLabel(String remark) =>
      _text('auditRemarkLabel').replaceFirst('{remark}', remark);
  String merchantReplyLabel(String reply) =>
      _text('merchantReplyLabel').replaceFirst('{reply}', reply);
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

  String replyToPreview({required String name, required String content}) =>
      _text('replyToPreview')
          .replaceFirst('{name}', name)
          .replaceFirst('{content}', content);
  String likeCommentStats({required int likes, required int comments}) =>
      _text('likeCommentStats')
          .replaceFirst('{likes}', '$likes')
          .replaceFirst('{comments}', '$comments');
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
  String appealStatusTitle({required int id, required String status}) =>
      _text('appealStatusTitle')
          .replaceFirst('{id}', '$id')
          .replaceFirst('{status}', status);
  String get appealApprovedHint => _text('appealApprovedHint');
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
