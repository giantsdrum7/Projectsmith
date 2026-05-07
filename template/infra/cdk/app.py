#!/usr/bin/env python3
"""CDK app entry point for per-client parameterized infrastructure deployment.

Each client (e.g., idi, stevens, hope) has a JSON config file in config/ that
drives all resource naming and stack parameters. The deployment_namespace
(derived from project_slug + client_id + environment_tier) ensures complete
isolation between client deployments in the same or different AWS accounts.

Usage:
    cdk deploy --all --context client=example --context env=dev
    cdk synth --all --context client=example --context env=dev

Per-client instance model (Deliverable 3, Section 6.3):
    Same codebase → cdk deploy with different --context client=X →
    isolated AWS resources per client, all prefixed with namespace.

Implements Deliverable 3, Section 6 (CDK Deployment Model).
"""

from __future__ import annotations

import json
import os
import sys

# Ensure this directory is on sys.path for local imports
_app_dir = os.path.dirname(os.path.abspath(__file__))
if _app_dir not in sys.path:
    sys.path.insert(0, _app_dir)

import aws_cdk as cdk  # noqa: E402

from stacks.data_stack import DataStack  # noqa: E402
from stacks.auth_stack import AuthStack  # noqa: E402
from stacks.api_stack import ApiStack  # noqa: E402
from stacks.orchestration_stack import OrchestrationStack  # noqa: E402
from stacks.frontend_stack import FrontendStack  # noqa: E402
from stacks.search_stack import SearchStack  # noqa: E402
from stacks.iam_stack import IamStack  # noqa: E402

app = cdk.App()

# --- Read context parameters ---
client = app.node.try_get_context("client")
env_tier = app.node.try_get_context("env")

if not client:
    raise ValueError(
        "Missing required context: --context client=<client_id>. "
        "Each client must have a config/<client_id>.json file."
    )
if not env_tier:
    raise ValueError(
        "Missing required context: --context env=<dev|staging|prod>. "
        "This determines the deployment target and resource naming."
    )

# --- Load client config ---
config_path = os.path.join(_app_dir, "config", f"{client}.json")
if not os.path.exists(config_path):
    raise FileNotFoundError(
        f"Client config not found: {config_path}. "
        f"Create config/{client}.json before deploying."
    )

with open(config_path) as f:
    config = json.load(f)

# Sanitize namespace: S3 bucket names and CloudFormation stack names disallow
# underscores. Hyphens are universally safe across all AWS resource types.
namespace = config["deployment_namespace"].replace("_", "-")
region = config.get("aws_region", "us-east-1")

cdk_env = cdk.Environment(region=region)

# --- Instantiate stacks ---
# Each stack uses namespace for resource naming and owns its own CloudWatch
# alarms (distributed ownership model, Deliverable 3 Section 6.4).

data = DataStack(
    app, f"{namespace}-data",
    config=config, namespace=namespace, env=cdk_env,
)
auth = AuthStack(
    app, f"{namespace}-auth",
    config=config, namespace=namespace, env=cdk_env,
)
api = ApiStack(
    app, f"{namespace}-api",
    config=config, namespace=namespace, env=cdk_env,
)
orchestration = OrchestrationStack(
    app, f"{namespace}-orchestration",
    config=config, namespace=namespace, env=cdk_env,
)
frontend = FrontendStack(
    app, f"{namespace}-frontend",
    config=config, namespace=namespace, env=cdk_env,
)
search = SearchStack(
    app, f"{namespace}-search",
    config=config, namespace=namespace, env=cdk_env,
)
iam_stack = IamStack(
    app, f"{namespace}-iam",
    config=config, namespace=namespace, env=cdk_env,
)

app.synth()
