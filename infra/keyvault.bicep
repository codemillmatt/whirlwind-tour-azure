@minLength(1)
@description('Primary location for all resources. Should specify an Azure region. e.g. `eastus2` ')
param location string

@description('Tags to be applied to all resources')
param tags object

@description('Abbreviations for objects')
param abbrs object

@minLength(1)
@description('Unique token to be used in naming resources')
param resourceToken string

@description('Azure Storage account name')
@secure()
param storageAccountName string

@minLength(1)
@description('SQL Admin username')
param sqlAdminUsername string

@secure()
@description('SQL Admin password')
param sqlAdminPassword string

@minLength(1)
@description('Menu db name')
param menuDbName string

@minLength(1)
@description('Checkout db name')
param checkoutDbName string

@minLength(1)
@description('SQL FQDN')
param sqlFQDN string

@description('Menu DB connection string')
var sqlMenuConnectionString = 'Server=tcp:${sqlFQDN},1433;Initial Catalog=${menuDbName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};'

@description('Checkout DB connection string')
var sqlCheckoutConnectionString = 'Server=tcp:${sqlFQDN},1433;Initial Catalog=${checkoutDbName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

@description('The connection string needed for .NET apps')
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${abbrs.keyVaultVaults}${resourceToken}'
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
  }
}

// sql, storage, signal r
resource sqlMenuConnectionValue 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'sql-menu-connection-string'
  properties: {
    value: sqlMenuConnectionString
  }
}

resource sqlCheckoutConnectionValue 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'sql-checkout-connection-string'
  properties: {
    value: sqlCheckoutConnectionString
  }
}

resource storageConnectionValue 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: storageConnectionString
  }
}

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: '${abbrs.appConfigurationConfigurationStores}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  dependsOn: [
    keyVault
  ]

  resource sqlMenuKVSetting 'keyValues@2023-03-01' = {
    name: 'menuDb'
    properties: {
      value: string({
        uri: '${keyVault.properties.vaultUri}secrets/${sqlMenuConnectionValue.name}'
      })
      contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
    }
  }

  resource sqlCheckKVSettings 'keyValues@2023-03-01' = {
    name: 'CheckoutDb'
    properties: {
      value: string({
        uri: '${keyVault.properties.vaultUri}secrets/${sqlCheckoutConnectionValue.name}'
      })
      contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
    }
  }

  resource storageKVSettings 'keyValues@2023-03-01' = {
    name: 'imageStorageUrl'
    properties: {
      value: string({
        uri: '${keyVault.properties.vaultUri}secrets/${storageConnectionValue.name}'
      })
      contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
    }
  }
}

output appConfigName string = appConfig.name 
