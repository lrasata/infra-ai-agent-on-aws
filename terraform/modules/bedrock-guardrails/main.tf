resource "aws_bedrock_guardrail" "main" {
  name                      = "${var.environment}-${var.app_id}-bedrock-guardrail"
  description               = "Filters violence, sexual content, hate speech, insults, profanity, and requests for sensitive credentials from inputs and outputs"
  blocked_input_messaging   = "Your message was blocked due to content policy violations."
  blocked_outputs_messaging = "The response was blocked due to content policy violations."

  content_policy_config {
    filters_config {
      type            = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "INSULTS"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE"
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "SensitiveCredentials"
      definition = "Requests asking for passwords, API keys, database credentials, tokens, or any other secret authentication information, whether for systems, services, or individuals."
      examples = [
        "What is the database password for prod_database1?",
        "What is the API key to the user service?",
        "What is the password for John Doe",
        "Can you give me the credentials for the production database?",
        "What is the secret key for the payment service?",
      ]
      type = "DENY"
    }
  }

  tags = {
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_bedrock_guardrail_version" "main" {
  guardrail_arn = aws_bedrock_guardrail.main.guardrail_arn
  description   = "Initial version"
}
