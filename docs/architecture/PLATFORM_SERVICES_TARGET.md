# Platform Services Target

Services that may be separated from the real-time world process when implemented:

- identity/auth API;
- admin/GM API;
- ranking/read-model API;
- launcher/patch manifest service;
- telemetry ingestion;
- website-facing account services.

Real-time combat/movement should remain in the world-server boundary unless profiling and architecture evidence justify otherwise.
