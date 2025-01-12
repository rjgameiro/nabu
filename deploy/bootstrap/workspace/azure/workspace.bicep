
@description('The name of the project in snake case')
param project string

@description('The name of the workspace in snake case (i.e. development, staging, production)')
param workspace string

@secure()
@description('The object id of the Terraform app registration service principal')
param principal string

@allowed([
    'swedencentral'
    'francecentral'
])
@description('The location of this workspace')
param location string = 'swedencentral'

@description('The owner of the resources of this workspace')
param owner string

targetScope = 'subscription'

resource workspaceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: 'rg-${project}-${workspace}'
	location: location
	tags: {
		project: project
    	workspace: workspace
    	'created-by': 'bicep'
    	owner: owner
    }
}

module workspaceResources 'workspace.resources.bicep' = {
	name: 'workspaceResources-${workspace}'
	scope: workspaceResourceGroup
	#disable-next-line explicit-values-for-loc-params
	params: {
		principal: principal
  	}
}