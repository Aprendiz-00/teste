# Legacy Build Blockers

Tracked blockers for a clean TMSrv/DBSrv build:

1. **MySQL linker library not provisioned** — source includes MySQL headers, but `libmysql.lib` is not present in the repository.
2. **Machine-specific paths** — project files contain absolute developer paths.
3. **Platform mapping debt** — solution exposes x64 names that map to Win32 configurations in several projects.
4. **Runtime/deploy mixing** — generated/native runtime binaries coexist with server data under `Server/`.
5. **Warning policy debt** — warning levels differ and Debug TMSrv historically disables warnings.

These are build-system defects, not reasons to rewrite gameplay. They will be removed incrementally with a Windows CI build as the acceptance gate.
