<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchTopic, fetchTopicPosts, type PublicTopic } from '@/services/topic'
import type { CommunityPost } from '@/types/community'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { useAppContext } from '@/composables/useAppContext'
import { communityStringsForRegion, localizeWebCommunityError } from '@/core/web_community_localizations'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'

const props = defineProps<{ topicId: number }>()
const { state: appState } = useAppContext()
const copy = computed(() => communityStringsForRegion(appState.region))
const certificationCopy = computed(() => discoveryStringsForRegion(appState.region).shopCard)
const topic = ref<PublicTopic | null>(null)
const posts = ref<CommunityPost[]>([])
const error = ref('')
let requestSequence = 0

useSeoMeta(() => {
  const canonicalPath = `/topics/${props.topicId}`
  const currentTopic = topic.value
  if (!currentTopic) return { title: copy.value.topics.detailSeoTitle, description: copy.value.topics.detailSeoDescription(0, 0, ''), canonical: canonicalPath, robots: 'noindex,nofollow' }
  const canonical = absoluteSeoUrl(canonicalPath)
  return {
    title: `#${currentTopic.name}`,
    description: copy.value.topics.detailSeoDescription(currentTopic.followerCount, currentTopic.postCount, currentTopic.name),
    canonical: canonicalPath,
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name: currentTopic.name,
      description: copy.value.topics.audience(currentTopic.followerCount, currentTopic.postCount),
      url: canonical,
      about: { '@type': 'Thing', name: currentTopic.name },
      mainEntity: {
        '@type': 'ItemList',
        itemListElement: posts.value.map((post, index) => ({
          '@type': 'ListItem',
          position: index + 1,
          name: post.title,
          url: absoluteSeoUrl(`/community/posts/${post.id}`),
          description: toSeoDescription(post.content),
        })),
      },
    },
  }
})

watch(() => props.topicId, async (topicId) => {
  const request = ++requestSequence
  topic.value = null
  posts.value = []
  error.value = ''
  try {
    const [detail, page] = await Promise.all([fetchTopic(topicId), fetchTopicPosts(topicId)])
    if (request !== requestSequence) return
    topic.value = detail
    posts.value = page.list
  } catch (cause) {
    if (request === requestSequence) error.value = localizeWebCommunityError(copy.value, cause, copy.value.topics.loadFailed)
  }
}, { immediate: true })
</script>

<template>
  <section class="page-section topic-detail">
    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <template v-if="topic">
      <header class="detail-hero">
        <div>
          <p class="eyebrow">{{ topic.region }} · {{ copy.topics.publicTopic }}</p>
          <h1>#{{ topic.name }}</h1>
          <p>{{ copy.topics.followerCount(topic.followerCount) }} · {{ copy.topics.postCount(topic.postCount) }}</p>
        </div>
        <div class="heat-seal">
          <span>{{ copy.topics.heatLabel }}</span>
          <strong>{{ topic.hotScore }}</strong>
          <small>{{ copy.topics.composition(topic.postCount7d, topic.likeCount7d, topic.commentCount7d) }}</small>
        </div>
      </header>

      <div class="post-index">
        <article v-for="post in posts" :key="post.id" class="post-entry">
          <div class="post-meta">
            <span class="name-with-badge">
              <RouterLink :to="`/users/${post.userId}`">{{ post.userName }}</RouterLink>
              <span v-if="post.authorCertification" class="verified-badge verified-badge--compact">
                {{ certificationCopy.certificationLabel(post.authorCertification.code, post.authorCertification.label) }}
              </span>
            </span>
            <span>{{ formatWebDateTime(post.createdAt, copy.tag) }}</span>
          </div>
          <h2><RouterLink :to="`/community/posts/${post.id}`">{{ post.title }}</RouterLink></h2>
          <p>{{ post.content }}</p>
          <div class="post-foot">
            <span v-for="name in post.topics" :key="name">#{{ name }}</span>
            <small>{{ copy.topics.likes }} {{ post.likeCount }} · {{ copy.topics.comments }} {{ post.commentCount }}</small>
          </div>
        </article>
      </div>
    </template>
  </section>
</template>

<style scoped>
.topic-detail { color:#17201c; -webkit-font-smoothing:antialiased; }
.detail-hero { display:grid; grid-template-columns:minmax(0,1fr) 240px; gap:30px; align-items:center; padding:38px; border-radius:32px; background:#f2eee3; box-shadow:0 0 0 1px rgba(0,0,0,.055),0 20px 48px rgba(42,35,24,.09); }
.detail-hero h1 { margin:0; font-family:"Noto Serif SC","Source Han Serif SC",serif; font-size:clamp(40px,6vw,70px); letter-spacing:-.05em; text-wrap:balance; }
.detail-hero p { color:#59645c; font-variant-numeric:tabular-nums; }
.heat-seal { display:grid; gap:6px; padding:22px; border-radius:24px; background:#17201c; color:#fff; text-align:center; box-shadow:0 16px 32px rgba(23,32,28,.2); }
.heat-seal span { color:#efb394; font-size:11px; font-weight:900; letter-spacing:.13em; }
.heat-seal strong { font-size:48px; font-variant-numeric:tabular-nums; }
.heat-seal small { color:#d8ded9; font-variant-numeric:tabular-nums; }
.post-index { display:grid; gap:14px; margin-top:24px; }
.post-entry { padding:25px; border-radius:22px; background:#fff; box-shadow:0 0 0 1px rgba(0,0,0,.055),0 12px 30px rgba(28,38,32,.06); }
.post-meta,.post-foot { display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; color:#7a837c; font-size:13px; }
.post-meta a,.post-entry h2 a { color:inherit; text-decoration:none; }
.post-meta a:hover,.post-entry h2 a:hover { color:#c6532e; }
.post-entry h2 { margin:14px 0 8px; font-family:"Noto Serif SC","Source Han Serif SC",serif; font-size:27px; }
.post-entry>p { color:#4e5951; text-wrap:pretty; }
.post-foot span { color:#355c48; font-weight:800; }
.post-foot small { font-variant-numeric:tabular-nums; }
@media(max-width:720px){.detail-hero{grid-template-columns:1fr;padding:26px}.heat-seal{max-width:280px}}
</style>
