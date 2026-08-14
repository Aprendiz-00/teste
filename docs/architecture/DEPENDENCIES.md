# Dependency Inventory — Initial

## Legacy server

| Dependency | Usage | Provisioning today | Modernization target |
|---|---|---|---|
| Visual C++ / MSVC | TMSrv, DBSrv, tools | developer machine | documented CI toolchain |
| Win32 API | process/window/timers | Windows SDK | isolate behind platform layer |
| Winsock2 | TCP networking | Windows SDK | protocol-independent transport abstraction |
| MySQL Connector C / `libmysql.lib` | TMSrv/DBSrv SQL | external machine install | declared/reproducible dependency |
| C runtime / legacy MSVC DLLs | runtime deployment | binaries in `Server/` | build/runtime artifact pipeline |

## Repository-provided source dependencies

`Source/Code/include_mysql` contains MySQL headers, but the linker library `libmysql.lib` was not found in the repository baseline. Headers alone are therefore insufficient for a clean link.

## Modern track

The initial modern CMake target intentionally uses only the C++ standard library. Third-party libraries will be introduced only through a declared package/dependency mechanism and accompanied by license/version documentation.

## Dependency policy

A new dependency must document:

1. purpose;
2. version/range;
3. source/provenance;
4. license;
5. build integration;
6. update strategy;
7. security implications when applicable.

Binary-only dependencies should be avoided where a reproducible source/package-manager path exists.
