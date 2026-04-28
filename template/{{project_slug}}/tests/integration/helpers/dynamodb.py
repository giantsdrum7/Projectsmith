"""DynamoDB Local helpers for integration tests.

Creates the single-table schema with GSI1–GSI4 matching ``data_stack.py``,
seeds test fixtures, and provides cleanup utilities.
"""

from __future__ import annotations

from typing import Any


def create_platform_table(endpoint_url: str, table_name: str = "test-platform") -> Any:
    """Create the single-table with all GSIs matching data_stack.py.

    Returns the boto3 Table resource.
    """
    import boto3

    dynamodb = boto3.resource("dynamodb", endpoint_url=endpoint_url, region_name="us-east-1")

    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[
            {"AttributeName": "PK", "KeyType": "HASH"},
            {"AttributeName": "SK", "KeyType": "RANGE"},
        ],
        AttributeDefinitions=[
            {"AttributeName": "PK", "AttributeType": "S"},
            {"AttributeName": "SK", "AttributeType": "S"},
            {"AttributeName": "GSI1PK", "AttributeType": "S"},
            {"AttributeName": "GSI1SK", "AttributeType": "S"},
            {"AttributeName": "GSI2PK", "AttributeType": "S"},
            {"AttributeName": "GSI2SK", "AttributeType": "S"},
            {"AttributeName": "GSI3PK", "AttributeType": "S"},
            {"AttributeName": "GSI3SK", "AttributeType": "S"},
            {"AttributeName": "GSI4PK", "AttributeType": "S"},
            {"AttributeName": "GSI4SK", "AttributeType": "S"},
        ],
        GlobalSecondaryIndexes=[
            {
                "IndexName": "GSI1",
                "KeySchema": [
                    {"AttributeName": "GSI1PK", "KeyType": "HASH"},
                    {"AttributeName": "GSI1SK", "KeyType": "RANGE"},
                ],
                "Projection": {
                    "ProjectionType": "INCLUDE",
                    "NonKeyAttributes": ["task_type", "status", "user_id"],
                },
            },
            {
                "IndexName": "GSI2",
                "KeySchema": [
                    {"AttributeName": "GSI2PK", "KeyType": "HASH"},
                    {"AttributeName": "GSI2SK", "KeyType": "RANGE"},
                ],
                "Projection": {
                    "ProjectionType": "INCLUDE",
                    "NonKeyAttributes": ["task_type", "priority"],
                },
            },
            {
                "IndexName": "GSI3",
                "KeySchema": [
                    {"AttributeName": "GSI3PK", "KeyType": "HASH"},
                    {"AttributeName": "GSI3SK", "KeyType": "RANGE"},
                ],
                "Projection": {"ProjectionType": "KEYS_ONLY"},
            },
            {
                "IndexName": "GSI4",
                "KeySchema": [
                    {"AttributeName": "GSI4PK", "KeyType": "HASH"},
                    {"AttributeName": "GSI4SK", "KeyType": "RANGE"},
                ],
                "Projection": {"ProjectionType": "KEYS_ONLY"},
            },
        ],
        BillingMode="PAY_PER_REQUEST",
    )

    table.wait_until_exists()
    return table


def seed_manifest_fixture(table: Any, manifest_dict: dict[str, Any]) -> None:
    """Insert a test manifest as META + STATUS items.

    Args:
        table: boto3 DynamoDB Table resource.
        manifest_dict: Must contain ``execution_id``, ``tenant_id``, ``user_id``,
            ``task_type``, and ``status``.
    """
    exec_id = manifest_dict["execution_id"]
    tenant_id = manifest_dict["tenant_id"]
    user_id = manifest_dict["user_id"]
    status = manifest_dict.get("status", "pending")
    created_at = manifest_dict.get("created_at", "2026-01-01T00:00:00Z")

    table.put_item(
        Item={
            "PK": f"EXEC#{exec_id}",
            "SK": "META",
            "GSI1PK": f"TENANT#{tenant_id}",
            "GSI1SK": f"EXEC#{created_at}",
            "task_type": manifest_dict.get("task_type", "proposal_generation"),
            "status": status,
            "user_id": user_id,
            **{
                k: v
                for k, v in manifest_dict.items()
                if k
                not in {
                    "execution_id",
                    "tenant_id",
                    "user_id",
                    "status",
                    "task_type",
                    "created_at",
                }
            },
        }
    )

    table.put_item(
        Item={
            "PK": f"EXEC#{exec_id}",
            "SK": "STATUS",
            "GSI2PK": f"USER#{user_id}#STATUS#{status}",
            "GSI2SK": f"EXEC#{created_at}",
            "task_type": manifest_dict.get("task_type", "proposal_generation"),
            "status": status,
            "priority": manifest_dict.get("priority", "medium"),
            "tokens_used": 0,
            "cost_usd": "0.00",
        }
    )


def cleanup_table(table: Any) -> None:
    """Delete all items from the table (for per-test cleanup)."""
    scan = table.scan(ProjectionExpression="PK, SK")
    with table.batch_writer() as batch:
        for item in scan.get("Items", []):
            batch.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
