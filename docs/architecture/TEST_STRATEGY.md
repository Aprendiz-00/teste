# Modernization Test Strategy

## Test layers

1. **Foundation tests** — toolchain and isolated modern build.
2. **Compatibility tests** — binary layouts, packet fixtures, legacy file fixtures.
3. **Unit tests** — domain logic without network/database.
4. **Integration tests** — database repositories and adapters.
5. **Simulation tests** — deterministic world/combat scenarios.
6. **End-to-end smoke tests** — login -> character -> world -> save -> reconnect.

## Priority fixtures

- representative login packets;
- character/account FileDB samples containing synthetic data only;
- inventory save/load roundtrip;
- item effect encoding;
- attack/damage scenarios;
- trade commit/cancel scenarios.

Production user data must not be used as fixtures.
