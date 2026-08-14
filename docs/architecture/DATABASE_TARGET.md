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
- credentials come from configuration provider;
- new write flows define transaction boundaries;
- FileDB remains behind an adapter during migration;
- database migration is not coupled to packet representation.
