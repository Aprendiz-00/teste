# Foundation PR Review Guide

Use this review guide for the initial modernization foundation.

## Scope

- documentation/governance;
- modern isolated build track;
- CI for modern track;
- legacy preflight audit;
- security/configuration contract documentation.

## Must not change

- packet behavior;
- login behavior;
- combat;
- items/drops;
- FileDB serialization;
- runtime server configuration.

## Review questions

1. Does any new file alter legacy runtime behavior?
2. Does CI accurately distinguish modern build from legacy preflight?
3. Are known build blockers documented instead of hidden?
4. Are secrets excluded from the new workflow?
5. Can every change be reverted without data migration?

## Expected answer

All runtime behavior remains unchanged and rollback is deletion/revert of Foundation-only files.
