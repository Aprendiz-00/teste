# Rollback Policy

Every modernization PR must identify rollback at the same level as the change.

- documentation/tooling: revert commit/PR;
- runtime code: revert plus compatibility validation;
- schema/data: restore/migration rollback plan;
- protocol: retain legacy adapter until client compatibility is proven;
- network: feature flag or selectable legacy transport during transition where practical.

Do not remove the last known-good path in the same step that introduces a high-risk replacement.
