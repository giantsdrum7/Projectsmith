# Architecture — {{ project_name }}

> {% raw %}{{FILL: 1-2 sentence architecture summary}}{% endraw %}

## Entry Points
{% raw %}{{FILL: List primary entry points (API server, workers, CLI commands)}}{% endraw %}

## System Map (High Level)
{% raw %}{{FILL: Describe the high-level system flow — ingestion, processing, retrieval, API}}{% endraw %}

## Core Components

### Storage / Data Layer
{% raw %}{{FILL: Where data lives (S3, databases, search indexes)}}{% endraw %}

### Compute / Orchestration
{% raw %}{{FILL: How work gets done (Lambda, ECS, Step Functions, etc.)}}{% endraw %}

### Metadata Layer
{% raw %}{{FILL: Operational source of truth (DynamoDB, PostgreSQL, etc.)}}{% endraw %}

### Search / Retrieval
{% raw %}{{FILL: How content is found (OpenSearch, vector DB, etc.)}}{% endraw %}

### Auth / Access Control
{% raw %}{{FILL: How users authenticate and what they can access}}{% endraw %}

## Data Flow
{% raw %}{{FILL: Describe the end-to-end data flow from ingestion to query response}}{% endraw %}

## Key Modules
| Module | Location | Purpose |
|--------|----------|---------|
| {% raw %}{{FILL}}{% endraw %} | `src/{{ project_slug }}/...` | {% raw %}{{FILL}}{% endraw %} |

## Invariants
{% raw %}{{FILL: List non-negotiable architectural rules (e.g., "every answer must cite evidence")}}{% endraw %}

## Infrastructure Identifiers
| Resource | Dev | Prod |
|----------|-----|------|
| {% raw %}{{FILL}}{% endraw %} | {% raw %}{{FILL}}{% endraw %} | {% raw %}{{FILL}}{% endraw %} |

---
*This document is the canonical architecture reference. Keep it current as the system evolves.*
