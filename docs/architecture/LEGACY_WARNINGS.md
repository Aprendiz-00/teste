# Legacy Compiler Warning Telemetry

## Why this exists

The legacy servers compile with a large historical warning backlog. Turning all warnings into errors at once would make the new clean-runner build gate unusable and would encourage blanket suppression instead of targeted fixes.

The current policy is therefore **measure first, reduce deliberately**.

## CI behavior

The Windows legacy compile gate captures the complete compile output in:

`out/legacy/Release/legacy-compile.log`

`tools/build/Summarize-LegacyWarnings.ps1` parses that log and writes an informational section to `GITHUB_STEP_SUMMARY` containing:

- total warning occurrences;
- number of unique warning codes;
- most frequent warning codes;
- files with the highest warning counts.

The telemetry step runs with `if: always()`, so diagnostics remain available when the compile itself fails.

## Blocking policy

Warnings do not currently change the job result. Existing blockers remain:

- C++/MSBuild compile errors;
- protocol layout contract failures;
- MySQL safety checks;
- modern CMake tests;
- legacy prerequisite checks.

A warning code should become blocking only after its existing backlog has been reduced to a known baseline or zero and the change has been reviewed for runtime compatibility.

## Recommended reduction order

Prioritize warnings that can reveal correctness problems before cosmetic/deprecation noise:

1. format/variadic argument mismatches;
2. suspicious control-flow warnings;
3. narrowing/truncation in identifiers, sizes, timestamps, money or combat values;
4. signed/unsigned boundary mismatches;
5. unsafe/deprecated CRT calls after behavior-preserving replacements are available.

Do not silence a warning globally merely to reduce the count.
