# Performance Measurement Targets

Before optimizing or partitioning the world server, measure:

- p50/p95/p99 world tick duration;
- connected/active players;
- packet throughput and queue depth;
- per-system CPU time after domain extraction;
- DB query/save latency;
- memory used by players/mobs/items/grids;
- disconnect/error rates;
- event-specific latency spikes.

No arbitrary concurrency or microservice target should replace profiling data.
