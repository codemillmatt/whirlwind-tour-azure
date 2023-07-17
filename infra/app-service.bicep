// bicep file that creates an app service plan

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

@minLength(1)
@description('Name of the managed identity to assign to all services')
param managedIdentityName string

@minLength(1)
@description('Name of the App Config Service')
param appConfigServiceName string

@minLength(1)
@description('Blazor signalr connection string')
param blazorSignalrConnectionString string

@minLength(1)
@description('Functions SignalR connection string')
param functionsSignalrConnectionString string

@minLength(1)
@description('Storage account name')
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

@minLength(1)
@description('CDN endpoint')
param cdnEndpoint string

resource appConfigSvc 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigServiceName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource webLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${abbrs.insightsComponents}${resourceToken}'
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: webLogAnalyticsWorkspace.id
  }
}

resource webAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${abbrs.webServerFarms}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'B1'
  }
  properties: {

  }
}

resource frontEnd 'Microsoft.Web/sites@2022-09-01' = {
  name: '${abbrs.webSitesAppService}${resourceToken}-front-end'
  location: location
  tags: union(tags, {
      'azd-service-name': 'front-end'
    })
  properties: {
    serverFarmId: webAppServicePlan.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
    }
    httpsOnly: true
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      ASPNETCORE_ENVIRONMENT: 'DEVELOPMENT'
      appConfigUrl: appConfigSvc.properties.endpoint
      AZURE_CLIENT_ID: managedIdentity.properties.clientId
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      ASPNETCORE_HOSTINGSTARTUPASSEMBLIES: 'Microsoft.Azure.SignalR'
      ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
      XDT_MicrosoftApplicationInsights_Mode: 'recommended'
      InstrumentationEngine_EXTENSION_VERSION: '~1'
      XDT_MicrosoftApplicationInsights_BaseExtensions: '~1'
      'Azure:SignalR:Enabled': 'true'
      'Azure:SignalR:ConnectionString': blazorSignalrConnectionString
      menuUrl: 'https://${menuApi.properties.defaultHostName}'
      cartUrl: 'https://${checkoutApi.properties.defaultHostName}'
      trackingUrl: 'https://${functionApp.properties.defaultHostName}/api'
      cdnUrl: 'https://${cdnEndpoint}'
    }
  }
}

resource menuApi 'Microsoft.Web/sites@2022-09-01' = {
  name: '${abbrs.webSitesAppService}${resourceToken}-menu-api'
  location: location
  tags: union(tags, {
      'azd-service-name': 'menu-api'
    })
  properties: {
    serverFarmId: webAppServicePlan.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
    }
    httpsOnly: true
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      ASPNETCORE_ENVIRONMENT: 'DEVELOPMENT'
      appConfigUrl: appConfigSvc.properties.endpoint
      AZURE_CLIENT_ID: managedIdentity.properties.clientId
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
      XDT_MicrosoftApplicationInsights_Mode: 'recommended'
      InstrumentationEngine_EXTENSION_VERSION: '~1'
      XDT_MicrosoftApplicationInsights_BaseExtensions: '~1'
    }
  }
}

resource checkoutApi 'Microsoft.Web/sites@2022-09-01' = {
  name: '${abbrs.webSitesAppService}${resourceToken}-checkout-api'
  location: location
  tags: union(tags, {
      'azd-service-name': 'checkout-api'
    })
  properties: {
    serverFarmId: webAppServicePlan.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
    }
    httpsOnly: true
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      ASPNETCORE_ENVIRONMENT: 'DEVELOPMENT'
      appConfigUrl: appConfigSvc.properties.endpoint
      AZURE_CLIENT_ID: managedIdentity.properties.clientId
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      //APPLICATIONINSIGHTS_CONNECTION_STRING: webApplicationInsightsResources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
      //'App:AppConfig:Uri': appConfigService.properties.endpoint
      //SCM_DO_BUILD_DURING_DEPLOYMENT: 'false'
      // App Insights settings
      // https://learn.microsoft.com/azure/azure-monitor/app/azure-web-apps-net#application-settings-definitions
      //APPINSIGHTS_INSTRUMENTATIONKEY: webApplicationInsightsResources.outputs.APPLICATIONINSIGHTS_INSTRUMENTATION_KEY
      ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
      XDT_MicrosoftApplicationInsights_Mode: 'recommended'
      InstrumentationEngine_EXTENSION_VERSION: '~1'
      XDT_MicrosoftApplicationInsights_BaseExtensions: '~1'
    }
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${abbrs.webSitesFunctions}${resourceToken}'
  location: location
  tags: union(tags, {
    'azd-service-name': 'tracker-function'
  })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: webAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('${abbrs.webSitesFunctions}${resourceToken}')
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'AzureSignalRConnectionString'
          value: functionsSignalrConnectionString
        }
      ]
    }
  }
}  
