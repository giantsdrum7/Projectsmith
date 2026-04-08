# Integration Tests

## Overview

Integration tests validate that components work together correctly using local service emulators (DynamoDB Local, Bedrock stubs) or real AWS dev resources.

## Mode Requirements

Integration tests run in **`offline`** mode by default (pinned by `conftest.py`). For tests that need real AWS services, use `local-live` mode with:

```
DYNAMODB_ENDPOINT=http://localhost:8000
APP_MODE=local-live
```

## Starting Local Services

```bash
docker-compose up dynamodb-local
```

DynamoDB Local runs on port 8000 by default. The `dynamodb_endpoint` fixture reads from `DYNAMODB_ENDPOINT` environment variable.

## Test Categories

### Smoke Tests (`test_healthcheck.py`)
- Run without any external services
- Validate FastAPI app starts and serves basic endpoints
- Always run in `offline` mode

### DynamoDB Integration (`helpers/dynamodb.py`)
- Use DynamoDB Local for table creation, CRUD, and GSI queries
- `create_platform_table()` creates the single-table schema matching `data_stack.py` (GSI1–GSI4)
- `seed_manifest_fixture()` inserts test manifests (META + STATUS items)
- `cleanup_table()` removes all items between tests

### Bedrock Stub Tests (`helpers/bedrock_stub.py`)
- `BedrockConverseStub` provides configurable responses without network calls
- Supports error injection (throttle, timeout, validation errors)
- Token counting simulation for budget tracking tests

## Fixture Patterns

| Fixture | Scope | Purpose |
|---------|-------|---------|
| `_pin_offline_mode` | function (autouse) | Pins APP_MODE=offline |
| `_reset_singletons` | function (autouse) | Clears DI caches between tests |
| `dynamodb_endpoint` | session | DynamoDB Local endpoint URL |
| `test_tenant_context` | function | Standard tenant/user/role claims |
| `api_client` | function | FastAPI TestClient with auth headers |

## Running Tests

```bash
# Smoke tests only (no external services needed)
python -m pytest tests/integration/test_healthcheck.py -v

# All integration tests (requires DynamoDB Local)
python -m pytest tests/integration/ -v

# With coverage
python -m pytest tests/integration/ --cov=src -v
```
