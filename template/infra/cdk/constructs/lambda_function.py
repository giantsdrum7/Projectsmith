"""Reusable L3 Lambda function construct with Lambda Powertools preconfigured.

Wraps aws_lambda.Function with:
- Lambda Powertools environment variables (Logger + Tracer + Metrics)
- X-Ray active tracing enabled
- Standard environment variables (DEPLOYMENT_NAMESPACE, TABLE_NAME, LOG_LEVEL)
- Standard tags (project, client, environment)
- Configurable memory and timeout with sensible defaults

Implements Deliverable 3, Section 2.6 (Observability) and Section 6.4
(distributed alarm ownership via Powertools custom metrics).
"""

from __future__ import annotations

from typing import Any

from aws_cdk import Duration, Tags, aws_lambda as _lambda, aws_logs as logs
from constructs import Construct


class PowertoolsFunction(Construct):
    """Lambda function with AWS Lambda Powertools preconfigured.

    Creates a Lambda function with Powertools environment variables for
    structured logging, tracing, and custom metrics. All functions share
    a consistent observability surface across the platform.
    """

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        namespace: str,
        function_name: str,
        handler: str,
        code: _lambda.Code,
        runtime: _lambda.Runtime = _lambda.Runtime.PYTHON_3_12,
        memory_size: int = 512,
        timeout_seconds: int = 30,
        environment: dict[str, str] | None = None,
        table_name: str | None = None,
        log_level: str = "INFO",
        layers: list[_lambda.ILayerVersion] | None = None,
        **kwargs: Any,
    ) -> None:
        super().__init__(scope, construct_id)

        env_vars: dict[str, str] = {
            "DEPLOYMENT_NAMESPACE": namespace,
            "LOG_LEVEL": log_level,
            "POWERTOOLS_SERVICE_NAME": function_name,
            "POWERTOOLS_METRICS_NAMESPACE": namespace,
            "POWERTOOLS_LOG_LEVEL": log_level,
        }
        if table_name:
            env_vars["TABLE_NAME"] = table_name
        if environment:
            env_vars.update(environment)

        self.function = _lambda.Function(
            self,
            "Function",
            function_name=f"{namespace}-{function_name}",
            runtime=runtime,
            handler=handler,
            code=code,
            memory_size=memory_size,
            timeout=Duration.seconds(timeout_seconds),
            environment=env_vars,
            tracing=_lambda.Tracing.ACTIVE,
            log_retention=logs.RetentionDays.ONE_MONTH,
            layers=layers or [],
            **kwargs,
        )

        Tags.of(self.function).add("project", namespace)
        # TODO: Add 'client' and 'environment' tags from config post-generation
