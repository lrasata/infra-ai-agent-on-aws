data "aws_caller_identity" "current" {}

locals {

  # OPS GET SERVICE INFO ACTION
  lambda_configs = {

    # RAG evaluation lambda — runs the golden-dataset evaluation pipeline
    rag_evaluation = {
      base_name    = "ops-get-service-info"
      source_dir   = "${path.module}/src/lambda_functions/ops_get_service_info"
      handler_file = "ops_get_service_info.handler"
      runtime      = "python3.14"
      iam_policy_statements = [
        {
          "Sid" : "AllowInvokeToolLambda",
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:ops_get_service_info"
          ]
        }
      ]
    }
  }

}