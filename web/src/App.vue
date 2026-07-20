<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import AppHeader from '@/components/AppHeader.vue'
import AuthDialog from '@/components/AuthDialog.vue'
import { useUserSession } from '@/composables/useUserSession'
import { fetchCurrentUser } from '@/services/auth'

const { state, setCurrentUser, clearSession, setInitializing } = useUserSession()

onMounted(async () => {
  if (!state.accessToken) {
    return
  }

  setInitializing(true)
  try {
    const profile = await fetchCurrentUser()
    setCurrentUser(profile)
  } catch {
    clearSession()
  } finally {
    setInitializing(false)
  }
})
</script>

<template>
  <div class="app-shell">
    <div class="app-shell__ambient" aria-hidden="true">
      <span class="app-shell__glow app-shell__glow--one"></span>
      <span class="app-shell__glow app-shell__glow--two"></span>
      <span class="app-shell__glow app-shell__glow--three"></span>
      <span class="app-shell__grid"></span>
    </div>
    <AppHeader />
    <main class="page-container">
      <RouterView />
    </main>
    <AuthDialog />
  </div>
</template>
