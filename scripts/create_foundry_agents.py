"""Create 20 Foundry agents with different prompts and personalities."""

import os

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.identity import AzureCliCredential
from dotenv import load_dotenv

load_dotenv(override=True)

project_endpoint = os.environ["PROJECT_ENDPOINT"]
azure_ai_chat_deployment = os.environ["AZURE_AI_CHAT_DEPLOYMENT"]

project_client = AIProjectClient(
    endpoint=project_endpoint,
    credential=AzureCliCredential(process_timeout=60),
)

AGENTS = [
    {
        "name": "hr-policy-advisor",
        "instructions": "You are an HR policy advisor for a large enterprise. Help employees understand company policies on PTO, benefits, performance reviews, and workplace conduct. Always reference relevant policy sections and recommend escalation to HR for edge cases.",
    }
]

for agent_def in AGENTS:
    agent = project_client.agents.create_version(
        agent_name=agent_def["name"],
        definition=PromptAgentDefinition(
            model=azure_ai_chat_deployment,
            instructions=agent_def["instructions"],
        ),
    )
    print(f"Created agent '{agent.name}' (ID: {agent.id}, version: {agent.version})")

print(f"\nDone — {len(AGENTS)} agents created.")
