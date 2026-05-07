# Generated Types

This directory receives TypeScript types generated from the shared contracts package (`packages/contracts/`).

## How to generate

```bash
npm run generate-types
```

This runs `packages/contracts/scripts/generate_ts_types.py` which:
1. Discovers all Pydantic models in `idi_platform_contracts`
2. Generates JSON Schema files (`.schema.json`)
3. Optionally generates TypeScript declaration files (`.d.ts`) if `json-schema-to-typescript` is installed

## Rules

- **Never hand-write types in this directory** — they are overwritten on each generation run
- Regenerate after any change to models in `packages/contracts/`
- CI enforces that generated types are up to date
