# DESIGN.md — BRACE Take-Home: Airport Baggage Conveyor

## Summary
This project implements a simple airport-style baggage conveyor:
- A 100-stud conveyor belt exists in the world and defines the path.
- Bags spawn at the belt origin every X seconds (default 1s).
- Bags move forward along the belt and are deleted at the end.
- Each bag is unique (BagId) and has server-authoritative randomized color/material.
- Clicking a bag prints its ID on both client and server.
- Spawn interval is controlled by a UI that only one player (controller) can use.

The implementation is intentionally minimal and framework-free to keep scope tight and the system easy to review, extend, and debug.

---

## Goals
- **Server authoritative state**: all players see the same bag visuals and IDs.
- **Deterministic behavior**: belt path and bag motion are consistent and debuggable.
- **Performance-aware**: avoid unnecessary physics cost and avoid unbounded growth.
- **Incremental development**: small commits per feature/fix/change with clear intent.

## Non-Goals
- Full physics simulation of a conveyor (bag pushing, collisions, stacking).
- Complex networking frameworks or ECS architecture.
- Persistence (DataStore) or long-term analytics/telemetry.
- Highly polished art/UX beyond.

---

## High-Level Architecture

### Composition root (ServerscriptService/server/init.server.luau)
`MainServerscript` acts as the composition root: it wires core systems together exactly once at startup.
This keeps gameplay modules focused on their domain logic, and keeps dependency direction clear.


### Conveyor-first initialization
The conveyor is created first and defines the system’s coordinate frame:
- Start position (origin)
- Direction vector (forward axis)
- Length (100 studs)
- End position (deletion threshold)
- Speed (studs/sec)

This avoids hardcoding spawn points and keeps the bag system dependent on a single “ConveyorSpec”.

**ConveyorManager**
- Creates the belt parts (semi-static, anchored).
- Returns a `ConveyorSpec` used by BagManager.

**BagManager**
- Owns bag lifecycle and metadata:
  - spawn timing
  - unique IDs
  - deterministic visuals (color/material)
  - movement along conveyor
  - deletion at end
- Depends only on `ConveyorSpec` (no circular dependencies).

## Dependency Injection Boundary (ControllerService)
Client-facing networking (RemoteEvents, controller selection, request validation) is isolated in
`ControllerService`. Instead of requiring `BagManager` directly inside this module, `ControllerService`
receives a small injected API surface from the composition root.

Example injected API:
- `SetInterval(seconds)` — update spawn interval (server-authoritative, clamped)
- `IsBag(instance)` — optional validation hook for click events

This keeps networking concerns separate from gameplay logic and prevents a monolithic bootstrap script.
It also keeps the dependency direction one-way: "remotes → gameplay API", rather than coupling gameplay
modules to networking implementation details.

### Remote ownership and authorization
RemoteEvents are created and owned server-side by `ControllerService`. This module is also responsible for:
- selecting a single "controller" player who is allowed to change spawn interval
- validating client requests (type checks, authorization checks, server-side clamping)
- routing validated requests to the injected gameplay API

`BagManager` does not know about remotes or player authorization rules; it only exposes gameplay functions.


---

## Data Model

### Instance vs metadata
- **Instance state**: what needs to replicate to all clients (visuals + BagId attribute).
- **Metadata table**: authoritative server tracking for logic (distance, spawn time, state, etc).

Bags are registered in a server table keyed by instance:

```lua
Bags[bagInstance] = {
  BagId = "...",
  Color = Color3,
  Material = Enum.Material,
  Distance = number, -- studs progressed along belt
  SpawnedAt = number,
}
```