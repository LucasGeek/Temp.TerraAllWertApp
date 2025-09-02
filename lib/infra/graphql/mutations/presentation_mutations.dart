// ========== PinMapPresentation Mutations ==========

// Mutation para criar ou atualizar PinMapData
const String upsertPinMapDataMutation = r'''
mutation UpsertPinMapData($input: PinMapDataInput!) {
  upsertPinMapData(input: $input) {
    id
    routeId
    backgroundImageUrl
    backgroundImagePath
    videoUrl
    videoPath
    videoTitle
    pins {
      id
      title
      description
      positionX
      positionY
      contentType
      imageUrls
      imagePaths
      createdAt
      updatedAt
    }
    createdAt
    updatedAt
  }
}
''';

// Mutation para adicionar/atualizar um pin
const String upsertMapPinMutation = r'''
mutation UpsertMapPin($routeId: ID!, $pin: MapPinInput!) {
  upsertMapPin(routeId: $routeId, pin: $pin) {
    id
    title
    description
    positionX
    positionY
    contentType
    imageUrls
    imagePaths
    createdAt
    updatedAt
  }
}
''';

// Mutation para deletar um pin
const String deleteMapPinMutation = r'''
mutation DeleteMapPin($routeId: ID!, $pinId: ID!) {
  deleteMapPin(routeId: $routeId, pinId: $pinId) {
    success
    message
  }
}
''';

// Mutation para deletar PinMapData
const String deletePinMapDataMutation = r'''
mutation DeletePinMapData($routeId: ID!) {
  deletePinMapData(routeId: $routeId) {
    success
    message
  }
}
''';

// ========== ImageCarouselPresentation Mutations ==========

// Mutation para criar ou atualizar CarouselData
const String upsertCarouselDataMutation = r'''
mutation UpsertCarouselData($input: CarouselDataInput!) {
  upsertCarouselData(input: $input) {
    id
    routeId
    imageUrls
    imagePaths
    videoUrl
    videoPath
    videoTitle
    textBox {
      id
      text
      fontSize
      fontColor
      backgroundColor
      positionX
      positionY
      createdAt
      updatedAt
    }
    mapConfig {
      id
      latitude
      longitude
      mapType
      zoom
      createdAt
      updatedAt
    }
    createdAt
    updatedAt
  }
}
''';

// Mutation para adicionar imagem ao carrossel
const String addCarouselImageMutation = r'''
mutation AddCarouselImage($routeId: ID!, $imageUrl: String!, $imagePath: String) {
  addCarouselImage(routeId: $routeId, imageUrl: $imageUrl, imagePath: $imagePath) {
    id
    imageUrls
    imagePaths
    updatedAt
  }
}
''';

// Mutation para remover imagem do carrossel
const String removeCarouselImageMutation = r'''
mutation RemoveCarouselImage($routeId: ID!, $imageUrl: String!) {
  removeCarouselImage(routeId: $routeId, imageUrl: $imageUrl) {
    id
    imageUrls
    imagePaths
    updatedAt
  }
}
''';

// Mutation para atualizar TextBox
const String updateTextBoxMutation = r'''
mutation UpdateTextBox($routeId: ID!, $textBox: TextBoxInput) {
  updateTextBox(routeId: $routeId, textBox: $textBox) {
    id
    text
    fontSize
    fontColor
    backgroundColor
    positionX
    positionY
    updatedAt
  }
}
''';

// Mutation para atualizar MapConfig
const String updateMapConfigMutation = r'''
mutation UpdateMapConfig($routeId: ID!, $mapConfig: MapConfigInput) {
  updateMapConfig(routeId: $routeId, mapConfig: $mapConfig) {
    id
    latitude
    longitude
    mapType
    zoom
    updatedAt
  }
}
''';

// Mutation para deletar CarouselData
const String deleteCarouselDataMutation = r'''
mutation DeleteCarouselData($routeId: ID!) {
  deleteCarouselData(routeId: $routeId) {
    success
    message
  }
}
''';

// ========== FloorPlanPresentation Mutations ==========

// Mutation para criar ou atualizar FloorPlanData
const String upsertFloorPlanDataMutation = r'''
mutation UpsertFloorPlanData($input: FloorPlanDataInput!) {
  upsertFloorPlanData(input: $input) {
    id
    routeId
    floors {
      id
      number
      floorPlanImageUrl
      floorPlanImagePath
      markers {
        id
        title
        description
        positionX
        positionY
        markerType
        apartmentId
        createdAt
        updatedAt
      }
      description
      createdAt
      updatedAt
    }
    apartments {
      id
      number
      area
      bedrooms
      suites
      sunPosition
      status
      floorPlanImageUrl
      floorPlanImagePath
      description
      createdAt
      updatedAt
    }
    createdAt
    updatedAt
  }
}
''';

// Mutation para adicionar/atualizar um Floor
const String upsertFloorMutation = r'''
mutation UpsertFloor($routeId: ID!, $floor: FloorInput!) {
  upsertFloor(routeId: $routeId, floor: $floor) {
    id
    number
    floorPlanImageUrl
    floorPlanImagePath
    markers {
      id
      title
      description
      positionX
      positionY
      markerType
      apartmentId
    }
    description
    createdAt
    updatedAt
  }
}
''';

// Mutation para deletar um Floor
const String deleteFloorMutation = r'''
mutation DeleteFloor($routeId: ID!, $floorId: ID!) {
  deleteFloor(routeId: $routeId, floorId: $floorId) {
    success
    message
  }
}
''';

// Mutation para adicionar/atualizar um Apartment
const String upsertApartmentMutation = r'''
mutation UpsertApartment($routeId: ID!, $apartment: ApartmentInput!) {
  upsertApartment(routeId: $routeId, apartment: $apartment) {
    id
    number
    area
    bedrooms
    suites
    sunPosition
    status
    floorPlanImageUrl
    floorPlanImagePath
    description
    createdAt
    updatedAt
  }
}
''';

// Mutation para deletar um Apartment
const String deleteApartmentMutation = r'''
mutation DeleteApartment($routeId: ID!, $apartmentId: ID!) {
  deleteApartment(routeId: $routeId, apartmentId: $apartmentId) {
    success
    message
  }
}
''';

// Mutation para adicionar/atualizar um FloorMarker
const String upsertFloorMarkerMutation = r'''
mutation UpsertFloorMarker($routeId: ID!, $floorId: ID!, $marker: FloorMarkerInput!) {
  upsertFloorMarker(routeId: $routeId, floorId: $floorId, marker: $marker) {
    id
    title
    description
    positionX
    positionY
    markerType
    apartmentId
    createdAt
    updatedAt
  }
}
''';

// Mutation para deletar um FloorMarker
const String deleteFloorMarkerMutation = r'''
mutation DeleteFloorMarker($routeId: ID!, $floorId: ID!, $markerId: ID!) {
  deleteFloorMarker(routeId: $routeId, floorId: $floorId, markerId: $markerId) {
    success
    message
  }
}
''';

// Mutation para deletar FloorPlanData
const String deleteFloorPlanDataMutation = r'''
mutation DeleteFloorPlanData($routeId: ID!) {
  deleteFloorPlanData(routeId: $routeId) {
    success
    message
  }
}
''';

// ========== Batch Sync Mutations ==========

// Mutation para sincronizar todas as presentations de uma vez
const String syncAllPresentationsMutation = r'''
mutation SyncAllPresentations($routeId: ID!, $data: AllPresentationsInput!) {
  syncAllPresentations(routeId: $routeId, data: $data) {
    success
    message
    syncedAt
  }
}
''';