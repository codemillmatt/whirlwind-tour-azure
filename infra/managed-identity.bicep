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

@minLength(1)
@description('Name of the Azure App Configuration service')
param appConfigServiceName string

@minLength(1)
@description('Id of the principal running the script')
param principalId string

@minLength(1)
@description('Type of the principal running the script')
param principalType string

@description('Built in \'Data Reader\' role ID: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles')
var appConfigurationRoleDefinitionId = '516239f1-63e1-4d78-a4de-a74fb236a071'

resource appConfigService 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigServiceName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  location: location
  tags: tags
}

@description('Grant the \'Data Reader\' role to the user-assigned managed identity, at the scope of the resource group.')
resource appConfigRoleAssignmentForWebApps 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(appConfigurationRoleDefinitionId, appConfigService.id, managedIdentity.name, resourceToken)
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', appConfigurationRoleDefinitionId)
    principalId: managedIdentity.properties.principalId
    description: 'Grant the "Data Reader" role to the user-assigned managed identity so it can access the azure app configuration service.'
  }
}

@description('Grant the \'Data Reader\' role to the principal, at the scope of the resource group.')
resource appConfigRoleAssignmentForPrincipal 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (principalType == 'user') {
  name: guid(appConfigurationRoleDefinitionId, appConfigService.id, principalId, resourceToken)
  scope: resourceGroup()
  properties: {
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', appConfigurationRoleDefinitionId)
    principalId: principalId
    description: 'Grant the "Data Reader" role to the principal identity so it can access the azure app configuration service.'
  }
}

@description('Built in \'Key Secrets User\' role ID: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles')
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

@description('Grant the \'Key Secrets User\' role to the principal, at the scope of the resource group.')
resource keyVaultRoleAssignmentForWebApp 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultSecretsUserRoleDefinitionId, appConfigService.id, principalId, resourceToken)
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
    principalId: managedIdentity.properties.principalId
    description: 'Grant the "Key Secrets User" role to the principal identity so it can manage the key vault service.'
  }
}

@description('Built in \'Key Vault Administrator\' role ID: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles')
var keyVaultAdminRoleDefinitionId = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

@description('Grant the \'Key Vault Administrator\' role to the principal, at the scope of the resource group.')
resource keyVaultRoleAssignmentForPrincipal 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (principalType == 'user') {
  name: guid(keyVaultAdminRoleDefinitionId, appConfigService.id, principalId, resourceToken)
  scope: resourceGroup()
  properties: {
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultAdminRoleDefinitionId)
    principalId: principalId
    description: 'Grant the "Key Vault Administrator" role to the principal identity so it can manage the key vault service.'
  }
}

output managedIdentityResourceId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
