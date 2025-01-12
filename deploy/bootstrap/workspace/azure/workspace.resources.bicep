
param principal string

resource terraformRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principal, resourceGroup().id, 'Owner')
  scope: resourceGroup()
  properties: {
    principalId: principal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalType: 'ServicePrincipal'
  }
}
