
param project string
param projectPascalCase string
param principal string
param location string = resourceGroup().location
param tags object

resource foundationStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
	name: 'st${toLower(projectPascalCase)}foundation'
	location: location
	sku: {
		name: 'Standard_LRS'
	}
	kind: 'StorageV2'
	properties: {
		minimumTlsVersion: 'TLS1_2'
		supportsHttpsTrafficOnly: true
		allowBlobPublicAccess: false
	}
	tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
	parent: foundationStorageAccount
	name: 'default'
	properties: {
        isVersioningEnabled: true
    }
}

resource terraformStateContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
	parent: blobService
	name: '${project}-terraform-state'
	properties: {
		publicAccess: 'None'
	}
}

resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2021-04-01' = {
  	name: 'default'
  	parent: foundationStorageAccount
  	properties: {
  	  	policy: {
  	  	  	rules: [{
  	  	  		enabled: true
  	  	  		name: 'DeleteOldVersionsAfter7Days'
  	  	  		type: 'Lifecycle'
  	  	  		definition: {
  	  	  			filters: { blobTypes: ['blockBlob'] }
  	  	  			actions: { version: { delete: { daysAfterCreationGreaterThan: 7 } } }
  	  	  		}
			}]
  	  	}
  	}
}

resource terraformRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principal, foundationStorageAccount.id, 'Reader and Data Access')
  scope: foundationStorageAccount
  properties: {
    principalId: principal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c12c1c16-33a1-487b-954d-41c89c60f349')
    principalType: 'ServicePrincipal'
  }
}
