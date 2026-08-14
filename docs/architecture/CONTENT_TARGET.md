# Content Engine Target

The content phase will migrate safe gameplay configuration from hardcoded C++ into versioned, validated data.

Candidate domains:

- drops;
- quests;
- events;
- crafting/composition recipes;
- shops;
- spawn/event schedules;
- balance tables;
- feature flags.

A content validator must reject invalid IDs, references, ranges and incompatible schema versions before the world server loads the data.
