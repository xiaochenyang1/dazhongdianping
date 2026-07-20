import { reactive } from 'vue'
import type { AdminProfile, Region } from '@/types/admin'

const TOKEN_STORAGE_KEY = 'dzdp:admin-token'
const PROFILE_STORAGE_KEY = 'dzdp:admin-profile'
const PERMISSIONS_STORAGE_KEY = 'dzdp:admin-permissions'
const REGIONS_STORAGE_KEY = 'dzdp:admin-regions'
const REGION_STORAGE_KEY = 'dzdp:admin-region'

function parseProfile(rawValue: string | null): AdminProfile | undefined {
  if (!rawValue) {
    return undefined
  }

  try {
    const parsed = JSON.parse(rawValue) as AdminProfile
    if (typeof parsed.id === 'number' && typeof parsed.account === 'string' && typeof parsed.name === 'string') {
      return parsed
    }
  } catch {
    localStorage.removeItem(PROFILE_STORAGE_KEY)
  }

  return undefined
}

function parsePermissions(rawValue: string | null) {
  if (!rawValue) {
    return [] as string[]
  }

  try {
    const parsed = JSON.parse(rawValue) as string[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    localStorage.removeItem(PERMISSIONS_STORAGE_KEY)
    return [] as string[]
  }
}

function parseRegions(rawValue: string | null): Region[] {
  if (!rawValue) {
    return []
  }

  try {
    const parsed = JSON.parse(rawValue) as string[]
    if (!Array.isArray(parsed)) {
      return []
    }
    return normalizedRegions(parsed)
  } catch {
    localStorage.removeItem(REGIONS_STORAGE_KEY)
    return []
  }
}

function normalizedRegions(regions: readonly string[]): Region[] {
  return [...new Set(regions.filter((region): region is Region => region === 'CN' || region === 'EU'))]
}

const state = reactive<{
  token?: string
  profile?: AdminProfile
  permissions: string[]
  regions: Region[]
  region: Region
}>({
  token: localStorage.getItem(TOKEN_STORAGE_KEY) ?? undefined,
  profile: parseProfile(localStorage.getItem(PROFILE_STORAGE_KEY)),
  permissions: parsePermissions(localStorage.getItem(PERMISSIONS_STORAGE_KEY)),
  regions: parseRegions(localStorage.getItem(REGIONS_STORAGE_KEY)),
  region: localStorage.getItem(REGION_STORAGE_KEY) === 'EU' ? 'EU' : 'CN',
})

function setSession(token: string, profile: AdminProfile, permissions: string[], regions: Region[]) {
  state.token = token
  localStorage.setItem(TOKEN_STORAGE_KEY, token)
  updateIdentity({ profile, permissions, regions })
}

function updateIdentity(identity: { profile: AdminProfile; permissions: string[]; regions: Region[] }) {
  state.profile = identity.profile
  state.permissions = [...new Set(identity.permissions)]
  state.regions = normalizedRegions(identity.regions)

  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(identity.profile))
  localStorage.setItem(PERMISSIONS_STORAGE_KEY, JSON.stringify(state.permissions))

  if (state.regions.length === 0) {
    localStorage.removeItem(REGIONS_STORAGE_KEY)
    return
  }

  localStorage.setItem(REGIONS_STORAGE_KEY, JSON.stringify(state.regions))
  if (!state.regions.includes(state.region)) {
    setRegion(state.regions[0])
  }
}

function clearSession() {
  state.token = undefined
  state.profile = undefined
  state.permissions = []
  state.regions = []

  localStorage.removeItem(TOKEN_STORAGE_KEY)
  localStorage.removeItem(PROFILE_STORAGE_KEY)
  localStorage.removeItem(PERMISSIONS_STORAGE_KEY)
  localStorage.removeItem(REGIONS_STORAGE_KEY)
}

function setRegion(region: Region) {
  state.region = region
  localStorage.setItem(REGION_STORAGE_KEY, region)
}

export function useAdminSession() {
  return {
    state,
    setSession,
    updateIdentity,
    clearSession,
    setRegion,
    hasPermission: (permission: string) => state.permissions.includes(permission),
  }
}
