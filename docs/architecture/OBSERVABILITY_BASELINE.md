# Observability Baseline

Current server observability is primarily ad-hoc file/console logging. The modernization target will standardize:

- structured logs with event/category fields;
- connection/session counters;
- packets in/out and rejection reasons;
- world tick duration and overruns;
- active players/mobs/items;
- DB query latency/error counters;
- save latency/failures;
- economy-relevant audit events;
- crash diagnostics.

No telemetry backend is introduced in Foundation; this document defines the required measurement surface for later phases.
