"""LLM client factory.

Creates LLM clients based on the current mode and provider configuration.
Supports the 3-mode contract: offline returns stubs, local-live and prod
return real clients.

{% raw %}{{FILL: Implement for your LLM provider (Bedrock, OpenAI, etc.)}}{% endraw %}
"""

from __future__ import annotations

from typing import Any


def create_llm_client(*, mode: str | None = None) -> Any:
    """Create an LLM client appropriate for the current mode.

    Args:
        mode: Override the current app mode. If None, reads from APP_MODE.

    Returns:
        An LLM client instance (or stub in offline mode).

    Raises:
        NotImplementedError: Until provider-specific implementation is added.
    """
    raise NotImplementedError("LLM client factory not yet implemented.")
