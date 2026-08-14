# Protocol Compatibility Policy

The legacy WYD wire protocol is a compatibility boundary during migration.

Before active protocol code is replaced:

- capture synthetic packet fixtures;
- assert exact sizes/offsets for critical structs;
- test encode/decode roundtrip;
- centralize invalid-size/checksum rejection;
- preserve packet IDs expected by the current client;
- introduce version negotiation only through an explicit ADR.

Protocol modernization must be performed in a dedicated PR, not folded into Foundation.
