"""Smoke tests for the contracts package pipeline.

Validates that:
- SampleManifest imports and instantiates
- Serialization round-trips through JSON
- model_json_schema() produces valid JSON with expected structure
"""

import json
from datetime import datetime

from idi_platform_contracts import SampleManifest


class TestSampleManifest:
    def test_create_instance(self) -> None:
        m = SampleManifest(sample_id="test-001", name="Test Sample")
        assert m.sample_id == "test-001"
        assert m.name == "Test Sample"
        assert m.value == 0.0
        assert isinstance(m.created_at, datetime)
        assert m.tags == []

    def test_serialize_deserialize(self) -> None:
        m = SampleManifest(
            sample_id="test-002",
            name="Round Trip",
            value=42.5,
            tags=["alpha", "beta"],
        )
        json_str = m.model_dump_json()
        restored = SampleManifest.model_validate_json(json_str)
        assert restored.sample_id == m.sample_id
        assert restored.name == m.name
        assert restored.value == m.value
        assert restored.tags == m.tags

    def test_json_schema_structure(self) -> None:
        schema = SampleManifest.model_json_schema()
        assert isinstance(schema, dict)
        assert "properties" in schema
        assert "sample_id" in schema["properties"]
        assert "name" in schema["properties"]
        assert "value" in schema["properties"]
        assert "created_at" in schema["properties"]
        assert "tags" in schema["properties"]

        json_str = json.dumps(schema)
        reparsed = json.loads(json_str)
        assert reparsed == schema

    def test_extra_fields_ignored(self) -> None:
        m = SampleManifest(
            sample_id="test-003",
            name="Extra Fields",
            unexpected_field="should be ignored",
        )
        assert m.sample_id == "test-003"
        assert not hasattr(m, "unexpected_field")
