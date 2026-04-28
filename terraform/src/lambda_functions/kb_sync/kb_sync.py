import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    kb_id = os.environ["KNOWLEDGE_BASE_ID"]
    ds_id = os.environ["DATA_SOURCE_ID"]

    client = boto3.client("bedrock-agent")
    response = client.start_ingestion_job(
        knowledgeBaseId=kb_id,
        dataSourceId=ds_id,
    )

    job_id = response["ingestionJob"]["ingestionJobId"]
    logger.info("Started ingestion job %s for KB %s", job_id, kb_id)
    return {"ingestionJobId": job_id}
