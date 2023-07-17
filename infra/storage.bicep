@minLength(1)
@description('Primary location for all resources. Should specify an Azure region. e.g. `eastus2` ')
param location string

@description('Tags to be applied to all resources')
param tags object

@description('Abbreviations for objects')
param abbrs object

@minLength(1)
@maxLength(64)
@description('Unique token to be used in naming resources')
param resourceToken string


resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  tags: tags
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name:'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobServices
  name: 'images'
  properties: {
    publicAccess: 'Container'
  }
}

// create a cdn that points back to the storage account
resource cdnProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: '${abbrs.cdnProfiles}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }
}

var hostName = replace(replace(storageAccount.properties.primaryEndpoints.blob,'https://', ''),'/', '')

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = {
  parent: cdnProfile
  name: '${abbrs.cdnProfilesEndpoints}${resourceToken}'
  location: location
  tags: tags
  properties: {
    origins: [
      {
        name: resourceToken
        properties: {
          hostName: hostName
          httpPort: 80
          httpsPort: 443
        }
      }
    ]
    isHttpAllowed: false
    isHttpsAllowed: true
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'text/javascript'
      'application/x-javascript'
      'application/javascript'
      'application/json'
      'application/xml'
      'application/rss+xml'
      'image/svg+xml'
    ]
    queryStringCachingBehavior: 'IgnoreQueryString'
    originHostHeader: hostName
    originPath: '/images'
  }
}


output storageAccountResourceId string = storageAccount.id
output storageAccocuntBlobURL string = storageAccount.properties.primaryEndpoints.blob
output containerId string = container.id
output containerName string = container.name
//output storageConnectionString string = storageAccount.listKeys().keys[0].value
output accountName string = storageAccount.name 
output cdnEndpointUrl string = endpoint.properties.hostName
