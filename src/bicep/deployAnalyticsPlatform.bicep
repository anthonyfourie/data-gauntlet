targetScope = 'subscription'

/*Resource Group parameters*/
param resGroupName string
param resGroupLocation string = 'australiaeast'

/*This controls if we deploy the resource our not*/
param deployDataLake bool = true
param deploySynapse bool = true

/*Resource specific parameters - Synapse Analytics*/
param synapseWorkspaceName string
@secure()
param synapseSqlAdministratorLogin string
@secure()
param synapseSqlAdministratorLoginPassword string

/*Resource specific parameters - Synapse Analytics*/
param storageName string
param storageSkuName string = 'Standard_LRS'
param storageSkuTier string = 'Standard'
param storageKind string = 'StorageV2'
param storageAccessTier string = 'Hot'
param storageIsHnsEnabled bool = true
param storageSupportsHttpsTrafficOnly bool = true
param storageEncryptionBlob bool = true
param storageEncryptionFile bool = true
param storageEncryptionQueue bool = true
param storageEncryptionTable bool = true


/*Create a resource group to host our data services*/
resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resGroupName
  location: resGroupLocation
}

/*Create a data lake storage account which we use as the Synapse Analytics default data lake*/
module datalakeStorage 'modules/storage.bicep' = if (deployDataLake == true) {
  name: 'deploy${storageName}'
  scope: resourceGroup(resGroup.name)
  params: {
    storageAccountName: storageName
    storageSkuName: storageSkuName
    storageSkuTier: storageSkuTier
    storageKind: storageKind
    storageIsHnsEnabled: storageIsHnsEnabled
    storageSupportsHttpsTrafficOnly: storageSupportsHttpsTrafficOnly
    storageAccessTier: storageAccessTier
    storageEncryptionBlob: storageEncryptionBlob
    storageEncryptionFile: storageEncryptionFile
    storageEncryptionQueue: storageEncryptionQueue
    storageEncryptionTable: storageEncryptionTable
  }
}

/*Create a Synapse Analytics workspace*/
module synapseWorkspace 'modules/synapse.bicep' = if (deploySynapse == true) {
  name: 'deploy${synapseWorkspaceName}'
  scope: resourceGroup(resGroup.name)
  params: {
    synapseWorkspaceName: synapseWorkspaceName
    synapsWorkspaceIdentity: 'SystemAssigned'
    defaultDataLakeStorageUrl: datalakeStorage.outputs.blobEndpointDFS
    defaultDataLakeStorageFileSystem: datalakeStorage.outputs.blobServiceContainerName
    synapseSqlAdministratorLogin: synapseSqlAdministratorLogin
    synapseSqlAdministratorLoginPassword: synapseSqlAdministratorLoginPassword
  }
}
