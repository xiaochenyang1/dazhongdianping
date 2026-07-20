import { describe, expect, it, vi } from 'vitest'
import { apiGet } from '@/lib/http'
import { fetchPost, fetchPosts } from './community'

vi.mock('@/lib/http', () => ({ apiGet: vi.fn() }))

describe('community service', () => {
  it('loads the public post feed and detail', () => {
    fetchPosts(2, 12)
    expect(apiGet).toHaveBeenNthCalledWith(1, '/api/c/v1/posts', { page: 2, pageSize: 12 })
    fetchPost(7)
    expect(apiGet).toHaveBeenNthCalledWith(2, '/api/c/v1/posts/7')
  })
})
