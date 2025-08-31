const String getTowersQuery = '''
  query GetTowers {
    towers {
      id
      name
      description
      address
      imageUrl
      createdAt
      updatedAt
      pavimentos {
        id
        towerId
        name
        floor
        floorPlanImageUrl
        description
        createdAt
        updatedAt
        apartments {
          id
          pavimentoId
          towerId
          number
          type {
            id
            name
            code
            description
            minArea
            maxArea
          }
          area
          bedrooms
          bathrooms
          price
          description
          imageUrls
          coordinates
          isAvailable
          createdAt
          updatedAt
        }
      }
    }
  }
''';

const String getTowerByIdQuery = '''
  query GetTowerById(\$id: ID!) {
    tower(id: \$id) {
      id
      name
      description
      address
      imageUrl
      createdAt
      updatedAt
      pavimentos {
        id
        towerId
        name
        floor
        floorPlanImageUrl
        description
        createdAt
        updatedAt
        apartments {
          id
          pavimentoId
          towerId
          number
          type {
            id
            name
            code
            description
            minArea
            maxArea
          }
          area
          bedrooms
          bathrooms
          price
          description
          imageUrls
          coordinates
          isAvailable
          createdAt
          updatedAt
        }
      }
    }
  }
''';

const String searchTowersQuery = '''
  query SearchTowers(\$query: String!) {
    searchTowers(query: \$query) {
      id
      name
      description
      address
      imageUrl
      createdAt
      updatedAt
    }
  }
''';