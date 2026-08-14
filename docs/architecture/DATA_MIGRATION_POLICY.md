# Data Migration Policy

Persistent data changes require stricter controls than code-only refactors.

## Rules

- schema migrations are versioned;
- migrations are forward-tested and rollback/restore strategy is documented;
- FileDB-to-SQL migration is incremental;
- no destructive migration is combined with unrelated gameplay work;
- identifiers used by client/protocol remain stable unless explicitly versioned;
- pre-migration backup and restore verification are mandatory for production.

Foundation performs no persistent data migration.
