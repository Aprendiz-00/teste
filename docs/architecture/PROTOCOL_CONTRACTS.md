# Legacy Protocol Layout Contracts

## Purpose

The client/server protocol is binary and depends on the exact in-memory layout of legacy message structures. Refactoring a field type, order, alignment, or compiler setting can therefore change the wire format even when the source still compiles.

`Source/Modern/Protocol/LegacyLayoutContracts.cpp` records the currently accepted layout as compile-time assertions.

## Protected baseline

The first contract set protects the common `_MSG` header and its standard parameter variants:

- `MSG_STANDARD`
- `MSG_STANDARDPARM`
- `MSG_STANDARDPARM2`
- `MSG_STANDARDSHORTPARM2`
- `MSG_STANDARDPARM3`

It also protects the core direction flags used in message type values.

The common header is expected to remain 12 bytes with these offsets:

| Field | Offset |
| --- | ---: |
| `Size` | 0 |
| `KeyWord` | 2 |
| `CheckSum` | 3 |
| `Type` | 4 |
| `ID` | 6 |
| `ClientTick` | 8 |

## CI-only integration

The contracts are added to TMSrv and DBSrv only when `WYD_ENABLE_PROTOCOL_CONTRACTS=true`.

The Windows legacy compile workflow sets this property and compiles both projects. Normal runtime builds do not add the contract translation unit, so this guard cannot change the linked server binaries.

## Change rule

A failed layout assertion is not a warning to suppress. It means one of the following must be established before changing the expected value:

1. the old layout was documented incorrectly;
2. the protocol version is intentionally changing together with every producer and consumer;
3. a compiler/platform ABI assumption changed and compatibility must be addressed explicitly.

The expected values should never be updated merely to make CI green.

## Next expansion

Additional contracts should be added incrementally for packed login messages and other high-risk client/game/database packets after their current layouts are verified on the Win32 build target.
