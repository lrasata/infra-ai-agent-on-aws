import json

SERVICES = {
    "payments": {
        "owner": "Payments Team",
        "on_call": "payments-oncall@example.com",
        "status": "Degraded performance",
    },
    "auth": {
        "owner": "Identity Team",
        "on_call": "identity-oncall@example.com",
        "status": "Operational",
    },
}

def _get_param(event, name: str):
    """
    Bedrock Agents commonly pass parameters as:
      event["parameters"] = [{"name": "...", "type": "...", "value": "..."}]
    """
    for p in event.get("parameters", []):
        if p.get("name") == name:
            return p.get("value")
    return None

def lambda_handler(event, context):
    # Extract inputs
    service = (_get_param(event, "service") or "").strip().lower()

    if not service:
        result = {
            "found": False,
            "message": "Missing required parameter: service",
        }
        http_status = 400
    elif service not in SERVICES:
        result = {
            "found": False,
            "service": service,
            "message": "Unknown service",
        }
        http_status = 404
    else:
        result = {
            "found": True,
            "service": service,
            "owner": SERVICES[service]["owner"],
            "on_call": SERVICES[service]["on_call"],
            "status": SERVICES[service]["status"],
        }
        http_status = 200

    # Bedrock Agents action-group response envelope
    response_body = {
        "application/json": {
            "body": json.dumps(result)
        }
    }

    action_response = {
        "actionGroup": event["actionGroup"],
        "apiPath": event["apiPath"],
        "httpMethod": event["httpMethod"],
        "httpStatusCode": http_status,
        "responseBody": response_body,
    }

    return {
        "messageVersion": "1.0",
        "response": action_response,
        "sessionAttributes": event.get("sessionAttributes", {}),
        "promptSessionAttributes": event.get("promptSessionAttributes", {}),
    }