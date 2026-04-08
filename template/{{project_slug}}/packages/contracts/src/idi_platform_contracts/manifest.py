"""ExecutionManifest base model skeleton (Group 1 locked contract).

The full manifest extensions (ProposalExtension, ChatExtension, etc.)
are implemented post-generation per project requirements. This skeleton
provides the base fields shared across all execution types.
"""

from datetime import UTC, datetime

from pydantic import BaseModel, Field

from .enums import ExecutionStatus, TaskType

__all__ = ["ExecutionManifest"]


def _utcnow() -> datetime:
    return datetime.now(UTC)


class ExecutionManifest(BaseModel):
    """Base execution manifest — the core runtime object for all task types.

    Every top-level execution and delegated child task creates an instance.
    DynamoDB single-table design: META/STATUS/OUTPUT items per execution.
    """

    model_config = {"extra": "ignore"}

    schema_version: int = Field(default=1, description="Contract schema version for backward compatibility")
    task_type: TaskType = Field(description="Discriminator for manifest extension type")
    tenant_id: str = Field(description="Tenant identifier from Cognito custom:tenant_id")
    execution_id: str = Field(description="Unique execution identifier (ULID recommended)")
    status: ExecutionStatus = Field(default=ExecutionStatus.pending, description="Current execution status")
    created_at: datetime = Field(default_factory=_utcnow, description="Execution creation timestamp")

    # {% raw %}{{FILL: Add capability extensions post-generation}}{% endraw %}
    # Example extensions to add per project:
    #   - ProposalExtension (Group 2: template, sections, financial calc I/O)
    #   - ChatExtension (chat context, KB references, streaming state)
    #   - BudgetConsumed (token counts, cost tracking, MCP call counts)
