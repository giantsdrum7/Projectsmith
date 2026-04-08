"""Step Functions state machine shells for proposal and document pipelines.

SHELL ONLY — no concrete state machine definitions. State machine logic
(Group 2 proposal DAG, document processing pipeline) is added post-generation.

Resources created:
- Step Functions state machine: {namespace}-proposal-pipeline (placeholder Pass state)
- Step Functions state machine: {namespace}-document-pipeline (placeholder Pass state)
- IAM roles for state machine execution (Lambda invoke, Bedrock invoke, DynamoDB access)

Alarms (owned by this stack):
- Execution failure rate
- Execution timeout rate

Implements:
- Deliverable 3, Section 3.1 (Step Functions Pipeline) — shell only
- Deliverable 4, Section 2.2 (orchestration_stack.py — shell starter)
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Duration,
    Stack,
    aws_cloudwatch as cloudwatch,
    aws_iam as iam,
    aws_stepfunctions as sfn,
)
from constructs import Construct


class OrchestrationStack(Stack):
    """Step Functions state machine shells with IAM wiring and alarm ownership."""

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

        # --- State Machine Execution Role ---
        self.execution_role = iam.Role(
            self,
            "ExecutionRole",
            role_name=f"{namespace}-sfn-execution",
            assumed_by=iam.ServicePrincipal("states.amazonaws.com"),
            description=f"Execution role for {namespace} Step Functions state machines",
        )

        self.execution_role.add_to_policy(
            iam.PolicyStatement(
                sid="InvokeLambda",
                effect=iam.Effect.ALLOW,
                actions=["lambda:InvokeFunction"],
                resources=[f"arn:aws:lambda:{region}:*:function:{namespace}-*"],
            )
        )
        self.execution_role.add_to_policy(
            iam.PolicyStatement(
                sid="InvokeBedrock",
                effect=iam.Effect.ALLOW,
                actions=[
                    "bedrock:InvokeModel",
                    "bedrock:InvokeModelWithResponseStream",
                ],
                resources=["*"],
            )
        )
        self.execution_role.add_to_policy(
            iam.PolicyStatement(
                sid="DynamoDBAccess",
                effect=iam.Effect.ALLOW,
                actions=[
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:Query",
                    "dynamodb:BatchGetItem",
                ],
                resources=[
                    f"arn:aws:dynamodb:{region}:*:table/{namespace}-platform",
                    f"arn:aws:dynamodb:{region}:*:table/{namespace}-platform/index/*",
                ],
            )
        )

        # --- Proposal Pipeline (placeholder) ---
        # TODO: Add concrete state machine definitions post-generation (Group 2 proposal DAG)
        # The proposal pipeline implements: template resolution → variable binding →
        # tiered-parallel section generation → validation → review pause → export.
        # See Deliverable 3, Section 3.1 for the full pipeline design.
        proposal_placeholder = sfn.Pass(
            self,
            "ProposalPlaceholder",
            comment=(
                "TODO: Replace with proposal pipeline state machine definition. "
                "See Group 2 locked contract for the section DAG, review lifecycle, "
                "and financial calculator integration."
            ),
        )

        self.proposal_pipeline = sfn.StateMachine(
            self,
            "ProposalPipeline",
            state_machine_name=f"{namespace}-proposal-pipeline",
            definition_body=sfn.DefinitionBody.from_chainable(proposal_placeholder),
            role=self.execution_role,
            timeout=Duration.hours(24),
        )

        # --- Document Pipeline (placeholder) ---
        # TODO: Add concrete state machine definitions post-generation (document processing)
        # The document pipeline implements: extract → embed → store in KB/OpenSearch.
        document_placeholder = sfn.Pass(
            self,
            "DocumentPlaceholder",
            comment=(
                "TODO: Replace with document processing pipeline definition. "
                "Steps: extract text → chunk → embed → store in search backend."
            ),
        )

        self.document_pipeline = sfn.StateMachine(
            self,
            "DocumentPipeline",
            state_machine_name=f"{namespace}-document-pipeline",
            definition_body=sfn.DefinitionBody.from_chainable(document_placeholder),
            role=self.execution_role,
            timeout=Duration.hours(4),
        )

        # --- Alarms ---
        self.failure_alarm = cloudwatch.Alarm(
            self,
            "ExecutionFailureAlarm",
            alarm_name=f"{namespace}-sfn-failures",
            metric=cloudwatch.Metric(
                namespace="AWS/States",
                metric_name="ExecutionsFailed",
                dimensions_map={
                    "StateMachineArn": self.proposal_pipeline.state_machine_arn,
                },
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=3,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"Step Functions execution failures for {namespace}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )

        self.timeout_alarm = cloudwatch.Alarm(
            self,
            "ExecutionTimeoutAlarm",
            alarm_name=f"{namespace}-sfn-timeouts",
            metric=cloudwatch.Metric(
                namespace="AWS/States",
                metric_name="ExecutionsTimedOut",
                dimensions_map={
                    "StateMachineArn": self.proposal_pipeline.state_machine_arn,
                },
                statistic="Sum",
                period=Duration.minutes(15),
            ),
            threshold=1,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"Step Functions execution timeouts for {namespace}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
