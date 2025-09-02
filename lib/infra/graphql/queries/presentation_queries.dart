// Query para buscar dados do PinMapPresentation
const String getPinMapDataQuery = r'''
query GetPinMapData($routeId: ID!) {
  getPinMapData(routeId: $routeId) {
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

// Query para buscar dados do ImageCarouselPresentation
const String getCarouselDataQuery = r'''
query GetCarouselData($routeId: ID!) {
  getCarouselData(routeId: $routeId) {
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

// Query para buscar dados do FloorPlanPresentation
const String getFloorPlanDataQuery = r'''
query GetFloorPlanData($routeId: ID!) {
  getFloorPlanData(routeId: $routeId) {
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

// Query para buscar todas as presentations de uma rota
const String getAllPresentationsQuery = r'''
query GetAllPresentations($routeId: ID!) {
  getAllPresentations(routeId: $routeId) {
    pinMapData {
      id
      routeId
      backgroundImageUrl
      pins {
        id
        title
      }
      updatedAt
    }
    carouselData {
      id
      routeId
      imageUrls
      videoUrl
      updatedAt
    }
    floorPlanData {
      id
      routeId
      floors {
        id
        number
      }
      apartments {
        id
        number
      }
      updatedAt
    }
  }
}
''';

// Query para verificar atualizações de presentations
const String checkPresentationsUpdatesQuery = r'''
query CheckPresentationsUpdates($routeId: ID!, $lastSyncTime: DateTime) {
  checkPresentationsUpdates(routeId: $routeId, lastSyncTime: $lastSyncTime) {
    hasUpdates
    pinMapUpdated
    carouselUpdated
    floorPlanUpdated
    lastModified
  }
}
''';