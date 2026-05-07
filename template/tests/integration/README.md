# Integration Tests

## Overview

Integration tests validate that components work together correctly using local service emulators ({% if metadata_store == "dynamodb" %}DynamoDB Local{% elif metadata_store == "postgres" %}PostgreSQL/pgvector{% else %}project-specific services{% endif %}, Bedrock stubs) or real AWS dev resources.

## Mode Requirements

Integration tests run in **`offline`** mode by default (pinned by `conftest.py`). For tests that need real AWS services, use `local-live` mode with:

```
{% if metadata_store == "dynamodb" %}
DYNAMODB_ENDPOINT=http://localhost:8000
{% elif metadata_store == "postgres" %}
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE={{ project_slug }}
{% endif %}
APP_MODE=local-live
```

## Starting Local Services

```bash
{% if metadata_store == "dynamodb" %}docker-compose up dynamodb-local{% elif metadata_store == "postgres" %}docker-compose up postgres{% else %}# Add a service to docker-compose.yml after choosing a metadata store.{% endif %}
```

{% if metadata_store == "dynamodb" %}
DynamoDB Local runs on port 8000 by default. The `dynamodb_endpoint` fixture reads from `DYNAMODB_ENDPOINT` environment variable.
{% elif metadata_store == "postgres" %}
PostgreSQL with pgvector runs on port 5432 by default. The `postgres_connection_info` fixture reads from `POSTGRES_*` environment variables.
{% else %}
No metadata-store emulator is scaffolded when `metadata_store=none`.
{% endif %}

## Test Categories

### Smoke Tests (`test_healthcheck.py`)
- Run without any external services
- Validate FastAPI app starts and serves basic endpoints
- Always run in `offline` mode

{% if metadata_store == "dynamodb" %}
### DynamoDB Integration (`helpers/dynamodb.py`)
- Use DynamoDB Local for table creation, CRUD, and GSI queries
- `create_platform_table()` creates the single-table schema matching `data_stack.py` (GSI1–GSI4)
- `seed_manifest_fixture()` inserts test manifests (META + STATUS items)
- `cleanup_table()` removes all items between tests
{% elif metadata_store == "postgres" %}
### PostgreSQL Integration
- Use local PostgreSQL with pgvector for metadata and vector retrieval tests.
- Add migrations and test helpers once the project defines its metadata schema.
- Use Aurora RDS Data API only against live Aurora dev resources; standard RDS PostgreSQL uses direct pooled connections.
{% endif %}

### Bedrock Stub Tests (`helpers/bedrock_stub.py`)
- `BedrockConverseStub` provides configurable responses without network calls
- Supports error injection (throttle, timeout, validation errors)
- Token counting simulation for budget tracking tests

## Fixture Patterns

| Fixture | Scope | Purpose |
|---------|-------|---------|
| `_pin_offline_mode` | function (autouse) | Pins APP_MODE=offline |
| `_reset_singletons` | function (autouse) | Clears DI caches between tests |
{% if metadata_store == "dynamodb" %}
| `dynamodb_endpoint` | session | DynamoDB Local endpoint URL |
{% elif metadata_store == "postgres" %}
| `postgres_connection_info` | session | PostgreSQL connection settings |
{% endif %}
| `test_tenant_context` | function | Standard tenant/user/role claims |
| `api_client` | function | FastAPI TestClient with auth headers |

## Running Tests

```bash
# Smoke tests only (no external services needed)
python -m pytest tests/integration/test_healthcheck.py -v

# All integration tests ({% if metadata_store == "dynamodb" %}requires DynamoDB Local{% elif metadata_store == "postgres" %}requires PostgreSQL for metadata-store tests{% else %}no metadata-store emulator scaffolded{% endif %})
python -m pytest tests/integration/ -v

# With coverage
python -m pytest tests/integration/ --cov=src -v
```
