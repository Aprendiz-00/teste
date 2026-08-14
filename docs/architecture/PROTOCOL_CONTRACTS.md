# Legacy Protocol Layout Contracts

## Purpose

The client/server protocol is binary and depends on the exact in-memory layout of legacy message structures. Refactoring a field type, order, alignment, or compiler setting can therefore change the wire format even when the source still compiles.

`Source/Modern/Protocol/LegacyLayoutContracts.cpp` records the currently accepted layout as compile-time assertions.

## Protected baseline

The common `_MSG` header and its standard parameter variants are protected:

- `MSG_STANDARD`
- `MSG_STANDARDPARM`
- `MSG_STANDARDPARM2`
- `MSG_STANDARDSHORTPARM2`
- `MSG_STANDARDPARM3`

The core direction flags used in message type values are also protected.

The common header is expected to remain 12 bytes with these offsets:

| Field | Offset |
| --- | ---: |
| `Size` | 0 |
| `KeyWord` | 2 |
| `CheckSum` | 3 |
| `Type` | 4 |
| `ID` | 6 |
| `ClientTick` | 8 |

## Account login contract

The packed client-to-game account login packet is also protected before any authentication/network extraction work.

Current Win32 contract:

- packet type `_MSG_AccountLogin`: `0x020D`;
- confirmation type `_MSG_CNFAccountLogin`: `0x010A`;
- account password field: 12 bytes;
- account login field: 16 bytes;
- `MSG_AccountLogin` total size: 58 bytes;
- `AccountPassword` offset: 12;
- `AccountLogin` offset: 24;
- `MacAddres` offset: 40.

These assertions protect representation only. They do not change login validation, credential handling, session policy, decoding, or authentication behavior.

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

Additional contracts should be added incrementally for other generic login/session messages and high-risk client/game/database packets after their current layouts are verified on the Win32 build target.
