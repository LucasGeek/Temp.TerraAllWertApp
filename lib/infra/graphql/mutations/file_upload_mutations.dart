library;

/// Mutation para obter URL assinada para upload
const String getSignedUploadUrlMutation = r'''
mutation GetSignedUploadUrl($input: SignedUrlRequestInput!) {
  getSignedUploadUrl(input: $input) {
    uploadUrl
    minioPath
    fileId
    expiresAt
    headers {
      key
      value
    }
    error {
      message
      code
    }
  }
}
''';

/// Mutation para obter múltiplas URLs assinadas (batch)
const String getBatchSignedUploadUrlsMutation = r'''
mutation GetBatchSignedUploadUrls($inputs: [SignedUrlRequestInput!]!) {
  getBatchSignedUploadUrls(inputs: $inputs) {
    results {
      uploadUrl
      minioPath
      fileId
      expiresAt
      headers {
        key
        value
      }
      error {
        message
        code
      }
    }
    errors {
      fileId
      message
      code
    }
  }
}
''';

/// Mutation para confirmar upload concluído
const String confirmFileUploadMutation = r'''
mutation ConfirmFileUpload($input: ConfirmUploadInput!) {
  confirmFileUpload(input: $input) {
    success
    fileId
    minioPath
    publicUrl
    error {
      message
      code
    }
  }
}
''';

/// Query para obter URLs de download assinadas
const String getSignedDownloadUrlsQuery = r'''
query GetSignedDownloadUrls($input: DownloadUrlsRequestInput!) {
  getSignedDownloadUrls(input: $input) {
    urls {
      fileId
      downloadUrl
      expiresAt
    }
    zipUrl
    zipExpiresAt
    error {
      message
      code
    }
  }
}
''';

/// Mutation para solicitar sincronização completa (zip)
const String requestFullSyncMutation = r'''
mutation RequestFullSync($input: FullSyncRequestInput!) {
  requestFullSync(input: $input) {
    zipUrl
    expiresAt
    fileCount
    totalSize
    syncToken
    error {
      message
      code
    }
  }
}
''';

/// Query para verificar status de sincronização
const String getSyncStatusQuery = r'''
query GetSyncStatus($syncToken: String!) {
  getSyncStatus(syncToken: $syncToken) {
    status
    progress
    fileCount
    completedFiles
    error {
      message
      code
    }
  }
}
''';

/// Mutation para marcar arquivos como baixados (offline)
const String markFilesDownloadedMutation = r'''
mutation MarkFilesDownloaded($input: MarkDownloadedInput!) {
  markFilesDownloaded(input: $input) {
    success
    markedCount
    error {
      message
      code
    }
  }
}
''';

/// Query para obter metadados de sincronização
const String getSyncMetadataQuery = r'''
query GetSyncMetadata($routeId: String!) {
  getSyncMetadata(routeId: $routeId) {
    version
    lastModified
    fileCount
    totalSize
    checksums {
      fileId
      checksum
      lastModified
    }
    error {
      message
      code
    }
  }
}
''';

/// Tipos de input esperados pela API (documentação)
/*

input SignedUrlRequestInput {
  fileId: String!
  fileName: String!
  fileType: String! # "image", "video", "document"
  contentType: String! # MIME type
  fileSize: Int!
  routeId: String
  pinId: String
  metadata: JSON
}

input ConfirmUploadInput {
  fileId: String!
  minioPath: String!
  checksum: String!
  fileSize: Int!
  metadata: JSON
}

input DownloadUrlsRequestInput {
  routeId: String!
  fileIds: [String!]
  includeZip: Boolean
  expirationMinutes: Int # Default: 60
}

input FullSyncRequestInput {
  routeId: String!
  lastSyncTimestamp: DateTime
  includeTypes: [String!] # ["image", "video", "document"]
  compressionLevel: Int # 1-9, default: 6
}

input MarkDownloadedInput {
  routeId: String!
  fileIds: [String!]!
  downloadedAt: DateTime!
}

type SignedUrlResponse {
  uploadUrl: String!
  minioPath: String!
  fileId: String!
  expiresAt: DateTime!
  headers: [HeaderPair!]!
  error: ApiError
}

type HeaderPair {
  key: String!
  value: String!
}

type ConfirmUploadResponse {
  success: Boolean!
  fileId: String!
  minioPath: String!
  publicUrl: String
  error: ApiError
}

type DownloadUrlsResponse {
  urls: [DownloadUrl!]!
  zipUrl: String
  zipExpiresAt: DateTime
  error: ApiError
}

type DownloadUrl {
  fileId: String!
  downloadUrl: String!
  expiresAt: DateTime!
}

type FullSyncResponse {
  zipUrl: String!
  expiresAt: DateTime!
  fileCount: Int!
  totalSize: Int!
  syncToken: String!
  error: ApiError
}

type SyncStatusResponse {
  status: String! # "preparing", "ready", "expired", "error"
  progress: Float! # 0.0 to 1.0
  fileCount: Int!
  completedFiles: Int!
  error: ApiError
}

type SyncMetadataResponse {
  version: String!
  lastModified: DateTime!
  fileCount: Int!
  totalSize: Int!
  checksums: [FileChecksum!]!
  error: ApiError
}

type FileChecksum {
  fileId: String!
  checksum: String!
  lastModified: DateTime!
}

type ApiError {
  message: String!
  code: String!
}

*/