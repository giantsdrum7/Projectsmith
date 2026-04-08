"""Cognito JWT validation stub with deny-by-default semantics.

In OFFLINE mode returns a synthetic test user context (no network call).
In LOCAL_LIVE / PROD mode, extracts tenant_id and groups from JWT claims
and enforces deny-by-default: empty or missing ``cognito:groups`` → 403.

TODO: Implement full JWKS fetch and RS256 verification post-generation.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any

from fastapi import Depends, HTTPException, Request

from {{ project_slug }}.config.mode import AppMode, get_current_mode


@dataclass(frozen=True)
class UserContext:
    """Authenticated user context extracted from JWT claims."""

    tenant_id: str
    user_id: str
    groups: list[str] = field(default_factory=list)
    email: str = ""

    @property
    def is_admin(self) -> bool:
        return "admin" in self.groups


_OFFLINE_TEST_USER = UserContext(
    tenant_id="test-tenant",
    user_id="test-user-001",
    groups=["admin", "proposal_author"],
    email="test@example.com",
)


def _get_jwks_url() -> str:
    """Construct Cognito JWKS URL from environment variables."""
    region = os.environ.get("AWS_REGION", "us-east-1")
    pool_id = os.environ.get("COGNITO_USER_POOL_ID", "")
    return f"https://cognito-idp.{region}.amazonaws.com/{pool_id}/.well-known/jwks.json"


def _extract_bearer_token(request: Request) -> str | None:
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        return auth_header[7:]
    return None


async def get_current_user(request: Request) -> UserContext:
    """FastAPI dependency that extracts and validates the current user.

    Deny-by-default: empty or missing ``cognito:groups`` → 403 Forbidden.
    In OFFLINE mode, returns a synthetic test user context.
    """
    mode = get_current_mode()

    if mode == AppMode.OFFLINE:
        return _OFFLINE_TEST_USER

    token = _extract_bearer_token(request)
    if not token:
        raise HTTPException(status_code=401, detail="Missing authorization token")

    # TODO: Implement full JWKS fetch and RS256 verification
    # 1. Fetch JWKS from _get_jwks_url() (cache keys)
    # 2. Decode JWT header to get kid
    # 3. Verify signature with matching public key
    # 4. Validate claims (exp, iss, aud, token_use)
    # 5. Extract tenant_id and groups from claims
    #
    # For now, reject all tokens in non-offline mode to enforce
    # deny-by-default until verification is implemented.
    claims: dict[str, Any] = {}  # placeholder for decoded claims

    groups: list[str] = claims.get("cognito:groups", [])
    if not groups:
        raise HTTPException(
            status_code=403,
            detail="Access denied: no authorized groups in token",
        )

    return UserContext(
        tenant_id=claims.get("custom:tenant_id", ""),
        user_id=claims.get("sub", ""),
        groups=groups,
        email=claims.get("email", ""),
    )


RequireAuth = Depends(get_current_user)
