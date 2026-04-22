# AI Agent on AWS

Terraform infrastructure for an AI Agent built with Amazon Bedrock.

## Source

This project follows the *LinkedIn Learning course by Kesha on AI*:
**AI Challenge: Build an AI Agent in 7 Steps in 7 Days with AWS**

## How it works

Amazon Bedrock is AWS's managed AI service. It lets you run a large language model (like Claude or Amazon Nova) without managing any servers. On top of that, **Bedrock Agents** adds the ability for the model to take actions — not just answer questions, but actually call your own code to fetch real data and return it as part of the response.

This project sets up one such agent. When you ask it something, it figures out whether it needs to look something up, calls the right Lambda function, and weaves the result into its answer.

### Session memory

The agent is configured with **SESSION_SUMMARY** memory. After each session ends, Bedrock automatically generates a summary of what was discussed and stores it. On the next session, the agent can recall that context — so it remembers things like which service the user was investigating or what was already checked.

Memory is opt-in via the `enable_memory` variable in the `bedrock-agent` module (default: `false`). Set it to `true` in the environment's `main.tf` to activate it. You can also control how long summaries are retained with `memory_storage_days` (default: 30, max: 365).

To test memory across sessions, use two separate `--session-id` values — the first to build context, the second to verify the agent recalls it.

### Action group: ServicesActions

An action group is how you teach the agent what it can do. Think of it as a plugin — it tells the agent: "if you need to look up a service, here's the API you can call."

This project has one action group called **ServicesActions**. When the agent receives a question about an internal service (e.g. "who owns the payments service?"), it:

1. Recognises it needs service information
2. Calls the `ops_get_service_info` Lambda function
3. Passes the service name as a parameter
4. Gets back the owner, on-call contact, and current status
5. Returns a natural-language answer to the user

The Lambda function is defined in `terraform/src/lambda_functions/ops_get_service_info/` and currently knows about two services: `payments` and `auth`.

The contract between the agent and the Lambda (what parameters to send, what response to expect) is defined by an OpenAPI schema at `terraform/environments/dev/schemas/services_actions.yaml`.

### How the pieces connect

```
User prompt
    │
    ▼
Bedrock Agent  ──── reads instructions + OpenAPI schema
    │
    │  calls when service info is needed
    ▼
Lambda: ops_get_service_info
    │
    ▼
Returns owner / on-call / status
    │
    ▼
Agent composes final answer
```

## Structure

```
terraform/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── locals.tf          # Lambda configs
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── schemas/
│           └── services_actions.yaml   # OpenAPI schema for the action group
└── modules/
    ├── bedrock-agent/
    │   ├── main.tf            # Agent, action group, IAM roles
    │   ├── variables.tf
    │   └── outputs.tf
    └── lambda_function/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
terraform/src/
└── lambda_functions/
    └── ops_get_service_info/
        └── ops_get_service_info.py    # The actual Lambda code
```

## Variables

| Name                 | Default                | Description                                        |
|----------------------|------------------------|----------------------------------------------------|
| `app_id`             | `ai-agent-on-aws`      | Application identifier used for naming and tagging |
| `aws_region`         | `eu-central-1`         | AWS region where resources are deployed            |
| `model`              | `amazon.nova-pro-v1:0` | Bedrock foundation model ID                        |
| `agent_instructions` | —                      | Instructions that define the agent's behavior      |
| `env`                | `dev`                  | Deployment environment                             |

## Deploy

```bash
cd terraform/environments/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Testing

### 1. Test the Lambda in isolation

Before involving the agent, confirm the Lambda works on its own. In the AWS Console, go to the `ops-get-service-info` Lambda → Test, and use this payload:

```json
{
  "actionGroup": "ServicesActions",
  "apiPath": "/get-service-info",
  "httpMethod": "GET",
  "parameters": [
    { "name": "service", "type": "string", "value": "payments" }
  ],
  "sessionAttributes": {},
  "promptSessionAttributes": {}
}
```

The response should include `owner`, `on_call`, and `status`. If this fails, the bug is in the Lambda — no need to involve the agent yet.

### 2. Test the agent via the AWS Console

Open the agent in the Bedrock console → Test panel. Try these prompts:

- `"Who owns the payments service?"` — should trigger the action group
- `"What's the status of auth?"` — different service, same action
- `"What's the weather like?"` — should **not** trigger the action group

Enable **Trace** in the test panel to see the agent's reasoning: which action it chose, what parameters it extracted, and what the Lambda returned. This is the most useful debugging tool.

### What to check

| What to check                               | Why it matters                                        |
|---------------------------------------------|-------------------------------------------------------|
| Did the agent call the Lambda?              | Confirms the OpenAPI schema is understood             |
| Did it pass the right service name?         | Confirms parameter extraction from natural language   |
| Did it use the Lambda response in its reply?| Confirms response parsing works                       |
| Did it skip Lambda for unrelated questions? | Confirms the agent doesn't over-trigger               |

### 3. Test via CLI

After `terraform apply`, prepare the agent if needed:

```bash
aws bedrock-agent prepare-agent \
  --agent-id <agent_id> \
  --region eu-central-1
```

Then invoke it:

```bash
aws bedrock-agent-runtime invoke-agent \
  --agent-id <agent_id> \
  --agent-alias-id <agent_alias_id> \
  --session-id my-test-session-001 \
  --input-text "Who owns the payments service?" \
  --enable-trace \
  --region eu-central-1 \
  output.txt
```