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

### Bag Spawning
Bags are spawned server-side at a fixed interval using a Heartbeat dt accumulator to ensure
frame-rate independent timing. Each bag is assigned a unique BagId on spawn. In the initial
implementation, bags are left unanchored to validate visuals and interaction flow early;
this is intentionally temporary and revisited once conveyor motion is finalized.

Bags are registered in a server-side table keyed by instance, allowing metadata
to be tracked independently of the visual representation. Attributes are used only
for data that must be read by clients (BagId).

## Alternatives Considered
- Physics conveyor (rejected for perf + nondeterminism)
- Tween-only motion (rejected for overall flexibility , debugability and performance)
