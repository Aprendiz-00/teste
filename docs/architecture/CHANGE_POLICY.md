# Change Policy

## Protected concepts

Until regression coverage exists, treat the following as compatibility-sensitive:

- packet IDs, sizes and binary layouts;
- FileDB binary layouts;
- login/save/logout ordering;
- inventory/trade atomicity;
- combat formulas;
- item effect encoding;
- guild/world persistent identifiers.

## PR sizing

Prefer a PR that can be understood from one technical objective. If a reviewer needs to reason about protocol, database, combat and event content simultaneously, the change is too broad.

## Migration rule

Add modern path -> validate parity -> migrate consumers -> observe -> remove legacy path.
