import type { Region } from '@/types/browse'

export interface WebCommunityStrings {
  tag: 'zh-CN' | 'en'
  feed: {
    loadFailed: string; seoTitle: string; seoDescription: string; eyebrow: string; title: string; summary: string
    appGuidance: string; groups: string; topics: string
    likes: (count: number) => string; comments: (count: number) => string
  }
  circles: {
    loadFailed: string; seoTitle: string; seoDescription: string; detailSeoTitle: string; detailSeoDescription: string
    eyebrow: string; title: string; summary: string; official: string
    counts: (members: number, posts: number) => string
    likes: (count: number) => string; comments: (count: number) => string
  }
  post: {
    auditApproved: string; auditRejected: string; share: string; shareReady: string; shareFailed: string
    seoTitle: string; seoDescription: string; loadFailed: string; readOnly: string; commentsTitle: string
    likes: (count: number) => string; comments: (count: number) => string
    noComments: string; replyContext: (user: string, content: string) => string
  }
  topics: {
    loadFailed: string; seoTitle: string; seoDescription: (hot: boolean) => string; schemaDescription: string
    eyebrow: string; title: string; summary: string; switchAria: string; recommended: string; hot: string
    loading: string; top: (position: number) => string; rank: (position: number) => string
    recommendedMark: string; composition: (posts: number, likes: number, comments: number) => string
    audience: (followers: number, posts: number) => string; heat: (score: number) => string
    detailSeoTitle: string; detailSeoFallbackDescription: string
    detailSeoDescription: (followers: number, posts: number, name: string) => string
    publicTopic: string; followerCount: (count: number) => string; postCount: (count: number) => string
    heatLabel: string; sevenDay: string
    likes: (count: number) => string; comments: (count: number) => string
  }
}

const zhCn: WebCommunityStrings = {
  tag: 'zh-CN',
  feed: {
    loadFailed: '社区加载失败', seoTitle: '华人社区', seoDescription: '只读浏览欧洲华人攻略、探店和生活经验。',
    eyebrow: 'Community · 只读版', title: '欧洲华人的生活经验，不该散落在聊天记录里。',
    summary: 'PC 端负责浏览和搜索收录；发布、点赞、关注与私信留在 APP。',
    appGuidance: '下载 APP 参与互动、发布攻略和管理自己的帖子。', groups: '浏览官方圈子', topics: '查看话题广场与热榜', likes: (count) => `喜欢 ${count}`, comments: (count) => `评论 ${count}`,
  },
  circles: {
    loadFailed: '圈子加载失败', seoTitle: '官方圈子', seoDescription: '只读浏览当前区域官方社区圈子。',
    detailSeoTitle: '圈子详情', detailSeoDescription: '查看官方圈子资料和公开帖子。', eyebrow: 'Official Groups · 只读',
    title: '找到在同一座城市生活的人。', summary: '官方圈子按当前区域展示，加入和发布请使用 APP。', official: '官方圈子',
    counts: (members, posts) => `${members} 位成员 · ${posts} 篇帖子`, likes: (count) => `喜欢 ${count}`, comments: (count) => `评论 ${count}`,
  },
  post: {
    auditApproved: '平台已通过你的帖子，现已公开展示。', auditRejected: '平台未通过你的帖子，可到 APP「我的帖子」查看驳回原因并修改重提。',
    share: '分享', shareReady: '分享链接已准备好', shareFailed: '分享失败，请稍后重试', seoTitle: '社区帖子', seoDescription: '阅读公开社区帖子与评论。', loadFailed: '帖子加载失败', readOnly: 'PC 端现在还是只读；想互动就去 APP，别在这儿硬抠按钮。', commentsTitle: '公开评论', likes: (count) => `喜欢 ${count}`, comments: (count) => `评论 ${count}`, noComments: '这条帖子下面还没人开口。', replyContext: (user, content) => `回复 ${user}：${content}`,
  },
  topics: {
    loadFailed: '话题加载失败', seoTitle: '话题广场', seoDescription: (hot) => hot ? '浏览最近 7 天公开帖子、点赞与评论计算出的城市话题热榜。' : '浏览当前区域推荐话题与公开社区讨论。', schemaDescription: '浏览当前区域推荐话题与最近 7 天热榜。', eyebrow: 'CITY TOPIC INDEX · 只读', title: '城市里正在被反复谈起的事。', summary: '推荐是编辑选择，热榜按最近 7 天公开帖子、点赞与评论计算。参与关注和发帖请使用 APP。', switchAria: '话题榜单切换', recommended: '编辑推荐', hot: '最近 7 天热榜', loading: '正在整理当前区域的话题...', top: (position) => `TOP ${position}`, rank: (position) => String(position).padStart(2, '0'), recommendedMark: '编辑推荐', composition: (posts, likes, comments) => `${posts} 帖 · ${likes} 赞 · ${comments} 评论`, audience: (followers, posts) => `${followers} 人关注 · ${posts} 篇公开帖子`, heat: (score) => `热度 ${score}`, detailSeoTitle: '话题详情', detailSeoFallbackDescription: '查看话题热度构成和公开社区帖子。', detailSeoDescription: (followers, posts, name) => `${followers} 人关注，${posts} 篇公开帖子。${name} 的城市生活讨论与经验分享。`, publicTopic: 'PUBLIC TOPIC', followerCount: (count) => `${count} 人关注`, postCount: (count) => `${count} 篇公开帖子`, heatLabel: '7 DAY HEAT', sevenDay: '最近 7 天', likes: (count) => `赞 ${count}`, comments: (count) => `评论 ${count}`,
  },
}

const en: WebCommunityStrings = {
  tag: 'en',
  feed: {
    loadFailed: 'Could not load the community feed', seoTitle: 'Community', seoDescription: 'Browse public local guides, reviews and practical community posts.',
    eyebrow: 'Community · Read only', title: 'Local knowledge, collected in one public community.',
    summary: 'Browse and search on the web. Use the app to publish, like, follow or send messages.',
    appGuidance: 'Use the app to join conversations, publish guides and manage your posts.', groups: 'Browse official groups', topics: 'Explore topics and trends', likes: (count) => `${count} ${count === 1 ? 'like' : 'likes'}`, comments: (count) => `${count} ${count === 1 ? 'comment' : 'comments'}`,
  },
  circles: {
    loadFailed: 'Could not load groups', seoTitle: 'Official groups', seoDescription: 'Browse official community groups in the current region.',
    detailSeoTitle: 'Group details', detailSeoDescription: 'View official group information and public posts.', eyebrow: 'Official groups · Read only',
    title: 'Meet people living in the same city.', summary: 'Groups are scoped to your region. Use the app to join or publish.', official: 'Official group',
    counts: (members, posts) => `${members} ${members === 1 ? 'member' : 'members'} · ${posts} ${posts === 1 ? 'post' : 'posts'}`, likes: (count) => `${count} ${count === 1 ? 'like' : 'likes'}`, comments: (count) => `${count} ${count === 1 ? 'comment' : 'comments'}`,
  },
  post: {
    auditApproved: 'Your post was approved and is now public.', auditRejected: 'Your post was not approved. Open My posts in the app to see the reason and resubmit.',
    share: 'Share', shareReady: 'Share link is ready', shareFailed: 'Could not share this post. Please try again.', seoTitle: 'Community post', seoDescription: 'Read a public community post and its comments.', loadFailed: 'Could not load the post', readOnly: 'This web page is read-only. Use the app to interact with the community.', commentsTitle: 'Public comments', likes: (count) => `${count} ${count === 1 ? 'like' : 'likes'}`, comments: (count) => `${count} ${count === 1 ? 'comment' : 'comments'}`, noComments: 'No one has commented on this post yet.', replyContext: (user, content) => `Replying to ${user}: ${content}`,
  },
  topics: {
    loadFailed: 'Could not load topics', seoTitle: 'Topics', seoDescription: (hot) => hot ? 'Browse the city hot list calculated from public posts, likes and comments in the last seven days.' : 'Browse recommended topics and public community discussions in the current region.', schemaDescription: 'Browse recommended topics and the seven-day hot list in the current region.', eyebrow: 'CITY TOPIC INDEX · Read only', title: 'What people in the city keep talking about.', summary: 'Recommendations are editorial. The hot list uses public posts, likes and comments from the last seven days. Use the app to follow or publish.', switchAria: 'Topic list mode', recommended: 'Recommended', hot: 'Last 7 days', loading: 'Organising topics for this region...', top: (position) => `TOP ${position}`, rank: (position) => String(position).padStart(2, '0'), recommendedMark: 'Recommended', composition: (posts, likes, comments) => `${posts} ${posts === 1 ? 'post' : 'posts'} · ${likes} ${likes === 1 ? 'like' : 'likes'} · ${comments} ${comments === 1 ? 'comment' : 'comments'}`, audience: (followers, posts) => `${followers} ${followers === 1 ? 'follower' : 'followers'} · ${posts} public ${posts === 1 ? 'post' : 'posts'}`, heat: (score) => `Heat ${score}`, detailSeoTitle: 'Topic details', detailSeoFallbackDescription: 'View topic activity and public community posts.', detailSeoDescription: (followers, posts, name) => `${followers} ${followers === 1 ? 'follower' : 'followers'} and ${posts} public ${posts === 1 ? 'post' : 'posts'}. Discussions and local experience around ${name}.`, publicTopic: 'PUBLIC TOPIC', followerCount: (count) => `${count} ${count === 1 ? 'follower' : 'followers'}`, postCount: (count) => `${count} public ${count === 1 ? 'post' : 'posts'}`, heatLabel: '7 DAY HEAT', sevenDay: 'Last 7 days', likes: (count) => `${count} ${count === 1 ? 'like' : 'likes'}`, comments: (count) => `${count} ${count === 1 ? 'comment' : 'comments'}`,
  },
}

const STRINGS: Record<Region, WebCommunityStrings> = { CN: zhCn, EU: en }
export const communityStringsForRegion = (region: Region) => STRINGS[region]
export function localizeWebCommunityError(strings: WebCommunityStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN' || !/\p{Script=Han}/u.test(error.message)) return error.message || fallback
  return fallback
}
