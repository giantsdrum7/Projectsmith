"""{% if metadata_store == "postgres" %}Placeholder for PostgreSQL/pgvector retrieval backend.

SHELL ONLY — no concrete search implementation. PostgreSQL-backed projects
start with pgvector in Aurora PostgreSQL. Add Bedrock Knowledge Bases or
OpenSearch Serverless only after retrieval quality evaluation shows pgvector is
insufficient.
{% else %}Placeholder for search backend (Bedrock Knowledge Bases or OpenSearch Serverless).

SHELL ONLY — no concrete search implementation. The choice between Bedrock KB
and OpenSearch Serverless is made post-generation based on retrieval quality
evaluation (Deliverable 3, Section 3.4).

V1 target: Bedrock Knowledge Bases (start managed, earn custom).
Pre-approved fallback: OpenSearch Serverless (if KB retrieval quality < 80% recall).

Resources created:
- IAM roles for KB/OpenSearch access
- Config context key for search backend choice

Implements:
- Deliverable 3, Section 3.4 (Retrieval for Proposals)
- Deliverable 4, Section 2.2 (search_stack.py — shell starter)
{% endif %}
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Stack,
    aws_iam as iam,
)
from constructs import Construct


class SearchStack(Stack):
    """{% if metadata_store == "postgres" %}pgvector retrieval placeholder with search-backend IAM hooks.{% else %}Search backend placeholder with IAM roles for KB/OpenSearch access.{% endif %}"""

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        config: dict[str, Any],
        namespace: str,
        **kwargs: Any,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        region = config.get("aws_region", "us-east-1")
        search_backend = config.get("search_backend", "{% if metadata_store == 'postgres' %}pgvector{% else %}bedrock-kb{% endif %}")

        # --- IAM Role for Search Access ---
        self.search_role = iam.Role(
            self,
            "SearchAccessRole",
            role_name=f"{namespace}-search-access",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            description=f"Search backend access role for {namespace}",
        )

        if search_backend == "bedrock-kb":
            # TODO: Configure search backend post-generation.
            # V1 target: Bedrock KB. Pre-approved fallback: OpenSearch Serverless.
            # See Deliverable 3 Section 3.4 for the evaluation gate:
            #   1. Curate proposal-retrieval validation set (min 20 queries)
            #   2. Evaluate Bedrock KB on recall and faithfulness
            #   3. If KB < 80% recall, activate OpenSearch Serverless fallback
            self.search_role.add_to_policy(
                iam.PolicyStatement(
                    sid="BedrockKBAccess",
                    effect=iam.Effect.ALLOW,
                    actions=[
                        "bedrock:Retrieve",
                        "bedrock:RetrieveAndGenerate",
                        "bedrock:ListKnowledgeBases",
                        "bedrock:GetKnowledgeBase",
                    ],
                    resources=["*"],
                )
            )
        elif search_backend == "opensearch":
            # TODO: Configure OpenSearch Serverless collection post-generation.
            # Only used if Bedrock KB fails the retrieval quality gate.
            # Patterns from HopeAI retrieval/supabase_backend.py (Extract-Knowledge-Only)
            # are available as reference: hybrid BM25 + vector + rerank.
            self.search_role.add_to_policy(
                iam.PolicyStatement(
                    sid="OpenSearchAccess",
                    effect=iam.Effect.ALLOW,
                    actions=[
                        "aoss:APIAccessAll",
                    ],
                    resources=[f"arn:aws:aoss:{region}:*:collection/*"],
                )
            )
        else:
{% if metadata_store == "postgres" %}
            # PostgreSQL/pgvector path. Access should be granted by the data
            # access role once the project-specific RDS/Aurora stack is added.
            # RDS Data API is Aurora-only; standard RDS PostgreSQL needs direct
            # network access and connection pooling.
{% elif metadata_store == "dynamodb" %}
            # DynamoDB-backed projects keep metadata in DynamoDB and choose a
            # retrieval backend after evaluation. Add backend-specific IAM here.
{% else %}
            # No metadata store or retrieval backend is scaffolded yet. Add
            # backend-specific IAM here after selecting the project retrieval path.
{% endif %}
            pass

        # TODO: Add search-specific alarms post-generation:
        # - {% if metadata_store == "postgres" %}pgvector query latency P99{% else %}KB/OpenSearch latency P99{% endif %}
        # - Retrieval error rate
        # - Index freshness (time since last document ingestion)
