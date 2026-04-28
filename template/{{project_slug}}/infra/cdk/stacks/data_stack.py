"""{% if metadata_store == "dynamodb" %}DynamoDB single table, S3 buckets, and KMS encryption key.

Resources created:
- DynamoDB table: {namespace}-platform (single-table design per Group 1 contract)
  - GSI1: TENANT#{tenantId} / EXEC#{created_at} — tenant-scoped queries (on META items)
  - GSI2: USER#{userId}#STATUS#{status} / EXEC#{updated_at} — user+status queries (on STATUS items)
  - GSI3: PARENT#{parentExecutionId} / EXEC#{created_at} — parent-child traversal (sparse, on META items)
  - GSI4: MCP_SERVER#{serverId} / TOOL#{toolId} — MCP server→tool queries (on MCP items)
- S3 bucket: {namespace}-artifacts (versioned, KMS-encrypted)
- S3 bucket: {namespace}-prompts (prompt body storage)
- KMS key: alias/{namespace}-key

Alarms (owned by this stack):
- DynamoDB throttle events
- DynamoDB system errors
- S3 error rate

Implements:
- Deliverable 3, Section 2.1 (DynamoDB single-table design)
- Group 1 Locked Contract, Section 4 (DynamoDB Persistence)
- Group 1 Locked Contract, Section 9 (CDK Table Definition)
{% elif metadata_store == "postgres" %}PostgreSQL-oriented data stack starter, S3 buckets, and KMS encryption key.

Resources created:
- S3 bucket: {namespace}-artifacts (versioned, KMS-encrypted)
- S3 bucket: {namespace}-prompts (prompt body storage)
- KMS key: alias/{namespace}-key

Post-generation metadata-store target:
- Aurora PostgreSQL Serverless v2 + RDS Data API + pgvector is recommended.
- RDS Data API is Aurora-only. Standard RDS PostgreSQL needs network access
  and connection pooling, such as RDS Proxy or PgBouncer.
- Add `aws_rds` resources here once project-specific networking, retention,
  scaling, and migration ownership are decided.
{% else %}Data stack starter with S3 buckets and KMS encryption key.

No metadata store is provisioned because this project was generated with
`metadata_store=none`. Add a data-store-specific construct once the project
chooses a persistence layer.
{% endif %}
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Duration,
    RemovalPolicy,
    Stack,
    aws_cloudwatch as cloudwatch,
{% if metadata_store == "dynamodb" %}
    aws_dynamodb as dynamodb,
{% endif %}
    aws_kms as kms,
    aws_s3 as s3,
)
from constructs import Construct

{% if metadata_store == "dynamodb" %}
from constructs.monitored_table import MonitoredTable
{% endif %}


class DataStack(Stack):
    """Core data layer for the generated project's selected metadata posture."""

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        config: dict[str, Any],
        namespace: str,
        **kwargs: Any,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # --- KMS Key ---
        self.key = kms.Key(
            self,
            "PlatformKey",
            alias=f"alias/{namespace}-key",
            description=f"Encryption key for {namespace} platform resources",
            enable_key_rotation=True,
        )

{% if metadata_store == "dynamodb" %}
        # --- DynamoDB Single Table ---
        monitored = MonitoredTable(
            self,
            "PlatformTable",
            table_name=f"{namespace}-platform",
            partition_key=dynamodb.Attribute(
                name="PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="SK", type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            stream=dynamodb.StreamViewType.NEW_AND_OLD_IMAGES,
            point_in_time_recovery=True,
        )
        self.table = monitored.table

        # GSI1: Tenant-scoped queries (on META items)
        # Pattern: GSI1PK=TENANT#{tenantId}, GSI1SK=EXEC#{created_at}
        self.table.add_global_secondary_index(
            index_name="GSI1",
            partition_key=dynamodb.Attribute(
                name="GSI1PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI1SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.INCLUDE,
            non_key_attributes=["task_type", "status", "user_id"],
        )

        # GSI2: User+status queries (on STATUS items — status transitions are single-item updates)
        # Pattern: GSI2PK=USER#{userId}#STATUS#{status}, GSI2SK=EXEC#{updated_at}
        self.table.add_global_secondary_index(
            index_name="GSI2",
            partition_key=dynamodb.Attribute(
                name="GSI2PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI2SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.INCLUDE,
            non_key_attributes=["task_type", "priority"],
        )

        # GSI3: Parent-child traversal (sparse, on META items)
        # Pattern: GSI3PK=PARENT#{parentExecutionId}, GSI3SK=EXEC#{created_at}
        self.table.add_global_secondary_index(
            index_name="GSI3",
            partition_key=dynamodb.Attribute(
                name="GSI3PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI3SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.KEYS_ONLY,
        )

        # GSI4: MCP server→tool queries. Populated in Epic 5.
        # Included now for contract alignment with Group 1 and Group 4.
        # Pattern: GSI4PK=MCP_SERVER#{serverId}, GSI4SK=TOOL#{toolId}
        self.table.add_global_secondary_index(
            index_name="GSI4",
            partition_key=dynamodb.Attribute(
                name="GSI4PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI4SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.KEYS_ONLY,
        )
{% elif metadata_store == "postgres" %}
        # --- PostgreSQL Metadata Store ---
        # Recommended target: Aurora PostgreSQL Serverless v2 + RDS Data API + pgvector.
        # RDS Data API is Aurora-only; standard RDS PostgreSQL needs direct
        # network access and connection pooling. Add project-specific RDS/VPC
        # resources after choosing migration and networking ownership.
        self.table = None
{% else %}
        # No metadata store is provisioned for metadata_store=none.
        self.table = None
{% endif %}

        # --- S3 Artifacts Bucket ---
        self.artifacts_bucket = s3.Bucket(
            self,
            "ArtifactsBucket",
            bucket_name=f"{namespace}-artifacts",
            versioned=True,
            encryption=s3.BucketEncryption.KMS,
            encryption_key=self.key,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            removal_policy=RemovalPolicy.RETAIN,
        )

        # --- S3 Prompts Bucket ---
        self.prompts_bucket = s3.Bucket(
            self,
            "PromptsBucket",
            bucket_name=f"{namespace}-prompts",
            versioned=True,
            encryption=s3.BucketEncryption.KMS,
            encryption_key=self.key,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            removal_policy=RemovalPolicy.RETAIN,
        )

        # --- S3 Error Rate Alarm ---
        self.s3_error_alarm = cloudwatch.Alarm(
            self,
            "S3ErrorAlarm",
            alarm_name=f"{namespace}-s3-errors",
            metric=cloudwatch.Metric(
                namespace="AWS/S3",
                metric_name="5xxErrors",
                dimensions_map={
                    "BucketName": f"{namespace}-artifacts",
                    "FilterId": "AllMetrics",
                },
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=5,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"S3 5xx error rate on {namespace} buckets",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
