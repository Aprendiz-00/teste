# Architecture Glossary

- **Legacy** — current TMSrv/DBSrv/CPSock/FileDB implementation retained for compatibility.
- **Modern track** — dependency-isolated C++ components built by root CMake.
- **Adapter** — compatibility boundary translating legacy representation to a modern contract.
- **GameContext** — future owner/facade for world state currently exposed through globals.
- **Content Engine** — validated/versioned data layer for gameplay content.
- **Platform service** — non-hot-path service such as auth/admin/ranking/launcher.
- **Strangler Pattern** — incremental replacement while old and new implementations coexist temporarily.
