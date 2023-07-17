targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@secure()
@minLength(1)
@description('Specifies a password that will be used to secure the Azure SQL Database')
param azureSqlPassword string

@minLength(1)
@description('Specifies the login name for the Azure SQL Database administrator')
param azureSqlAdminLogin string

@minLength(1)
@description('Id of the user or app to assign application roles')
param principalId string

@minLength(1)
@description('When the deployment is executed by a user we give the principal RBAC access to key vault')
param principalType string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module azureSql 'azure-sql.bicep' = {
  name: '${resourceToken}-azure-sql'
  scope: rg
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    abbrs: abbrs
    sqlAdministratorLogin: azureSqlAdminLogin
    sqlAdministratorPassword: azureSqlPassword
  }
}

module azureStorage 'storage.bicep' = {
  name: '${resourceToken}-storage'
  scope: rg
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    abbrs: abbrs
  }
}

module signalR 'signal-r.bicep' = {
  name: '${resourceToken}-signal-r'
  scope: rg
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    abbrs: abbrs
  }
}

module keyvault 'keyvault.bicep' = {
  name: '${resourceToken}-keyvault'
  scope: rg
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    abbrs: abbrs
    checkoutDbName: azureSql.outputs.sqlDbCheckoutName
    menuDbName: azureSql.outputs.sqlDbMenuName
    sqlAdminPassword: azureSqlPassword
    sqlAdminUsername: azureSqlAdminLogin
    sqlFQDN: azureSql.outputs.sqlServerFqdn
    storageAccountName: azureStorage.outputs.accountName
  }
  dependsOn: [
    azureSql
    azureStorage
    signalR
  ]
}

module managedIdentity 'managed-identity.bicep' = {
  name: '${resourceToken}-managed-identity'
  scope: rg
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    abbrs: abbrs
    appConfigServiceName: keyvault.outputs.appConfigName
    principalId: principalId
    principalType: principalType
  }
}

module appServiceResources 'app-service.bicep' = {
  name: '${resourceToken}-app-service'
  scope: rg
  dependsOn: [
    azureSql
    azureStorage
    signalR
    keyvault
    managedIdentity
  ]
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    abbrs: abbrs
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    appConfigServiceName: keyvault.outputs.appConfigName
    blazorSignalrConnectionString: signalR.outputs.signalRBlazorConnectionString
    cdnEndpoint: azureStorage.outputs.cdnEndpointUrl
    functionsSignalrConnectionString: signalR.outputs.signalRFunctionsConnectionString
    storageAccountName: azureStorage.outputs.accountName
  }
}


// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
