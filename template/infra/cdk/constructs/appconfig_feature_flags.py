"""AppConfig construct for feature flags, prompt version control, and kill switches.

Creates the AppConfig infrastructure wiring:
- Application: one per deployment namespace
- Environment: default environment
- Configuration Profile: feature flags (AWS.AppConfig.FeatureFlags type)
- Deployment Strategy: linear 20% over 10 minutes with 5-minute bake

The construct provides the infrastructure skeleton. Actual flag definitions
and prompt-version policies are added post-generation.

Used for:
- Feature flags (proposal_gen, chat, documents, mcp_enabled, etc.)
- Prompt version control (active prompt version per environment)
- Kill switches (emergency feature disable without deployment)

Implements Deliverable 3, Section 2.2 (Prompt Registry — AppConfig layer)
and Deliverable 4, Section 2.2 (appconfig_feature_flags construct).
"""

from __future__ import annotations

from aws_cdk import aws_appconfig as appconfig
from constructs import Construct


class AppConfigFeatureFlags(Construct):
    """AppConfig application with feature flag configuration profile."""

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        namespace: str,
    ) -> None:
        super().__init__(scope, construct_id)

        self.application = appconfig.CfnApplication(
            self,
            "Application",
            name=f"{namespace}-config",
            description=f"Feature flags and runtime configuration for {namespace}",
        )

        self.environment = appconfig.CfnEnvironment(
            self,
            "Environment",
            application_id=self.application.ref,
            name="default",
            description="Default deployment environment",
        )

        self.deployment_strategy = appconfig.CfnDeploymentStrategy(
            self,
            "DeploymentStrategy",
            name=f"{namespace}-linear-20pct-10min",
            deployment_duration_in_minutes=10,
            growth_factor=20,
            growth_type="LINEAR",
            replicate_to="NONE",
            final_bake_time_in_minutes=5,
            description="Linear 20% over 10 minutes for safe feature flag rollout",
        )

        self.feature_flag_profile = appconfig.CfnConfigurationProfile(
            self,
            "FeatureFlagProfile",
            application_id=self.application.ref,
            name="feature-flags",
            location_uri="hosted",
            type="AWS.AppConfig.FeatureFlags",
            description="Feature visibility flags and kill switches",
        )

        # TODO: Add hosted configuration version with actual flag definitions post-generation
        # Expected flags: proposal_gen, chat, documents, rate_cases, mcp_enabled
        # See Deliverable 3, Section 4.2 (Feature Visibility) for the full flag contract.
        # Also used for prompt version pointers and operational kill switches.
