# Database Configuration

## Runtime variables

TMSrv and DBSrv now consult the same environment contract before using legacy defaults.

| Variable | Purpose | Validation |
|---|---|---|
| `WYD_DB_HOST` | MySQL host/IP | non-empty string |
| `WYD_DB_USER` | application DB user | non-empty string |
| `WYD_DB_PASSWORD` | application DB password | non-empty value overrides legacy fallback |
| `WYD_DB_NAME` | database/schema name | non-empty string |
| `WYD_DB_PORT` | MySQL TCP port | integer `1..65535` |
| `WYD_DB_CONNECT_TIMEOUT_SECONDS` | connection timeout | integer `1..3600` |

See `config/database.env.example` for an example contract. The application does not parse `.env` files itself; deployment tooling is responsible for injecting environment variables.

## Precedence

```text
WYD_DB_* environment value
        |
        +-- present and valid --> use it
        |
        +-- absent/empty/invalid --> legacy fallback
```

The fallback exists only to preserve existing installations during migration.

## Production policy

A production deployment should set every required `WYD_DB_*` variable and use a dedicated least-privilege MySQL account. Do not use MySQL `root` for the game server.

Recommended separation as the platform evolves:

- game runtime account: gameplay persistence only;
- auth account: identity/session tables only;
- admin/migration account: schema migrations, not used by TMSrv;
- read-only analytics/ranking account when required.

## Secret handling

Do not commit the real values. A deployment secret manager may populate `WYD_DB_PASSWORD` (and the other values) at process startup; the server remains provider-agnostic.

## Compatibility note

This phase intentionally does not remove the old macros from the headers. Removal becomes safe only after deployments are migrated and caller/build compatibility has been proven.
