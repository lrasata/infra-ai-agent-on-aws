import json
import logging
import os

import boto3
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

REGION = os.environ.get("REGION", "YOUR_REGION")
AGENT_ID = os.environ.get("AGENT_ID", "YOUR_AGENT_ID")
ALIAS_ID = os.environ.get("ALIAS_ID", "YOUR_ALIAS_ID")

client = boto3.client("bedrock-agent-runtime", region_name=REGION)


def invoke_agent(client, agent_id, alias_id, prompt, session_id, enable_trace=True):
    """
    Invokes a Bedrock Agent and returns:
      - completion_text: the assembled agent response text
      - trace_summaries: lightweight trace info for logging/debug
    """
    response = client.invoke_agent(
        agentId=agent_id,
        agentAliasId=alias_id,
        enableTrace=enable_trace,
        sessionId=session_id,
        inputText=prompt,
        streamingConfigurations={
            "applyGuardrailInterval": 20,
            "streamFinalResponse": True,
        },
    )

    completion_text = ""
    trace_summaries = []

    for event in response.get("completion", []):
        # Collect agent output chunks
        if "chunk" in event:
            chunk = event["chunk"]
            completion_text += chunk["bytes"].decode("utf-8")

        # Log trace output (keep it readable)
        if enable_trace and "trace" in event:
            trace_event = event.get("trace", {})
            trace = trace_event.get("trace", {})
            # Don't dump everything; just log keys and a short summary
            trace_summaries.append({"traceKeys": list(trace.keys())})
            logger.info("Trace keys: %s", list(trace.keys()))

    return completion_text, trace_summaries


def lambda_handler(event, context):
    """
    Test event example:
    {
      "prompt": "My service is payments. What is the status and who is on call?",
      "sessionId": "day6-test-001",
      "enableTrace": true
    }
    """
    prompt = event.get("prompt", "Hello agent")
    session_id = event.get("sessionId", "default-session")
    enable_trace = bool(event.get("enableTrace", True))

    try:
        completion, trace_summaries = invoke_agent(
            client=client,
            agent_id=AGENT_ID,
            alias_id=ALIAS_ID,
            prompt=prompt,
            session_id=session_id,
            enable_trace=enable_trace,
        )

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "sessionId": session_id,
                    "prompt": prompt,
                    "agentResponse": completion,
                    "trace": trace_summaries if enable_trace else [],
                }
            ),
        }

    except ClientError as e:
        logger.error("ClientError invoking agent: %s", str(e), exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e), "sessionId": session_id}),
        }
