export type EnglishCount = number | string | null | undefined

export function isSingularEnglishCount(count: EnglishCount) {
  if (typeof count === 'number') return count === 1
  return typeof count === 'string' && count.trim() !== '' && Number(count) === 1
}

export function formatEnglishCount(
  count: EnglishCount,
  singular: string,
  plural = `${singular}s`,
) {
  return `${count ?? '—'} ${isSingularEnglishCount(count) ? singular : plural}`
}
