# AI Agent on AWS

Terraform infrastructure for an AI Agent built with Amazon Bedrock.

## Source

This project follows the LinkedIn Learning course:
**AI Challenge: Build an AI Agent in 7 Steps in 7 Days with AWS**

## Structure

```
terraform/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
└── modules/
    └── bedrock-agent/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
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

After `terraform apply`, prepare the agent before invoking it:

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
  --input-text "Hello, what can you do?" \
  --region eu-central-1 \
  output.txt
```