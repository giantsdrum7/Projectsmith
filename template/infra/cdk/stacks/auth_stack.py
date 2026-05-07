"""Cognito User Pool for authentication and user management.

Resources created:
- Cognito User Pool: {namespace}-users
  - Custom attribute: custom:tenant_id (immutable after creation)
  - Standard attributes: email (required, verified)
- App client with OAuth configuration (callback/logout URLs from client config)
- User groups: proposal_author, reviewer, admin

Alarms (owned by this stack):
- Failed authentication attempts above baseline

Implements:
- Deliverable 3, Section 5 (Auth & Tenancy Model)
- Deliverable 3, Section 5.2 (Cognito Configuration)
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Duration,
    Stack,
    aws_cloudwatch as cloudwatch,
    aws_cognito as cognito,
)
from constructs import Construct


class AuthStack(Stack):
    """Cognito User Pool with tenant-aware custom attributes and user groups."""

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

        cognito_config = config.get("cognito", {})

        # --- Cognito User Pool ---
        self.user_pool = cognito.UserPool(
            self,
            "UserPool",
            user_pool_name=f"{namespace}-users",
            self_sign_up_enabled=False,
            sign_in_aliases=cognito.SignInAliases(email=True),
            auto_verify=cognito.AutoVerifiedAttrs(email=True),
            standard_attributes=cognito.StandardAttributes(
                email=cognito.StandardAttribute(required=True, mutable=True),
                fullname=cognito.StandardAttribute(required=False, mutable=True),
            ),
            custom_attributes={
                "tenant_id": cognito.StringAttribute(
                    mutable=False,
                    min_len=1,
                    max_len=64,
                ),
            },
            password_policy=cognito.PasswordPolicy(
                min_length=12,
                require_lowercase=True,
                require_uppercase=True,
                require_digits=True,
                require_symbols=True,
                temp_password_validity=Duration.days(7),
            ),
            account_recovery=cognito.AccountRecovery.EMAIL_ONLY,
            # TODO: Configure identity provider per client requirements
            # TODO: Configure MFA per client security requirements
        )

        # --- App Client ---
        callback_urls = cognito_config.get("callback_urls", ["http://localhost:5173/callback"])
        logout_urls = cognito_config.get("logout_urls", ["http://localhost:5173/"])

        self.app_client = self.user_pool.add_client(
            "AppClient",
            user_pool_client_name=f"{namespace}-app",
            auth_flows=cognito.AuthFlow(
                user_password=True,
                user_srp=True,
            ),
            o_auth=cognito.OAuthSettings(
                flows=cognito.OAuthFlows(authorization_code_grant=True),
                scopes=[cognito.OAuthScope.OPENID, cognito.OAuthScope.EMAIL, cognito.OAuthScope.PROFILE],
                callback_urls=callback_urls,
                logout_urls=logout_urls,
            ),
            prevent_user_existence_errors=True,
        )

        # --- User Groups ---
        # Maps to capability bundle roles (Deliverable 3, Section 2.4)
        for group_name, description in [
            ("proposal_author", "Can create and edit proposals"),
            ("reviewer", "Can review and approve proposals"),
            ("admin", "Full administrative access"),
        ]:
            cognito.CfnUserPoolGroup(
                self,
                f"Group{group_name.title().replace('_', '')}",
                user_pool_id=self.user_pool.user_pool_id,
                group_name=group_name,
                description=description,
            )

        # --- Alarm: Failed Auth Attempts ---
        self.failed_auth_alarm = cloudwatch.Alarm(
            self,
            "FailedAuthAlarm",
            alarm_name=f"{namespace}-failed-auth",
            metric=cloudwatch.Metric(
                namespace="AWS/Cognito",
                metric_name="SignInSuccesses",
                dimensions_map={"UserPool": self.user_pool.user_pool_id},
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            # TODO: Replace with a proper failed-auth metric or custom metric
            # Cognito does not natively emit a "failed sign-in" CloudWatch metric.
            # Consider a Lambda trigger on failed auth events to emit custom metrics.
            threshold=0,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=(
                f"Authentication activity monitor for {namespace}. "
                "Replace with failed-auth custom metric post-generation."
            ),
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
