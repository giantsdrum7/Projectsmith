"""IAM roles, OIDC provider, and policies for CI/CD and runtime.

Resources created:
- OIDC provider for GitHub Actions (allows keyless authentication)
- Deploy role with least-privilege policies scoped to {namespace}-* resources
- Region-deny with NotAction exception for Bedrock cross-region inference profiles
- Separate roles: API Lambda execution, worker Lambda execution, Step Functions execution

Alarms (owned by this stack):
- Unauthorized access attempts

Implements:
- Deliverable 3, Section 6 (CDK Deployment Model)
- Deliverable 4, Section 2.8 (Deploy Workflows — OIDC pattern)
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Duration,
    Stack,
    aws_cloudwatch as cloudwatch,
    aws_iam as iam,
)
from constructs import Construct


class IamStack(Stack):
    """IAM roles and OIDC provider for CI/CD and Lambda execution."""

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

        region = config.get("aws_region", "us-east-1")

        # --- GitHub Actions OIDC Provider ---
        # Only one OIDC provider per account for GitHub — this may already exist.
        # If deploying to a fresh account, this creates it; if it already exists,
        # use iam.OpenIdConnectProvider.from_open_id_connect_provider_arn() instead.
        self.github_oidc = iam.OpenIdConnectProvider(
            self,
            "GitHubOidc",
            url="https://token.actions.githubusercontent.com",
            client_ids=["sts.amazonaws.com"],
            thumbprints=["ffffffffffffffffffffffffffffffffffffffff"],
        )

        # --- Deploy Role (for GitHub Actions CI/CD) ---
        self.deploy_role = iam.Role(
            self,
            "DeployRole",
            role_name=f"{namespace}-deploy",
            assumed_by=iam.FederatedPrincipal(
                self.github_oidc.open_id_connect_provider_arn,
                conditions={
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub": "repo:*:ref:refs/heads/main",
                    },
                },
                assume_role_action="sts:AssumeRoleWithWebIdentity",
            ),
            max_session_duration=Duration.hours(1),
            description=f"CDK deploy role for {namespace} (GitHub Actions OIDC)",
        )

        # Least-privilege: scoped to namespace-prefixed resources
        self.deploy_role.add_to_policy(
            iam.PolicyStatement(
                sid="AllowNamespacedResources",
                effect=iam.Effect.ALLOW,
                actions=[
                    "cloudformation:*",
                    "s3:*",
{% if metadata_store == "dynamodb" %}
                    "dynamodb:*",
{% elif metadata_store == "postgres" %}
                    "rds:*",
                    "rds-data:*",
                    "secretsmanager:GetSecretValue",
{% endif %}
                    "lambda:*",
                    "apigateway:*",
                    "cognito-idp:*",
                    "states:*",
                    "kms:*",
                    "cloudfront:*",
                    "appconfig:*",
                    "logs:*",
                    "cloudwatch:*",
                    "sns:*",
                    "iam:PassRole",
                ],
                resources=[f"arn:aws:*:*:*:*{namespace}*"],
            )
        )

        # CDK bootstrap resources
        self.deploy_role.add_to_policy(
            iam.PolicyStatement(
                sid="AllowCdkBootstrap",
                effect=iam.Effect.ALLOW,
                actions=[
                    "ssm:GetParameter",
                    "sts:AssumeRole",
                ],
                resources=[
                    f"arn:aws:ssm:{region}:*:parameter/cdk-bootstrap/*",
                    f"arn:aws:iam::*:role/cdk-*",
                ],
            )
        )

        # Region-deny with NotAction exception for Bedrock cross-region inference
        self.deploy_role.add_to_policy(
            iam.PolicyStatement(
                sid="DenyNonPrimaryRegionExceptBedrock",
                effect=iam.Effect.DENY,
                not_actions=["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
                resources=["*"],
                conditions={
                    "StringNotEquals": {
                        "aws:RequestedRegion": [region],
                    },
                },
            )
        )

        # --- API Lambda Execution Role ---
        self.api_lambda_role = iam.Role(
            self,
            "ApiLambdaRole",
            role_name=f"{namespace}-api-lambda",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AWSXRayDaemonWriteAccess"
                ),
            ],
            description=f"Execution role for {namespace} API Lambda functions",
        )
        # TODO: Add {% if metadata_store == "dynamodb" %}DynamoDB{% elif metadata_store == "postgres" %}PostgreSQL/Aurora{% else %}metadata-store{% endif %}, S3, Bedrock, AppConfig permissions scoped to namespace resources

        # --- Worker Lambda Execution Role ---
        self.worker_lambda_role = iam.Role(
            self,
            "WorkerLambdaRole",
            role_name=f"{namespace}-worker-lambda",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AWSXRayDaemonWriteAccess"
                ),
            ],
            description=f"Execution role for {namespace} worker Lambda functions",
        )
        # TODO: Add {% if metadata_store == "dynamodb" %}DynamoDB{% elif metadata_store == "postgres" %}PostgreSQL/Aurora{% else %}metadata-store{% endif %}, S3, Bedrock, Step Functions permissions scoped to namespace resources

        # --- Step Functions Execution Role ---
        self.step_functions_role = iam.Role(
            self,
            "StepFunctionsRole",
            role_name=f"{namespace}-stepfunctions",
            assumed_by=iam.ServicePrincipal("states.amazonaws.com"),
            description=f"Execution role for {namespace} Step Functions state machines",
        )
        self.step_functions_role.add_to_policy(
            iam.PolicyStatement(
                sid="AllowLambdaInvoke",
                effect=iam.Effect.ALLOW,
                actions=["lambda:InvokeFunction"],
                resources=[f"arn:aws:lambda:{region}:*:function:{namespace}-*"],
            )
        )
        self.step_functions_role.add_to_policy(
            iam.PolicyStatement(
                sid="AllowBedrockInvoke",
                effect=iam.Effect.ALLOW,
                actions=["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
                resources=["*"],
            )
        )
{% if metadata_store == "dynamodb" %}
        self.step_functions_role.add_to_policy(
            iam.PolicyStatement(
                sid="AllowDynamoDBAccess",
                effect=iam.Effect.ALLOW,
                actions=[
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:Query",
                    "dynamodb:BatchGetItem",
                    "dynamodb:BatchWriteItem",
                ],
                resources=[
                    f"arn:aws:dynamodb:{region}:*:table/{namespace}-platform",
                    f"arn:aws:dynamodb:{region}:*:table/{namespace}-platform/index/*",
                ],
            )
        )
{% elif metadata_store == "postgres" %}
        self.step_functions_role.add_to_policy(
            iam.PolicyStatement(
                sid="AllowAuroraDataApiAccess",
                effect=iam.Effect.ALLOW,
                actions=[
                    "rds-data:BatchExecuteStatement",
                    "rds-data:BeginTransaction",
                    "rds-data:CommitTransaction",
                    "rds-data:ExecuteStatement",
                    "rds-data:RollbackTransaction",
                    "secretsmanager:GetSecretValue",
                ],
                resources=[
                    f"arn:aws:rds:{region}:*:cluster:{namespace}-*",
                    f"arn:aws:secretsmanager:{region}:*:secret:{namespace}-*",
                ],
            )
        )
{% endif %}

        # --- Alarm: Unauthorized Access Attempts ---
        # Uses CloudTrail metrics for access denied events
        self.unauthorized_alarm = cloudwatch.Alarm(
            self,
            "UnauthorizedAccessAlarm",
            alarm_name=f"{namespace}-unauthorized-access",
            metric=cloudwatch.Metric(
                namespace=f"{namespace}/Security",
                metric_name="UnauthorizedAttempts",
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=10,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=(
                f"Unauthorized access attempts above baseline for {namespace}. "
                "Requires custom metric emission from Lambda authorizer."
            ),
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
