"""Shared enums for the IDI platform contract layer.

These are contract-level definitions from Group 1 (ExecutionManifest).
Values are locked — do not modify without advisory team approval.
"""

from enum import Enum

__all__ = ["TaskType", "ExecutionStatus", "Priority"]


class TaskType(str, Enum):
    """Discriminator for execution manifest extensions.

    Each task type maps to a specific manifest extension model
    (e.g., chat -> ChatExtension, proposal -> ProposalExtension).
    """

    chat = "chat"
    proposal = "proposal"
    task = "task"
    child = "child"


class ExecutionStatus(str, Enum):
    """Manifest-level execution statuses (Group 1 locked contract).

    Terminal statuses: succeeded, failed, cancelled, timed_out.
{% if metadata_store == "dynamodb" %}
    All status transitions use DynamoDB condition expressions.
{% elif metadata_store == "postgres" %}
    All status transitions should use PostgreSQL transactions or compare-and-swap updates.
{% else %}
    Define atomic status-transition rules when the project selects a metadata store.
{% endif %}
    """

    pending = "pending"
    queued = "queued"
    running = "running"
    awaiting_approval = "awaiting_approval"
    awaiting_input = "awaiting_input"
    paused = "paused"
    succeeded = "succeeded"
    failed = "failed"
    cancelled = "cancelled"
    timed_out = "timed_out"


class Priority(str, Enum):
    """Execution priority levels for orchestration scheduling."""

    critical = "critical"
    normal = "normal"
    background = "background"
