# Merge Gates

For modernization branches:

- modern CI green where applicable;
- legacy preflight completed;
- diff reviewed for accidental runtime changes;
- no new secrets;
- rollback documented;
- architecture decision referenced for boundary changes.

Runtime-facing high-risk PRs add focused regression tests before merge.
