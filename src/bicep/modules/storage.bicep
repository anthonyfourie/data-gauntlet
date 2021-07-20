@description('The prefix for the storage account name.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('The sku name for the storage account')
@allowed([
  'Standard_LRS'
])
param storageSkuName string

@description('The sku tier for the storage account')
@allowed([
  'Standard'
])
param storageSkuTier string

@description('The kind of storage account')
param storageEncryptionBlob bool
@description('The kind of storage account')
param storageEncryptionFile bool
@description('The kind of storage account')
param storageEncryptionQueue bool
@description('The kind of storage account')
param storageEncryptionTable bool


param storageIsHnsEnabled bool
param storageSupportsHttpsTrafficOnly bool
param storageAccessTier string = 'Hot'


@description('The kind of storage account')
@allowed([
  'StorageV2'
])
param storageKind string

var resourceLocation = resourceGroup().location
var storageAccountNameSuffix = toLower('${storageAccountName}${uniqueString(resourceGroup().id)}')

resource datalake 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountNameSuffix
  location: resourceLocation
  sku: {
    name: storageSkuName
    tier: storageSkuTier
  }
  kind: storageKind
  properties: {
    isHnsEnabled: storageIsHnsEnabled
    supportsHttpsTrafficOnly: storageSupportsHttpsTrafficOnly
    accessTier: storageAccessTier
    networkAcls: {
      defaultAction: 'Allow' 
      bypass: 'AzureServices' /*Maybe we can test out using a policy or CI process to block or raise warnings for this?*/
      virtualNetworkRules: []
      ipRules: []
    }
    encryption: {
      services: {
        blob: {
          enabled: storageEncryptionBlob
        }
        file: {
          enabled: storageEncryptionFile
        }
        queue: {
          enabled: storageEncryptionQueue
        }
        table: {
          enabled: storageEncryptionTable
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}


/*
  I built this child resource by wroking my way back through these templates: https://github.com/Azure-Samples/Synapse/tree/main/Manage/DeployWorkspace/storage 
  It get's a little tricky, but we are building a dependency chain of parent-child resources. e.g. Storage account -> Blob -> Container
*/
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: datalake
  name: 'default'
  properties: {
    cors: {
        corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource blobServiceContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: 'workspace'
  properties: {
    publicAccess: 'None'
  }
}

output blobEndpointDFS string = datalake.properties.primaryEndpoints.dfs
output blobServiceName string = blobService.name
output blobServiceId string = blobService.id
output blobServiceContainerName string = blobServiceContainer.name
output blobServiceContainerId string = blobServiceContainer.id 
