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

The wrapper locates the installed Visual Studio/MSBuild toolchain with `vswhere.exe` and redirects outputs/intermediates to `out/legacy/<Configuration>` so developer-specific `OutDir` values do not control automation.

## MySQL headers

TMSrv and DBSrv now include the MySQL C API from the repository:

`Source/Code/include_mysql`

This removes the requirement to have `MySQL Connector C 6.1/include` installed at a developer-specific path merely to compile.

## Full link

For a full build, provide a **Win32-compatible** `libmysql.lib` directory:

```powershell
$env:WYD_MYSQL_LIB_DIR = 'C:\path\to\mysql\lib'
./tools/build/Build-Legacy.ps1 -Configuration Release -Project All
```

The wrapper verifies `libmysql.lib` exists before invoking the full `Build` target.

The library is intentionally not committed as an opaque binary dependency. A reproducible source/package provenance for the required connector remains a tracked build-hardening item.

## CI

`.github/workflows/legacy-compile.yml` runs the Release/Win32 compile-only gate on Windows.

This gate is useful because it detects:

- missing headers;
- C++ syntax/type regressions;
- incompatibilities introduced by modern compatibility shims;
- project/source drift.

It does **not** claim that deployable server binaries were linked.

## Remaining debt

- machine-specific paths are still present in legacy `.vcxproj` files;
- Release/Debug CRT configuration requires audit;
- `libmysql.lib` provenance/version must be made reproducible;
- solution x64 labels still map to Win32 for multiple legacy projects.

These will be handled after the compile gate provides a reliable feedback loop.
