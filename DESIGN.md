# DESIGN.md — BRACE Take-Home: Airport Baggage Conveyor

## Summary
This project implements a simple airport-style baggage conveyor system:

- A 100-stud conveyor belt exists in the world and defines the motion path.
- Bags spawn at the belt origin every X seconds (default: 1s).
- Bags move forward along the belt and are deleted at the end.
- Each bag is uniquely identified (BagId) and has server-authoritative randomized color/material.
- Clicking a bag prints its BagId on both client and server.
- Spawn interval is controlled by a UI that only one player (controller) can use.

The implementation is intentionally minimal and framework-free to keep scope tight, performance predictable, and the system easy to review and reason about.

---

## Goals
- **Server-authoritative identity and lifecycle**  
  Bag creation, deletion, and validation are owned by the server.
- **Deterministic visuals across clients**  
  All clients see the same bags with the same timing, colors, and paths.
- **Network efficiency**  
  Avoid per-frame replication and unnecessary physics.
- **Clear separation of concerns**  
  Networking, gameplay logic, and rendering are isolated.
- **Incremental development**  
  Features are built and committed in small, reviewable steps.

## Non-Goals
- Full physics simulation (collisions, stacking, pushing).
- Heavy networking frameworks or ECS architectures.
- Persistence or long-term analytics.
- Highly polished UI/UX beyond assignment requirements.

---

## High-Level Architecture

### Composition Root (ServerScriptService/server/ServerInit.server.luau)
`ServerInit` acts as the composition root. It wires core systems together exactly once at startup:

- Initializes the conveyor.
- Initializes bag spawning/deletion logic.
- Injects gameplay APIs into client-facing services.

This prevents a monolithic bootstrap script and keeps dependencies flowing in one direction.

---

### Conveyor-First Initialization
The conveyor is created first and defines the global motion frame:

- Start position
- Direction vector
- Length (100 studs)
- Speed (studs/sec)

This avoids hardcoded spawn points and ensures all bag motion derives from a single shared definition.

**ConveyorManager**
- Creates semi-static, anchored conveyor visuals.
- Produces a `ConveyorSpec` describing motion parameters.

---

### Bag Lifecycle Management (Server)

**BagManager**
- Owns bag spawning cadence.
- Generates unique BagIds.
- Randomizes deterministic visuals (color/material).
- Decides when a bag should be deleted.
- Publishes conveyor parameters and bag metadata for clients.

The server **does not** animate or move bag parts.

Instead, it creates lightweight **BagRecord** objects:
- Represented as `Folder` instances under `ReplicatedStorage/Bags`
- Each record contains replicated attributes:
  - `BagId`
  - `SpawnT` (server time)
  - Color (R/G/B)
  - Material name

When a bag reaches the end of the conveyor (computed by time × speed), the server destroys the BagRecord.

---

## Client Rendering Model

### BagRecords → Local Visuals
Clients listen for BagRecord creation/removal and render bags locally:

- When a BagRecord appears:
  - Create a local, non-replicated Part.
  - Apply color/material from attributes.
  - Play spawn VFX (pop + drop + bounce).
- Every frame:
  - Compute distance from `(now - SpawnT) * speed`.
  - Position the bag along the conveyor direction.
  - Apply smoothing/interpolation locally.
- When a BagRecord is removed:
  - Play despawn VFX (lift + shrink).
  - Destroy the local visual.

This model ensures:
- Smooth motion
- Deterministic behavior
- Near-zero network cost for movement

---

## Dependency Injection Boundary (ControllerService)

Client-facing networking and authorization logic is isolated in `ControllerService`.

Responsibilities:
- Creating and owning RemoteEvents.
- Selecting a single “controller” player.
- Validating client requests.
- Forwarding validated actions to injected gameplay APIs.

Instead of requiring `BagManager` directly, `ControllerService` receives a small injected API from the composition root, such as:
- `SetInterval(seconds)`
- `IsBagId(bagId)`

This keeps networking concerns decoupled from gameplay logic and avoids circular dependencies.

---

## Remote Ownership and Authorization
All RemoteEvents are created and owned server-side by `ControllerService`.

Authorization rules:
- Only the controller player may change spawn interval.
- Click events are validated server-side using BagId lookup.
- Clients never directly control bag state.

`BagManager` has no knowledge of remotes or players.

---

## Replication & Performance Strategy

### Key Optimization
An early approach moved server-owned bag parts every Heartbeat, causing excessive transform replication.

The final design:
- Replicates **only bag metadata** (BagRecords + attributes).
- Clients simulate motion deterministically from shared inputs.
- Server remains authoritative over creation, deletion, and validation.

Result:
- Motion replication cost ≈ 0
- Network traffic scales with events, not frames
- Visual smoothness improves with client-side interpolation

---

## Data Model

### Server-Side (Authoritative)
- **BagRecord (Folder, replicated)**
  - Attributes: `BagId`, `SpawnT`, `Color`, `Material`
- Optional internal tables for fast validation or bookkeeping.

### Client-Side (Render State)
- Local mapping of `BagRecord → VisualPart`
- Transient render-only state:
  - spawn/despawn animation
  - interpolation
  - visual offsets

No client-rendered data is trusted for gameplay decisions.

---

## Summary
This architecture prioritizes clarity, determinism, and performance.  
By separating **authority**, **replication**, and **rendering**, the system scales cleanly while remaining easy to reason about and extend.

