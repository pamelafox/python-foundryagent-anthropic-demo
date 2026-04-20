"""Create a single Foundry agent."""

import os

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.ai.projects.models import MCPTool
from azure.identity import AzureDeveloperCliCredential
from dotenv import load_dotenv

load_dotenv(override=True)

project_endpoint = os.environ["PROJECT_ENDPOINT"]
azure_ai_chat_deployment = os.environ["AZURE_AI_CHAT_DEPLOYMENT"]
cupcake_mcp_endpoint = os.environ["CUPCAKE_MCP_ENDPOINT"]

project_client = AIProjectClient(
    endpoint=project_endpoint,
    credential=AzureDeveloperCliCredential(tenant_id=os.environ["AZURE_TENANT_ID"]),
)

agent = project_client.agents.create_version(
    agent_name="cupcake-agent",
    definition=PromptAgentDefinition(
        model=azure_ai_chat_deployment,
        instructions= "You help customers order cupcakes and check the status of their orders.",
        tools=[
            MCPTool(
                server_label="cupcake-mcp-server",
                server_url=cupcake_mcp_endpoint,
                require_approval="never",
                allowed_tools=["list_cupcakes", "order_cupcake", "check_order_status"],
                project_connection_id="cupcake-mcp",
            )
        ],
    ),
)

print(f"Created agent '{agent.name}' (ID: {agent.id}, version: {agent.version})")
