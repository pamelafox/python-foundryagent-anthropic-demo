$ErrorActionPreference = "Stop"

Write-Host "Running postprovision hook..."

# Write .env file for scripts
$envContent = @"
# Microsoft Foundry Configuration
PROJECT_ENDPOINT=$($env:MICROSOFT_FOUNDRY_PROJECT_ENDPOINT)
PROJECT_RESOURCE_ID=$($env:MICROSOFT_FOUNDRY_PROJECT_ID)
AZURE_TENANT_ID=$($env:AZURE_TENANT_ID)
CUPCAKE_MCP_ENDPOINT=$($env:CUPCAKE_MCP_ENDPOINT)
CUPCAKE_MCP_PROJECT_CONNECTION_NAME=$($env:CUPCAKE_MCP_PROJECT_CONNECTION_NAME)

# Claude model deployment
AZURE_AI_CHAT_DEPLOYMENT=$($env:AZURE_AI_CHAT_DEPLOYMENT)
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $PWD ".env"), $envContent, $utf8NoBom)

Write-Host "Created .env file"
Write-Host "Postprovision complete!"
