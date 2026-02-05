## Goals
- Server authoritative bag data + Attribute for anti spoofing
- Deterministic visuals across clients
- Simple, performant conveyor movement

## Non-Goals
- Physics-based conveyor
- Persistent storage
- Complex frameworks and libs

## Initial Approach
- Server spawns anchored bags with GUIDs
- Heartbeat-based movement using deltatime
- Single controller UI for spawn interval

## Alternatives Considered
- Physics conveyor (rejected for perf + nondeterminism)
- Tween-only motion (rejected for overall flexibility , debugability and performance)
