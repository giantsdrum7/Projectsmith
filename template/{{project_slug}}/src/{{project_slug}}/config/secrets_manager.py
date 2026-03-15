"""Secrets Manager integration.

Retrieves configuration from a secrets store (e.g., AWS Secrets Manager).
The pointer-config pattern: a small set of env vars point to a secrets
store entry that contains the full configuration.

{% raw %}{{FILL: Implement for your secrets provider}}{% endraw %}
"""

from __future__ import annotations


def get_secret(secret_id: str, *, region: str | None = None) -> dict:
    """Retrieve and parse a JSON secret by ID.

    Args:
        secret_id: The secret identifier (e.g., "myproject/dev/all").
        region: AWS region override. Defaults to env config.

    Returns:
        Parsed JSON secret as a dictionary.

    Raises:
        NotImplementedError: Until provider-specific implementation is added.
    """
    raise NotImplementedError(f"Secrets retrieval not yet implemented. Secret requested: {secret_id}")
