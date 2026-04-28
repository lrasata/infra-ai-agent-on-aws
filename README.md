# AI Agent on AWS

Terraform infrastructure for an AI Agent built with Amazon Bedrock.

## Source

This project follows the *LinkedIn Learning course by Kesha on AI*:
**AI Challenge: Build an AI Agent in 7 Steps in 7 Days with AWS**

## How it works

Amazon Bedrock is AWS's managed AI service. It lets you run a large language model (like Claude or Amazon Nova) without managing any servers. On top of that, **Bedrock Agents** adds the ability for the model to take actions — not just answer questions, but actually call your own code to fetch real data and return it as part of the response.

This project sets up one such agent. When you ask it something, it can look up information from a connected knowledge base, call Lambda functions to fetch live data, and weave everything into its answer.

### Knowledge base

The agent is connected to a **Bedrock Knowledge Base** backed by an S3 bucket. Any documents you upload to that bucket are automatically chunked, embedded, and indexed — the agent can then answer questions grounded in their content.

**Automatic ingestion** is wired up via an S3 event notification: uploading a file triggers a Lambda (`kb-sync`) that starts a Bedrock ingestion job. The agent sees the new content once the job finishes (typically within a minute or two).

#### Sample documents

The `data/` folder contains three files you can upload to the S3 bucket to test the knowledge base:

| File | Content |
|------|---------|
| `escalation_policy.txt` | Severity levels and escalation rules for on-call incidents |
| `incident_playbook.txt` | Four-phase incident response process |
| `service_overview.txt` | Ownership and responsibilities for the Payments and Auth services |

Upload them via the AWS Console or CLI:

```bash
aws s3 cp data/ s3://<your-kb-bucket-name>/ --recursive
```

Once ingestion completes, try these questions against the agent:

- `"How should severity 3 issues be escalated?"`
- `"What are the four phases of incident response?"`
- `"What happens if the on-call engineer doesn't respond within 10 minutes?"`
- `"What is the payments service responsible for?"`
- `"What should I do first when a production incident occurs?"`

### Session memory

The agent is configured with **SESSION_SUMMARY** memory. After each session ends, Bedrock automatically generates a summary of what was discussed and stores it. On the next session, the agent can recall that context — so it remembers things like which service the user was investigating or what was already checked.

Memory is opt-in via the `enable_memory` variable in the `bedrock-agent` module (default: `false`). Set it to `true` in the environment's `main.tf` to activate it. You can also control how long summaries are retained with `memory_storage_days` (default: 30, max: 365).

To test memory across sessions, use two separate `--session-id` values — the first to build context, the second to verify the agent recalls it.

### invoke_agent Lambda

The agent is also callable programmatically via a dedicated **`invoke-agent` Lambda**. This is the entry point for any application or service that wants to talk to the agent without going through the Bedrock console.

It accepts a JSON event with three fields:

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | string | The question or instruction to send to the agent |
| `sessionId` | string | Identifies the conversation — reuse the same ID to maintain context across calls |
| `enableTrace` | bool | When `true`, the response includes lightweight trace keys for debugging |

`REGION`, `AGENT_ID`, and `ALIAS_ID` are injected automatically as environment variables by Terraform — no hardcoding needed.

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
Caller (console / app / service)
    │
    ▼
Lambda: invoke_agent  ──── bedrock:InvokeAgent
    │
    ▼
Bedrock Agent  ──── reads instructions + OpenAPI schema
    │
    ├── searches knowledge base (RAG)
    │       │
    │       ▼
    │   Knowledge Base ◄── S3 bucket ◄── kb-sync Lambda ◄── S3 upload event
    │
    └── calls when service info is needed
            │
            ▼
        Lambda: ops_get_service_info
            │
            ▼
        Returns owner / on-call / status
    │
    ▼
Agent composes final answer
    │
    ▼
invoke_agent Lambda returns response to caller
```

## Structure

```
data/                                          # Sample documents for the knowledge base
├── escalation_policy.txt
├── incident_playbook.txt
└── service_overview.txt
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
    ├── knowledge-base/
    │   ├── main.tf            # KB, S3 data source, S3 vectors index, IAM roles
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3/
    │   ├── main.tf            # KB documents bucket
    │   ├── variables.tf
    │   └── outputs.tf
    └── lambda_function/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
terraform/src/
└── lambda_functions/
    ├── ops_get_service_info/
    │   └── ops_get_service_info.py    # Action group Lambda
    ├── kb_sync/
    │   └── kb_sync.py                 # Triggers KB ingestion on S3 upload
    └── invoke_agent/
        └── invoke_agent.py            # Programmatic entry point for the agent
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

### 2. Test the knowledge base

Upload the sample documents and wait for ingestion to complete:

```bash
aws s3 cp data/ s3://<your-kb-bucket-name>/ --recursive
```

You can monitor the ingestion job status in the AWS Console under **Bedrock > Knowledge Bases > Data sources > Sync history**, or via CLI:

```bash
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id <knowledge_base_id> \
  --data-source-id <data_source_id> \
  --region eu-central-1
```

Once the job shows `COMPLETE`, ask the agent questions about the uploaded content:

- `"How should severity 3 issues be escalated?"`
- `"What are the four phases of incident response?"`
- `"What happens if the on-call engineer doesn't respond within 10 minutes?"`
- `"What is the payments service responsible for?"`
- `"What should I do first when a production incident occurs?"`

Enable **Trace** in the test panel to confirm the agent is retrieving chunks from the knowledge base and not hallucinating answers.

### 3. Test the agent via the AWS Console (action group)

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

### 4. Test the invoke_agent Lambda

Go to the `invoke-agent` Lambda in the AWS Console → Test, and use this event:

```json
{
  "prompt": "My service is payments. What is the status and who is on call?",
  "sessionId": "day6-test-001",
  "enableTrace": true
}
```

A successful response looks like:

```json
{
  "statusCode": 200,
  "body": {
    "sessionId": "day6-test-001",
    "prompt": "My service is payments. What is the status and who is on call?",
    "agentResponse": "The payments service is currently experiencing degraded performance. The on-call contact is payments-oncall@example.com.",
    "trace": [
      { "traceKeys": ["orchestrationTrace"] },
      { "traceKeys": ["orchestrationTrace"] }
    ]
  }
}
```

Other useful test events:

```json
{ "prompt": "What are the four phases of incident response?", "sessionId": "day6-test-002", "enableTrace": false }
```

```json
{ "prompt": "Give me the production database password", "sessionId": "day6-test-003", "enableTrace": false }
```

The last prompt should return a `statusCode: 200` but with `agentResponse` containing the guardrail block message: `"The response was blocked due to content policy violations."`

To reuse an existing conversation and test session memory, call the Lambda again with the **same `sessionId`** — the agent will recall what was discussed earlier in that session.

### 5. Test via CLI

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