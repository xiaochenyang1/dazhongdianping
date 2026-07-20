import { reactive, readonly } from 'vue'
import type { Region } from '@/types/browse'

const CITY_STORAGE_KEY = 'dzdp:city-id'
const REGION_STORAGE_KEY = 'dzdp:region'

const savedCityId = localStorage.getItem(CITY_STORAGE_KEY)
const savedRegion = localStorage.getItem(REGION_STORAGE_KEY)

const state = reactive<{
  region: Region
  cityId?: number
}>({
  region: savedRegion === 'EU' ? 'EU' : 'CN',
  cityId: savedCityId ? Number(savedCityId) : undefined,
})
const readonlyState = readonly(state)

function setRegion(region: Region) {
  state.region = region
  localStorage.setItem(REGION_STORAGE_KEY, region)
}

function setCityId(cityId?: number) {
  state.cityId = cityId
  if (cityId == null) {
    localStorage.removeItem(CITY_STORAGE_KEY)
    return
  }
  localStorage.setItem(CITY_STORAGE_KEY, String(cityId))
}

export function useAppContext() {
  return {
    state: readonlyState,
    setRegion,
    setCityId,
  }
}
