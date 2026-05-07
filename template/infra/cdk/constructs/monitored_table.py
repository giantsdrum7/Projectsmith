"""DynamoDB table construct with CloudWatch alarms auto-attached.

Creates a DynamoDB table and attaches standard alarms for operational
awareness. Follows the distributed alarm ownership model where the stack
that creates a resource also owns its alarms.

Alarms:
- Throttle alarm: ReadThrottleEvents + WriteThrottleEvents > threshold
- System error alarm: SystemErrors > 0

Implements Deliverable 3, Section 6.4 (distributed alarm ownership).
"""

from __future__ import annotations

from aws_cdk import (
    Duration,
    aws_cloudwatch as cloudwatch,
    aws_cloudwatch_actions as cw_actions,
    aws_dynamodb as dynamodb,
    aws_sns as sns,
)
from constructs import Construct


class MonitoredTable(Construct):
    """DynamoDB table with throttle and system error alarms auto-attached."""

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        table_name: str,
        partition_key: dynamodb.Attribute,
        sort_key: dynamodb.Attribute | None = None,
        billing_mode: dynamodb.BillingMode = dynamodb.BillingMode.PAY_PER_REQUEST,
        stream: dynamodb.StreamViewType | None = None,
        point_in_time_recovery: bool = True,
        alarm_topic: sns.ITopic | None = None,
    ) -> None:
        super().__init__(scope, construct_id)

        table_kwargs: dict = {
            "table_name": table_name,
            "partition_key": partition_key,
            "billing_mode": billing_mode,
            "point_in_time_recovery": point_in_time_recovery,
        }
        if sort_key:
            table_kwargs["sort_key"] = sort_key
        if stream:
            table_kwargs["stream"] = stream

        self.table = dynamodb.Table(self, "Table", **table_kwargs)

        read_throttle = cloudwatch.Metric(
            namespace="AWS/DynamoDB",
            metric_name="ReadThrottleEvents",
            dimensions_map={"TableName": table_name},
            statistic="Sum",
            period=Duration.minutes(5),
        )
        write_throttle = cloudwatch.Metric(
            namespace="AWS/DynamoDB",
            metric_name="WriteThrottleEvents",
            dimensions_map={"TableName": table_name},
            statistic="Sum",
            period=Duration.minutes(5),
        )

        self.throttle_alarm = cloudwatch.Alarm(
            self,
            "ThrottleAlarm",
            alarm_name=f"{table_name}-throttle",
            metric=cloudwatch.MathExpression(
                expression="m1 + m2",
                using_metrics={"m1": read_throttle, "m2": write_throttle},
            ),
            threshold=5,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"DynamoDB throttle events on {table_name}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )

        self.system_error_alarm = cloudwatch.Alarm(
            self,
            "SystemErrorAlarm",
            alarm_name=f"{table_name}-system-errors",
            metric=cloudwatch.Metric(
                namespace="AWS/DynamoDB",
                metric_name="SystemErrors",
                dimensions_map={"TableName": table_name},
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=1,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            alarm_description=f"DynamoDB system errors on {table_name}",
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )

        if alarm_topic:
            self.throttle_alarm.add_alarm_action(cw_actions.SnsAction(alarm_topic))
            self.system_error_alarm.add_alarm_action(cw_actions.SnsAction(alarm_topic))
