# Security Baseline Findings

Initial findings requiring remediation in dedicated runtime PRs:

- database credentials defined in source headers;
- legacy configuration suggests use of MySQL `root` with empty password;
- SQL is frequently assembled with formatted strings;
- account/test data exists in the versioned SQL dump;
- ban/session controls are split between files and database;
- admin/database responsibilities are not least-privilege separated.

Foundation documents these findings but does not silently change runtime credentials because doing so before deployment configuration exists would break the server. Remediation begins in the persistence/security branch.
