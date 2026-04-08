"""Sample manifest model for validating the contracts pipeline.

This model exists to verify that:
1. The package installs correctly
2. Pydantic v2 model definition works
3. JSON Schema generation produces valid output
4. The TypeScript type generation script has something to process

Replace or extend with real contract models post-generation.
"""

from datetime import datetime

from pydantic import BaseModel, Field

__all__ = ["SampleManifest"]


class SampleManifest(BaseModel):
    """Minimal sample model exercising the Pydantic v2 contract pattern."""

    model_config = {"extra": "ignore"}

    sample_id: str = Field(description="Unique identifier for the sample")
    name: str = Field(description="Human-readable name")
    value: float = Field(default=0.0, description="Numeric value for testing serialization")
    created_at: datetime = Field(default_factory=datetime.utcnow, description="Creation timestamp")
    tags: list[str] = Field(default_factory=list, description="Arbitrary tags for testing collection fields")
