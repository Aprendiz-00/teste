# Database Target Architecture

Target layering:

```text
Domain/Application
       |
Repository interfaces
       |
Persistence adapters
       |
Connection manager / prepared statements
       |
MySQL initially
```

Rules:

- no global query buffers in new code;
- result ownership is RAII-managed;
- credentials come from the configuration provider;
- new write flows define transaction boundaries;
- FileDB remains behind an adapter during migration;
- database migration is not coupled to packet representation.

## Runtime configuration contract

The compatibility path still accepts legacy defaults when database environment variables are absent. This avoids changing existing deployments merely by introducing the configuration provider.

Controlled deployments can set:

```text
WYD_DB_REQUIRE_ENV=1
```

When strict mode is enabled, the process rejects startup configuration unless all of these values are present and non-empty:

- `WYD_DB_HOST`
- `WYD_DB_USER`
- `WYD_DB_PASSWORD`
- `WYD_DB_NAME`

`WYD_DB_PORT` and `WYD_DB_CONNECT_TIMEOUT_SECONDS` remain optional and continue to use bounded parsing with their configured defaults.

Strict mode is intentionally opt-in during migration. It should be enabled after deployment configuration is managed outside the repository and the operator has verified all required values are injected.
