"""S3 static hosting, CloudFront distribution, and client configuration bucket.

Resources created:
- S3 bucket: {namespace}-frontend (static hosting via CloudFront)
- S3 bucket: {namespace}-config (client-config.json delivery)
- CloudFront distribution with Origin Access Control
  - /* → S3 frontend origin (default behavior)

Alarms (owned by this stack):
- CloudFront error rate

Implements:
- Deliverable 3, Section 4 (Per-Client Product Model)
- Deliverable 3, Section 4E (Config Loading Architecture — S3/CDN)
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Duration,
    RemovalPolicy,
    Stack,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as origins,
    aws_cloudwatch as cloudwatch,
    aws_s3 as s3,
)
from constructs import Construct


class FrontendStack(Stack):
    """S3 + CloudFront for static frontend hosting and client configuration."""

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

        # --- S3 Frontend Bucket ---
        self.frontend_bucket = s3.Bucket(
            self,
            "FrontendBucket",
            bucket_name=f"{namespace}-frontend",
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            removal_policy=RemovalPolicy.RETAIN,
        )

        # --- S3 Config Bucket ---
        # Serves client-config.json with branding, feature flags, and theme tokens.
        # Content-hashed filenames enable deterministic cache invalidation.
        self.config_bucket = s3.Bucket(
            self,
            "ConfigBucket",
            bucket_name=f"{namespace}-config",
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            versioned=True,
            removal_policy=RemovalPolicy.RETAIN,
        )

        # --- CloudFront Distribution ---
        self.distribution = cloudfront.Distribution(
            self,
            "Distribution",
            comment=f"{namespace} frontend distribution",
            default_behavior=cloudfront.BehaviorOptions(
                origin=origins.S3BucketOrigin.with_origin_access_control(
                    self.frontend_bucket,
                ),
                viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                cache_policy=cloudfront.CachePolicy.CACHING_OPTIMIZED,
            ),
            default_root_object="index.html",
            error_responses=[
                cloudfront.ErrorResponse(
                    http_status=404,
                    response_http_status=200,
                    response_page_path="/index.html",
                    ttl=Duration.seconds(0),
                ),
                cloudfront.ErrorResponse(
                    http_status=403,
                    response_http_status=200,
                    response_page_path="/index.html",
                    ttl=Duration.seconds(0),
                ),
            ],
        )

        # Config bucket as additional origin
        self.distribution.add_behavior(
            "/config/*",
            origins.S3BucketOrigin.with_origin_access_control(self.config_bucket),
            viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
            cache_policy=cloudfront.CachePolicy.CACHING_DISABLED,
        )

        # TODO: Add /api/* → API Gateway origin post-generation
        # Requires API Gateway REST API URL from api_stack.
        # Pattern: /api/* → HttpOrigin(api_gateway_url)

        # TODO: Add custom domain configuration per client
        # Requires ACM certificate and Route53 hosted zone.

        # --- Alarm: CloudFront Error Rate ---
        self.error_alarm = cloudwatch.Alarm(
            self,
            "CloudFrontErrorAlarm",
            alarm_name=f"{namespace}-cloudfront-errors",
            metric=cloudwatch.Metric(
                namespace="AWS/CloudFront",
                metric_name="5xxErrorRate",
                dimensions_map={
                    "DistributionId": self.distribution.distribution_id,
                    "Region": "Global",
                },
                statistic="Average",
                period=Duration.minutes(5),
            ),
            threshold=5,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"CloudFront 5xx error rate for {namespace}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
