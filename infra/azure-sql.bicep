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
@description('The name of an admin account that can be used to add Managed Identities to Azure SQL')
param sqlAdministratorLogin string

@secure()
@minLength(1)
// note - this password should not be saved. the apps, and devs, connect with Managed Identity or Azure AD
@description('The password for an admin account that can be used to add Managed Identities to Azure SQL')
param sqlAdministratorPassword string

var sqlServerName = '${abbrs.sqlServers}${resourceToken}'

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    version: '12.0'
  }
}

var sqlDbMenuName = '${abbrs.sqlServersDatabases}${resourceToken}-menu'
var sqlDbCheckoutName = '${abbrs.sqlServersDatabases}${resourceToken}-checkout'

resource sqlDatabaseMenu 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: '${sqlServer.name}/${sqlDbMenuName}'
  location: location
  tags: union(tags, {
    displayName: sqlDbMenuName
  })
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 10
  }
  properties: {
    requestedBackupStorageRedundancy: 'Local'
    readScale: 'Disabled'
  }
}

resource sqlDatabaseCheckout 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: '${sqlServer.name}/${sqlDbCheckoutName}'
  location: location
  tags: union(tags, {
    displayName: sqlDbCheckoutName
  })
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 10
  }
  properties: {
    requestedBackupStorageRedundancy: 'Local'
    readScale: 'Disabled'
  }
}

// To allow applications hosted inside Azure to connect to your SQL server, Azure connections must be enabled. 
// To enable Azure connections, there must be a firewall rule with starting and ending IP addresses set to 0.0.0.0. 
// This recommended rule is only applicable to Azure SQL Database.
// Ref: https://learn.microsoft.com/azure/azure-sql/database/firewall-configure?view=azuresql#connections-from-inside-azure
resource allowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-11-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDbMenuName string = sqlDbMenuName
output sqlDbCheckoutName string = sqlDbCheckoutName

output sqlServerName string = sqlServer.name
output sqlServerId string = sqlServer.id
output sqlMenuDatabaseName string = sqlDatabaseMenu.name
output sqlCheckoutDatabaseName string = sqlDatabaseCheckout.name

output sqlMenuConnectionString string = '${sqlServer.properties.fullyQualifiedDomainName};database=${sqlDbMenuName};user id=${sqlAdministratorLogin};password=${sqlAdministratorPassword}'
output sqlCheckoutConnectionString string = '${sqlServer.properties.fullyQualifiedDomainName};database=${sqlDbCheckoutName};user id=${sqlAdministratorLogin};password=${sqlAdministratorPassword}'
