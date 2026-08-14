# Foundation Review Notes

- The new root CMake project does **not** replace `Source/The New World.sln`.
- Only dependency-isolated modern code is built by CMake in this phase.
- The legacy preflight is intentionally diagnostic; known MySQL/path debt produces warnings, not false green claims.
- No server SQL schema, packet layout, FileDB layout, combat logic or login flow is modified by Foundation.
- Rollback is a normal revert with no database action.
