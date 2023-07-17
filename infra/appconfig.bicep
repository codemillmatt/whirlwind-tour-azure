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
}
