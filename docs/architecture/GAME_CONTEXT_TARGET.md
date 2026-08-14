# GameContext Target

`GameContext` will become the explicit access point for runtime world state now exposed through globals.

Initial responsibilities are expected to provide controlled access to:

- player registry;
- mob registry;
- item registry;
- spatial/grid state;
- clock/scheduler;
- guild/event state facades.

It is not intended to become a new god object. Domains should receive the smallest interfaces they need, with `GameContext` serving as migration boundary while globals are retired.
