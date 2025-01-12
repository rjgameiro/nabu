
@description('The name of the project in snake case')
param project string

@description('The name of the project in pascal case')
param projectPascalCase string

@secure()
@description('The object id of the Terraform app registration service principal')
param principal string

@description('The owner of the resources of this state backend')
param owner string

@allowed([
    'swedencentral'
    'francecentral'
])
@description('The location of this state backend')
param location string = 'swedencentral'

targetScope = 'subscription'

resource foundationResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: 'rg-${project}-foundation'
	location: location
	tags: {
		project: project
		workspace: 'foundation'
		'created-by': 'bicep'
		owner: owner
	}
}

module terraformStateResources 'state.resources.bicep' = {
  	name: 'foundationResources'
  	scope: foundationResourceGroup
	#disable-next-line explicit-values-for-loc-params
  	params: {
        project: project
    	projectPascalCase: projectPascalCase
    	principal: principal
    	tags: {
			project: project
        	workspace: 'foundation'
        	'created-by': 'bicep'
        	owner: owner
        }
  	}
}
