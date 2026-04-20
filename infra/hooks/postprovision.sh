#!/bin/sh
set -e

echo "Running postprovision hook..."

# Write .env file for scripts
cat > .env << EOF
# Microsoft Foundry Configuration
PROJECT_ENDPOINT=${MICROSOFT_FOUNDRY_PROJECT_ENDPOINT}
PROJECT_RESOURCE_ID=${MICROSOFT_FOUNDRY_PROJECT_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
CUPCAKE_MCP_ENDPOINT=${CUPCAKE_MCP_ENDPOINT}

# Claude model deployment
AZURE_AI_CHAT_DEPLOYMENT=${AZURE_AI_CHAT_DEPLOYMENT}
EOF

echo "Created .env file"
echo "Postprovision complete!"
