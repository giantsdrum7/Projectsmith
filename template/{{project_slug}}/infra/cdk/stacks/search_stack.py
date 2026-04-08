"""Placeholder for search backend (Bedrock Knowledge Bases or OpenSearch Serverless).

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
"""

from __future__ import annotations

from typing import Any

from aws_cdk import (
    Stack,
    aws_iam as iam,
)
from constructs import Construct


class SearchStack(Stack):
    """Search backend placeholder with IAM roles for KB/OpenSearch access."""

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
        search_backend = config.get("search_backend", "bedrock-kb")

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
        else:
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

        # TODO: Add search-specific alarms post-generation:
        # - KB/OpenSearch latency P99
        # - Retrieval error rate
        # - Index freshness (time since last document ingestion)
