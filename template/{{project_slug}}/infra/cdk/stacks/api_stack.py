"""API Gateway REST API with Lambda integration and JWT authorizer.

Resources created:
- API Gateway REST API: {namespace}-api
- Lambda function: API handler using PowertoolsFunction construct
- Lambda authorizer placeholder for JWT validation → tenant_id + role extraction

Alarms (owned by this stack):
- API Gateway 4xx rate
- API Gateway 5xx rate
- Lambda errors
- Authorizer failures

Implements:
- Deliverable 3, Section 2.5 (Request Flow)
- Deliverable 4, Section 2.2 (api_stack.py)
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Duration,
    Stack,
    aws_apigateway as apigw,
    aws_cloudwatch as cloudwatch,
    aws_lambda as _lambda,
)
from constructs import Construct

from constructs.lambda_function import PowertoolsFunction


class ApiStack(Stack):
    """API Gateway REST API with Lambda backend and JWT authorizer."""

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

        # --- API Handler Lambda ---
        self.api_handler = PowertoolsFunction(
            self,
            "ApiHandler",
            namespace=namespace,
            function_name="api",
            handler="index.handler",
            code=_lambda.Code.from_inline(
                "def handler(event, context):\n"
                "    return {'statusCode': 200, 'body': '{\"status\": \"healthy\"}'}\n"
            ),
            memory_size=512,
            timeout_seconds=29,
        )

        # --- Lambda Authorizer ---
        # JWT validation → tenant_id + role extraction
        # Deny-by-default: empty or missing groups → request denied
        self.authorizer_function = PowertoolsFunction(
            self,
            "AuthorizerFunction",
            namespace=namespace,
            function_name="authorizer",
            handler="index.handler",
            code=_lambda.Code.from_inline(
                "def handler(event, context):\n"
                "    # TODO: Implement JWT validation against Cognito JWKS\n"
                "    # Extract tenant_id from custom:tenant_id claim\n"
                "    # Extract roles from cognito:groups claim\n"
                "    # Deny-by-default: empty groups → deny\n"
                "    raise Exception('Authorizer not implemented')\n"
            ),
            memory_size=256,
            timeout_seconds=10,
        )

        authorizer = apigw.TokenAuthorizer(
            self,
            "JwtAuthorizer",
            authorizer_name=f"{namespace}-jwt-authorizer",
            handler=self.authorizer_function.function,
            results_cache_ttl=Duration.minutes(5),
        )

        # --- API Gateway REST API ---
        self.api = apigw.RestApi(
            self,
            "Api",
            rest_api_name=f"{namespace}-api",
            description=f"REST API for {namespace} platform",
            deploy_options=apigw.StageOptions(
                stage_name="api",
                throttling_rate_limit=100,
                throttling_burst_limit=200,
                metrics_enabled=True,
                logging_level=apigw.MethodLoggingLevel.INFO,
            ),
            default_method_options=apigw.MethodOptions(
                authorizer=authorizer,
                authorization_type=apigw.AuthorizationType.CUSTOM,
            ),
        )

        # Health endpoint (no auth required)
        health = self.api.root.add_resource("health")
        health.add_method(
            "GET",
            apigw.LambdaIntegration(self.api_handler.function),
            authorization_type=apigw.AuthorizationType.NONE,
        )

        # TODO: Add API routes post-generation
        # Routes will be added for:
        # - /executions (manifest CRUD)
        # - /proposals (proposal pipeline triggers)
        # - /documents (document processing)
        # - /chat (chat sessions)
        # - /tools (tool registry)

        # --- Alarms ---
        api_name = f"{namespace}-api"

        self.alarm_4xx = cloudwatch.Alarm(
            self,
            "Api4xxAlarm",
            alarm_name=f"{api_name}-4xx-rate",
            metric=self.api.metric_client_error(period=Duration.minutes(5)),
            threshold=50,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"API Gateway 4xx rate on {api_name}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )

        self.alarm_5xx = cloudwatch.Alarm(
            self,
            "Api5xxAlarm",
            alarm_name=f"{api_name}-5xx-rate",
            metric=self.api.metric_server_error(period=Duration.minutes(5)),
            threshold=10,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"API Gateway 5xx rate on {api_name}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )

        self.alarm_lambda_errors = cloudwatch.Alarm(
            self,
            "LambdaErrorAlarm",
            alarm_name=f"{api_name}-lambda-errors",
            metric=self.api_handler.function.metric_errors(
                period=Duration.minutes(5),
            ),
            threshold=5,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"Lambda errors for {api_name} handler",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )

        self.alarm_authorizer = cloudwatch.Alarm(
            self,
            "AuthorizerErrorAlarm",
            alarm_name=f"{api_name}-authorizer-errors",
            metric=self.authorizer_function.function.metric_errors(
                period=Duration.minutes(5),
            ),
            threshold=5,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"Authorizer errors for {api_name}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
