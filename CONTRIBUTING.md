# Contributing

## Branches

Use short-lived branches with one technical purpose:

- `architecture/...` — architecture/foundation;
- `build/...` — build and dependency management;
- `security/...` — security hardening;
- `persistence/...` — database/FileDB migration;
- `protocol/...` — packet contracts/serialization;
- `network/...` — transport/event loop;
- `game/...` — domain extraction or gameplay work;
- `content/...` — data/content pipeline.

## Commits

Prefer Conventional Commit style:

- `docs:` documentation only;
- `build:` build system/dependencies;
- `ci:` automation;
- `test:` tests;
- `security:` security controls;
- `fix:` bug fix preserving intended behavior;
- `refactor:` structural change without intended behavior change;
- `feat:` new behavior.

Keep commits reviewable and avoid mixing gameplay balancing with infrastructure refactors.

## Pull Requests

Every non-trivial PR should contain:

1. problem statement;
2. scope;
3. behavior compatibility statement;
4. validation/tests;
5. risks;
6. rollback plan;
7. ADR reference when architecture changes.

## Legacy compatibility

Changes affecting binary packet layouts, FileDB structures, item/mob structs, login/save/logout flow or combat calculations require explicit regression coverage before merge.

## Security

Never commit real credentials or user data. Follow `SECURITY.md`.

## Merge policy during modernization

Prefer squash merge for focused implementation PRs and regular merge only when preserving a meaningful multi-commit history is valuable. Never force-update `main`.
