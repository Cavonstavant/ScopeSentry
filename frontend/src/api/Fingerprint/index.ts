import request from '@/axios'
import type { fingerprintData, fingerprintRespData } from './types'

interface fingerprintDataResponse {
  list: fingerprintData[]
  total: number
}
export const getFingerprintDataApi = (
  search: string,
  pageIndex: number,
  pageSize: number
): Promise<IResponse<fingerprintDataResponse>> => {
  return request.post({ url: '/api/fingerprint/data', data: { search, pageIndex, pageSize } })
}

export const addFingerprintDataApi = (content: string): Promise<IResponse<fingerprintRespData>> => {
  return request.post({
    url: '/api/fingerprint/add',
    data: { content }
  })
}

export const updateFingerprintDataApi = (
  id: string,
  content: string
): Promise<IResponse<fingerprintRespData>> => {
  return request.post({
    url: '/api/fingerprint/update',
    data: { id, content }
  })
}

export const deleteFingerprintDataApi = (
  ids: string[]
): Promise<IResponse<fingerprintRespData>> => {
  return request.post({ url: '/api/fingerprint/delete', data: { ids } })
}

interface VersionResponse {
  version: string
}

export const getFingerprintVersionApi = (): Promise<IResponse<VersionResponse>> => {
  return request.get({ url: '/api/fingerprint/version' })
}

interface CountByUpdateTimeResponse {
  count: number
}

export const getCountByUpdateTimeApi = (
  _updateTime: string
): Promise<IResponse<CountByUpdateTimeResponse>> => {
  // Remote fingerprint API removed
  return Promise.resolve({ count: 0 } as IResponse<CountByUpdateTimeResponse>)
}

interface FingerprintUpdateItem {
  id: string
  name: string
  content: string
  updateTime: string
}

interface GetFingerprintsByUpdateTimeResponse {
  data: {
    data: FingerprintUpdateItem[]
  }
}

// 获取需要更新的指纹列表（不需要认证）
export const getFingerprintsByUpdateTimeApi = (
  _updateTime: string
): Promise<GetFingerprintsByUpdateTimeResponse> => {
  // Remote fingerprint API removed
  return Promise.resolve({ data: { data: [] } } as GetFingerprintsByUpdateTimeResponse)
}

// 批量添加指纹
export const batchAddFingerprintApi = (
  items: FingerprintUpdateItem[]
): Promise<IResponse<fingerprintRespData>> => {
  return request.post({
    url: '/api/fingerprint/batch-add',
    data: { items }
  })
}
