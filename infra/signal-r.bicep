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

resource signalRBlazor 'Microsoft.SignalRService/signalR@2023-03-01-preview' = {
  name: '${abbrs.signalRServiceSignalR}${resourceToken}-blazor'
  location: location
  tags: tags
  sku: {
    capacity: 1
    name: 'Standard_S1'
  }
  kind: 'SignalR'
  properties: {
    features: [
      {
        flag: 'ServiceMode', value: 'Default'
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
  }
}

resource signalRFunctions 'Microsoft.SignalRService/signalR@2023-03-01-preview' = {
  name: '${abbrs.signalRServiceSignalR}${resourceToken}-functions'
  location: location
  tags: tags
  sku: {
    capacity: 1
    name: 'Standard_S1'
  }
  kind: 'SignalR'
  properties: {
    features: [
      {
        flag: 'ServiceMode', value: 'Serverless'
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
  }
}

output signalRBlazorConnectionString string = signalRBlazor.listKeys().primaryConnectionString
output signalRFunctionsConnectionString string = signalRFunctions.listKeys().primaryConnectionString
