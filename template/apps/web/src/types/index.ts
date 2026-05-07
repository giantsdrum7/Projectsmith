/**
 * Re-export generated contract types.
 *
 * Types in ./generated/ are produced by running:
 *   npm run generate-types
 *
 * See packages/contracts/scripts/generate_ts_types.py for the generation pipeline.
 * Never hand-write types that should come from contracts.
 */

export type {
  BrandConfig,
  FeatureFlags,
  NavItem,
  ClientConfig,
} from "@/contexts/ClientConfigProvider";
