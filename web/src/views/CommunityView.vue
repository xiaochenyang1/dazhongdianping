<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchPosts } from '@/services/community'
import type { CommunityPost } from '@/types/community'
import { absoluteSeoUrl, toSeoDescription, useSeoMeta } from '@/composables/useSeoMeta'
import { useAppContext } from '@/composables/useAppContext'
import { communityStringsForRegion, localizeWebCommunityError } from '@/core/web_community_localizations'
import { discoveryStringsForRegion } from '@/core/web_discovery_localizations'
import { formatWebDateTime } from '@/core/web_localizations'

const posts = ref<CommunityPost[]>([])
const errorMessage = ref('')
const { state } = useAppContext()
const copy = computed(() => communityStringsForRegion(state.region))
const certificationCopy = computed(() => discoveryStringsForRegion(state.region).shopCard)
let requestSequence = 0

useSeoMeta(() => ({
  title: copy.value.feed.seoTitle,
  description: copy.value.feed.seoDescription,
  canonical: '/community',
  jsonLd: {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: copy.value.feed.seoTitle,
    description: copy.value.feed.seoDescription,
    url: absoluteSeoUrl('/community'),
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
}))

watch(
  () => state.region,
  async () => {
    const request = ++requestSequence
    posts.value = []
    errorMessage.value = ''
    try {
      const page = await fetchPosts()
      if (request !== requestSequence) return
      posts.value = page.list
    } catch (error) {
      if (request === requestSequence) {
        errorMessage.value = localizeWebCommunityError(copy.value, error, copy.value.feed.loadFailed)
      }
    }
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header"><div><p class="eyebrow">{{ copy.feed.eyebrow }}</p><h1>{{ copy.feed.title }}</h1><p>{{ copy.feed.summary }}</p></div></div>
    <p class="feedback">{{ copy.feed.appGuidance }} <RouterLink to="/groups">{{ copy.feed.groups }}</RouterLink> · <RouterLink to="/topics">{{ copy.feed.topics }}</RouterLink></p>
    <p v-if="errorMessage" class="feedback is-error">{{errorMessage}}</p>
    <div class="rank-list">
      <article v-for="post in posts" :key="post.id" class="content-card rank-item">
        <div class="rank-item__body">
          <p class="eyebrow name-with-badge">
            <RouterLink :to="`/users/${post.userId}`">{{ post.userName }}</RouterLink>
            <span v-if="post.authorCertification" class="verified-badge verified-badge--compact">
              {{ certificationCopy.certificationLabel(post.authorCertification.code, post.authorCertification.label) }}
            </span>
            <span>· {{ formatWebDateTime(post.createdAt, copy.tag) }}</span>
          </p>
          <h2><RouterLink :to="`/community/posts/${post.id}`">{{ post.title }}</RouterLink></h2>
          <p>{{ post.content }}</p>
          <div class="tag-row"><span v-for="topic in post.topics" :key="topic">#{{ topic }}</span></div>
          <small>{{ copy.feed.likes(post.likeCount) }} · {{ copy.feed.comments(post.commentCount) }}</small>
        </div>
      </article>
    </div>
  </section>
</template>
