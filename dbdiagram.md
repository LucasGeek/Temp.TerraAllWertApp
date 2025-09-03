Table sync_metadata {
  id integer [pk, increment, note: 'SQLite autoincrement']
  table_name varchar(100) [unique, not null, note: 'Nome da tabela sincronizada']
  last_sync_at timestamp [note: 'Última sincronização bem-sucedida']
  last_sync_version varchar(50) [note: 'Versão/token da última sync']
  sync_status sync_status [not null, default: 'pending', note: 'Status atual da sync']
  pending_changes_count integer [default: 0, note: 'Quantidade de mudanças pendentes']
  last_error text [note: 'Último erro de sincronização']
  retry_count integer [default: 0, note: 'Tentativas de retry']
  next_retry_at timestamp [note: 'Próxima tentativa de sync']
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp

  indexes {
    table_name [name: 'idx_sync_meta_table']
    sync_status [name: 'idx_sync_meta_status']
  }
}

Enum sync_status {
  idle [note: 'Sem mudanças']
  pending [note: 'Mudanças pendentes']
  syncing [note: 'Sincronizando']
  error [note: 'Erro na sincronização']
  conflict [note: 'Conflito detectado']
}

Table sync_queue {
  id integer [pk, increment, note: 'SQLite autoincrement']
  entity_type varchar(100) [not null, note: 'Tipo da entidade (tabela)']
  entity_local_id varchar(36) [not null, note: 'ID local da entidade']
  entity_remote_id varchar(36) [note: 'UUID do servidor (quando sincronizado)']
  operation sync_operation [not null, note: 'Tipo de operação']
  payload text [not null, note: 'JSON com dados da operação']
  sync_status queue_status [not null, default: 'pending']
  priority integer [default: 5, note: 'Prioridade (1-10, 1 = máxima)']
  attempt_count integer [default: 0, note: 'Tentativas de envio']
  last_attempt_at timestamp [note: 'Última tentativa']
  error_message text [note: 'Mensagem de erro se falhou']
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  synced_at timestamp [note: 'Quando foi sincronizado']

  indexes {
    (entity_type, entity_local_id) [name: 'idx_queue_entity']
    sync_status [name: 'idx_queue_status']
    priority [name: 'idx_queue_priority']
    created_at [name: 'idx_queue_created']
  }
}

Enum sync_operation {
  create
  update
  delete
  upsert
}

Enum queue_status {
  pending [note: 'Aguardando sync']
  processing [note: 'Processando']
  success [note: 'Sincronizado']
  failed [note: 'Falhou']
  conflict [note: 'Conflito']
  cancelled [note: 'Cancelado']
}

Table conflict_resolution {
  id integer [pk, increment]
  entity_type varchar(100) [not null]
  entity_local_id varchar(36) [not null]
  entity_remote_id varchar(36)
  local_data text [not null, note: 'JSON com dados locais']
  remote_data text [not null, note: 'JSON com dados do servidor']
  conflict_type conflict_type [not null]
  resolution_strategy resolution_strategy
  resolved_data text [note: 'JSON com dados resolvidos']
  resolved_at timestamp
  resolved_by varchar(36) [note: 'ID do usuário que resolveu']
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]

  indexes {
    (entity_type, entity_local_id) [name: 'idx_conflict_entity']
    resolved_at [name: 'idx_conflict_resolved']
  }
}

Enum conflict_type {
  concurrent_update [note: 'Atualização simultânea']
  deleted_remotely [note: 'Deletado no servidor']
  deleted_locally [note: 'Deletado localmente']
  version_mismatch [note: 'Versões diferentes']
}

Enum resolution_strategy {
  local_wins [note: 'Mantém versão local']
  remote_wins [note: 'Mantém versão remota']
  merge [note: 'Mescla as versões']
  manual [note: 'Resolução manual']
}

// ==========================================
// CORE TABLES - SIMPLIFIED FOR MOBILE
// ==========================================

Table enterprises {
  local_id varchar(36) [pk, note: 'UUID v7 local']
  remote_id varchar(36) [unique, note: 'UUID do servidor']
  title varchar(255) [not null]
  description text
  logo_file_local_id varchar(36) [note: 'FK para arquivo local']
  slug varchar(255) [unique, not null]
  // Endereço simplificado
  full_address text [note: 'Endereço completo formatado']
  latitude real [note: 'Coordenada latitude']
  longitude real [note: 'Coordenada longitude']
  status varchar(20) [not null, default: 'active']
  // Sync control
  sync_version integer [not null, default: 1, note: 'Versão para controle de conflitos']
  is_modified boolean [default: false, note: 'Modificado localmente?']
  last_modified_at timestamp [note: 'Última modificação local']
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_enterprises_remote']
    slug [name: 'idx_enterprises_slug']
    is_modified [name: 'idx_enterprises_modified']
  }
}

Table users {
  local_id varchar(36) [pk, note: 'UUID v7 local']
  remote_id varchar(36) [unique, note: 'UUID do servidor']
  enterprise_local_id varchar(36) [note: 'FK local para enterprise']
  name varchar(255) [not null]
  email varchar(255) [unique, not null]
  role varchar(20) [not null, default: 'visitor']
  avatar_url text [note: 'URL do avatar (cached)']
  // Auth tokens
  access_token text [note: 'Token de acesso (encrypted)']
  refresh_token text [note: 'Token de refresh (encrypted)']
  token_expires_at timestamp
  // Sync control
  is_current_user boolean [default: false, note: 'Usuário atual do app?']
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp

  indexes {
    remote_id [name: 'idx_users_remote']
    email [name: 'idx_users_email']
    is_current_user [name: 'idx_users_current']
  }
}

// ==========================================
// FILE MANAGEMENT - SIMPLIFIED
// ==========================================

Table cached_files {
  local_id varchar(36) [pk, note: 'UUID v7 local']
  remote_id varchar(36) [unique, note: 'UUID do servidor']
  file_type varchar(20) [not null]
  mime_type varchar(100) [not null]
  original_name varchar(255) [not null]
  cache_path text [note: 'Caminho no cache local']
  remote_url text [not null, note: 'URL remota original']
  file_size_bytes integer [not null]
  width integer [note: 'Para imagens/vídeos']
  height integer [note: 'Para imagens/vídeos']
  duration_seconds integer [note: 'Para vídeos']
  // Cache control
  cache_status cache_status [not null, default: 'pending']
  download_priority integer [default: 5, note: '1-10, 1 = máxima']
  download_progress real [default: 0, note: 'Progresso 0-100']
  last_accessed_at timestamp [note: 'Último acesso (para LRU cache)']
  expires_at timestamp [note: 'Quando expira o cache']
  retry_count integer [default: 0]
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]

  indexes {
    remote_id [name: 'idx_files_remote']
    cache_status [name: 'idx_files_status']
    download_priority [name: 'idx_files_priority']
    last_accessed_at [name: 'idx_files_lru']
  }
}

Enum cache_status {
  pending [note: 'Aguardando download']
  downloading [note: 'Baixando']
  cached [note: 'Em cache']
  failed [note: 'Falha no download']
  expired [note: 'Cache expirado']
}

// ==========================================
// MENU SYSTEM - OPTIMIZED FOR MOBILE
// ==========================================

Table menus {
  local_id varchar(36) [pk]
  remote_id varchar(36) [unique]
  enterprise_local_id varchar(36) [not null]
  parent_menu_local_id varchar(36) [note: 'Auto-referência para submenus']
  title varchar(255) [not null]
  slug varchar(255) [not null]
  screen_type varchar(20) [not null]
  menu_type varchar(20) [not null, default: 'standard']
  position integer [not null, default: 0]
  icon varchar(50)
  is_visible boolean [not null, default: true]
  path_hierarchy varchar(500) [note: 'Caminho materializado']
  depth_level integer [not null, default: 0]
  // Offline capabilities
  is_available_offline boolean [default: true, note: 'Disponível offline?']
  requires_sync boolean [default: false, note: 'Requer sync para acessar?']
  // Sync control
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_menus_remote']
    enterprise_local_id [name: 'idx_menus_enterprise']
    parent_menu_local_id [name: 'idx_menus_parent']
    position [name: 'idx_menus_position']
    is_modified [name: 'idx_menus_modified']
  }
}

// ==========================================
// FLOOR PLAN MODULE - MOBILE OPTIMIZED
// ==========================================

Table towers {
  local_id varchar(36) [pk]
  remote_id varchar(36) [unique]
  menu_local_id varchar(36) [not null]
  title varchar(255) [not null]
  description text
  total_floors integer [not null]
  units_per_floor integer
  position integer [not null, default: 0]
  // Sync control
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_towers_remote']
    menu_local_id [name: 'idx_towers_menu']
    is_modified [name: 'idx_towers_modified']
  }
}

Table floors {
  local_id varchar(36) [pk]
  remote_id varchar(36) [unique]
  tower_local_id varchar(36) [not null]
  floor_number integer [not null]
  floor_name varchar(100)
  banner_file_local_id varchar(36)
  floor_plan_file_local_id varchar(36)
  // Sync control
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_floors_remote']
    tower_local_id [name: 'idx_floors_tower']
    is_modified [name: 'idx_floors_modified']
  }
}

Table suites {
  local_id varchar(36) [pk]
  remote_id varchar(36) [unique]
  floor_local_id varchar(36) [not null]
  unit_number varchar(20) [not null]
  title varchar(255) [not null]
  description text
  position_x real
  position_y real
  area_sqm real [not null]
  bedrooms integer [not null, default: 0]
  suites_count integer [not null, default: 0]
  bathrooms integer [not null, default: 0]
  parking_spaces integer [default: 0]
  sun_position varchar(2)
  status varchar(20) [not null, default: 'available']
  floor_plan_file_local_id varchar(36)
  price real
  // Favoritos locais
  is_favorite boolean [default: false, note: 'Marcado como favorito?']
  favorited_at timestamp
  // Notas locais
  local_notes text [note: 'Anotações do usuário']
  // Sync control
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_suites_remote']
    floor_local_id [name: 'idx_suites_floor']
    status [name: 'idx_suites_status']
    is_favorite [name: 'idx_suites_favorite']
    is_modified [name: 'idx_suites_modified']
    (bedrooms, area_sqm, price) [name: 'idx_suites_search']
  }
}

// ==========================================
// CAROUSEL MODULE - MOBILE OPTIMIZED
// ==========================================

Table carousel_items {
  local_id varchar(36) [pk]
  remote_id varchar(36) [unique]
  menu_local_id varchar(36) [not null]
  item_type varchar(20) [not null]
  background_file_local_id varchar(36)
  position integer [not null, default: 0]
  title varchar(255)
  subtitle varchar(500)
  cta_text varchar(100)
  cta_url varchar(500)
  // Map data
  map_data text [note: 'JSON com dados do mapa']
  // Cache control
  preload_priority integer [default: 5, note: 'Prioridade de pré-carregamento']
  // Sync control
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_carousel_remote']
    menu_local_id [name: 'idx_carousel_menu']
    position [name: 'idx_carousel_position']
    is_modified [name: 'idx_carousel_modified']
  }
}

// ==========================================
// PIN MODULE - MOBILE OPTIMIZED
// ==========================================

Table pin_markers {
  local_id varchar(36) [pk]
  remote_id varchar(36) [unique]
  menu_local_id varchar(36) [not null]
  title varchar(255) [not null]
  description text
  position_x real [not null]
  position_y real [not null]
  icon_type varchar(50) [default: 'default']
  icon_color varchar(7) [default: '#FF0000']
  action_type varchar(20) [default: 'info']
  action_data text [note: 'JSON com dados da ação']
  is_visible boolean [default: true]
  // Interações locais
  was_viewed boolean [default: false, note: 'Usuário já visualizou?']
  viewed_at timestamp
  // Sync control
  sync_version integer [not null, default: 1]
  is_modified boolean [default: false]
  last_modified_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp
  deleted_at timestamp

  indexes {
    remote_id [name: 'idx_pins_remote']
    menu_local_id [name: 'idx_pins_menu']
    is_modified [name: 'idx_pins_modified']
  }
}

// ==========================================
// OFFLINE ANALYTICS - LOCAL TRACKING
// ==========================================

Table offline_events {
  id integer [pk, increment]
  event_type varchar(50) [not null, note: 'Tipo do evento']
  entity_type varchar(50) [note: 'Tipo da entidade relacionada']
  entity_local_id varchar(36) [note: 'ID local da entidade']
  event_data text [note: 'JSON com dados do evento']
  user_local_id varchar(36)
  session_id varchar(100) [not null]
  // Device info
  device_id varchar(100) [note: 'ID único do dispositivo']
  device_model varchar(100)
  os_version varchar(50)
  app_version varchar(20)
  // Network info
  network_type varchar(20) [note: 'wifi, 4g, 3g, offline']
  // Location
  latitude real
  longitude real
  // Sync status
  is_synced boolean [default: false]
  synced_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]

  indexes {
    event_type [name: 'idx_events_type']
    is_synced [name: 'idx_events_synced']
    created_at [name: 'idx_events_created']
    session_id [name: 'idx_events_session']
  }
}

// ==========================================
// USER PREFERENCES & SETTINGS
// ==========================================

Table user_preferences {
  id integer [pk, increment]
  user_local_id varchar(36) [unique, not null]
  // Sync preferences
  auto_sync_enabled boolean [default: true]
  sync_on_wifi_only boolean [default: false]
  sync_interval_minutes integer [default: 30]
  // Cache preferences
  max_cache_size_mb integer [default: 500]
  auto_cache_images boolean [default: true]
  auto_cache_videos boolean [default: false]
  cache_quality varchar(20) [default: 'medium', note: 'low, medium, high']
  // Offline preferences
  offline_mode_enabled boolean [default: false]
  download_favorites_only boolean [default: false]
  // UI preferences
  language varchar(5) [default: 'pt-BR']
  theme varchar(20) [default: 'system', note: 'light, dark, system']
  // Notification preferences
  push_enabled boolean [default: true]
  email_enabled boolean [default: true]
  // Data
  last_sync_prompt_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  updated_at timestamp

  indexes {
    user_local_id [name: 'idx_prefs_user']
  }
}

// ==========================================
// DOWNLOAD QUEUE - FOR OFFLINE CONTENT
// ==========================================

Table download_queue {
  id integer [pk, increment]
  resource_type varchar(50) [not null, note: 'file, tower, floor, etc']
  resource_local_id varchar(36) [not null]
  resource_url text [not null]
  priority integer [default: 5]
  status download_status [not null, default: 'pending']
  progress real [default: 0, note: '0-100']
  file_size_bytes integer
  downloaded_bytes integer [default: 0]
  retry_count integer [default: 0]
  max_retries integer [default: 3]
  error_message text
  started_at timestamp
  completed_at timestamp
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]

  indexes {
    status [name: 'idx_download_status']
    priority [name: 'idx_download_priority']
    resource_type [name: 'idx_download_type']
  }
}

Enum download_status {
  pending
  downloading
  paused
  completed
  failed
  cancelled
}

// ==========================================
// DATA VERSION CONTROL
// ==========================================

Table data_versions {
  id integer [pk, increment]
  entity_type varchar(100) [not null]
  entity_local_id varchar(36) [not null]
  version_number integer [not null]
  change_type varchar(20) [not null]
  changed_fields text [note: 'JSON array com campos alterados']
  old_values text [note: 'JSON com valores anteriores']
  new_values text [note: 'JSON com novos valores']
  changed_by_local_id varchar(36)
  device_id varchar(100)
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]

  indexes {
    (entity_type, entity_local_id) [name: 'idx_versions_entity']
    created_at [name: 'idx_versions_created']
  }
}

// ==========================================
// SEARCH CACHE - FOR OFFLINE SEARCH
// ==========================================

Table search_cache {
  id integer [pk, increment]
  search_type varchar(50) [not null, note: 'suites, towers, etc']
  search_query text [not null, note: 'Query ou filtros aplicados']
  search_hash varchar(64) [unique, not null, note: 'Hash SHA-256 da query']
  result_ids text [not null, note: 'JSON array com IDs dos resultados']
  result_count integer [not null]
  expires_at timestamp [not null]
  created_at timestamp [not null, default: `CURRENT_TIMESTAMP`]
  last_accessed_at timestamp

  indexes {
    search_hash [name: 'idx_search_hash']
    expires_at [name: 'idx_search_expires']
    search_type [name: 'idx_search_type']
  }
}

// ==========================================
// RELATIONSHIPS DOCUMENTATION
// ==========================================

// Note: Foreign keys are not enforced in SQLite by default
// All relationships use local_id references
// Remote_id fields maintain server relationships after sync
// Sync queue handles all server communication
// Conflict resolution manages data inconsistencies