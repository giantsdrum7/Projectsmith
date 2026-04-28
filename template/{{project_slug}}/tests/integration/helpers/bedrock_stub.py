"""Bedrock Converse stub for offline-mode integration tests.

Provides configurable responses, token counting simulation, and error
injection without any network calls.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


class BedrockConverseError(Exception):
    """Simulated Bedrock API error."""

    def __init__(self, error_type: str, message: str) -> None:
        self.error_type = error_type
        super().__init__(message)


@dataclass
class BedrockConverseStub:
    """Configurable stub for the Bedrock Converse API.

    Matches the interface pattern a real Bedrock Converse wrapper would use.
    Supports per-model/prompt response configuration, token counting simulation,
    and error injection.

    Usage::

        stub = BedrockConverseStub()
        stub.add_response("us.anthropic.claude-sonnet-4-6", "Hello!", input_tokens=10, output_tokens=5)
        result = stub.converse(model_id="us.anthropic.claude-sonnet-4-6", messages=[...])
    """

    responses: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    call_log: list[dict[str, Any]] = field(default_factory=list)
    _error_injection: dict[str, str] = field(default_factory=dict)

    def add_response(
        self,
        model_id: str,
        content: str,
        *,
        input_tokens: int = 100,
        output_tokens: int = 50,
    ) -> None:
        """Queue a response for a given model ID."""
        if model_id not in self.responses:
            self.responses[model_id] = []
        self.responses[model_id].append(
            {
                "content": content,
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
            }
        )

    def inject_error(self, model_id: str, error_type: str) -> None:
        """Configure error injection for a model ID.

        Supported error_type values: ``throttle``, ``timeout``, ``validation``.
        """
        self._error_injection[model_id] = error_type

    def clear_error(self, model_id: str) -> None:
        self._error_injection.pop(model_id, None)

    def converse(
        self,
        model_id: str,
        messages: list[dict[str, Any]],
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Simulate a Bedrock Converse API call.

        Returns a response dict matching the Bedrock Converse response shape.
        Raises ``BedrockConverseError`` if error injection is active.
        """
        self.call_log.append({"model_id": model_id, "messages": messages, **kwargs})

        if model_id in self._error_injection:
            error_type = self._error_injection[model_id]
            raise BedrockConverseError(error_type, f"Simulated {error_type} error for {model_id}")

        model_responses = self.responses.get(model_id, [])
        if not model_responses:
            return {
                "output": {"message": {"role": "assistant", "content": [{"text": "stub response"}]}},
                "usage": {"inputTokens": 0, "outputTokens": 0, "totalTokens": 0},
                "stopReason": "end_turn",
            }

        resp = model_responses.pop(0)
        total_tokens = resp["input_tokens"] + resp["output_tokens"]
        return {
            "output": {"message": {"role": "assistant", "content": [{"text": resp["content"]}]}},
            "usage": {
                "inputTokens": resp["input_tokens"],
                "outputTokens": resp["output_tokens"],
                "totalTokens": total_tokens,
            },
            "stopReason": "end_turn",
        }

    @property
    def total_input_tokens(self) -> int:
        return sum(call.get("usage", {}).get("inputTokens", 0) for call in self.call_log)

    def reset(self) -> None:
        """Clear all responses, call log, and error injections."""
        self.responses.clear()
        self.call_log.clear()
        self._error_injection.clear()
