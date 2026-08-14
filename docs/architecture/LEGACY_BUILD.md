# Legacy TMSrv/DBSrv Build

## Goal

Make the legacy C++ code verifiable on a clean Windows runner without pretending the external MySQL linker dependency is already solved.

## Build wrapper

Use:

```powershell
./tools/build/Build-Legacy.ps1 -Configuration Release -Project All -CompileOnly
```

This performs the C++ compile stage for TMSrv and DBSrv and intentionally skips the linker.

Supported options:

- `-Configuration Debug|Release`
- `-Project TMSrv|DBSrv|All`
- `-CompileOnly`

The wrapper locates the installed Visual Studio/MSBuild toolchain with `vswhere.exe` and redirects outputs/intermediates to `out/legacy/<Configuration>` for automated builds.

## Native MSBuild policy

`Source/Code/Directory.Build.targets` is imported automatically by MSBuild for the legacy projects below that directory. Its rules are scoped to `TMSrv` and `DBSrv` only.

It provides:

- C++17 for both Debug and Release;
- multiprocess compilation;
- the repository-owned MySQL include directory;
- a portable default `OutDir` under `Server/<ProjectName>/run`;
- optional MySQL library discovery through `WYD_MYSQL_LIB_DIR`.

Set `WYD_LEGACY_OUT_DIR` before invoking MSBuild if a different runtime output root is required. The CI wrapper still overrides `OutDir` and `IntDir` so automation remains isolated from runtime directories.

## MySQL dependency contract

`config/build-dependencies.json` is the source-controlled contract for the legacy MySQL client dependency.

Current baseline:

- MySQL Connector/C: **6.1.11**;
- server/protocol header family: **5.7.16**;
- target architecture: **Win32**;
- import library: `libmysql.lib`;
- headers: `Source/Code/include_mysql`;
- library provisioning: external.

The preflight compares the manifest with `Source/Code/include_mysql/mysql_version.h`. A header/version drift therefore fails CI until the dependency contract is reviewed and updated deliberately.

TMSrv and DBSrv use the MySQL C API headers from the repository, so compiling no longer requires a developer-specific Connector/C include path.

## Full link

For a full build, provide a **Connector/C 6.1.11 Win32-compatible** `libmysql.lib` directory:

```powershell
$env:WYD_MYSQL_LIB_DIR = 'C:\path\to\mysql\lib'
./tools/build/Build-Legacy.ps1 -Configuration Release -Project All
```

The wrapper verifies `libmysql.lib` exists before invoking the full `Build` target. The MSBuild policy also exposes the same directory to the linker when projects are built directly from Visual Studio/MSBuild.

The library is intentionally not committed as an opaque binary dependency. The manifest records the expected ABI/version family, but a fully reproducible external package acquisition plus cryptographic artifact verification still requires a reviewed source/package provenance before deployable binaries can be claimed reproducible.

## CI

`.github/workflows/legacy-compile.yml` runs the Release/Win32 compile-only gate on Windows. `Modern Foundation CI` also runs `Validate-LegacyBuild.ps1`, which checks the dependency manifest and the repository-wide provisioning assumption.

The compile gate detects:

- missing headers;
- C++ syntax/type regressions;
- MSBuild policy regressions;
- protocol layout contract regressions;
- incompatibilities introduced by modern compatibility shims;
- project/source drift.

It does **not** claim that deployable server binaries were linked.

## Remaining debt

- old machine-specific values still exist inside some legacy `.vcxproj` files, but the shared MSBuild policy overrides the relevant TMSrv/DBSrv build settings;
- Release/Debug CRT configuration requires a separate audit;
- external `libmysql.lib` acquisition/checksum provenance is not yet automated;
- solution x64 labels still map to Win32 for multiple legacy projects.

These items are handled separately so build-system cleanup does not silently change runtime behavior.
