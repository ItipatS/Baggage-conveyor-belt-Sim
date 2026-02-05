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

### Conveyor-first world definition
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