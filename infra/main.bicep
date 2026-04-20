// ===============================================
// Creates: Microsoft Foundry (with model deployments)
// ===============================================

@description('Principal ID for role assignments (provided by azd)')
param principalId string

@description('The location where all resources will be deployed')
param location string

@description('Chat/reasoning model name')
param llmModelName string = 'claude-sonnet-4-5'

@description('Chat/reasoning model deployment capacity')
@minValue(1)
@maxValue(200)
param llmModelCapacity int = 50

@description('Bump this value if role assignment deployment fails due to stale ARM tombstones')
param roleAssignmentSuffix string = 'v2'


// Variables for resource naming and configuration
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourceNames = {
  microsoftFoundry: 'foundry-${uniqueSuffix}'
  microsoftFoundryProject: 'foundry-project-${uniqueSuffix}'
  llmDeployment: llmModelName
  logAnalyticsWorkspace: 'log-${uniqueSuffix}'
  applicationInsights: 'appi-${uniqueSuffix}'
}

// ===============================================
// MICROSOFT FOUNDRY (Account + Project)
// ===============================================

@description('Microsoft Foundry account')
resource microsoftFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: resourceNames.microsoftFoundry
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: resourceNames.microsoftFoundry
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

@description('Microsoft Foundry project')
resource microsoftFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: microsoftFoundryAccount
  name: resourceNames.microsoftFoundryProject
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// Azure AI User role for the Foundry project's own managed identity on itself.
// Required by the Portal/runtime so the project MI can invoke its own agents and models.
resource microsoftFoundryProjectMIAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(microsoftFoundryProject.id, 'Azure AI User', microsoftFoundryProject.name, roleAssignmentSuffix)
  scope: microsoftFoundryProject
  properties: {
    principalId: microsoftFoundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '53ca6127-db72-4b80-b1b0-d745d6d5456d')
  }
}

// ===============================================
// MODEL DEPLOYMENTS (under Microsoft Foundry account)
// ===============================================

@description('Anthropic Claude model deployment')
resource llmModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview' = {
  parent: microsoftFoundryAccount
  name: resourceNames.llmDeployment
  properties: {
    model: {
      format: 'Anthropic'
      name: llmModelName
      version: '1'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: llmModelCapacity
  }
}

// Azure AI User role for lab user on Microsoft Foundry account (needed for Azure OpenAI API)
resource userMicrosoftFoundryAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(microsoftFoundryAccount.id, 'Azure AI User', principalId)
  scope: microsoftFoundryAccount
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '53ca6127-db72-4b80-b1b0-d745d6d5456d')
  }
}

// Azure AI Project Manager role for lab user on Microsoft Foundry account
resource userMicrosoftFoundryAccountProjectManagerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(microsoftFoundryAccount.id, 'Azure AI Project Manager', principalId)
  scope: microsoftFoundryAccount
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'eadc314b-1a2d-4efa-be10-5d325db5065e')
  }
}

// Azure AI User role for lab user on Microsoft Foundry project (needed for projects/agents API)
resource userMicrosoftFoundryProjectRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(microsoftFoundryProject.id, 'Azure AI User', principalId)
  scope: microsoftFoundryProject
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '53ca6127-db72-4b80-b1b0-d745d6d5456d')
  }
}

// Azure AI Project Manager role for lab user on Microsoft Foundry project (needed for agents/write)
resource userMicrosoftFoundryProjectManagerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(microsoftFoundryProject.id, 'Azure AI Project Manager', principalId)
  scope: microsoftFoundryProject
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'eadc314b-1a2d-4efa-be10-5d325db5065e')
  }
}

// ===============================================
// APPLICATION INSIGHTS + LOG ANALYTICS
// ===============================================

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  name: 'logAnalyticsWorkspaceDeploy'
  params: {
    name: resourceNames.logAnalyticsWorkspace
    location: location
  }
}

module applicationInsights 'br/public:avm/res/insights/component:0.7.1' = {
  name: 'applicationInsightsDeploy'
  params: {
    name: resourceNames.applicationInsights
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  parent: microsoftFoundryProject
  name: 'appinsights-connection'
  properties: {
    category: 'AppInsights'
    target: applicationInsights.outputs.connectionString
    authType: 'ApiKey'
    isSharedToAll: true
    metadata: {
      ResourceId: applicationInsights.outputs.resourceId
    }
    credentials: {
      key: applicationInsights.outputs.instrumentationKey
    }
  }
}

@description('Microsoft Foundry project endpoint in SDK format')
output MICROSOFT_FOUNDRY_PROJECT_ENDPOINT string = 'https://${microsoftFoundryAccount.name}.services.ai.azure.com/api/projects/${microsoftFoundryProject.name}'

@description('Microsoft Foundry project resource ID')
output MICROSOFT_FOUNDRY_PROJECT_ID string = microsoftFoundryProject.id

@description('Claude model deployment name')
output AZURE_AI_CHAT_DEPLOYMENT string = llmModelDeployment.name

@description('Application Insights connection string for tracing')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
