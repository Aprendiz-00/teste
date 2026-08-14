# Modernization Working Agreement

## Definition of Done for infrastructure work

A change is complete when:

- scope is explicit;
- code/config is versioned;
- automated validation exists where feasible;
- no secret is introduced;
- compatibility impact is documented;
- rollback is known;
- architecture decision is recorded when necessary.

## Change isolation

Do not combine in the same PR:

- network rewrite + combat balance;
- persistence migration + item rebalance;
- protocol layout change + unrelated event content;
- build tool migration + large gameplay refactor.

## Risk levels

### Low

Documentation, isolated tooling, tests not used at runtime.

### Medium

Build settings, logging, configuration plumbing, adapters not yet on the hot path.

### High

Protocol, login/session, FileDB serialization, combat, inventory transactions, trade/economy, world state ownership.

High-risk changes require focused tests and explicit rollback.
