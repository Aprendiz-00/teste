# Next Phase Entry Criteria

The next implementation branch is `persistence/mysql-safety-baseline`.

Before that branch changes runtime code, it must:

1. preserve public signatures unless a complete caller audit is available;
2. fix memory/resource lifetime defects with minimal behavior change;
3. avoid schema migrations in the same PR;
4. add regression-focused tests or static checks for each corrected class of defect;
5. keep FileDB behavior unchanged;
6. keep packet structs unchanged.

Initial targets:

- `Source/Code/TMSrv/wMySQL.cpp/.h`;
- `Source/Code/DBSrv/dbMySQL.cpp/.h`;
- configuration ownership;
- result/connection lifetime;
- unsafe return buffers;
- duplicated DB utility behavior.
