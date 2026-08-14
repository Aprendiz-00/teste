# Initial Modernization Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| protocol incompatibility | critical | byte-level compatibility tests before replacement |
| FileDB corruption | critical | adapters, fixtures, backup/restore tests |
| inventory/economy duplication | critical | transactional boundaries and audit events |
| login/session regression | critical | end-to-end login/save/reconnect tests |
| DB injection/unsafe lifetime | critical | prepared statements, RAII, focused fixes |
| tick latency regression | high | metrics/profiling before and after domain extraction |
| premature microservices | high | ADR-0001 modular monolith first |
| hidden machine dependencies | high | legacy preflight + reproducible dependency work |
| configuration drift | high | versioned schemas/config contracts |
| large unreviewable refactors | high | small branches/PRs and explicit rollback |
