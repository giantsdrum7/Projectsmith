"""Mangum Lambda adapter — entry point for AWS Lambda behind API Gateway.

Referenced by the Dockerfile CMD and the CDK api_stack.py Lambda handler config.
"""

from __future__ import annotations

from mangum import Mangum

from {{ project_slug }}.api.app import app

lambda_handler = Mangum(app, lifespan="off")
