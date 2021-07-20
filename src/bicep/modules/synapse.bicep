@minLength(1)
@maxLength(50)
param synapseWorkspaceName string

@allowed([
  'SystemAssigned'
])
param synapsWorkspaceIdentity string

@secure()
param synapseSqlAdministratorLogin string
@secure()
param synapseSqlAdministratorLoginPassword string

param defaultDataLakeStorageUrl string
param defaultDataLakeStorageFileSystem string

var resourceLocation = resourceGroup().location
var synapseWorkspaceNameToLower = toLower(synapseWorkspaceName)


/*Create a Synapse Analytics workspace*/
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-04-01-preview' = {
  name: synapseWorkspaceNameToLower
  location: resourceLocation
  identity: {
    type: synapsWorkspaceIdentity
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: defaultDataLakeStorageUrl
      filesystem: defaultDataLakeStorageFileSystem
    }
    sqlAdministratorLogin: synapseSqlAdministratorLogin
    sqlAdministratorLoginPassword: synapseSqlAdministratorLoginPassword
  }

  resource workspaceFirewall 'firewallRules@2021-04-01-preview' = {
    name: 'allowAll'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255' /*Maybe we can test out using a policy or CI process to block or raise warnings for this?*/
    }
  }
}

output synapseWorkspaceName string = synapseWorkspace.name
output synapseWorkspaceId string = synapseWorkspace.id
